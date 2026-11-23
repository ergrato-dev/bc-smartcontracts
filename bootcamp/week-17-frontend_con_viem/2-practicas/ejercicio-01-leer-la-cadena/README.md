# Ejercicio 01 — Leer la cadena

> Al terminar habrás creado un cliente público de viem y leído con él el bloque, un saldo de
> ETH, el código de una dirección y los datos y saldos de un ERC-20.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 01](../../1-teoria/01-de-cast-a-typescript.md) y
[Teoría 02](../../1-teoria/02-leer-con-viem.md) leídas; imagen reconstruida con Node y pnpm.

## Contexto

Ejercicio de TypeScript: cada paso es una función de `src/read.ts` que empieza con
`throw new Error("TODO: Paso N");` y trae la solución en líneas `//> `. Resolver un paso es
borrar la línea del `throw` y quitar el `//> ` de las siguientes.

| Archivo | Qué es |
| ------- | ------ |
| `src/read.ts` | Los cinco pasos. Aquí trabajas |
| `src/abi.ts` | La ABI del Token en formato legible |
| `test/read.test.ts` | Los tests, uno por paso. **No lo modifiques** |
| `test.sh` | Despliega el Token en un anvil propio, ejecuta los tests y revisa los tipos |
| `contrato/` | El Token (un ERC-20 de 1000 BCT) y su script de despliegue |

`test.sh` arranca su anvil en el puerto 8546, despliega con `--slow` (una transacción por
bloque) y pasa la dirección del Token a los tests en la variable `TOKEN`. Al empezar los tests
hay tres bloques: la emisión de 1000 BCT a la cuenta 0, 100 BCT a la cuenta 1 y 50 a la
cuenta 2.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-17-frontend_con_viem/2-practicas/ejercicio-01-leer-la-cadena/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: cinco `✖ Paso N`, cada uno con `Error: TODO: Paso 1` (los pasos 2 a 5 usan el
cliente del paso 1), `ℹ fail 5` y, al final, `Tipos:` sin errores de tipos.

## Paso 1: El cliente público

**Por qué**: todas las lecturas pasan por un cliente que sabe a qué red habla y por dónde
mandar las peticiones.

```ts
export function createClient(rpcUrl: string): PublicClient {
  return createPublicClient({ chain: foundry, transport: http(rpcUrl) });
}
```

**Abre** `src/read.ts` y resuelve el paso 1.

**Verifica**: `bash test.sh` da `✔ Paso 1: el cliente habla con anvil`. El test comprueba que
`getChainId()` es 31337 y `getBlockNumber()` es `3n`.

## Paso 2: Saldo de ETH

**Por qué**: el saldo llega en wei, como `bigint`. Para mostrarlo se pasa a ETH como texto.

```ts
const wei = await client.getBalance({ address: account });
return formatEther(wei);
```

**Verifica**: `✔ Paso 2`. La cuenta 9 de anvil no ha hecho nada y tiene `"10000"`.

## Paso 3: ¿Contrato o cuenta?

**Por qué**: antes de llamar a un contrato conviene saber que en esa dirección hay código. Si
no lo hay, cualquier lectura termina en `returned no data ("0x")`.

```ts
const code = await client.getCode({ address });
return code !== undefined;
```

**Verifica**: `✔ Paso 3`: `true` para el Token y `false` para la cuenta 1.

## Paso 4: Los datos del Token

**Por qué**: cuatro lecturas independientes. Con `Promise.all` van a la vez, en lugar de
esperar cada una a la anterior.

```ts
const [name, symbol, decimals, totalSupply] = await Promise.all([
  client.readContract({ address: token, abi: tokenAbi, functionName: "name" }),
  client.readContract({ address: token, abi: tokenAbi, functionName: "symbol" }),
  client.readContract({ address: token, abi: tokenAbi, functionName: "decimals" }),
  client.readContract({ address: token, abi: tokenAbi, functionName: "totalSupply" }),
]);
return { name, symbol, decimals, totalSupply };
```

Pasa el ratón por encima de `decimals` en tu editor: es `number`, porque en la ABI es `uint8`.
`totalSupply` es `bigint`.

**Verifica**: `✔ Paso 4` con `{ name: "Bootcamp Token", symbol: "BCT", decimals: 18,
totalSupply: 1000000000000000000000n }`.

## Paso 5: Saldo de tokens

**Por qué**: `balanceOf` da unidades enteras; los decimales del Token dicen dónde va la coma.

```ts
const [raw, decimals] = await Promise.all([
  client.readContract({ address: token, abi: tokenAbi, functionName: "balanceOf", args: [account] }),
  client.readContract({ address: token, abi: tokenAbi, functionName: "decimals" }),
]);
return formatUnits(raw, decimals);
```

**Verifica**: `✔ Paso 5` (`"850"` para la cuenta 0 y `"100"` para la cuenta 1), `ℹ pass 5`,
`ℹ fail 0` y `✔ sin errores de tipos`.

## Qué aprendiste

- Un cliente público necesita una red (`chain`) y un transporte (`http`).
- `getBalance`, `getCode` y `readContract` leen sin cuenta ni gas.
- `uint256` llega como `bigint` y `uint8` como `number`; `formatUnits` lo convierte en texto
  para mostrar.
- Las lecturas independientes van juntas con `Promise.all`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 05 — La página con Vite](../../1-teoria/05-la-pagina-con-vite.md) | **Ejercicio 01 — Leer la cadena** | [Ejercicio 02 — Escribir transacciones →](../ejercicio-02-escribir-transacciones/README.md) |
