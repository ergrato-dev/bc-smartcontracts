# Rúbrica de evaluación — Semana 17: Frontend con viem

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: la página del protocolo |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Por qué un `uint256` llega a TypeScript como `bigint` y no como `number`? ¿Y por qué un `uint8` sí llega como `number`? | 10 |
| 2 | Node ejecuta un `.ts` con un error de tipos sin quejarse. ¿Por qué, y qué lo detecta? | 10 |
| 3 | ¿Qué fija `pnpm-lock.yaml` que no fija `package.json`, y por qué importa en una biblioteca que firma transacciones? | 10 |
| 4 | ¿Qué hace cada pieza de viem: transporte, red y cliente? ¿Qué diferencia al cliente público del de cartera? | 10 |
| 5 | Una lectura falla con `returned no data ("0x")`. ¿Qué significa y cuáles son sus dos causas habituales? | 10 |
| 6 | ¿Por qué se simula antes de enviar, y por qué una simulación correcta no garantiza que la transacción salga bien? | 10 |
| 7 | ¿De dónde sale el valor que devuelve una función que escribe, si la transacción enviada no devuelve nada a quien la envía? | 10 |
| 8 | En un log, ¿qué va en `topics` y qué en `data`? ¿Por qué solo se puede filtrar por campos `indexed`? | 10 |
| 9 | ¿Por qué la página no busca eventos desde el bloque 0 en Sepolia, y por qué filtra siempre por `address`? | 10 |
| 10 | ¿Por qué no va nunca una clave en una variable `VITE_`, y por qué la página pinta las etiquetas con `textContent`? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Un `number` es un decimal de 64 bits y solo guarda enteros exactos hasta 2⁵³; un `uint256`
   llega a 2²⁵⁶ y 1 token de 18 decimales ya son 10¹⁸ unidades. `bigint` no tiene límite. Un
   `uint8` (y cualquier entero de hasta 48 bits) cabe entero en un `number`, y viem lo da así.
2. Node solo quita las anotaciones de tipos y ejecuta; no las comprueba. Lo detecta `tsc`
   (`pnpm exec tsc`), que revisa los tipos sin ejecutar. Por eso `test.sh` hace las dos cosas.
3. `package.json` fija las dependencias directas; el lockfile fija también las dependencias de
   esas dependencias, con su hash. Un paquete comprometido en cualquier nivel puede robar claves
   o cambiar lo que se firma; con el lockfile y `--frozen-lockfile`, se instala exactamente lo
   revisado.
4. El transporte decide cómo llegan las peticiones JSON-RPC al nodo (`http(url)`); la red dice
   a qué cadena se habla (id 31337, 11155111); el cliente ofrece las acciones. El público lee y
   simula sin cuenta; el de cartera tiene una cuenta y firma transacciones.
5. Que el nodo devolvió cero bytes: en esa dirección no hay código, y viem no puede decodificar
   la respuesta. Casi siempre es una dirección equivocada o una red equivocada.
6. Porque la simulación ejecuta la llamada sin guardar nada ni pagar gas, y si revierte da el
   error con nombre. No garantiza nada porque usa el último bloque: otra transacción puede
   entrar antes y cambiar el estado. Lo que vale es el recibo.
7. De la simulación (`result`) o de un evento del recibo (`parseEventLogs`), como el id del
   `ItemRegistered`.
8. `topics[0]` es el hash de la firma del evento y los siguientes son los campos `indexed`;
   `data` lleva el resto, codificado en ABI. El nodo indexa `address` y `topics`, así que puede
   filtrar por ellos; `data` hay que traerlo y decodificarlo.
9. Porque un RPC público limita el rango de una búsqueda (`exceed maximum block range: 50000`):
   se empieza en el bloque del despliegue. Y porque cualquier contrato puede emitir un evento
   con el mismo nombre y los datos que quiera: solo valen los de tu registro.
10. Vite copia las variables `VITE_` en el JavaScript que descarga cualquiera: una clave ahí
    está publicada. Las etiquetas las escribe quien registra; con `innerHTML`, una etiqueta con
    HTML ejecutaría código en la página de quien la mira (XSS). `textContent` nunca interpreta
    HTML.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Leer la cadena | `bash test.sh`: 5 de 5 y sin errores de tipos | 20 |
| | Explica por qué `decimals` es `number` y `totalSupply` es `bigint` | 5 |
| 02 — Escribir transacciones | `bash test.sh`: 5 de 5 y sin errores de tipos | 20 |
| | Explica quién firma con una cuenta local y con una JSON-RPC, y qué pasa al quitar el `error` de la ABI | 10 |
| 03 — Escuchar eventos | `bash test.sh`: 5 de 5 y sin errores de tipos | 20 |
| | Explica por qué el filtro por `to` lo hace el nodo y por qué hay que llamar a `unwatch` | 10 |
| Todos | Sin claves fuera de los tests y sin tocar `test/` ni `test.sh` | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-17/` con tus contratos en `contracts/`, sin `.env.local`, `node_modules/` ni `dist/`, y pull request `week-17` → `main` | 10 |
| `bash test.sh`: 9 de 9 tests y `tsc` y `vite build` sin errores | 30 |
| `protocol.ts` completo: simula antes de cada escritura, lee la tasa del contrato y filtra los eventos por la dirección del registro | 15 |
| En anvil: alta, error con nombre, baja, actividad en vivo en dos pestañas y `TooManyItems` tras actualizar a V2 | 20 |
| En Sepolia: la página lee tu registro de la semana 16 en solo lectura | 10 |
| Textos de tu dominio, errores frecuentes explicados para personas y todo texto de la cadena con `textContent` | 15 |

**Total**: 100 puntos → 30 % de la nota.

---

## 🏅 Bandas

| Banda | Rango |
| ----- | ----- |
| Sobresaliente | 90-100 |
| Notable | 80-89 |
| Aprobado | 70-79 |
| No aprobado | < 70 en alguna evidencia |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Proyecto — La página del protocolo](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
