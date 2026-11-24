# 📖 Glosario — Semana 23

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Aceptado (*accepted risk*) | Veredicto de un hallazgo cuyo riesgo existe y se asume, con su justificación | `block.timestamp` en un plazo de días |
| Análisis de flujo de datos (*taint analysis*) | Seguir de dónde viene un valor: si lo controla quien llama, si es un saldo o un timestamp | Slither marca `amount == 0` porque `amount` comparte struct con `since` |
| Análisis estático (*static analysis*) | Analizar el código sin ejecutarlo y avisar de patrones peligrosos | `slither .`, `forge lint` |
| AST (*abstract syntax tree*) | Árbol con la estructura del código que deja el compilador: contrato, funciones, instrucciones | Lo que lee Slither del `--build-info` de forge |
| Confianza (*confidence*) | Cuántas veces acierta un detector de Slither: `High`, `Medium` o `Low` | `reentrancy-eth`: `Medium` |
| Detector | Regla de Slither que busca un patrón y devuelve hallazgos | `tx-origin`, `eth-send-without-guard` |
| Falso negativo (*false negative*) | Un fallo que existe y del que ninguna herramienta avisa | `unstake` que no paga la recompensa |
| Falso positivo (*false positive*) | Un aviso que no corresponde a ningún fallo | `arbitrary-send-eth` en `withdrawFees`, que solo llama el tesorero |
| Fixture | Contrato de casos, que no se despliega, para probar un detector | `Treasury.sol` del ejercicio 03 |
| Grafo de control (*control-flow graph*, CFG) | Las instrucciones de una función como nodos, con flechas a las que pueden ir después | Lo que dice a Slither que la llamada va antes de la escritura |
| Hallazgo (*finding*) | Lo que devuelve un detector o un lint: qué, dónde y por qué | `Reentrancy in Crowdfund.refund()` |
| Impacto (*impact*) | Cuánto daño haría un hallazgo de Slither si es real: `High` a `Informational` y `Optimization` | `missing-zero-check`: `Low` |
| Impresora (*printer*) | Resumen de Slither que no busca fallos: orienta antes de auditar | `--print vars-and-auth` |
| Lint | Regla de forge lint, con una severidad y un identificador | `unsafe-typecast` (`med`) |
| Linter | Analizador estático de errores probables y de estilo | `forge lint` |
| Severidad (*severity*) | Nivel de un lint de forge lint: `high`, `med`, `low`, `info`, `gas` o `code-size` | Por defecto, solo las tres primeras |
| SlithIR | Representación intermedia de Slither: cada nodo, en operaciones simples | `TMP_148(bool) = TMP_147 == GOAL` |
| Triaje (*triage*) | Decidir, hallazgo por hallazgo, si es verdadero, falso positivo o aceptado | La tabla del informe del proyecto |
| Verdadero positivo (*true positive*) | Un aviso que corresponde a un fallo real | `reentrancy-eth` en `refund` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 24 — Fuzzing de invariantes →](../../week-24-fuzzing_de_invariantes/README.md) |
