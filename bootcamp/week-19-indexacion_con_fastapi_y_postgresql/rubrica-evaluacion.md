# Rúbrica de evaluación — Semana 19: Indexación con FastAPI y PostgreSQL

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: el indexador del protocolo |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Qué preguntas no contesta bien un contrato y por qué tampoco basta con pedir todos los logs en cada visita? | 10 |
| 2 | ¿Por qué se dice que la cadena es la fuente de verdad y la base de datos, una copia? ¿Qué regla sale de ahí? | 10 |
| 3 | En un log de `Transfer`, ¿dónde va cada parámetro y cómo sacas de ahí una dirección y un importe? | 10 |
| 4 | ¿Por qué un `uint256` va en `NUMERIC(78, 0)` en la tabla y como texto en el JSON? | 10 |
| 5 | ¿Qué protege la clave primaria `(block_number, log_index)` y qué añade `ON CONFLICT DO NOTHING`? | 10 |
| 6 | ¿Qué pasa si el nodo falla a mitad de guardar un tramo sin transacción? ¿Y con ella? | 10 |
| 7 | Una etiqueta del registro es `x' OR '1'='1`. ¿Qué pasa con una f-string y qué con `%s`? ¿Y si lleva el byte 0x00? | 10 |
| 8 | ¿Qué es un reorg y por qué basta con comparar el hash del último bloque guardado para notarlo? | 10 |
| 9 | ¿Por qué se pide el último bloque del tramo antes que los logs, y por qué la baja guarda su bloque en vez de poner `active = false`? | 10 |
| 10 | ¿Qué cambias al pasar de 0 a 3 confirmaciones, y para qué esperarías a `finalized`? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Las que recorren todo el registro: listas filtradas, ordenadas y paginadas, o agregados como
   "altas por mes". Un `view` que recorre miles de entradas es lento o choca con el gas de la
   llamada. Pedir los logs en cada visita repite el mismo trabajo cada vez, y los nodos públicos
   limitan el rango de bloques de `eth_getLogs`.
2. Porque todo lo que guarda el indexador sale de eventos: si la base de datos se borra, se
   reconstruye desde el bloque del despliegue. La regla: no guardar nada que no salga de la
   cadena (o guardarlo aparte), para poder reindexar sin perder nada.
3. topic0 es el keccak256 de la firma; `from` y `to`, `indexed`, van en topics[1] y topics[2],
   y la dirección son sus últimos 40 caracteres. `value` va en `data`: `int(data, 16)`.
4. Un `uint256` tiene hasta 78 dígitos: `BIGINT` da `bigint out of range` y `float` redondea.
   En JSON, JavaScript lee los números como `double`, exactos solo hasta 2⁵³: el importe llegaría
   redondeado sin error. Como texto llega entero y la página usa `BigInt`.
5. Que un log se guarde dos veces: el segundo `INSERT` falla. `ON CONFLICT DO NOTHING` lo
   convierte en "no hacer nada", así que repetir un tramo (tras un reinicio) deja lo mismo: la
   escritura es idempotente.
6. Sin transacción quedan unas filas sí y otras no: por ejemplo, el bloque sin sus eventos. El
   cursor avanza y lo que faltaba no se vuelve a pedir. Con transacción se deshace todo y la
   vuelta siguiente repite el tramo entero.
7. Con f-string, la comilla cierra la del SQL y el resto se ejecuta como SQL: inyección (o un
   error de sintaxis con `o'brien`). Con `%s`, el valor viaja aparte y se compara como texto. El
   0x00 no cabe en `TEXT`: psycopg lanza `DataError` y el indexador se queda atascado en ese
   bloque para siempre si no limpia la etiqueta.
8. Los últimos bloques que dio el nodo dejan de existir y en su lugar hay otros. Cada bloque
   incluye el hash de su padre, así que cambiar uno cambia todos los siguientes hasta la cabeza:
   cualquier reorg cambia el último bloque guardado.
9. Si un reorg llega entre los dos pasos, el hash guardado es el de la versión vieja: no
   coincide en la vuelta siguiente y se deshace. Al revés, los logs viejos quedarían con el hash
   nuevo y nunca se notaría. La baja guarda `retired_block` para que borrar ese bloque
   (`ON DELETE SET NULL`) la deshaga; con `active = false` no habría forma de saber cuándo
   volver a `true`.
10. Con 3, el indexador no guarda un bloque hasta que tiene 3 encima: la página ve los datos
    unos 36 s más tarde en Sepolia y deshace menos reorgs. A `finalized` (unos 13 minutos)
    esperarías antes de algo que no se puede deshacer, como entregar un producto.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Eventos desde Python | `bash test.sh`: `5 passed` | 15 |
| | Explica por qué los tramos empiezan en `end + 1` y qué pasaría si empezaran en `end` | 5 |
| 02 — Guardar en PostgreSQL | `bash test.sh`: `5 passed` | 20 |
| | Explica qué falla al quitar la transacción y al usar una f-string en `balance_of` | 10 |
| 03 — API con FastAPI | `bash test.sh`: `5 passed` | 20 |
| | Explica por qué `/balances/hola` no llega a ejecutar tu función y qué protege CORS | 15 |
| Todos | Sin tocar `tests/` ni `test.sh` | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-19/` sin `.venv/` ni `broadcast/` de anvil, y pull request `week-19` → `main` | 10 |
| `bash test.sh`: `10 passed` | 30 |
| Todo valor de fuera va con parámetros; ningún `uint256` en `BIGINT` ni como número en el JSON | 15 |
| En anvil: alta, baja y un reorg a mano que la API refleja | 20 |
| En Sepolia: el indexador sigue a tu Registry desde su bloque de despliegue, con confirmaciones | 10 |
| README con cómo arrancar indexador y API, `START_BLOCK`, `CONFIRMATIONS` y nombres de tu dominio | 15 |

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
| [← Proyecto — El indexador del protocolo](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
