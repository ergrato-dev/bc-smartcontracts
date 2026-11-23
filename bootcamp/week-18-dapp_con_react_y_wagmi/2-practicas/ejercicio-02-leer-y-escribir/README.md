# Ejercicio 02 — Leer y escribir

> Al terminar habrás leído varias funciones en una llamada, leído el saldo de la cuenta de la
> wallet, enviado una transferencia que firma la wallet, explicado cada error con palabras y
> avisado de cada fase de la transacción.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 01](../ejercicio-01-conectar-la-cuenta/README.md) terminado;
[Teoría 04 — Estado de una transacción](../../1-teoria/04-estado-de-una-transaccion.md) leída.

## Contexto

Mismo formato que el ejercicio 01, sobre `src/token.ts`. `test.sh` arranca su anvil en el
puerto 8546 y despliega el Token de la semana 17: la cuenta 1 tiene 100 BCT y la 2, 50.

| Archivo | Qué es |
| ------- | ------ |
| `src/token.ts` | Los cinco pasos. Aquí trabajas |
| `src/config.ts` | La configuración del ejercicio 01, solo con anvil. Viene resuelta |
| `src/abi.ts` | La ABI del Token, la de la semana 17 |
| `test/token.test.ts` | Los tests. Conectan una wallet `mock` antes de llamar a tu código. **No lo modifiques** |

Ninguna función recibe la cuenta: la da la wallet conectada.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-18-dapp_con_react_y_wagmi/2-practicas/ejercicio-02-leer-y-escribir/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: `ℹ fail 5` y `✔ sin errores de tipos`. Los pasos 1, 3, 4 y 5 fallan con su
`Error: TODO: Paso N`; el 2, con un `AssertionError`, porque el test espera el error
`Conecta una wallet` y recibe el `TODO`.

## Paso 1: Varias lecturas en una

**Por qué**: la cabecera de una página necesita varios datos del contrato a la vez.

```ts
const contract = { address: token, abi: tokenAbi } as const;
const [name, symbol, decimals] = await readContracts(config, {
  allowFailure: false,
  contracts: [
    { ...contract, functionName: "name" },
    { ...contract, functionName: "symbol" },
    { ...contract, functionName: "decimals" },
  ],
});
return { name, symbol, decimals };
```

Con `allowFailure: false`, `readContracts` devuelve los valores con sus tipos:
`[string, string, number]`. En anvil no hay contrato Multicall3 y wagmi hace una llamada por
lectura (teoría 02).

**Verifica**: `✔ Paso 1`: `{ name: "Bootcamp Token", symbol: "BCT", decimals: 18 }`.

## Paso 2: El saldo de la wallet

**Por qué**: la página enseña "tu saldo", y "tú" es quien está conectado.

```ts
const { address } = getConnection(config);
if (!address) throw new Error("Conecta una wallet");
return readContract(config, { address: token, abi: tokenAbi, functionName: "balanceOf", args: [address] });
```

**Verifica**: `✔ Paso 2`: sin conectar, el error `Conecta una wallet`; con la cuenta 1,
`100000000000000000000n`.

## Paso 3: Enviar con la wallet

**Por qué**: el flujo es el de la semana 17, simular, enviar y esperar, pero quien firma es la
wallet conectada. No hay `account` en ningún sitio.

```ts
const { request } = await simulateContract(config, {
  address: token,
  abi: tokenAbi,
  functionName: "transfer",
  args: [to, amount],
  chainId: config.chains[0].id,
});
const hash = await writeContract(config, request);
return waitForTransactionReceipt(config, { hash });
```

Con `chainId`, el `request` lleva la red del contrato y `writeContract` se niega a firmar si la
wallet está en otra (teoría 03).

**Verifica**: `✔ Paso 3`: el recibo dice `success`, viene de la cuenta 1 y la cuenta 5 tiene
10 BCT.

## Paso 4: Un texto para cada error

**Por qué**: "Cancelaste la firma" y "No tienes saldo" son cosas muy distintas para quien usa
la página. Las dos llegan como un error.

```ts
if (!(err instanceof BaseError)) return "Error desconocido";
if (err.walk((e) => e instanceof UserRejectedRequestError)) return "Cancelaste la firma en la wallet";
const revert = err.walk((e) => e instanceof ContractFunctionRevertedError);
if (revert instanceof ContractFunctionRevertedError && revert.data) return revert.data.errorName;
return err.shortMessage;
```

`walk` recorre la cadena de causas del error; `shortMessage` es la primera línea de viem, sin
los detalles técnicos.

**Verifica**: `✔ Paso 4`. El test comprueba cuatro casos: un rechazo
(`Cancelaste la firma en la wallet`), la cuenta 2 enviando 1000 BCT
(`ERC20InsufficientBalance`), un nodo que no responde (`HTTP request failed.`) y un `Error`
cualquiera (`Error desconocido`).

## Paso 5: Las fases

**Por qué**: firmar puede tardar lo que quiera la persona y confirmar, lo que tarde el bloque.
La página dice en qué fase está para que nadie pulse dos veces.

```ts
onPhase("simulando");
const { request } = await simulateContract(config, {
  address: token,
  abi: tokenAbi,
  functionName: "transfer",
  args: [to, amount],
  chainId: config.chains[0].id,
});
onPhase("firmando");
const hash = await writeContract(config, request);
onPhase("confirmando");
const receipt = await waitForTransactionReceipt(config, { hash });
onPhase("confirmada");
return receipt;
```

**Verifica**: `✔ Paso 5`, `ℹ pass 5` y `✔ sin errores de tipos`. Las fases llegan en orden:
`["simulando", "firmando", "confirmando", "confirmada"]`, y la cuenta 5 tiene 12 BCT.

## Qué aprendiste

- `readContracts` hace varias lecturas en una llamada, con sus tipos.
- La cuenta sale de la conexión, no de un argumento: sin wallet, no hay cuenta.
- Simular, enviar y esperar es igual que en viem, pero firma la wallet; `chainId` ata la
  transacción a la red del contrato.
- Rechazo, revert y fallo de red se distinguen con `walk`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Conectar la cuenta](../ejercicio-01-conectar-la-cuenta/README.md) | **Ejercicio 02 — Leer y escribir** | [Ejercicio 03 — Hooks de React →](../ejercicio-03-hooks-de-react/README.md) |
