# Semana 13 — Control de acceso

Desde la semana 08, tu registro tiene un dueño: una dirección fija que lo puede todo. Esta
semana el control de acceso crece. `Ownable` deja cambiar de dueño, y `Ownable2Step` evita
perderlo por una dirección mal escrita. `AccessControl` reparte los permisos en roles, para
que cada cuenta pueda solo lo que necesita. `Pausable` da una parada de emergencia. Un
multisig exige varias claves y un timelock retrasa los cambios para que los usuarios los vean
venir. En el proyecto, el registro pasa de un dueño a tres roles, con un timelock como
administrador.

## 🎯 Objetivos de aprendizaje

- Explicar qué es el control de acceso y el principio de mínimo privilegio.
- Usar `Ownable` y `Ownable2Step`, y desactivar `renounceOwnership` cuando haga falta.
- Repartir permisos con `AccessControl`: roles, `onlyRole`, rol administrador y jerarquías.
- Añadir una parada de emergencia con `Pausable` y decidir qué se pausa y qué no.
- Escribir un multisig con confirmaciones y poner un contrato bajo un `TimelockController`.
- Reconocer los riesgos: dueños perdidos, administradores de una sola clave, pausas que
  atrapan fondos y timelocks con un administrador de más que se salta el plazo.

## 📋 Prerrequisitos

[Semana 12](../week-12-nfts_erc721_y_erc1155/README.md) terminada: ERC-721, receptores,
metadata on-chain y ERC-1155. Tu repositorio `bc-smartcontracts-<dominio>` con el proyecto de
la semana 12 en `main`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Ownable y Ownable2Step](1-teoria/01-ownable-y-ownable2step.md) | 40 min |
| 2 | [Teoría 02 — AccessControl y roles](1-teoria/02-accesscontrol-y-roles.md) | 50 min |
| 3 | [Teoría 03 — Pausable y parada de emergencia](1-teoria/03-pausable-y-parada-de-emergencia.md) | 40 min |
| 4 | [Teoría 04 — Timelock y multisig](1-teoria/04-timelock-y-multisig.md) | 50 min |
| 5 | [Ejercicio 01 — Roles con AccessControl](2-practicas/ejercicio-01-roles-con-accesscontrol/README.md) | 2 h |
| 6 | [Ejercicio 02 — Pausa y dueño en dos pasos](2-practicas/ejercicio-02-pausa-y-dueno-en-dos-pasos/README.md) | 2 h |
| 7 | [Ejercicio 03 — Multisig](2-practicas/ejercicio-03-multisig/README.md) | 2 h |
| 8 | [Proyecto — Roles del protocolo](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 6 h |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |

## ✅ Cómo saber que terminaste

- Los tres ejercicios: `forge test --deny warnings` en verde (11, 11 y 14 tests).
- En tu repositorio, `forge test` de `week-13/` pasa 101 tests y salta el de fork; en anvil
  el timelock es el único administrador, cambiaste el hook pasando por su plazo y la
  guardiana pausó sin plazo; el test de fork pasa, `.gas-snapshot` está actualizado y hay un
  pull request `week-13` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 12](../week-12-nfts_erc721_y_erc1155/5-glosario/README.md) | **Semana 13 — Control de acceso** | [Teoría 01 — Ownable y Ownable2Step →](1-teoria/01-ownable-y-ownable2step.md) |

← [Volver al índice del bootcamp](../README.md)
