# Semana 33 — L2 y cross-chain

Ethereum ejecuta pocas transacciones por segundo y las cobra caras. Esta semana sales de L1.
Primero los **rollups**: qué publican en Ethereum, qué hace el secuenciador y por qué una retirada
tarda siete días. Después, **desplegar en una L2**: la misma dirección en dos cadenas, firmas que
valen en una sola y precios que no se usan con el secuenciador caído. Luego los **puentes**: cómo
un token "pasa" de una cadena a otra y por qué ahí se han robado miles de millones. Y por último
los **mensajes entre cadenas**: cómo un contrato de L1 manda en uno de la L2. En el proyecto, tu
protocolo se despliega en una L2 y lo gobierna desde L1 la misma DAO.

## 🎯 Objetivos de aprendizaje

- Explicar cómo funciona un rollup, optimista o ZK, y qué riesgos trae su secuenciador.
- Desplegar el mismo contrato en varias cadenas, con la misma dirección y sin que sus firmas
  valgan en las dos.
- Leer el feed de disponibilidad del secuenciador de Chainlink antes de usar un precio en una L2.
- Escribir un mensajero entre cadenas y un contrato que solo acepta mensajes de un remitente.
- Escribir un puente de bloquear y acuñar y probar su invariante de respaldo.
- Reconocer los riesgos: autenticación de mensajes a medias, puentes sin respaldo, suposiciones
  de L1 que una L2 no cumple.

## 📋 Prerrequisitos

[Semana 32](../week-32-account_abstraction/README.md) terminada: tu protocolo con las altas
patrocinadas, en `main`. Esta semana usa `CREATE2` de la semana 10, el ERC-20 de la 11, las firmas
EIP-712 de la 14, los scripts de la 16, el feed de Chainlink de la 20, el fuzzing de la 24, el
modelo de amenazas de la 26 y la DAO de la 31.

La imagen del contenedor no cambia.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Rollups](1-teoria/01-rollups.md) | 45 min |
| 2 | [Teoría 02 — Desplegar en una L2](1-teoria/02-desplegar-en-una-l2.md) | 50 min |
| 3 | [Teoría 03 — Puentes](1-teoria/03-puentes.md) | 45 min |
| 4 | [Teoría 04 — Mensajes entre cadenas](1-teoria/04-mensajes-entre-cadenas.md) | 40 min |
| 5 | [Ejercicio 01 — Un contrato en varias cadenas](2-practicas/ejercicio-01-un-contrato-en-varias-cadenas/README.md) | 1 h 30 min |
| 6 | [Ejercicio 02 — Mensajes entre cadenas](2-practicas/ejercicio-02-mensajes-entre-cadenas/README.md) | 2 h |
| 7 | [Ejercicio 03 — Un puente de tokens](2-practicas/ejercicio-03-un-puente-de-tokens/README.md) | 2 h |
| 8 | [Proyecto — Tu protocolo en una L2](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 5 h 30 min |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |
| Margen para el informe | 30 min |

## ✅ Cómo saber que terminaste

- Los tres ejercicios con `forge test` sin error: `11 tests passed`, `12 tests passed` y
  `10 tests passed`.
- En tu repositorio, `bash test.sh` de `week-33/` acaba sin error, con los nueve tests de
  `test/l2/OnL2.t.sol` en verde y los treinta y ocho mutantes muertos, y hay un pull request
  `week-33` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 32](../week-32-account_abstraction/5-glosario/README.md) | **Semana 33 — L2 y cross-chain** | [Teoría 01 — Rollups →](1-teoria/01-rollups.md) |

← [Volver al índice del bootcamp](../README.md)
