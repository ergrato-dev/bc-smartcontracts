# Semana 06 — Estructuras de datos

En la semana 05 tu registro aprendió a decir "no", pero cada recurso seguía siendo solo un
número de un contador. Esta semana aprendes a guardar datos con forma: mappings para
encontrar un valor por su clave, structs para agrupar campos, enums para estados con
nombre, arrays para listas, y las tres ubicaciones de datos (`storage`, `memory` y
`calldata`) que deciden si un cambio se guarda o se pierde. En el proyecto, cada recurso
pasa a ser un registro con dueño, estado y etiqueta, y se puede retirar.

## 🎯 Objetivos de aprendizaje

- Usar mappings simples y anidados, y explicar por qué toda clave devuelve un valor.
- Declarar structs y enums, guardarlos en un mapping y leerlos con `cast`.
- Usar arrays dinámicos y fijos, quitar elementos con swap-and-pop y acotar los bucles que
  los recorren.
- Elegir entre `storage`, `memory` y `calldata`, y predecir si una asignación copia o
  referencia.
- Combinar mapping y array para tener búsqueda directa y lista recorrible.
- Reconocer los riesgos: valores por defecto que parecen datos, copias que no guardan,
  listas sin límite y `delete` que no borra mappings.

## 📋 Prerrequisitos

[Semana 05](../week-05-control_y_errores/README.md) terminada: condicionales, bucles,
`require`, `revert`, errores personalizados, `assert`, `unchecked` y modificadores. Tu
repositorio `bc-smartcontracts-<dominio>` con el proyecto de la semana 05 en `main`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Mappings](1-teoria/01-mappings.md) | 35 min |
| 2 | [Teoría 02 — Structs y enums](1-teoria/02-structs-y-enums.md) | 35 min |
| 3 | [Teoría 03 — Arrays](1-teoria/03-arrays.md) | 35 min |
| 4 | [Teoría 04 — storage, memory y calldata](1-teoria/04-storage-memory-y-calldata.md) | 40 min |
| 5 | [Teoría 05 — Patrones de colecciones](1-teoria/05-patrones-de-colecciones.md) | 35 min |
| 6 | [Ejercicio 01 — Mappings](2-practicas/ejercicio-01-mappings/README.md) | 1 h 30 min |
| 7 | [Ejercicio 02 — Structs y enums](2-practicas/ejercicio-02-structs-y-enums/README.md) | 2 h |
| 8 | [Ejercicio 03 — Arrays](2-practicas/ejercicio-03-arrays/README.md) | 2 h 30 min |
| 9 | [Proyecto — Registro de recursos](3-proyecto/README.md) | 4 h |
| 10 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 11 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 6 h |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |

## ✅ Cómo saber que terminaste

- Los tres ejercicios: `forge test` en verde y sin warnings.
- En tu repositorio, `forge test` de `week-06/` pasa los 23 tests del proyecto, el
  contrato está desplegado en anvil con sus tres errores probados y hay un pull request
  `week-06` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 05](../week-05-control_y_errores/5-glosario/README.md) | **Semana 06 — Estructuras de datos** | [Teoría 01 — Mappings →](1-teoria/01-mappings.md) |

← [Volver al índice del bootcamp](../README.md)
