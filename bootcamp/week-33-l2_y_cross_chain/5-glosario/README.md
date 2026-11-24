# 📖 Glosario — Semana 33

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Alias de dirección (*address aliasing*) | La dirección con la que llega a la L2 un contrato de L1 que llama directamente al portal: la suya más `0x1111…1111` | `0x5FbD…0aa3` llega como `0x70CE…1bB4` |
| Batcher | Proceso del OP Stack que comprime las transacciones de la L2 y las publica en L1 | Lotes en blobs cada pocos minutos |
| Blob | Bloque de datos de 128 KiB que viaja con una transacción de L1 (EIP-4844); los contratos no lo leen y se borra a las semanas | Donde los rollups publican sus lotes |
| Bloquear y acuñar (*lock and mint*) | Modelo de puente que bloquea en el origen y acuña una representación en el destino | `deposit` bloquea, `finalizeDeposit` acuña |
| Confirmación blanda (*soft confirmation*) | Recibo del secuenciador antes de que el lote esté en L1 | La transacción de la L2 confirmada en 2 s |
| Disponibilidad de datos (*data availability*) | Garantía de que los datos de la L2 se publicaron y cualquiera pudo descargarlos | Los lotes en blobs de L1 |
| Fábrica de Nick | Contrato CREATE2 en `0x4e59…956C`, en la misma dirección en casi todas las cadenas | `CrossChainAddress.deploy(salt, initCode)` |
| Feed de disponibilidad del secuenciador (*L2 Sequencer Uptime Feed*) | Feed de Chainlink cuya respuesta es 0 si el secuenciador está en marcha y 1 si está caído | `sequencerUptimeFeed.latestRoundData()` |
| Inclusión forzada (*forced inclusion*) | Enviar una transacción de la L2 desde L1 para que el secuenciador tenga que incluirla | Por el `OptimismPortal` |
| L1 (capa 1) | La cadena base que da seguridad a las L2: aquí, Ethereum | Chain id 1, o 11155111 en Sepolia |
| L2 (capa 2) | Cadena que ejecuta fuera de L1 y usa L1 para los datos y para decidir su estado | OP Mainnet, Base, Arbitrum One |
| Mensaje fallido | Mensaje entregado cuya llamada revirtió; queda apuntado y cualquiera lo puede reintentar | `failedMessages[msgHash]` |
| Mensajero (*cross-domain messenger*) | Contrato de cada cadena que envía mensajes a la otra y los entrega con el remitente a la vista | `CrossDomainMessenger` |
| Plazo de gracia (*grace period*) | Tiempo que se espera tras volver el secuenciador antes de fiarse del precio | `GRACE_PERIOD = 1 hours` |
| Proposer | Proceso que publica en L1 las raíces de estado de la L2 | La raíz contra la que se demuestra una retirada |
| Prueba de fraude (*fault proof*) | Demostración en L1 de que una raíz de estado de un rollup optimista es falsa | Durante la ventana de disputa |
| Prueba de validez (*validity proof*) | Prueba criptográfica (SNARK o STARK) de que una raíz de estado de un rollup ZK es correcta | Verificada en L1 en cada lote |
| Puente (*bridge*) | Pareja de contratos, uno en cada cadena, que lleva activos de una a otra | `L1Bridge` y `L2Bridge` |
| Puente canónico (*native bridge*) | El puente del propio rollup: te fías de lo mismo que para usar la L2 | `L1StandardBridge` del OP Stack |
| Quemar y acuñar (*burn and mint*) | Modelo de puente que quema en el origen y acuña en el destino; exige controlar el token en las dos | El USDC de Circle (CCTP) |
| Raíz de estado (*state root*, *output root*) | Hash que resume el estado de la L2 en un bloque, publicado en L1 | La que se disputa durante 7 días |
| Respaldo (*backing*) | Invariante de un puente: lo bloqueado en el origen es lo que circula en el destino | `testFuzz_Paso5_LockedBacksTheL2Supply` |
| Rollup | L2 que publica en L1 los datos de todas sus transacciones | Optimista o ZK |
| Rollup optimista | Rollup cuyas raíces se dan por buenas salvo prueba de fraude durante la ventana de disputa | OP Mainnet, Arbitrum One |
| Rollup ZK | Rollup cuyas raíces llegan con una prueba de validez | zkSync Era, Scroll |
| Secuenciador (*sequencer*) | Nodo que ordena las transacciones de la L2 y produce sus bloques | Un bloque cada 2 s en el OP Stack |
| Tarifa de datos de L1 (*L1 data fee*) | Parte del coste de una transacción de L2 que paga su publicación en L1 | `getL1Fee` del `GasPriceOracle` |
| Ventana de disputa (*challenge period*) | Tiempo durante el que una raíz de un rollup optimista se puede disputar | 7 días en OP Mainnet |
| `xDomainMessageSender` | Función del mensajero que, durante una entrega, devuelve quién envió el mensaje en la otra cadena | `messenger.xDomainMessageSender() == l1Dao` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 34 — Integración final y auditoría cruzada →](../../week-34-proyecto_integrador/README.md) |
