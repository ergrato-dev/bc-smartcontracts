# Semana 05 — Control de flujo y errores

En la semana 04 tu registro guardó un dueño y una capacidad, pero no los hacía cumplir.
Esta semana aprendes a decidir y a decir "no": condicionales y bucles, `require` y
`revert`, errores personalizados que explican qué falló, `assert` para los invariantes,
`unchecked` para cuando sabes que no hay desbordamiento y modificadores para escribir cada
regla una sola vez. En el proyecto, el registro rechaza lo que rompe sus reglas.

## 🎯 Objetivos de aprendizaje

- Escribir condicionales y bucles acotados, y explicar por qué un bucle sin límite es un
  riesgo.
- Rechazar llamadas con `require`, `revert` y errores personalizados, y leer sus datos
  con `cast`.
- Explicar qué deshace un revert y qué no.
- Distinguir `require` de `assert` y usar `unchecked` con seguridad.
- Escribir modificadores, con y sin parámetros, y predecir su orden de ejecución.
- Comprobar en los tests que cada llamada revierte con el error exacto.

## 📋 Prerrequisitos

[Semana 04](../week-04-tipos_y_funciones/README.md) terminada: tipos, visibilidad,
`view`/`pure`, constructor, `constant` e `immutable`. Tu repositorio
`bc-smartcontracts-<dominio>` con el proyecto de la semana 04 en `main`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Condicionales y bucles](1-teoria/01-condicionales-y-bucles.md) | 30 min |
| 2 | [Teoría 02 — require y revert](1-teoria/02-require-y-revert.md) | 40 min |
| 3 | [Teoría 03 — Errores personalizados](1-teoria/03-errores-personalizados.md) | 40 min |
| 4 | [Teoría 04 — assert, panic y unchecked](1-teoria/04-assert-panic-y-unchecked.md) | 35 min |
| 5 | [Teoría 05 — Modificadores](1-teoria/05-modificadores.md) | 35 min |
| 6 | [Ejercicio 01 — Control de flujo](2-practicas/ejercicio-01-control-de-flujo/README.md) | 1 h 30 min |
| 7 | [Ejercicio 02 — Errores](2-practicas/ejercicio-02-errores/README.md) | 2 h |
| 8 | [Ejercicio 03 — Modificadores](2-practicas/ejercicio-03-modificadores/README.md) | 2 h 30 min |
| 9 | [Proyecto — Registro con reglas](3-proyecto/README.md) | 4 h |
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
- En tu repositorio, `forge test` de `week-05/` pasa los 18 tests del proyecto, el
  contrato está desplegado en anvil con sus tres errores probados y hay un pull request
  `week-05` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 04](../week-04-tipos_y_funciones/5-glosario/README.md) | **Semana 05 — Control de flujo y errores** | [Teoría 01 — Condicionales y bucles →](1-teoria/01-condicionales-y-bucles.md) |

← [Volver al índice del bootcamp](../README.md)
