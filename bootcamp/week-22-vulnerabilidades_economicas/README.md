# Semana 22 — Vulnerabilidades económicas

La semana 21 atacó fallos del código. Esta ataca contratos que hacen exactamente lo que dicen y
aun así pierden dinero, porque se fían de algo que el atacante controla: un **precio** que se
mueve con un swap, el **capital** que da un flash loan durante una transacción, el **orden** en
que entran las transacciones de un bloque, o el **redondeo** de una división. En cada clase
escribes el ataque, lo ves ganar contra un contrato ingenuo y perder contra uno corregido. Después
revisas tu registro con esas cuatro preguntas, y una de ellas encuentra algo: la tasa que cobra
cambia con el precio, y el alta revierte si cambia mientras espera en la mempool.

## 🎯 Objetivos de aprendizaje

- Explicar por qué un precio al contado se compra en una transacción y leer un price feed con
  sus comprobaciones.
- Seguir el flujo de un flash loan ERC-3156 y escribir un prestatario que se fíe solo de quien debe.
- Revisar un contrato suponiendo que el atacante tiene capital ilimitado durante una transacción.
- Explicar qué es la mempool, quién ordena un bloque y qué es el MEV.
- Reproducir un sándwich y frustrarlo con `minAmountOut` y `deadline`.
- Escribir un commit-reveal que no se pueda copiar desde la mempool.
- Redondear cada cálculo a favor del contrato con `Math.mulDiv`.
- Reproducir un ataque de inflación contra una bóveda y defenderla con participaciones virtuales.
- Añadir al informe de auditoría la revisión económica de tu protocolo y el hallazgo H-02,
  corregido y desplegado.

## 📋 Prerrequisitos

[Semana 21](../week-21-vulnerabilidades_clasicas/README.md) terminada: tu registro con H-01
corregido y el informe de auditoría, en `main`. Del resto del bootcamp, esta semana usa sobre todo
la priority fee de EIP-1559 (semana 02), las firmas y el permit (semana 14) y el price feed con
`mulDiv` (semana 20).

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Manipulación de oráculos](1-teoria/01-manipulacion-de-oraculos.md) | 45 min |
| 2 | [Teoría 02 — Flash loans](1-teoria/02-flash-loans.md) | 40 min |
| 3 | [Teoría 03 — Front-running y MEV](1-teoria/03-front-running-y-mev.md) | 55 min |
| 4 | [Teoría 04 — Redondeo](1-teoria/04-redondeo.md) | 40 min |
| 5 | [Ejercicio 01 — Oráculo y flash loan](2-practicas/ejercicio-01-oraculo-y-flash-loan/README.md) | 2 h |
| 6 | [Ejercicio 02 — Front-running y MEV](2-practicas/ejercicio-02-front-running-y-mev/README.md) | 2 h |
| 7 | [Ejercicio 03 — Redondeo](2-practicas/ejercicio-03-redondeo/README.md) | 2 h |
| 8 | [Proyecto — Ataques económicos a tu protocolo](3-proyecto/README.md) | 4 h |
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

- Los ejercicios con `forge test` en `7 passed`, `9 passed` y `7 passed`.
- En tu repositorio, `bash test.sh` de `week-22/` acaba en `8 passed`, `7 passed` y `9 passed`,
  sin warnings. `week-22/audit/README.md` tiene la revisión económica y el hallazgo H-02, y hay un
  pull request `week-22` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 21](../week-21-vulnerabilidades_clasicas/5-glosario/README.md) | **Semana 22 — Vulnerabilidades económicas** | [Teoría 01 — Manipulación de oráculos →](1-teoria/01-manipulacion-de-oraculos.md) |

← [Volver al índice del bootcamp](../README.md)
