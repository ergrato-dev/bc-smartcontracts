# Teoría 01 — De cast a TypeScript

## 🎯 Objetivos

- Explicar por qué una página necesita un programa que hable con el nodo, y qué hace viem.
- Ejecutar un archivo `.ts` con Node y comprobar sus tipos con `tsc`.
- Usar `bigint` para cantidades de la cadena y saber por qué `number` no sirve.
- Instalar dependencias con pnpm a versiones exactas, desde un lockfile.

## 1. Qué problema resuelve

Desde la semana 02 hablas con el nodo con `cast`: `cast call` lee, `cast send` firma y envía,
`cast logs` busca eventos. Por debajo, `cast` hace peticiones **JSON-RPC** (semana 02): manda
al nodo un JSON con un método (`eth_call`, `eth_sendRawTransaction`, `eth_getLogs`) y recibe
otro JSON con la respuesta.

Una página web no puede ejecutar `cast`. Lo que sí puede ejecutar el navegador es
**JavaScript**, así que necesitas una biblioteca de JavaScript que haga lo mismo que `cast`:
codificar llamadas con la ABI, mandar las peticiones JSON-RPC, firmar transacciones y
decodificar respuestas y eventos. Esa biblioteca es **viem**.

Esta semana escribes ese código en **TypeScript**: JavaScript con tipos. La ventaja es concreta:
viem lee la ABI de tu contrato y TypeScript sabe que `balanceOf` recibe un `address` y devuelve
un `uint256`. Si te equivocas de función o de argumento, el error sale antes de ejecutar.

## 2. Cómo funciona

Las piezas, todas dentro del contenedor del bootcamp:

| Pieza | Qué es | Versión |
| ----- | ------ | ------- |
| **Node** | El programa que ejecuta JavaScript fuera del navegador | `v24.22.3` |
| **pnpm** | El gestor de paquetes: descarga bibliotecas y fija sus versiones | `11.28.12` |
| **TypeScript** (`tsc`) | El comprobador de tipos | `6.0.3` |
| **viem** | La biblioteca que habla con el nodo | `2.57.20` |
| **Vite** | El servidor que entrega la página al navegador (teoría 05) | `8.3.7` |

Node 24 ejecuta un archivo `.ts` directamente: antes de ejecutarlo **quita los tipos** y no
los comprueba. Comprobarlos es trabajo de `tsc`. Por eso cada `test.sh` de esta semana hace las
dos cosas: `node --test` ejecuta los tests y `pnpm exec tsc` revisa los tipos.

## 3. Cómo se escribe

### Un archivo, ejecutado con Node

Cualquier ejercicio de esta semana sirve de carpeta de pruebas. Entra en el contenedor desde el
starter del ejercicio 01 e instala sus dependencias:

```bash
cd bootcamp/week-17-frontend_con_viem/2-practicas/ejercicio-01-leer-la-cadena/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
pnpm install --offline --frozen-lockfile
```

Crea `numeros.ts` con esto:

```ts
const big = 2 ** 53;
console.log(big + 1);
console.log(2n ** 53n + 1n);
console.log(typeof 1n, 10n ** 18n);
```

Ejecútalo con `node numeros.ts`:

```
9007199254740992
9007199254740993n
bigint 1000000000000000000n
```

La primera línea está mal: 2⁵³ + 1 es 9007199254740993. Un `number` de JavaScript es un decimal
de 64 bits y solo representa enteros exactos hasta 2⁵³. Un `uint256` llega a 2²⁵⁶, y 1 token de
18 decimales ya son 10¹⁸ unidades. Para eso está **`bigint`**: enteros de tamaño arbitrario, que
se escriben con una `n` al final (`10n ** 18n`). viem devuelve todo `uint256` como `bigint`.

`bigint` y `number` no se mezclan: `1n + 1` es un error. Para pasar de uno a otro, `BigInt(5)` y
`Number(5n)`, y solo cuando sabes que el número cabe.

### Los tipos los mira tsc, no Node

Crea `tipos.ts`:

```ts
const label: string = 42;
console.log(label);
```

`node tipos.ts` imprime `42`: Node quitó `: string` y ejecutó. `pnpm exec tsc` sí lo ve:

```
tipos.ts(1,7): error TS2322: Type 'number' is not assignable to type 'string'.
```

(Para que `tsc` lo mire, añade `"tipos.ts"` a `include` en `tsconfig.json`. Bórralo después: no
forma parte del ejercicio.)

### Lo que Node no sabe quitar

Node solo quita anotaciones. Lo que en TypeScript genera código, como `enum`, no lo entiende:

```ts
enum Status { None, Active }
```

```
SyntaxError [ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX]: TypeScript enum is not supported in strip-only mode
```

El `tsconfig.json` de los starters trae `"erasableSyntaxOnly": true`, así que `tsc` lo avisa
antes:

```
enum.ts(1,6): error TS1294: This syntax is not allowed when 'erasableSyntaxOnly' is enabled.
```

Para los estados de un `enum` de Solidity, viem ya te da un `number` (0, 1, 2).

### Los ajustes de tsconfig.json

```json
{
  "compilerOptions": {
    "target": "esnext",
    "module": "nodenext",
    "strict": true,
    "noEmit": true,
    "allowImportingTsExtensions": true,
    "erasableSyntaxOnly": true,
    "verbatimModuleSyntax": true,
    "skipLibCheck": true,
    "types": ["node"]
  },
  "include": ["src", "test"]
}
```

- `noEmit`: `tsc` solo revisa; no escribe archivos `.js`. El que ejecuta es Node.
- `allowImportingTsExtensions`: los `import` llevan la extensión real (`"./abi.ts"`), como
  exige Node.
- `verbatimModuleSyntax`: un import que solo trae tipos se escribe `import type { Address }`.
  Así Node sabe que puede borrarlo entero.
- `strict`: comprueba `undefined` y `null` en serio; es lo que atrapa una dirección que no
  llegó.

### Módulos y async

Cada archivo es un módulo: `export function` publica una función e `import { ... } from`
la trae. Hablar con el nodo tarda, así que casi todo lo de viem devuelve una **promesa**, un
valor que llegará después. `await` la espera; solo vale dentro de una función `async` o en lo
alto de un módulo. `Promise.all([a, b])` espera varias a la vez.

### pnpm, package.json y pnpm-lock.yaml

`package.json` dice qué bibliotecas usa el proyecto, con versión exacta. Las de esta semana:

```json
"dependencies": { "viem": "2.57.20" },
"devDependencies": { "@types/node": "24.19.2", "typescript": "6.0.3", "vite": "8.3.7" }
```

Los starters traen además las de la semana 18 (React y wagmi): todas las semanas comparten el
mismo `package.json` para que la imagen las tenga descargadas.

`pnpm-lock.yaml` fija además cada dependencia de esas dependencias, con su hash. viem trae otras
ocho (`ox`, `abitype`, `@noble/curves`...). `pnpm install --frozen-lockfile` instala
exactamente lo del lockfile y falla si `package.json` no coincide con él.

La imagen trae ya descargado todo lo del lockfile de los starters: `--offline` instala sin red.

## 4. Antipatrones y riesgos

- **Una cantidad de la cadena en un `number`.** Por encima de 2⁵³ pierde unidades sin avisar.
  Una cantidad es `bigint` hasta el momento de mostrarla.
- **Ejecutar sin pasar `tsc`.** Node no comprueba tipos: un argumento cambiado de sitio llega al
  nodo y falla en la cadena, o no falla y hace otra cosa.
- **Versiones con `^` o `latest`.** `"viem": "^2.57.0"` deja que pnpm instale mañana otra
  versión. Las bibliotecas de JavaScript sufren **ataques a la cadena de suministro**: alguien
  publica una versión maliciosa de un paquete popular, que se retira a los pocos días. Una
  biblioteca que firma transacciones es el objetivo perfecto. Fija la versión exacta
  (`pnpm add -E viem@2.57.20`), elige una con al menos una semana publicada
  (`pnpm view viem time`) y sube siempre el lockfile.
- **`npm` o `npx`.** El bootcamp usa pnpm: un solo lockfile y un solo gestor. Para ejecutar una
  herramienta, `pnpm exec` (instalada en el proyecto) o `pnpm dlx` (de una vez).

## 5. Trucos

- `node --test` busca y ejecuta tests sin instalar nada: `test()` y `assert` vienen con Node
  (`node:test`, `node:assert/strict`).
- `console.log` imprime un `bigint` con su `n`; `` `${10n}` `` o `String(10n)` lo dejan sin ella.
- `JSON.stringify` no acepta `bigint`: conviértelo antes a texto.

## ✅ Checklist

- [ ] Ejecuto un `.ts` con `node` y reviso sus tipos con `pnpm exec tsc`.
- [ ] Explico por qué un `uint256` es `bigint` en TypeScript y no `number`.
- [ ] Sé por qué Node rechaza un `enum` y qué ajuste lo avisa antes.
- [ ] Instalo con `pnpm install --frozen-lockfile` y sé qué fija el lockfile que no fija
      `package.json`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 17 — Frontend con viem](../README.md) | **Teoría 01 — De cast a TypeScript** | [Teoría 02 — Leer con viem →](02-leer-con-viem.md) |
