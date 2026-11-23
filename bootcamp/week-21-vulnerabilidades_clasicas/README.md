# Semana 21 — Vulnerabilidades clásicas

Empieza la fase 5, la de seguridad. Desde la semana 03 cada teoría ha cerrado con sus riesgos;
ahora se ordenan por clases, como las ordena un auditor, y se atacan de verdad. Esta semana, las
cuatro clases que más se repiten en los informes desde hace años: **reentrancy**, **control de
acceso** (con su caso especial, `tx.origin`), **denegación de servicio** y **aritmética** que se
escapa de la checked math. En cada una escribes el atacante, ves cómo gana contra un contrato
roto y cómo pierde contra uno corregido, y dejas el ataque como test. Después los diriges contra
tu protocolo, y uno de ellos encuentra algo.

## 🎯 Objetivos de aprendizaje

- Explicar por qué una llamada externa entrega el control y reconocer la reentrancy en una
  función, entre funciones, entre contratos y de solo lectura.
- Defender un contrato con checks-effects-interactions, `nonReentrant` y el patrón pull, y saber
  qué cubre cada uno.
- Distinguir `msg.sender` de `tx.origin` en una cadena de llamadas y robar a un contrato que
  autoriza con `tx.origin`.
- Cerrar los inicializadores de un contrato detrás de un proxy y encontrar las funciones
  privilegiadas sin comprobación.
- Reconocer una denegación de servicio por una llamada que revierte, un bucle sin límite, un
  saldo forzado o un contrato que gasta o devuelve demasiado.
- Saber qué no comprueba la checked math (`unchecked`, conversiones, divisiones,
  desplazamientos) y usar `SafeCast`.
- Escribir en Foundry el atacante de cada clase y un test que compruebe el efecto del ataque.
- Empezar el informe de auditoría de tu protocolo con un hallazgo real, corregido y desplegado.

## 📋 Prerrequisitos

[Semana 20](../week-20-oraculos_y_datos_offchain/README.md) terminada: tu registro V3 con la tasa
en dólares, en `main`. Del resto del bootcamp, esta semana usa sobre todo el envío de ETH con
`call` (semana 07), las llamadas entre contratos (semana 10), `AccessControl` (semana 13) y los
proxies con sus inicializadores (semana 15).

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Reentrancy](1-teoria/01-reentrancy.md) | 50 min |
| 2 | [Teoría 02 — Control de acceso y `tx.origin`](1-teoria/02-control-de-acceso-y-tx-origin.md) | 40 min |
| 3 | [Teoría 03 — Denegación de servicio](1-teoria/03-denegacion-de-servicio.md) | 50 min |
| 4 | [Teoría 04 — Aritmética y `unchecked`](1-teoria/04-aritmetica-y-unchecked.md) | 40 min |
| 5 | [Ejercicio 01 — Reentrancy](2-practicas/ejercicio-01-reentrancy/README.md) | 2 h |
| 6 | [Ejercicio 02 — Control de acceso y `tx.origin`](2-practicas/ejercicio-02-control-de-acceso-y-tx-origin/README.md) | 2 h |
| 7 | [Ejercicio 03 — DoS y aritmética](2-practicas/ejercicio-03-dos-y-aritmetica/README.md) | 2 h |
| 8 | [Proyecto — Ataques clásicos a tu protocolo](3-proyecto/README.md) | 4 h |
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

- Los tres ejercicios con `forge test` en `7 passed`.
- En tu repositorio, `bash test.sh` de `week-21/` acaba en `8 passed` y `7 passed`, sin
  warnings. `week-21/audit/README.md` tiene la revisión por clases y el hallazgo H-01, y hay un
  pull request `week-21` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 20](../week-20-oraculos_y_datos_offchain/5-glosario/README.md) | **Semana 21 — Vulnerabilidades clásicas** | [Teoría 01 — Reentrancy →](1-teoria/01-reentrancy.md) |

← [Volver al índice del bootcamp](../README.md)
