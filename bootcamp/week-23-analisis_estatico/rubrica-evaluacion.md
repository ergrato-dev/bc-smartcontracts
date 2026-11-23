# Rúbrica de evaluación — Semana 23: Análisis estático

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: análisis estático de tu protocolo |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Qué diferencia un analizador estático de un test? Da una cosa que encuentra cada uno y el otro no. | 10 |
| 2 | ¿Qué es SlithIR y por qué un detector busca patrones en ella y no en el texto de Solidity? | 10 |
| 3 | Define falso positivo y falso negativo con un ejemplo de esta semana de cada uno. ¿Por qué ninguna herramienta los evita del todo? | 10 |
| 4 | ¿Qué tres veredictos puede tener un hallazgo y qué haces con cada uno? | 10 |
| 5 | ¿Por qué se silencia un hallazgo en su línea y no excluyendo el detector en la configuración? | 10 |
| 6 | En `slither.config.json`, ¿qué clave hace que Slither falle desde impacto bajo, y qué pasa si escribes mal una clave? | 10 |
| 7 | `forge lint` termina con código 0 aunque avise. ¿Cómo lo conviertes en un control, y qué severidades mira por defecto? | 10 |
| 8 | Una línea necesita un comentario de Slither y otro de forge lint. ¿Por qué no puedes apilarlos y cómo lo resuelves? | 10 |
| 9 | En un detector, ¿por qué se usa `all_nodes()` o `all_internal_calls()` en vez de `nodes` o `internal_calls`? | 10 |
| 10 | ¿Cómo pruebas un detector propio, y por qué comparas la lista entera de hallazgos? Di una cosa que tu detector del proyecto no ve. | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Un test ejecuta el contrato con unos valores concretos y comprueba un resultado; el analizador
   lee el código sin ejecutarlo y avisa de patrones con cualquier valor. El analizador encuentra
   un `call` sin comprobar en una función que ningún test toca; el test encuentra que `unstake`
   no paga la recompensa, que no es ningún patrón.
2. La representación intermedia de Slither: cada nodo del grafo de control traducido a operaciones
   simples de la forma `TMP = operación(argumentos)`. Una misma cosa se escribe de muchas formas en
   Solidity y de una sola en SlithIR: enviar ETH son tres clases (`Transfer`, `Send`,
   `LowLevelCall` con `call_value`).
3. Falso positivo: un aviso que no es un fallo, como el `timestamp` de Slither sobre `amount == 0`
   en el staking, porque `amount` comparte struct con `since`. Falso negativo: un fallo sin
   aviso, como el `unstake` que no paga. Decidir sin ejecutar qué hace un programa cualquiera es
   imposible en general: cada herramienta elige entre avisar de más o de menos.
4. Verdadero: se corrige y se prueba con un test. Falso positivo: se silencia en la línea con el
   porqué. Aceptado: el riesgo existe y se asume; se silencia con el porqué y se anota en el
   informe.
5. Porque excluir el detector silencia también los hallazgos verdaderos que alguien escriba
   después, en cualquier parte del proyecto. El comentario en la línea solo cubre lo que ya se
   revisó, y deja escrito por qué.
6. `"fail_on": "low"`. Una clave mal escrita no da error: Slither imprime
   `slither.config.json has an unknown key` y la ignora, así que la configuración no hace lo que
   crees.
7. Con `--deny warnings` (o `--deny notes` para incluir las notas). Por defecto mira `high`,
   `med` y `low`; `info` y `gas` hay que pedirlas con `--severity`.
8. Los dos exigen su comentario en la línea inmediatamente anterior: el de arriba deja de estarlo.
   Slither va encima (`slither-disable-next-line`) y forge lint al final de la misma línea
   (`forge-lint: disable-line(...)`), o forge lint con `disable-next-item` sobre la función.
9. Porque siguen las funciones internas: un envío de ETH dentro de `_send`, o la llamada a
   `_register` dentro de `_registerWithPoints`, cuentan para la función de entrada que las llama.
   Sin `all_`, solo ves la propia función.
10. Con un contrato de casos (fixture), una función por caso, y un test que compara la lista exacta
    de funciones encontradas. Así falla tanto si sobra un hallazgo como si falta. No ve las
    llamadas por `delegatecall`: `multicall` llega a `register` así.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Slither | `bash test.sh` sin error: `6 passed` y `0 result(s) found` | 15 |
| | Los dos `slither-disable-next-line timestamp` llevan encima un porqué escrito por ti | 10 |
| 02 — forge lint | `bash test.sh` sin error: `4 passed` y `forge lint` sin avisos | 15 |
| | Explica por qué Slither da cuatro hallazgos que forge lint no da, y si alguno es real | 10 |
| 03 — Detector propio | `bash test.sh`: `3 passed` | 20 |
| | Explica por qué `justifiedSweep` no sale sin haber escrito nada para ello | 15 |
| Todos | Sin tocar `test/`, `tests/`, la configuración ni los contratos marcados "no lo modifiques" | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-23/` sin `out/`, `cache/` ni `broadcast/` de anvil, y pull request `week-23` → `main` | 10 |
| `bash test.sh` sin error: `26 tests passed`, `forge lint` sin avisos, `0 result(s) found` y `2 passed` | 25 |
| `_registerWithPoints` con `_register` antes de `burnFrom` | 10 |
| Cada silencio en su línea con un porqué; nada excluido en `slither.config.json` ni en `foundry.toml` | 20 |
| `audit/README.md`: herramientas y versiones, resultados inicial y final, y un veredicto por hallazgo | 20 |
| H-03 con severidad justificada, y lo que no ven las herramientas ni el detector | 15 |

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
| [← Proyecto — Análisis estático de tu protocolo](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
