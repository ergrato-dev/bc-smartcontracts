# Semana 11 — ERC-20 y OpenZeppelin

Empieza la fase de estándares. Un token es un contrato con una tabla de saldos, y ERC-20 es
el acuerdo que deja a cualquier wallet o contrato manejarlo sin conocerlo. Esta semana
escribes uno a mano para verlo por dentro, después lo haces con OpenZeppelin, la
biblioteca auditada que usan casi todos, y aprendes a cobrar en tokens desde un contrato
con `approve` y `transferFrom`, también con tokens que no se portan como dice el estándar.
En el proyecto, los puntos de tu registro pasan a ser un token de fidelidad.

## 🎯 Objetivos de aprendizaje

- Explicar qué es un token, las funciones y los eventos de ERC-20, y el papel de `decimals`.
- Escribir un ERC-20 completo a mano y moverlo entre cuentas con `cast`.
- Usar `approve`, `allowance` y `transferFrom` para que un contrato cobre en tokens.
- Instalar una dependencia con `forge install` e importar OpenZeppelin con un remapping.
- Heredar `ERC20` y sus extensiones, y extenderlo con `_update` y `super`.
- Mover tokens desconocidos con `SafeERC20` y apuntar lo que de verdad llegó.
- Reconocer los riesgos: tokens perdidos en el contrato, la carrera de `approve`, permisos
  ilimitados, funciones heredadas sin revisar y tokens raros.

## 📋 Prerrequisitos

[Semana 10](../week-10-llamadas_entre_contratos/README.md) terminada: codificación ABI,
llamadas de bajo nivel, `try`/`catch` y `CREATE`. Tu repositorio
`bc-smartcontracts-<dominio>` con el proyecto de la semana 10 en `main`.

La imagen del contenedor incluye OpenZeppelin desde esta semana: reconstrúyela antes de
empezar (`docker build -t bc-smartcontracts-dev docker`, desde la raíz del bootcamp).

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Tokens y ERC-20](1-teoria/01-tokens-y-erc20.md) | 40 min |
| 2 | [Teoría 02 — Allowance](1-teoria/02-allowance.md) | 40 min |
| 3 | [Teoría 03 — OpenZeppelin y forge install](1-teoria/03-openzeppelin-y-forge-install.md) | 50 min |
| 4 | [Teoría 04 — Tokens raros y SafeERC20](1-teoria/04-tokens-raros-y-safeerc20.md) | 50 min |
| 5 | [Ejercicio 01 — ERC-20 a mano](2-practicas/ejercicio-01-erc20-a-mano/README.md) | 2 h |
| 6 | [Ejercicio 02 — Token con OpenZeppelin](2-practicas/ejercicio-02-token-con-openzeppelin/README.md) | 2 h |
| 7 | [Ejercicio 03 — Allowance y SafeERC20](2-practicas/ejercicio-03-allowance-y-safeerc20/README.md) | 2 h |
| 8 | [Proyecto — Token de fidelidad](3-proyecto/README.md) | 4 h |
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

- Los tres ejercicios: `forge test --deny warnings` en verde (7, 8 y 7 tests).
- En tu repositorio, `forge test` de `week-11/` pasa 78 tests y salta el de fork; en anvil
  ganaste 30 tokens con tres altas y pagaste una cuarta con ellos, el test de fork pasa,
  `.gas-snapshot` está actualizado y hay un pull request `week-11` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 10](../week-10-llamadas_entre_contratos/5-glosario/README.md) | **Semana 11 — ERC-20 y OpenZeppelin** | [Teoría 01 — Tokens y ERC-20 →](1-teoria/01-tokens-y-erc20.md) |

← [Volver al índice del bootcamp](../README.md)
