# Rúbrica de evaluación — Semana 28: Yul e inline assembly

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: la llamada al hook en assembly |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Por qué `sub(0, 1)` en assembly no revierte y `0 - 1` en Solidity sí? ¿Qué tienes que escribir para que una suma en assembly se comporte como la de Solidity? | 10 |
| 2 | Yul solo tiene un tipo. ¿Cómo distingue entonces `-1` de `2²⁵⁶ - 1`? Usa el paso 3 del ejercicio 01. | 10 |
| 3 | En un objeto Yul, ¿qué hacen el `code` de fuera y el objeto `runtime`, y cuál de los dos queda en la cadena? | 10 |
| 4 | ¿Por qué `r := count` no compila dentro de un bloque de assembly, y cómo se lee una variable de estado? | 10 |
| 5 | En el paso 4 del ejercicio 02, ¿por qué sin `mstore(0x40, ...)` el array de sietes aparece dentro del tuyo? | 10 |
| 6 | Asignas `0x1ff` a un `uint8` en assembly. ¿Qué devuelve la función? ¿Y qué ve otro bloque de assembly que lee esa variable? | 10 |
| 7 | ¿Qué promete `assembly ("memory-safe")`, quién lo comprueba y qué pasa si mientes? | 10 |
| 8 | Una llamada con `call` a una cuenta sin código, ¿sale bien o mal? ¿Qué tiene que comprobar `balanceOf` del ejercicio 03 por eso? | 10 |
| 9 | ¿Qué pasa si haces `returndatacopy(0, 0, 4)` después de una llamada que devolvió 3 bytes? ¿Qué mutante del proyecto lo prueba? | 10 |
| 10 | Slither da 0 hallazgos en tu registro. ¿Qué te dice eso de `_callHook`, y qué pruebas sí lo respaldan? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Porque los opcodes de la EVM no comprueban: `sub` da la vuelta y devuelve `2²⁵⁶ - 1`. Las
   comprobaciones de Solidity desde la 0.8 las genera solc alrededor de cada operación, y dentro
   de `assembly` no genera ninguna. Para comportarse igual, comprueba el desbordamiento (en una
   suma, `lt(c, a)`) y revierte con el **mismo** error: `Panic(uint256)` con el código `0x11`, es
   decir, el selector `0x4e487b71` y una palabra con `0x11`, 36 bytes.
2. No los distingue: son la misma palabra, 256 bits a uno. Lo que cambia es el opcode con que la
   lees. `gt(x, 0)` la lee sin signo y la da por positiva; `sgt(x, 0)` la lee en complemento a dos
   y la da por negativa. Por eso `sign` usa `sgt` y `slt`; con `gt` y `lt`, el fuzzer encuentra un
   negativo que da 1.
3. El `code` de fuera es el código de despliegue: se ejecuta una vez, en la transacción que crea
   el contrato. El de `Counter` guarda 7 en el slot 0, copia el runtime a memoria con `datacopy` y
   lo devuelve con `return`. Lo devuelto es lo que queda en la dirección del contrato: el objeto
   `runtime`. Cada llamada posterior ejecuta solo ese código.
4. Porque un bloque de assembly solo ve variables locales: `Error (1408): Only local variables are
   supported`. Una variable de estado no es un valor en la pila sino un sitio en storage. Se lee con
   `sload(count.slot)`, y si está empaquetada, desplazando `count.offset` bytes y con una máscara.
5. Porque Solidity reserva memoria en `mload(0x40)`, el puntero de memoria libre. Tu array se
   escribió en `0x80`, pero el puntero siguió en `0x80`: para Solidity esa memoria estaba libre.
   El array de sietes empezó ahí mismo y escribió los sietes encima: `assertion failed: 7 != 0`.
   Moviendo el puntero detrás del array, los sietes van a `0x100`.
6. La función devuelve 255: Solidity limpia los bits que sobran antes de codificar el valor para
   devolverlo, y también antes de compararlo. Otro bloque de assembly recibe la palabra tal cual,
   `0x1ff` (511). Esos bits son los bits sucios: si un valor sale de assembly hacia un tipo de
   menos de 256 bits, límpialo con una máscara.
7. Promete que el bloque respeta las reglas de memoria de Solidity: solo toca el scratch space, la
   memoria ya reservada y la memoria libre, moviendo el puntero si quiere conservarla. Nadie lo
   comprueba: solc se fía. Con `--via-ir`, el optimizador puede usar esa promesa para mover
   variables de la pila a memoria; si mientes, puede poner sus variables justo donde escribes, y el
   fallo aparece lejos del bloque.
8. Sale bien: no hay código que ejecutar, así que no hay nada que revierta. `ok` vale 1 y
   `returndatasize()` vale 0. Por eso `balanceOf` no basta con mirar `ok`: exige también 32 bytes de
   respuesta o más. Sin eso, `mload(0)` devuelve lo que quedaba en el scratch space, y el test con
   la cuenta sin código falla con `next call did not revert as expected`.
9. Revierte toda la llamada del registro: `returndatacopy` fuera de rango no completa con ceros
   como `calldataload`. Un hook que revierte con 3 bytes bloquearía cada alta. Es el mutante
   `copia 4 bytes de una returndata más corta` (`gt(size, 0)` en vez de `gt(size, 3)`):
   `testFuzz_FailedHookEmitsSelector` y `test_ShortRevertsEmitEmptyReason` lo matan.
10. Casi nada. Slither marca los bloques con su detector informativo `assembly`, que el proyecto
    excluye, y sus demás detectores apenas entran en ellos: un `call` sin mirar `ok` en assembly no
    da `unchecked-lowlevel`. Lo respaldan los tests de `test/asm`: el diferencial con fuzzing contra
    la referencia de `try`, los motivos de 0 a 5 bytes, el de gas con `MemoryBombHook`, y los
    mutantes de `mutants.sh` que demuestran que esos tests miran cada línea.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Yul paso a paso | `forge test` sin error: `9 tests passed, 0 failed` | 15 |
| | Explica el dispatcher de `Counter.yul` y señala en su bytecode los dos selectores y `datasize("runtime")` | 10 |
| 02 — Memoria y storage en assembly | `forge test` sin error: `6 tests passed, 0 failed` | 15 |
| | Explica qué falla sin mover el puntero de memoria libre y sin quitar el cerrojo, con el error de cada test | 10 |
| 03 — Llamadas en assembly | `forge test` sin error: `11 tests passed, 0 failed` | 15 |
| | Explica qué comprueba `balanceOf` que `staticcall` no, y por qué `deploy` mira la dirección que devuelve `create2` | 15 |
| Todos | Sin tocar `foundry.toml` ni los tests | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-28/` sin `out/`, `cache/` ni `crytic-export/`, y pull request `week-28` → `main` | 10 |
| `bash test.sh` sin error: informe, tests, specs, `forge lint`, Slither, detector, Medusa y los diecisiete mutantes muertos | 25 |
| `_callHook` en una función privada, con solo la llamada en assembly y el comentario que justifica `memory-safe` | 25 |
| Sección `## Assembly (semana 28)` del informe: tabla del bloque, lo que `try` hacía y ya no, mutantes y el equivalente | 20 |
| Hallazgo H-05 con tus números de gas, su prueba y su fila en la revisión de correcciones | 20 |

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
| [← Proyecto — La llamada al hook en assembly](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
