# Rúbrica de evaluación — Semana 24: Fuzzing de invariantes

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: invariantes de tu protocolo |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Qué encuentra el fuzzing con estado que no encuentra el de la semana 09? Da un ejemplo de esta semana. | 10 |
| 2 | Escribe una invariante de conservación, una de contabilidad y una de límite para tu protocolo. | 10 |
| 3 | ¿Por qué una invariante no debe copiar lo que hace el código? | 10 |
| 4 | Una campaña da `[PASS]` con `reverts: 128000` de 128 000 llamadas. ¿Qué ha probado y por qué? | 10 |
| 5 | ¿Qué pasa si no llamas a `targetContract` en el `setUp`? Usa el ejercicio 02. | 10 |
| 6 | ¿Qué es encoger una secuencia, y qué hace forge con la secuencia que falla la próxima vez que ejecutas `forge test`? | 10 |
| 7 | Di las cuatro piezas de un handler, y cuándo se actualiza una variable fantasma. | 10 |
| 8 | ¿Por qué el handler del proyecto intenta también las altas que el registro debe rechazar? ¿Qué mutante lo demuestra? | 10 |
| 9 | Di tres diferencias entre forge y Medusa que obligan a cambiar un harness. | 10 |
| 10 | ¿Qué es un mutante, cuándo muere, y qué significa que sobreviva? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Fallos que necesitan varias llamadas en un orden concreto: cada llamada parte del estado de la
   anterior. En `Seats`, `book(0)` y después `transferSeat(0, address(0))`; cada función por
   separado hace lo que dice.
2. Por ejemplo: los certificados de todas las cuentas suman `count`; el saldo del registro es lo
   cobrado menos lo retirado; `activeCount <= capacity`.
3. Porque entonces comprueba que el código hace lo que hace: el fallo del código está también en
   la invariante. La invariante sale de lo que el protocolo promete.
4. Nada: todas las llamadas revirtieron, el estado no salió del de `setUp` y la invariante se
   comprobó siempre sobre él. Las cuentas del fuzzer no tenían saldo ni allowance.
5. forge llama a todos los contratos desplegados en `setUp`. En el ejercicio 02, a `Token.mint`
   también, que acuña al vault por un camino que las variables fantasma no cuentan, y
   `invariant_AssetsAccounted` falla con el vault correcto.
6. Quitar llamadas de la secuencia mientras la invariante siga fallando, hasta dejar las
   imprescindibles. forge la guarda en `cache/invariant/failures` y la repite primero.
7. Cuentas fijas, entradas acotadas con `bound`, precondiciones (saldo, allowance) y variables
   fantasma. Se actualiza después de la llamada al protocolo y solo si sale bien.
8. Porque lo que el handler nunca intenta no se prueba: un registro que acepta la alta que sobra
   pasaría todas las invariantes. El mutante de `maxPerAccount` con `>` sobrevivía cuando el
   handler se saltaba esas altas.
9. Medusa mueve el reloj y forge no (el harness necesita una acción con `vm.warp`); Medusa no
   tiene `vm.startBroadcast` ni `vm.computeCreateAddress`; con `vm.prank`, Medusa paga el `value`
   desde el harness. También: Medusa despliega el harness sin argumentos y no tiene `setUp`.
10. El código con un fallo pequeño a propósito. Muere si alguna invariante falla con él. Si
    sobrevive, ninguna invariante mira lo que ese cambio rompe, o el mutante es equivalente.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Invariantes | `forge test` sin error: `5 passed` y las tres invariantes en verde | 15 |
| | Explica por qué el paso 6 sigue en verde sin la comprobación de `MAX_PER_HOLDER` | 10 |
| 02 — Handlers | `forge test` sin error: las dos invariantes del handler en verde con 0 reverts | 15 |
| | Explica por qué `invariant_SharesBackedByAssets` pasaba sin probar nada | 10 |
| 03 — Medusa | `bash test.sh` sin error: forge en verde y `Test summary: 3 test(s) passed` | 20 |
| | Explica por qué los tests unitarios no veían el fallo de `released` | 15 |
| Todos | Sin tocar los tests unitarios, `medusa.json` ni los archivos marcados "no lo modifiques" | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-24/` sin `out/`, `cache/` ni `crytic-export/`, y pull request `week-24` → `main` | 10 |
| `bash test.sh` sin error: `27 tests passed`, `forge lint` y Slither limpios, detector, Medusa y los cuatro mutantes muertos | 30 |
| Las cuatro acciones del handler: no revierten fuera de su `try` y comprueban lo que el registro rechaza | 20 |
| Las variables fantasma se actualizan solo cuando la acción sale bien | 10 |
| `audit/README.md`: invariantes, campañas, mutantes y lo que la suite no prueba | 20 |
| Una invariante o acción propia de tu dominio, o el porqué de no necesitarla | 10 |

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
| [← Proyecto — Invariantes de tu protocolo](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
