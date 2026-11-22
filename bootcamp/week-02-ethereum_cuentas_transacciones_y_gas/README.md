# Semana 02 — Ethereum: cuentas, transacciones y gas

La semana 01 te dio las piezas: hashes, claves, firmas y bloques. Esta semana las ves
funcionando en Ethereum. Arrancas un nodo local (anvil), le hablas en su idioma
(JSON-RPC), lees cuentas y saldos, firmas y envías transacciones, y mides lo que cuestan
en gas. Terminas desplegando un contrato de 10 bytes escrito en bytecode, para entender
qué hará el compilador por ti desde la semana 03. En el proyecto, la cuenta de tu
protocolo empieza a pagar.

## 🎯 Objetivos de aprendizaje

- Arrancar anvil y hablar con él con `curl` (JSON-RPC) y con `cast`.
- Describir el estado como una tabla de cuentas y distinguir una EOA de un contrato.
- Convertir entre wei, gwei y ether, y explicar por qué Ethereum cuenta con enteros.
- Seguir una transacción de principio a fin: construir, firmar, enviar, minar y recibo.
- Explicar qué protege el nonce y el chain id, y resolver un hueco de nonce.
- Calcular el costo de una transacción con base fee y propina (EIP-1559).
- Crear un contrato desde bytecode, predecir su dirección y llamarlo.

## 📋 Prerrequisitos

[Semana 01](../week-01-criptografia_y_blockchain/README.md) terminada: imagen
`bc-smartcontracts-dev` construida, `cast` básico y tu repositorio
`bc-smartcontracts-<dominio>` con el proyecto de la semana 01 en `main`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — Ethereum y anvil](1-teoria/01-ethereum-y-anvil.md) | 25 min |
| 2 | [Teoría 02 — Cuentas y unidades](1-teoria/02-cuentas-y-unidades.md) | 25 min |
| 3 | [Teoría 03 — JSON-RPC](1-teoria/03-json-rpc.md) | 25 min |
| 4 | [Teoría 04 — Transacciones](1-teoria/04-transacciones.md) | 30 min |
| 5 | [Teoría 05 — El nonce](1-teoria/05-el-nonce.md) | 20 min |
| 6 | [Teoría 06 — Gas y EIP-1559](1-teoria/06-gas-y-eip-1559.md) | 30 min |
| 7 | [Teoría 07 — La EVM y los contratos](1-teoria/07-la-evm-y-los-contratos.md) | 25 min |
| 8 | [Ejercicio 01 — Leer la cadena](2-practicas/ejercicio-01-leer-la-cadena/README.md) | 2 h |
| 9 | [Ejercicio 02 — Una transacción paso a paso](2-practicas/ejercicio-02-una-transaccion-paso-a-paso/README.md) | 2 h |
| 10 | [Ejercicio 03 — Gas y nonce](2-practicas/ejercicio-03-gas-y-nonce/README.md) | 2 h |
| 11 | [Proyecto — Primeras transacciones](3-proyecto/README.md) | 4 h |
| 12 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 13 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 6 h |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |

## ✅ Cómo saber que terminaste

- Los tres ejercicios terminan con `6 de 6 pasos correctos` en `bash test.sh`.
- En tu repositorio, `bash test.sh` de `week-02/` pasa los 8 tests del proyecto y hay un
  pull request `week-02` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 01](../week-01-criptografia_y_blockchain/5-glosario/README.md) | **Semana 02 — Ethereum: cuentas, transacciones y gas** | [Teoría 01 — Ethereum y anvil →](1-teoria/01-ethereum-y-anvil.md) |

← [Volver al índice del bootcamp](../README.md)
