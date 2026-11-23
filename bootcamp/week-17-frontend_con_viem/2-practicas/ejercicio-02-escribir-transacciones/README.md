# Ejercicio 02 — Escribir transacciones

> Al terminar habrás firmado con una cuenta local, simulado una transferencia sin enviarla,
> enviado otra y esperado su recibo, sacado el nombre del error de una que revierte y firmado
> con una cuenta del nodo.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 01](../ejercicio-01-leer-la-cadena/README.md) terminado;
[Teoría 03 — Escribir con viem](../../1-teoria/03-escribir-con-viem.md) leída.

## Contexto

Mismo formato que el ejercicio 01: cada paso es una función de `src/write.ts` con su
`throw new Error("TODO: Paso N");` y la solución en líneas `//> `. El contrato, la ABI y
`test.sh` son los del ejercicio 01.

| Archivo | Qué es |
| ------- | ------ |
| `src/write.ts` | Los cinco pasos. Aquí trabajas |
| `test/write.test.ts` | Los tests. Traen las claves de las cuentas 1 y 2 de anvil. **No lo modifiques** |

Las claves de los tests son las de prueba de anvil: públicas, solo valen en anvil y no van
nunca en una página (teoría 03). En `write.ts` llegan como argumento.

`Wallet`, arriba del archivo, es el tipo de un cliente de cartera que ya tiene cuenta y red:
así `wallet.account` nunca es `undefined`.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-17-frontend_con_viem/2-practicas/ejercicio-02-escribir-transacciones/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: `ℹ fail 5` y, en `Tipos:`, cuatro errores como
`test/write.test.ts(33,11): error TS2339: Property 'result' does not exist on type 'void'.`
Mientras `simulateTransfer` y `transfer` solo tienen el `throw`, TypeScript no sabe qué
devuelven. Se van al resolver los pasos 2 y 3.

## Paso 1: La cartera

**Por qué**: firmar exige una cuenta. Con `privateKeyToAccount`, la clave vive en la memoria de
tu programa y la firma se hace aquí, sin preguntar al nodo.

```ts
return createWalletClient({ account: privateKeyToAccount(privateKey), chain: foundry, transport: http(rpcUrl) });
```

**Verifica**: `✔ Paso 1`. La dirección sale de la clave: la de la cuenta 1, y
`account.type` es `"local"`.

## Paso 2: Simular

**Por qué**: el nodo ejecuta `transfer` como si fuera de verdad y no guarda nada. Si fuera a
revertir, lo sabrías aquí, sin pagar gas.

```ts
return client.simulateContract({
  account: wallet.account,
  address: token,
  abi: tokenAbi,
  functionName: "transfer",
  args: [to, amount],
});
```

**Verifica**: `✔ Paso 2`. `result` es `true` (lo que devuelve `transfer`), y el nonce de la
cuenta 1 y el saldo de la cuenta 5 siguen a 0: no se envió nada.

## Paso 3: Enviar y esperar

**Por qué**: `writeContract` devuelve el hash en cuanto el nodo acepta la transacción. Hasta
el recibo no sabes si se ejecutó.

```ts
const { request } = await simulateTransfer(client, wallet, token, to, amount);
const hash = await wallet.writeContract(request);
return client.waitForTransactionReceipt({ hash });
```

**Verifica**: `✔ Paso 3`. El recibo dice `success` y viene de la cuenta 1, cuyo nonce pasa a 1.
La cuenta 5 tiene 10 BCT. Si los pasos 2 y 3 están resueltos, `Tipos:` dice
`✔ sin errores de tipos`.

## Paso 4: Por qué revierte

**Por qué**: una página no muestra "error" a secas: dice "no tienes saldo suficiente". Para eso
necesita el nombre del custom error y sus argumentos.

```ts
try {
  await simulateTransfer(client, wallet, token, to, amount);
  return undefined;
} catch (err) {
  if (!(err instanceof BaseError)) throw err;
  const revert = err.walk((e) => e instanceof ContractFunctionRevertedError);
  if (!(revert instanceof ContractFunctionRevertedError)) throw err;
  return { name: revert.data?.errorName, args: revert.data?.args };
}
```

Un error que no es un revert (el nodo caído, por ejemplo) se vuelve a lanzar: no es asunto de
esta función.

**Verifica**: `✔ Paso 4`. La cuenta 2 tiene 50 BCT e intenta enviar 1000:
`{ name: "ERC20InsufficientBalance", args: [cuenta 2, 50000000000000000000n,
1000000000000000000000n] }`. Con 1 BCT, `undefined`.

Quita la línea `error ERC20InsufficientBalance(…)` de `src/abi.ts` y vuelve a ejecutar: el
test falla porque viem ya no sabe nombrar el error. Déjala como estaba.

## Paso 5: Firma el nodo

**Por qué**: la página del proyecto no tendrá claves. En anvil, el nodo firma por sus cuentas
de prueba si le das solo la dirección.

```ts
return createWalletClient({ account: address, chain: foundry, transport: http(rpcUrl) });
```

**Verifica**: `✔ Paso 5`, `ℹ pass 5` y `✔ sin errores de tipos`. La cuenta es de tipo
`"json-rpc"` y `transfer` (tu paso 3) funciona igual con ella: el flujo no cambia, solo quién
firma.

## Qué aprendiste

- Un cliente de cartera firma con una cuenta local (clave en el programa) o JSON-RPC (firma el
  nodo).
- El flujo es simular, enviar y esperar el recibo; el valor de vuelta sale de la simulación.
- El error de un revert se saca con `walk` hasta `ContractFunctionRevertedError`, y solo si la
  ABI trae el `error`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Leer la cadena](../ejercicio-01-leer-la-cadena/README.md) | **Ejercicio 02 — Escribir transacciones** | [Ejercicio 03 — Escuchar eventos →](../ejercicio-03-escuchar-eventos/README.md) |
