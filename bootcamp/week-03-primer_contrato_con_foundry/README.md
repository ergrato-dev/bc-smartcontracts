# Semana 03 — Primer contrato con Foundry

En la semana 02 desplegaste un contrato de 10 bytes escrito en bytecode. Esta semana
escribes contratos en Solidity y dejas que el compilador haga ese trabajo. Montas un
proyecto Foundry, compilas, escribes tests que se ejecutan en milisegundos, despliegas en
anvil y hablas con el contrato con `cast call` y `cast send`. En el proyecto, tu protocolo
tiene por primera vez código en la cadena: un registro de su recurso principal.

## 🎯 Objetivos de aprendizaje

- Leer y escribir un contrato mínimo en Solidity: licencia, `pragma`, variables de estado
  y funciones.
- Explicar qué produce el compilador (bytecode y ABI) y calcular el selector de una
  función.
- Organizar un proyecto Foundry y encontrar lo compilado en el artefacto.
- Distinguir funciones que escriben, `view` y `pure`, y explicar qué cuesta escribir en
  el storage.
- Escribir tests con `forge`: `setUp`, aserciones, `vm.prank` y `vm.expectRevert`.
- Desplegar con `forge create` y usar `cast call` y `cast send` sin confundirlos.

## 📋 Prerrequisitos

[Semana 02](../week-02-ethereum_cuentas_transacciones_y_gas/README.md) terminada: anvil,
`cast`, transacciones, gas y la diferencia entre llamar con y sin transacción. Tu
repositorio `bc-smartcontracts-<dominio>` con el proyecto de la semana 02 en `main`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Solidity y el compilador](1-teoria/01-solidity-y-el-compilador.md) | 35 min |
| 2 | [Teoría 02 — Un proyecto Foundry](1-teoria/02-proyecto-foundry.md) | 30 min |
| 3 | [Teoría 03 — Estado y funciones](1-teoria/03-estado-y-funciones.md) | 40 min |
| 4 | [Teoría 04 — Tests con forge](1-teoria/04-tests-con-forge.md) | 40 min |
| 5 | [Teoría 05 — Desplegar y llamar](1-teoria/05-desplegar-y-llamar.md) | 35 min |
| 6 | [Ejercicio 01 — Primer contrato](2-practicas/ejercicio-01-primer-contrato/README.md) | 2 h |
| 7 | [Ejercicio 02 — Tests con forge](2-practicas/ejercicio-02-tests-con-forge/README.md) | 2 h |
| 8 | [Ejercicio 03 — Desplegar y llamar](2-practicas/ejercicio-03-desplegar-y-llamar/README.md) | 2 h |
| 9 | [Proyecto — Contrato registro](3-proyecto/README.md) | 4 h |
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
- En tu repositorio, `forge test` de `week-03/` pasa los 8 tests del proyecto, el contrato
  está desplegado en anvil y hay un pull request `week-03` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 02](../week-02-ethereum_cuentas_transacciones_y_gas/5-glosario/README.md) | **Semana 03 — Primer contrato con Foundry** | [Teoría 01 — Solidity y el compilador →](1-teoria/01-solidity-y-el-compilador.md) |

← [Volver al índice del bootcamp](../README.md)
