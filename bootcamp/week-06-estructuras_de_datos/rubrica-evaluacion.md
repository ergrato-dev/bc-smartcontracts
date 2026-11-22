# Rúbrica de evaluación — Semana 06: Estructuras de datos

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: registro de recursos en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | `balanceOf[x]` devuelve `0`. ¿Puedes concluir que `x` nunca usó el contrato? ¿Cómo lo sabrías con seguridad? | 10 |
| 2 | ¿Por qué un mapping no tiene `length` ni se puede recorrer? | 10 |
| 3 | Un enum es `enum Status { Created, Shipped }`. ¿Qué estado tiene un envío que nadie creó? ¿Qué riesgo tiene y cómo lo evitas? | 10 |
| 4 | `cast call` con un número que no corresponde a ningún valor del enum revierte. ¿Con qué error? | 10 |
| 5 | ¿Qué deja `delete values[1]` en `[10, 20, 30]`? ¿Y swap-and-pop sobre la misma posición? | 10 |
| 6 | Cualquiera puede añadir a un array y una función imprescindible lo recorre entero. ¿Qué puede pasar y cómo lo evitas? | 10 |
| 7 | `Package memory p = packages[id]; p.weight = 5;` ¿Cambia lo guardado? ¿Revierte? ¿Cómo te avisa el compilador? | 10 |
| 8 | ¿Por qué un parámetro de una función `external` que solo lees debería ir en `calldata` y no en `memory`? | 10 |
| 9 | En un conjunto mapping + array, ¿por qué se guarda "posición + 1" y no la posición? | 10 |
| 10 | Un struct contiene un mapping. Haces `delete` del struct y lo vuelves a crear con el mismo id. ¿Qué encuentras en el mapping? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. No: un mapping devuelve el valor por defecto para cualquier clave, escrita o no, y una
   cuenta que gastó todo también tiene 0. Hace falta un indicador explícito: un mapping a
   `bool`, un estado con un valor `None` o un campo que nunca es 0 en un dato real.
2. Porque no guarda sus claves: el valor de cada clave está en una posición de storage que
   se calcula con keccak256 a partir de la clave. No hay lista de qué claves se escribieron.
3. `Created`, el primer valor (0), que es el valor por defecto. Un id inexistente parece
   recién creado y pasaría guardas como "solo se puede enviar lo que está en `Created`".
   Se evita poniendo primero un valor `None` y comprobando contra él.
4. `Panic(0x21)`: conversión inválida a un enum.
5. `delete` deja `[10, 0, 30]`: la longitud sigue en 3 y queda un hueco. Swap-and-pop deja
   `[10, 30]`: el último ocupa la posición 1 y se hace `pop`.
6. Un DoS: el array crece hasta que recorrerlo gasta más gas del que cabe en un bloque y la
   función ya no se puede ejecutar nunca. Se evita con un límite de longitud o leyendo por
   páginas, y no recorriendo listas sin límite dentro de una transacción.
7. No cambia lo guardado y no revierte: modifica una copia que se pierde al terminar la
   llamada. El compilador avisa con `Warning (2018)`: la función se puede marcar `view`,
   porque no escribe en storage.
8. `calldata` lee los datos directamente de la transacción; `memory` los copia antes, y la
   copia cuesta gas (unas 22 000 unidades con un array de 100 elementos). Además,
   `calldata` garantiza que no se modifican.
9. Porque la posición 0 es válida y también es el valor por defecto del mapping. Con "+1",
   el 0 queda libre para significar "no está".
10. Los datos viejos: `delete` deja en su valor por defecto los demás campos, pero no puede
    borrar el mapping porque no sabe qué claves tiene. El struct nuevo hereda sus entradas.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Mappings | `forge test`: 6 de 6 sin warnings | 15 |
| | Explica por qué hace falta `isMember` si ya existe `points` | 10 |
| 02 — Structs y enums | `forge test`: 6 de 6 sin warnings | 20 |
| | Explica por qué `start` con `memory` no revierte pero no hace nada | 10 |
| 03 — Arrays | `forge test`: 6 de 6 sin warnings | 25 |
| | Explica qué pasaría con `sum()` sin `MAX_LENGTH` | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-06/` en tu repositorio, sin `out/` ni `cache/`, y pull request `week-06` → `main` | 10 |
| `forge test`: 23 de 23 tests en verde, sin warnings | 40 |
| Desplegado en anvil desde la cuenta de tu `INDEX`, con la salida de `forge create`, las llamadas y los tres errores en el pull request | 15 |
| `storage` y `memory` donde corresponde, parámetros de texto en `calldata`, guardas antes de escribir | 10 |
| NatSpec en el constructor y en todas las funciones `external` | 10 |
| Calidad: sin `// TODO:` restantes, identificadores en inglés y comentarios en español, mensaje de commit claro | 15 |

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
| [← Proyecto — Registro de recursos](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
