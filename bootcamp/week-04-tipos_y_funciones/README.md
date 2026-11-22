# Semana 04 — Tipos y funciones

En la semana 03 escribiste tu primer contrato con `uint256`, `address` y funciones
`external`. Esta semana eliges el tipo justo para cada dato, decides qué se ve desde fuera
y qué no, y pones cada valor en su sitio: lo que nunca cambia, en el bytecode; lo que se
decide al desplegar, en el constructor; lo que cambia, en el storage. En el proyecto, tu
registro gana dueño, capacidad y getters automáticos.

## 🎯 Objetivos de aprendizaje

- Elegir entre `uint`, `int`, `bool`, `address` y `bytesN`, y prever qué pasa al salirse
  del rango o al convertir.
- Predecir el storage layout de un contrato y empaquetar variables.
- Elegir la visibilidad de cada función y variable, y explicar por qué `private` no
  oculta nada.
- Escribir funciones `view` y `pure`, con varios valores de retorno y documentadas con
  NatSpec.
- Escribir un constructor con argumentos y usar `constant` e `immutable`.

## 📋 Prerrequisitos

[Semana 03](../week-03-primer_contrato_con_foundry/README.md) terminada: proyecto Foundry,
`forge test`, `forge create`, `cast call` y `cast send`. Tu repositorio
`bc-smartcontracts-<dominio>` con el proyecto de la semana 03 en `main`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Tipos de valor](1-teoria/01-tipos-de-valor.md) | 40 min |
| 2 | [Teoría 02 — Variables de estado y storage](1-teoria/02-variables-de-estado-y-storage.md) | 35 min |
| 3 | [Teoría 03 — Visibilidad](1-teoria/03-visibilidad.md) | 35 min |
| 4 | [Teoría 04 — Funciones: view, pure y retornos](1-teoria/04-funciones-view-pure-y-retornos.md) | 35 min |
| 5 | [Teoría 05 — Constructor, constant e immutable](1-teoria/05-constructor-constant-e-immutable.md) | 35 min |
| 6 | [Ejercicio 01 — Tipos de valor](2-practicas/ejercicio-01-tipos-de-valor/README.md) | 2 h |
| 7 | [Ejercicio 02 — Visibilidad](2-practicas/ejercicio-02-visibilidad/README.md) | 2 h |
| 8 | [Ejercicio 03 — Constructor y constantes](2-practicas/ejercicio-03-constructor-y-constantes/README.md) | 2 h |
| 9 | [Proyecto — Registro configurable](3-proyecto/README.md) | 4 h |
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

- Ejercicios 01 y 02: `forge test` en verde y sin warnings. Ejercicio 03:
  `6 de 6 pasos correctos` en `bash test.sh`.
- En tu repositorio, `forge test` de `week-04/` pasa los 10 tests del proyecto, el
  contrato está desplegado en anvil y hay un pull request `week-04` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 03](../week-03-primer_contrato_con_foundry/5-glosario/README.md) | **Semana 04 — Tipos y funciones** | [Teoría 01 — Tipos de valor →](1-teoria/01-tipos-de-valor.md) |

← [Volver al índice del bootcamp](../README.md)
