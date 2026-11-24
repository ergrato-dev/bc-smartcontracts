# Semana 31 — Gobernanza y DAOs

Desde la semana 13, una sola cuenta puede cambiar tu protocolo entero, y en la semana 26 lo
escribiste como hallazgo. Esta semana aprendes la alternativa: una **DAO**, donde las decisiones
se votan en un contrato y el contrato ejecuta lo aprobado. Primero los **votos**: por qué no pueden
ser el saldo del momento, cómo `ERC20Votes` guarda una foto por bloque y qué es delegar. Después el
**Governor**: el ciclo de una propuesta, los plazos, el quórum y el recuento. Luego el **timelock**:
el plazo entre aprobar y ejecutar, sus roles y el guardián. Y por último los **ataques**: votos
prestados, poca participación y propuestas con trampa, con los casos reales. En el proyecto, las
shares de tu vault de puntos pasan a ser votos y tu registro pasa a la DAO.

## 🎯 Objetivos de aprendizaje

- Explicar por qué una votación on-chain cuenta los votos de un bloque pasado, y cómo lo hacen la
  delegación y los checkpoints de `ERC20Votes`.
- Recorrer los estados de una propuesta y elegir `votingDelay`, `votingPeriod`, el umbral y el
  quórum con argumentos.
- Escribir el módulo de recuento de un Governor y montar uno con las extensiones de OpenZeppelin.
- Conectar un Governor con un `TimelockController` sin dejar ninguna cuenta con poder de
  administrador, y decidir qué puede un guardián.
- Reconocer los ataques a una gobernanza (flash loans, préstamos durante la foto, poca
  participación, propuestas que ejecutan código que cambia) y qué los limita.

## 📋 Prerrequisitos

[Semana 30](../week-30-defi/README.md) terminada: tu protocolo con el vault de puntos, en `main`.
Esta semana usa el ERC-20 y OpenZeppelin de la semana 11, los roles, el timelock y el multisig de
la semana 13, las firmas EIP-712 de la 14, el proxy de la 15, los scripts de la 16, los flash
loans de la 22, el modelo de amenazas y el hallazgo H-04 de la 26 y el vault de la 30.

La imagen del contenedor no cambia: es la de la semana 25.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Votos con ERC20Votes](1-teoria/01-votos-con-erc20votes.md) | 45 min |
| 2 | [Teoría 02 — El Governor](1-teoria/02-el-governor.md) | 50 min |
| 3 | [Teoría 03 — El timelock de la DAO](1-teoria/03-el-timelock-de-la-dao.md) | 40 min |
| 4 | [Teoría 04 — Ataques a la gobernanza](1-teoria/04-ataques-a-la-gobernanza.md) | 45 min |
| 5 | [Ejercicio 01 — Votos con checkpoints](2-practicas/ejercicio-01-votos-con-checkpoints/README.md) | 2 h |
| 6 | [Ejercicio 02 — Un Governor](2-practicas/ejercicio-02-un-governor/README.md) | 1 h 30 min |
| 7 | [Ejercicio 03 — Una DAO con timelock](2-practicas/ejercicio-03-una-dao-con-timelock/README.md) | 2 h |
| 8 | [Proyecto — La DAO del protocolo](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 5 h 30 min |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |
| Margen para el informe del proyecto | 30 min |

## ✅ Cómo saber que terminaste

- Los tres ejercicios con `forge test` sin error: `11 tests passed`, `10 tests passed` y
  `8 tests passed`.
- En tu repositorio, `bash test.sh` de `week-31/` acaba sin error, con los ocho tests de
  `test/dao/Governance.t.sol` en verde, H-04 corregido en tu informe y los veintiocho mutantes
  muertos, y hay un pull request `week-31` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 30](../week-30-defi/5-glosario/README.md) | **Semana 31 — Gobernanza y DAOs** | [Teoría 01 — Votos con ERC20Votes →](1-teoria/01-votos-con-erc20votes.md) |

← [Volver al índice del bootcamp](../README.md)
