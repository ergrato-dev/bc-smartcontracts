# Semana 20 — Oráculos y datos off-chain

Un contrato solo ve la cadena: no sabe cuánto vale un ETH en dólares, no puede sacar un número
que nadie prevea y no puede guardar una imagen sin pagar una fortuna en gas. Esta semana traes
esos datos de fuera sin entregar el control a quien los trae. Un **price feed** de Chainlink da
el precio ETH/USD agregado por muchos nodos, **Chainlink VRF** da números aleatorios con una
prueba que el contrato comprueba, e **IPFS** guarda archivos nombrados por su hash. Tu protocolo
cierra la fase 4 cobrando su tasa en dólares.

## 🎯 Objetivos de aprendizaje

- Explicar por qué un contrato no puede leer datos de fuera y qué confianza añade un oráculo.
- Leer un price feed desde Solidity, rechazar precios no positivos o antiguos y convertir
  dólares a wei con los decimales del feed, redondeando a favor del protocolo.
- Explicar por qué los datos del bloque no sirven como azar y qué garantiza una VRF.
- Pedir y recibir números de Chainlink VRF v2.5 en dos transacciones, sin dejar el contrato
  bloqueado si la respuesta falla o no llega.
- Calcular, guardar y leer contenido en IPFS por su CID, y elegir cómo apunta un `tokenURI` a
  su metadata.
- Probar todo sin red con los mocks de Chainlink y un nodo de IPFS propio, y contra Sepolia con
  un fork.
- Reconocer los riesgos: precios viejos, decimales supuestos, redondeos que regalan valor,
  números previsibles, callbacks que revierten y archivos que nadie fija.

## 📋 Prerrequisitos

[Semana 19](../week-19-indexacion_con_fastapi_y_postgresql/README.md) terminada: tu indexador en
`week-19/`, en `main`. Del resto del bootcamp, esta semana usa sobre todo los forks y `vm.warp`
(semana 09), el ERC-721 y su `tokenURI` (semana 12) y las actualizaciones UUPS (semana 15).

La imagen del bootcamp trae desde esta semana los contratos de Chainlink (en
`/opt/lib/chainlink-contracts`) y kubo, el nodo de IPFS: reconstrúyela antes de empezar
(`docker build -t bc-smartcontracts-dev docker`).

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — El problema del oráculo](1-teoria/01-el-problema-del-oraculo.md) | 45 min |
| 2 | [Teoría 02 — Price feeds](1-teoria/02-price-feeds.md) | 45 min |
| 3 | [Teoría 03 — Aleatoriedad con VRF](1-teoria/03-aleatoriedad-con-vrf.md) | 45 min |
| 4 | [Teoría 04 — IPFS y metadatos](1-teoria/04-ipfs-y-metadatos.md) | 45 min |
| 5 | [Ejercicio 01 — Precio con Chainlink](2-practicas/ejercicio-01-precio-con-chainlink/README.md) | 2 h |
| 6 | [Ejercicio 02 — Sorteo con VRF](2-practicas/ejercicio-02-sorteo-con-vrf/README.md) | 2 h 30 min |
| 7 | [Ejercicio 03 — Metadatos en IPFS](2-practicas/ejercicio-03-metadatos-en-ipfs/README.md) | 1 h 30 min |
| 8 | [Proyecto — Tasa en dólares con un oráculo](3-proyecto/README.md) | 4 h |
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

- Ejercicio 01: `forge test` con `8 passed`. Ejercicio 02: `7 passed`. Ejercicio 03:
  `5 de 5 pasos correctos`.
- En tu repositorio, `bash test.sh` de `week-20/` acaba en `8 passed`. Tu registro es V3 en
  anvil y en Sepolia, cobra `registrationFee()` según el feed ETH/USD y tu página lo usa. Hay un
  pull request `week-20` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 19](../week-19-indexacion_con_fastapi_y_postgresql/5-glosario/README.md) | **Semana 20 — Oráculos y datos off-chain** | [Teoría 01 — El problema del oráculo →](1-teoria/01-el-problema-del-oraculo.md) |

← [Volver al índice del bootcamp](../README.md)
