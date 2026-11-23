# Ejercicio 03 — Hooks de React

> Al terminar habrás escrito hooks que leen el token, leen el saldo de la wallet cuando la hay,
> resumen el estado de una transferencia, la envían desde un componente refrescando los saldos
> y reciben las transferencias entrantes en vivo.

**Duración estimada**: 2 h 30 min
**Prerrequisitos**: [Ejercicio 02](../ejercicio-02-leer-y-escribir/README.md) terminado;
[Teoría 01 — De la página a React](../../1-teoria/01-de-la-pagina-a-react.md) leída.

## Contexto

Los mismos datos que el ejercicio 02, ahora con los hooks de `wagmi`: lo que usará la página del
proyecto. Cada paso es un hook (o una función) de `src/hooks.ts`.

| Archivo | Qué es |
| ------- | ------ |
| `src/hooks.ts` | Los cinco pasos. Aquí trabajas |
| `src/config.ts`, `src/abi.ts` | Los del ejercicio 02 |
| `test/render.ts` | Prepara un navegador falso y monta tus hooks dentro de los proveedores. **No lo modifiques** |
| `test/hooks.test.ts` | Los tests. **No lo modifiques** |

Un hook solo se ejecuta dentro de un componente. Los tests usan `renderHook` de Testing Library:
crea un componente de prueba que llama a tu hook, lo monta con `WagmiProvider` y
`QueryClientProvider` sobre un DOM de [happy-dom](https://github.com/capricorn86/happy-dom) y
guarda el último resultado en `result.current`. `waitFor` repite una comprobación hasta que pasa
(o hasta 1 s). Así se prueba un hook sin abrir el navegador.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-18-dapp_con_react_y_wagmi/2-practicas/ejercicio-03-hooks-de-react/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: `ℹ fail 6` (el paso 4 tiene dos tests), cada uno con su `Error: TODO: Paso N`, y
`✔ sin errores de tipos`.

## Paso 1: Leer el token

**Por qué**: lo mismo que el paso 1 del ejercicio 02, pero el resultado vive en la caché y el
componente se vuelve a pintar cuando llega.

```ts
const contract = { address: token, abi: tokenAbi } as const;
const { data } = useReadContracts({
  allowFailure: false,
  contracts: [
    { ...contract, functionName: "name" },
    { ...contract, functionName: "symbol" },
    { ...contract, functionName: "decimals" },
  ],
});
return data && { name: data[0], symbol: data[1], decimals: data[2] };
```

**Verifica**: `✔ Paso 1`. El primer resultado es `undefined` y después llega
`{ name: "Bootcamp Token", symbol: "BCT", decimals: 18 }`.

## Paso 2: El saldo, cuando hay wallet

**Por qué**: sin wallet no hay cuenta, y un hook no puede ir dentro de un `if`. `enabled` deja
la lectura en espera.

```ts
const { address } = useConnection();
const { data } = useReadContract({
  address: token,
  abi: tokenAbi,
  functionName: "balanceOf",
  args: address && [address],
  query: { enabled: address !== undefined },
});
return data;
```

**Verifica**: `✔ Paso 2`: sin conectar, sigue en `undefined` tras 300 ms; con la cuenta 2,
`50000000000000000000n`.

## Paso 3: El estado en una palabra

**Por qué**: la interfaz necesita un solo valor para decidir el texto y si el botón está activo.
Sale del estado de la firma y del estado del recibo (teoría 04).

```ts
if (write === "idle") return "lista";
if (write === "pending") return "firmando";
if (write === "error" || receipt === "error") return "fallida";
return receipt === "success" ? "confirmada" : "confirmando";
```

**Verifica**: `✔ Paso 3`: las seis combinaciones de la tabla de la teoría 04.

## Paso 4: Enviar desde un componente

**Por qué**: es el flujo completo de la página: simular, pedir la firma, esperar el recibo y
refrescar lo que se ve.

```ts
const config = useConfig();
const queryClient = useQueryClient();
const [simulateError, setSimulateError] = useState<Error | null>(null);
const write = useWriteContract();
const receipt = useWaitForTransactionReceipt({ hash: write.data });
useEffect(() => {
  if (receipt.isSuccess) queryClient.invalidateQueries();
}, [receipt.isSuccess, queryClient]);
function send(to: Address, amount: bigint) {
  setSimulateError(null);
  simulateContract(config, {
    address: token,
    abi: tokenAbi,
    functionName: "transfer",
    args: [to, amount],
    chainId: config.chains[0].id,
  }).then(({ request }) => write.mutate(request), setSimulateError);
}
const error = simulateError ?? write.error ?? receipt.error;
return { send, status: error ? "fallida" : txStatus(write.status, receipt.status), error };
```

Necesita el paso 3. Prueba a quitar la simulación y llamar directamente a
`write.mutate({ address: token, abi: tokenAbi, functionName: "transfer", args: [to, amount] })`:
el segundo test del paso 4 falla porque el error llega como `custom error 0xe450d38c`, sin
nombre. Y prueba a quitar el `invalidateQueries`: el primero falla porque el saldo se queda en
100 BCT. Déjalo como estaba.

**Verifica**: los dos `✔ Paso 4`. El primero envía 10 BCT con la cuenta 1, guarda el estado de
cada render (`["lista", "firmando", "confirmando", "confirmada"]`) y ve el saldo bajar a 90 BCT.
El segundo envía 1000 BCT desde la cuenta 2 y acaba en `fallida` con
`ERC20InsufficientBalance` en el error.

## Paso 5: Transferencias entrantes, en vivo

**Por qué**: la página se entera de lo que te envía otra persona, sin recargar.

```ts
const { address } = useConnection();
const [received, setReceived] = useState<bigint[]>([]);
useWatchContractEvent({
  address: token,
  abi: tokenAbi,
  eventName: "Transfer",
  args: { to: address },
  enabled: address !== undefined,
  pollingInterval: 100,
  onLogs: (logs) => setReceived((list) => [...list, ...logs.map((log) => log.args.value ?? 0n)]),
});
return received;
```

No hay `unwatch`: el hook deja de escuchar cuando el componente se quita de la pantalla (el test
llama a `unmount` en un `finally`). `setReceived` recibe una función por lo que viste en la
teoría 01: dos tandas de eventos seguidas partirían de la misma lista vieja.

**Verifica**: `✔ Paso 5`, `ℹ pass 6` y `✔ sin errores de tipos`. La cuenta 2 envía 1 y 2 BCT a la
5 desde otra wallet, y el hook de la cuenta 5 recibe
`[1000000000000000000n, 2000000000000000000n]`.

## Qué aprendiste

- Los hooks de lectura devuelven `undefined` hasta que llegan los datos; `enabled` espera a la
  wallet.
- `useWriteContract` y `useWaitForTransactionReceipt` dan dos estados que se resumen en uno.
- Simular antes de `mutate` da errores con nombre; invalidar tras el recibo refresca la página.
- `useWatchContractEvent` escucha mientras el componente existe.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Leer y escribir](../ejercicio-02-leer-y-escribir/README.md) | **Ejercicio 03 — Hooks de React** | [Proyecto — La dApp del protocolo →](../../3-proyecto/README.md) |
