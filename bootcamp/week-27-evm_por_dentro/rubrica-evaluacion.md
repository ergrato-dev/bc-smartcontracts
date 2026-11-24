# Rúbrica de evaluación — Semana 27: La EVM por dentro

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: mapa de storage |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Por qué el programa del salto mal contado del ejercicio 01 gasta todo el gas de la llamada, y el correcto solo 21 020? | 10 |
| 2 | ¿Qué hace el *dispatcher* de un contrato de solc, y qué pasa con un selector que no existe? | 10 |
| 3 | ¿Por qué Solidity da error *stack too deep* con 17 parámetros, y qué opciones tienes? | 10 |
| 4 | ¿Por qué ampliar la memoria a 1 MiB cuesta mucho más que 1024 veces lo que cuesta 1 KiB? | 10 |
| 5 | Llamas a un contrato ajeno con `(bool ok, bytes memory ret) = target.call(...)`. ¿Qué es una *return bomb* y cómo te defiendes? | 10 |
| 6 | Una variable `private` guarda la respuesta de un juego. ¿Por qué no es secreta? Usa el ejercicio 02. | 10 |
| 7 | ¿Por qué en el proyecto la etiqueta del segundo `Item` tiene exactamente 32 bytes? | 10 |
| 8 | ¿Por qué el primer `SLOAD` de un slot cuesta 2100 y el segundo 100, y qué cambia `transient` en un cerrojo de reentrancy? | 10 |
| 9 | ¿Qué hace el decodificador de Solidity con una dirección que trae `0xff` en sus 12 bytes altos, y qué pasa si lees esa calldata a mano? | 10 |
| 10 | Insertas una variable en `RegistryV2` antes de `maxPerAccount`. ¿Por qué pasan tus 31 tests anteriores y por qué falla el mapa de storage? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Porque cae en un `JUMPI` a una posición sin `JUMPDEST`. Un salto inválido, como `INVALID` o una
   pila vacía, deshace la llamada **y gasta todo su gas**: `gasUsed` es el límite entero, 100 000.
   El correcto llega a `REVERT`, que también deshace los cambios pero devuelve el gas que sobra:
   solo paga los 21 000 de la transacción y los pocos opcodes ejecutados.
2. Lee los 4 primeros bytes de la calldata, el selector, y lo compara con el de cada función
   `external` o `public`; si coincide, salta a su código. Si ninguno coincide, salta a `fallback`
   si existe, o revierte. No comprueba nada más: un `fallback` que acepta cualquier cosa responde
   a funciones que nadie escribió.
3. Porque `DUP` y `SWAP` solo llegan a las 16 posiciones de arriba de la pila, y la función
   necesita más valores vivos a la vez. Agrupar los datos en un `struct`, dividir la función o
   compilar con `via_ir = true`, que reordena la pila y cambia el bytecode y el gas.
4. Porque el coste total de `w` palabras es `3 · w + w² / 512`: con pocas palabras manda el
   término lineal, con muchas el cuadrático. 1 KiB son 98 de gas; 1 MiB, 2 195 456, más de lo que
   cabe en un bloque.
5. Un contrato malicioso devuelve una returndata enorme (un motivo de revert gigante) y Solidity la
   copia entera en tu memoria: pagas tú la ampliación y tu transacción se queda sin gas. Te
   defiendes poniendo tope de gas a la llamada y sin copiar la returndata que no necesitas.
6. Porque `private` solo impide que otros contratos la lean con Solidity. El valor está en un slot
   del storage, y cualquiera lo lee con `cast storage` o `vm.load`. En el ejercicio 02, `_secret()`
   sale de su slot sin llamar a ninguna función.
7. Porque 32 bytes es el string más corto que ya no cabe en su slot: hasta 31 bytes, los datos van
   en el slot con la longitud por 2 en el último byte; desde 32, el slot guarda `longitud * 2 + 1` y
   los datos van en `keccak256(slot)`. Con 32 bytes el test prueba la codificación larga en su
   frontera.
8. Por EIP-2929: el primer acceso de la transacción a un slot es frío y paga por traer el dato; los
   siguientes son calientes. Una variable `transient` vive en el transient storage, que cuesta
   siempre 100 y se borra al acabar la transacción: el cerrojo deja de pagar los 20 000 de escribir
   un slot de cero a otro valor.
9. Revierte sin datos de error: el decodificador comprueba que los bits que sobran están a cero.
   Leída a mano, `address(uint160(...))` corta esos bits en silencio y la llamada sigue como si la
   dirección fuera válida, sin ninguna comprobación.
10. Porque cada test despliega un proxy nuevo con todas las versiones mutadas: el contrato es
    coherente consigo mismo y todo se comporta bien. El mapa compara el slot 8 con
    `maxPerAccount()`: tras la mutación, `maxPerAccount` está en el 9 y el slot 8 es la variable
    nueva. En el proxy ya desplegado, esa versión leería `maxPerAccount` del slot 9, el de `priceFeed`.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Bytecode a mano | `forge test` sin error: `5 passed; 0 failed` | 15 |
| | Sigue la traza del paso 6: explica cada `pc`, la pila y por qué el programa del salto mal contado gasta `100000` | 10 |
| 02 — Storage al descubierto | `forge test` sin error: `6 passed; 0 failed` | 15 |
| | Explica cómo calculaste el slot de cada paso, del empaquetado al struct | 10 |
| 03 — Calldata y memoria | `forge test` sin error: `6 passed; 0 failed` | 15 |
| | Codifica el `string[]` del paso 2 en papel, con sus offsets, y explica qué rechaza el decodificador | 15 |
| Todos | Sin tocar `foundry.toml` ni los tests | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-27/` sin `out/`, `cache/` ni `crytic-export/`, y pull request `week-27` → `main` | 10 |
| `bash test.sh` sin error: informe, tests, specs, `forge lint`, Slither, detector, Medusa y los catorce mutantes muertos | 25 |
| Los cinco tests de `StorageMap.t.sol`, con cada slot calculado en el código | 25 |
| Cada variable de tu `forge inspect`, también las propias de tu dominio, con su comprobación | 20 |
| Sección `## Mapa de storage` del informe: tabla de slots, test de cada fila y qué pasa si una variable se mueve | 20 |

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
| [← Proyecto — Mapa de storage](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
