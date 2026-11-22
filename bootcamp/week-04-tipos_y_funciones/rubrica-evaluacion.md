# Rúbrica de evaluación — Semana 04: Tipos y funciones

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: registro configurable en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | Un `uint8` vale 255 y le sumas 1. ¿Qué pasa? ¿Y si conviertes `uint256(256)` a `uint8` con `uint8(...)`? | 10 |
| 2 | ¿Qué tipo usarías para: un número de entradas vendidas, la variación de temperatura de un día, un hash y "el recurso está activo"? | 10 |
| 3 | Un contrato declara `uint128 a; uint256 b; uint128 c;`. ¿Cuántos slots usa? ¿Cómo lo reducirías? | 10 |
| 4 | ¿Por qué no se puede llamar por su nombre a una función `external` desde el propio contrato, y qué visibilidad usarías si hace falta? | 10 |
| 5 | Una variable `private` guarda la respuesta de un juego. ¿Puede leerla alguien de fuera? ¿Cómo? | 10 |
| 6 | ¿Qué escribe el compilador por ti cuando declaras `uint256 public count;`? | 10 |
| 7 | Una función `view` se llama desde fuera con `cast call` y no cuesta nada. ¿Sigue siendo gratis si la llama otra función dentro de una transacción? | 10 |
| 8 | ¿Qué diferencia hay entre `constant` e `immutable`? Pon un ejemplo de cada una en tu protocolo. | 10 |
| 9 | ¿Por qué leer una `constant` cuesta menos gas que leer una variable de estado? | 10 |
| 10 | Tu contrato guarda `OWNER = msg.sender` en el constructor. ¿Impide eso que otra cuenta llame a sus funciones? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. La suma revierte con `panic: arithmetic underflow or overflow (0x11)`: desde la 0.8,
   la aritmética se comprueba. La conversión explícita no comprueba nada: se queda con los
   8 bits bajos y devuelve `0` sin revertir.
2. `uint256` (o un `uint` menor si sabes el máximo) para las entradas; `int` para la
   variación, que puede ser negativa; `bytes32` para el hash; `bool` para "activo".
3. Tres: `a` en el slot 0, `b` no cabe en los 16 bytes restantes y va al 1, `c` al 2.
   Declarando `a` y `c` juntas (`uint128 a; uint128 c; uint256 b;`) usa dos.
4. Una función `external` solo existe como entrada desde fuera, a través de su selector;
   el compilador no la deja visible por su nombre dentro del contrato. Si se llama desde
   fuera y desde dentro, `public`; si solo desde dentro, `internal` o `private`.
5. Sí. `private` solo impide que otros contratos la lean a través del código. El storage
   es público: con el número de slot, `cast storage <dirección> <slot>` la lee.
6. Una función `count()` `external view` que devuelve el valor: el getter. Aparece en la
   ABI.
7. No. Es gratis solo como `eth_call` desde fuera. Dentro de una transacción, su
   ejecución gasta gas como cualquier otro código.
8. `constant` se fija al compilar y solo admite valores que el compilador conoce
   (`PROTOCOL_NAME`). `immutable` se fija en el constructor, al desplegar (`OWNER`,
   `CAPACITY`). Ninguna ocupa storage ni cambia después.
9. Su valor está dentro del bytecode. Leer una variable de estado necesita leer un slot
   del storage, que es lo que marca la diferencia: en `Config`, 21367 frente a 23532.
10. No. Solo guarda una dirección. Para rechazar a otras cuentas hace falta comprobar
    `msg.sender` en cada función, lo que llega en la semana 05.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Tipos de valor | `forge test`: 6 de 6 sin warnings | 20 |
| | Explica por qué `toUint8(300)` devuelve 44 y no revierte | 10 |
| 02 — Visibilidad | `forge test`: 6 de 6 sin warnings | 20 |
| | Explica por qué `add` es `public` y `addTwice` puede ser `external` | 10 |
| 03 — Constructor y constantes | `bash test.sh`: 6 de 6 | 25 |
| | Explica dónde viven `MAX_LIMIT` y `OWNER`, y por qué no salen en el storage layout | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-04/` en tu repositorio, sin `out/` ni `cache/`, y pull request `week-04` → `main` | 10 |
| `forge test`: 10 de 10 tests en verde, sin warnings | 40 |
| Desplegado en anvil desde la cuenta de tu `INDEX`, con la salida de `forge create` y de las seis llamadas en el pull request | 15 |
| Nombres coherentes con tu dominio y con la semana 03; capacidad razonable para tu dominio | 10 |
| NatSpec en todas las funciones `external` y en el constructor | 10 |
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
| [← Proyecto — Registro configurable](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
