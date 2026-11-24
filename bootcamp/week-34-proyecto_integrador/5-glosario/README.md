# 📖 Glosario — Semana 34

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Alerta | Programa que lee los eventos de un protocolo y avisa a una persona cuando algo exige actuar | Un `RoleGranted` inesperado |
| Análisis de variantes (*variant analysis*) | Buscar en el resto del código la misma causa de un hallazgo ya encontrado | `setRewardRate` tampoco llama a `_update` |
| Asimetría | Dos funciones que cambian lo mismo y se protegen distinto: el sitio donde más hallazgos salen | `withdraw` llama a `_update` y `stake` no |
| Auditoría cruzada | Auditoría del código de otra persona, que lo lee sin las intenciones de quien lo escribió | Tú auditas a tu pareja y ella a ti |
| Comprobación del despliegue | Script que, solo con lecturas, revierte si un despliegue no tiene los roles y conexiones esperados | `CheckDeployment.s.sol` |
| Configuración | Lo que se decide al desplegar y no está en el código: roles, direcciones, parámetros | El plazo del timelock |
| Corregido | Estado de un hallazgo cuyo ataque ya no funciona, con su test de regresión | H-06 |
| Divulgación responsable (*responsible disclosure*) | Contar un fallo primero a los autores, en privado, y publicarlo cuando está corregido | Un aviso privado de GitHub |
| En disputa | Estado de un hallazgo en el que la autora no está de acuerdo, con sus argumentos | "No es explotable: hace falta el rol de dueño" |
| Etiqueta (*tag*) | Nombre fijo de git para un commit; la anotada guarda autor, fecha y mensaje | `git tag -a v1.0.0` |
| Hallazgo (*finding*) | Fallo confirmado por una prueba de concepto, con su severidad y recomendación | C-01 |
| Incidente | Lo que pone en riesgo fondos o servicio de un protocolo desplegado | Un oráculo que se para |
| Informe de incidente (*post-mortem*) | Relato, tras corregir, de qué pasó, cuándo se supo, qué se hizo y qué cambia | El post-mortem de Parity |
| Plan de incidentes | Documento escrito antes que dice quién pausa, cómo se corrige y cómo se comunica | En el repositorio, junto al informe |
| Programa de recompensas por fallos (*bug bounty*) | Pago por los fallos que llegan por divulgación responsable, según su severidad | Un programa en Immunefi |
| Prueba de concepto (*PoC*, *proof of concept*) | Test que demuestra un hallazgo en el commit auditado, sin cambiar su código | `test_Paso1_PoC_AnyoneSetsTheRateAndDrainsThePool` |
| Reconocido | Estado de un hallazgo que existe y no se corrige, con el porqué; pasa a riesgo aceptado | H-07 |
| Revisión de correcciones (*fix review*) | Leer las correcciones de un informe buscando las incompletas, las nuevas y las incompatibles | El paso 4 del ejercicio 03 |
| `SECURITY.md` | Archivo de la raíz de un repositorio que dice cómo informar de un fallo | GitHub lo enseña en la pestaña Security |
| Severidad | Gravedad de un hallazgo según su impacto y su probabilidad | Crítica, alta, media, baja, informativa |
| Sospecha descartada | Hipótesis que un test demuestra imposible, y que se queda como test | `test_Paso4_NoOneWithdrawsMoreThanTheirStake` |
| Test de regresión | El ataque de una PoC con la conclusión al revés: comprueba que ya no funciona | `test_RevertWhen_TheUptimeFeedHasNotStarted` |
| Versionado semántico (*semantic versioning*) | Tres números: incompatible, compatible nuevo, corrección | `v1.0.0` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Índice del bootcamp →](../../README.md) |
