# Rúbrica de evaluación — Semana 03: Primer contrato con Foundry

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: contrato registro en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | El bytecode desplegado no contiene los nombres de las funciones. ¿Cómo sabe entonces `cast` qué enviar para llamar a `increment()`? | 10 |
| 2 | ¿Por qué el bootcamp fija `pragma solidity 0.8.38;` y no `^0.8.0`, si las dos compilan? | 10 |
| 3 | `forge build` deja `bytecode` y `deployedBytecode` en el artefacto. ¿Qué diferencia hay y cuál va en la transacción de despliegue? | 10 |
| 4 | Un contrato guarda una "contraseña" en una variable de estado sin función que la devuelva. ¿Está protegida? ¿Por qué? | 10 |
| 5 | ¿Por qué el primer `increment()` de `Counter` gasta más gas que el segundo? | 10 |
| 6 | Llamas a `set(5)` con `cast call` y luego `get()` sigue devolviendo el valor anterior. ¿Qué pasó? | 10 |
| 7 | ¿Por qué `msg.sender` sirve para saber quién llama, y qué impide que alguien ponga ahí la dirección de otro? | 10 |
| 8 | En un test, ¿para qué sirve `setUp` y por qué un test no ve los cambios que hizo otro? | 10 |
| 9 | Un test con `vm.expectRevert()` pasa. ¿Prueba eso que la función revierte por el motivo que querías? | 10 |
| 10 | Despliegas `Counter` en un anvil recién arrancado desde la cuenta 0 y cae en `0x5FbDB...0aa3`, la misma dirección que el contrato de bytecode de la semana 02. ¿Por qué? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Por la ABI, que sale del compilador y no va a la cadena. Con la firma `increment()`
   `cast` calcula el selector (los 4 primeros bytes de su keccak256, `0xd09de08a`) y lo
   pone al principio del `input`. El bytecode compara ese selector con los suyos y salta a
   la función.
2. Con `^` el bytecode depende de qué compilador haya instalado: el mismo código puede
   desplegar bytecode distinto, nadie puede reproducirlo para comprobarlo y se puede colar
   una versión con un fallo conocido. Con versión exacta, el resultado es siempre el mismo.
3. `bytecode` es el código de creación: se ejecuta una vez y devuelve el código que se
   queda. `deployedBytecode` es ese código que queda en la cuenta. En la transacción va el
   de creación.
4. No. Todo el storage es público: `cast storage DIRECCIÓN SLOT` lee cualquier slot,
   tenga o no función que lo devuelva. Además, el valor viajó en una transacción que
   cualquiera puede leer.
5. Porque pasa el slot de `number` de cero a no cero: ocupa espacio nuevo en el estado, que
   todos los nodos guardan. El segundo cambia un valor que ya existía y cuesta menos.
6. `cast call` ejecuta la función en una copia del estado del nodo y descarta los cambios.
   No hubo transacción. Para guardar, `cast send`.
7. Lo pone la EVM, no quien llama: es la cuenta que firmó la transacción (o el contrato que
   hizo la llamada). Para que salga otra dirección haría falta la firma de su clave
   privada.
8. `setUp` se ejecuta antes de cada test y deja el escenario de partida (por ejemplo, un
   contrato recién desplegado). `forge` ejecuta cada test aislado, sobre el estado que deja
   `setUp`, así que el orden no importa.
9. No. `vm.expectRevert()` sin argumentos acepta cualquier reversión, también la de un
   fallo distinto. Solo prueba que revirtió.
10. La dirección de un contrato depende solo de quién lo crea y de su nonce, no del código.
    En los dos casos es la cuenta 0 con nonce 0.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Primer contrato | `forge test`: 6 de 6 sin warnings | 20 |
| | Explica por qué `get` es `view`, `add` es `pure` e `increment` no lleva ninguno | 10 |
| 02 — Tests con forge | `forge test`: 5 de 5 sin warnings | 20 |
| | Explica qué cambio en `Scoreboard` haría fallar el test del paso 5 | 10 |
| 03 — Desplegar y llamar | `bash test.sh`: 6 de 6 | 25 |
| | Explica qué pasaría en el paso 6 si `set(7)` se enviara con `cast send` | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-03/` en tu repositorio, sin `out/` ni `cache/`, y pull request `week-03` → `main` | 10 |
| `forge test`: 8 de 8 tests en verde, sin warnings | 40 |
| Desplegado en anvil desde la cuenta de tu `INDEX`, con la salida de `forge create` y de las cuatro llamadas en el pull request | 20 |
| `protocolName()` y `resourceName()` coherentes con tu dominio y con la semana 02 | 15 |
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
| [← Proyecto — Contrato registro](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
