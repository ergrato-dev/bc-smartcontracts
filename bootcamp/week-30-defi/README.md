# Semana 30 — DeFi: AMM, vaults y préstamos

DeFi son los contratos que cambian, prestan y hacen rendir tokens sin una empresa en medio: las
reglas son el código, y cualquiera puede usarlas. Esta semana escribes sus tres piezas básicas.
Primero un **AMM** de producto constante: cómo un contrato da precio con una fórmula, qué cobra
cada swap y qué ganan y qué arriesgan quienes ponen la liquidez. Después un **vault ERC-4626**: el
estándar para guardar un token en nombre de muchos, con sus reglas de redondeo, sus shares
virtuales y lo que hay que cambiar para añadir una comisión o un tope. Y por último un **préstamo
con garantía**: el valor de la garantía con un oráculo, la salud de cada posición, la liquidación y
el interés con un índice. Los ataques de la semana 22 vuelven en cada pieza, ahora desde dentro. En
el proyecto, tu protocolo gana un vault donde tus usuarios guardan sus puntos y cobran un bonus por
cada alta.

## 🎯 Objetivos de aprendizaje

- Calcular un swap de un AMM de producto constante con comisión, y explicar el impacto en el
  precio y el crecimiento de `k`.
- Calcular las LP shares de la primera liquidez y de las siguientes, lo que devuelve una retirada
  y la pérdida impermanente.
- Usar las funciones de ERC-4626 sabiendo qué prometen `preview*` y `max*` y hacia dónde redondea
  cada una, y escribir un vault con el `ERC4626` de OpenZeppelin.
- Elegir el offset de las shares virtuales contra el ataque de inflación.
- Calcular el máximo a pedir con el LTV, el factor de salud, el precio de liquidación y lo que se
  lleva un liquidador, y llevar el interés con un índice.
- Reconocer en cada pieza sus riesgos: precios manipulables, redondeo, regalos y funciones del
  estándar que no dicen la verdad.

## 📋 Prerrequisitos

[Semana 29](../week-29-optimizacion_de_gas/README.md) terminada: tu protocolo con el alta
optimizada y el gas guardado, en `main`. Esta semana usa el ERC-20 y OpenZeppelin de la semana 11,
el control de acceso de la semana 13, los price feeds de la semana 20, la reentrancy de la semana
21, los ataques económicos y el redondeo de la semana 22, el modelo de amenazas de la semana 26 y
el gas guardado de la semana 29.

La imagen del contenedor no cambia: es la de la semana 25.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — El AMM de producto constante](1-teoria/01-el-amm-de-producto-constante.md) | 45 min |
| 2 | [Teoría 02 — La liquidez de un AMM](1-teoria/02-la-liquidez-de-un-amm.md) | 40 min |
| 3 | [Teoría 03 — Vaults ERC-4626](1-teoria/03-vaults-erc-4626.md) | 50 min |
| 4 | [Teoría 04 — Préstamos con garantía](1-teoria/04-prestamos-con-garantia.md) | 45 min |
| 5 | [Ejercicio 01 — Un AMM](2-practicas/ejercicio-01-un-amm/README.md) | 2 h |
| 6 | [Ejercicio 02 — Un vault con comisiones](2-practicas/ejercicio-02-vault-con-comisiones/README.md) | 1 h 30 min |
| 7 | [Ejercicio 03 — Un préstamo con garantía](2-practicas/ejercicio-03-prestamo-con-garantia/README.md) | 2 h |
| 8 | [Proyecto — Un vault de puntos](3-proyecto/README.md) | 4 h |
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

- Los tres ejercicios con `forge test` sin error: `10 tests passed`, `9 tests passed` y
  `9 tests passed`.
- En tu repositorio, `bash test.sh` de `week-30/` acaba sin error, con los ocho tests de
  `test/defi/PointsVault.t.sol` en verde, el gas nuevo del alta en tu informe y los veinticuatro
  mutantes muertos, y hay un pull request `week-30` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 29](../week-29-optimizacion_de_gas/5-glosario/README.md) | **Semana 30 — DeFi: AMM, vaults y préstamos** | [Teoría 01 — El AMM de producto constante →](1-teoria/01-el-amm-de-producto-constante.md) |

← [Volver al índice del bootcamp](../README.md)
