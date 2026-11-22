# Rúbrica de evaluación — Semana 05: Control de flujo y errores

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: registro con reglas en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | Una función recibe `n` y hace `n` vueltas de un bucle que escribe en storage. ¿Qué riesgo tiene y cómo lo evitas? | 10 |
| 2 | Una función escribe `count = 5` y después revierte. ¿Cuánto vale `count`? ¿Quién paga el gas? | 10 |
| 3 | `cast send` contesta `Failed to estimate gas` con `execution reverted`. ¿Se envió la transacción? ¿Hay recibo? | 10 |
| 4 | ¿Qué ventajas tiene `revert TooLarge(v, 100)` frente a `require(v <= 100, "too large")`? | 10 |
| 5 | Los datos de un revert empiezan por `0x08c379a0`. ¿Qué tipo de error es? ¿Y si empiezan por `0x4e487b71`? | 10 |
| 6 | ¿Cuándo usas `assert` y cuándo `require`? | 10 |
| 7 | Un `uint8` vale 250. ¿Qué devuelve `x + 10` con aritmética comprobada? ¿Y dentro de `unchecked`? | 10 |
| 8 | ¿Qué pasa si un modificador no contiene `_`? ¿Y si la comprobación va después de `_`? | 10 |
| 9 | Una función lleva `whenOpen validAmount(amount) withinLimit`. ¿En qué orden se ejecuta todo? | 10 |
| 10 | Olvidas `onlyOwner` en `setOpen`. ¿Te avisa el compilador? ¿Cómo lo detectas? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Quien llama decide el gas que se gasta. Con un `n` grande, la transacción no cabe en el
   gas limit del bloque y no se puede ejecutar; si la función es imprescindible, el
   contrato queda bloqueado (DoS). Se evita con un máximo (`MAX_BATCH`) comprobado al
   principio.
2. Vale lo que valía antes: el revert deshace todos los cambios de la llamada. El gas
   gastado hasta el revert lo paga quien envió la transacción.
3. No: `cast` estimó el gas, la estimación revirtió y no envió nada. No hay recibo. Con
   `--gas-limit` se puede forzar el envío; entonces hay recibo con `status 0`.
4. Lleva los valores que causaron el fallo, ocupa menos bytecode (el despliegue cuesta
   menos) y se comprueba con exactitud en los tests. Con `require(v <= 100, TooLarge(v, 100))`
   se tiene lo mismo con la forma de `require`.
5. `0x08c379a0` es `Error(string)`: un `require` o `revert` con mensaje de texto.
   `0x4e487b71` es `Panic(uint256)`: un `assert`, un desbordamiento o una división entre
   cero.
6. `require` (o `revert` con un error) para entradas y permisos: fallos esperados de quien
   llama. `assert` para invariantes del propio contrato: si falla, hay un bug.
7. Comprobada: revierte con `Panic(0x11)`. En `unchecked`: `4` (260 − 256).
8. Sin `_` no compila: `Error (2883): Modifier body does not contain '_'.`. Después de `_`
   es una poscondición: se ejecuta cuando la función ya terminó y, si revierte, deshace
   también lo que hizo el cuerpo.
9. `whenOpen` comprueba, `validAmount` comprueba, se ejecuta el cuerpo y `withinLimit`
   comprueba al final. De izquierda a derecha, cada `_` ejecuta al siguiente.
10. No: compila sin warnings. Lo detecta un test que llama desde otra cuenta con
    `vm.prank` y espera `NotOwner`.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Control de flujo | `forge test`: 6 de 6 sin warnings | 15 |
| | Explica por qué `countDigits` necesita `do-while` | 10 |
| 02 — Errores | `forge test`: 6 de 6 sin warnings | 20 |
| | Explica por qué `InsufficientLevel` es mejor que dejar que la resta revierta | 10 |
| 03 — Modificadores | `forge test`: 6 de 6 sin warnings | 25 |
| | Explica por qué `count` vuelve a 9 en el paso 5 | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-05/` en tu repositorio, sin `out/` ni `cache/`, y pull request `week-05` → `main` | 10 |
| `forge test`: 18 de 18 tests en verde, sin warnings | 40 |
| Desplegado en anvil desde la cuenta de tu `INDEX`, con la salida de `forge create`, las llamadas y los tres errores en el pull request | 15 |
| Modificadores en todas las funciones que los necesitan y en ninguna más; guardas antes de escribir | 10 |
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
| [← Proyecto — Registro con reglas](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
