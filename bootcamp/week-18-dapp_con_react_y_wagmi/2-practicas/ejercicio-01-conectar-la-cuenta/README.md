# Ejercicio 01 — Conectar la cuenta

> Al terminar habrás escrito la configuración de wagmi, conectado una wallet, descrito la
> conexión en una línea, cambiado de red solo cuando hace falta y seguido cada cambio.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 02 — wagmi por dentro](../../1-teoria/02-wagmi-por-dentro.md) y
[Teoría 03 — Conectar la wallet](../../1-teoria/03-conectar-la-wallet.md) leídas.

## Contexto

Es un starter de TypeScript como los de la semana 17: cada paso es una función de
`src/wallet.ts` con su `throw new Error("TODO: Paso N");` y la solución en líneas `//> `. Esta
vez usas `@wagmi/core`, las acciones de wagmi, que funcionan en Node sin React.

| Archivo | Qué es |
| ------- | ------ |
| `src/wallet.ts` | Los cinco pasos. Aquí trabajas |
| `test/wallet.test.ts` | Los tests. **No lo modifiques** |

En Node no hay wallet de navegador. Los tests usan el conector `mock` de wagmi: dice tener la
cuenta 1 de anvil y, si hubiera que firmar, se lo pediría al nodo. Conectar y cambiar de red no
llegan al nodo, así que este ejercicio no arranca anvil.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-18-dapp_con_react_y_wagmi/2-practicas/ejercicio-01-conectar-la-cuenta/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: `ℹ fail 5`, los cinco con `Error: TODO: Paso 1` (todos los tests empiezan creando
la configuración), y `✔ sin errores de tipos`.

## Paso 1: La configuración

**Por qué**: todas las funciones de wagmi reciben la configuración: qué redes acepta la página,
cómo leer de cada una y con qué wallets conectar.

```ts
const anvil = { ...foundry, rpcUrls: { default: { http: [rpcUrl] } } };
return createConfig({
  chains: [anvil, sepolia],
  connectors: [connector],
  transports: { [anvil.id]: http(rpcUrl), [sepolia.id]: http() },
});
```

`anvil` es la red `foundry` de viem con otra URL. El transporte usa `rpcUrl` para leer, pero el
conector `mock` firma enviando al RPC de `rpcUrls`: sin cambiarlo, firmaría en el puerto 8545 y
no en el del test. Con una wallet real, `rpcUrls` es lo que wagmi le da si tiene que añadir la
red.

**Verifica**: `✔ Paso 1`. Los otros cuatro ya fallan con su propio `TODO`.

## Paso 2: Conectar

**Por qué**: hasta que la wallet acepta, la página no tiene cuenta.

```ts
return connect(config, { connector: config.connectors[0] });
```

Con una wallet real, aquí se abriría su ventana y la persona podría rechazar.

**Verifica**: `✔ Paso 2`: la cuenta es la 1 de anvil y la red, 31337.

## Paso 3: La conexión en una línea

**Por qué**: la cabecera de la página dice con quién está conectada y en qué red, y avisa si la
red no es de las suyas.

```ts
const { status, address, chain } = getConnection(config);
if (status !== "connected") return "Sin conectar";
if (!chain) return `${address} en una red no soportada`;
return `${address} en ${chain.name}`;
```

`chainId` es la red de la wallet; `chain`, la de la configuración con ese id. Si la wallet está
en una red que no está en `chains`, `chain` es `undefined`. El conector `mock` no puede
conectarse a una red que no esté en la configuración, así que el test no prueba esa rama; con
una wallet real ocurre a menudo.

**Verifica**: `✔ Paso 3`: `Sin conectar` y, al conectar,
`0x70997970C51812dc3A010C7d01b50e0d17dc79C8 en Foundry` (`Foundry` es el nombre de la red en
viem).

## Paso 4: Cambiar de red solo si hace falta

**Por qué**: antes de escribir, la wallet tiene que estar en la red del contrato. Pedir el
cambio cuando ya lo está abriría la wallet para nada.

```ts
if (getConnection(config).chainId === chainId) return;
await switchChain(config, { chainId });
```

**Verifica**: `✔ Paso 4`: la wallet pasa a Sepolia (11155111), sigue ahí al pedirlo dos veces y
vuelve a anvil (31337).

## Paso 5: Seguir la conexión

**Por qué**: la persona cambia de cuenta o de red desde la wallet. La página solo se entera si
escucha.

```ts
return watchConnection(config, { onChange: () => onChange(connectionLabel(config)) });
```

`watchConnection` devuelve la función que deja de escuchar. El test la llama en un `finally`.

**Verifica**: `✔ Paso 5`, `ℹ pass 5` y `✔ sin errores de tipos`. El test conecta y desconecta y
recibe `0x7099…79C8 en Foundry` y, al final, `Sin conectar`.

## Qué aprendiste

- `createConfig` reúne redes, transportes y conectores. El conector firma por el RPC de la red,
  no por el transporte.
- `connect` pide las cuentas; `getConnection` dice cuenta, red y si esa red es de la página.
- `switchChain` cambia la red de la wallet, y conviene pedirlo solo si hace falta.
- `watchConnection` avisa de cada cambio y devuelve con qué dejar de escuchar.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Estado de una transacción](../../1-teoria/04-estado-de-una-transaccion.md) | **Ejercicio 01 — Conectar la cuenta** | [Ejercicio 02 — Leer y escribir →](../ejercicio-02-leer-y-escribir/README.md) |
