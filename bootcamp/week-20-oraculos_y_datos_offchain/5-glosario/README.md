# 📖 Glosario — Semana 20

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Agregador (*aggregator*) | Contrato de un price feed que comprueba las firmas de los nodos y guarda la mediana de sus respuestas como una ronda | `cast call $F "aggregator()(address)"` |
| Carril de gas (*gas lane*, `keyHash`) | Identificador de VRF que fija el precio máximo del gas que pagas por la respuesta | `0x787d…77ae`, 500 gwei en Sepolia |
| CID (*Content IDentifier*) | Nombre de un contenido en IPFS: su hash, con la versión, el códec y la función hash delante | `bafkreiath3uyskj7sjzwgajibrxrjse5kijabql5zxhmziym2idqkmzniq` |
| Códec (*codec*) | Parte del CID que dice cómo interpretar los bytes: tal cual (`raw`) o como bloque que lista otros (`dag-pb`) | `0x55` es `raw` |
| Coordinador de VRF (*VRF coordinator*) | Contrato de Chainlink que recibe peticiones de números aleatorios, comprueba la prueba de la respuesta y llama al consumidor | `s_vrfCoordinator.requestRandomWords(...)` |
| Desviación (*deviation threshold*) | Cambio de precio, en porcentaje, a partir del cual un feed escribe una ronda nueva | 0,5 % en ETH/USD de Ethereum |
| Direccionamiento por contenido (*content addressing*) | Nombrar un archivo por lo que contiene y no por dónde está: otro contenido es otro nombre | `ipfs://<CID>` frente a `https://servidor/archivo` |
| Fijar (*pin*) | Marcar un contenido en un nodo de IPFS para que la recolección de basura no lo borre | `ipfs pin rm <CID>` |
| Gateway | Servidor web que sirve contenido de IPFS por HTTP | `http://127.0.0.1:8080/ipfs/<CID>` |
| IPFS (*InterPlanetary File System*) | Red de nodos que guardan y sirven archivos nombrados por su CID | `ipfs add`, `ipfs cat` |
| Kubo | La implementación de referencia de un nodo de IPFS, el comando `ipfs` | `ipfs version` |
| Latido (*heartbeat*) | Tiempo máximo entre dos rondas de un feed aunque el precio no cambie | 1 hora en ETH/USD de Ethereum |
| Mock | Contrato falso que imita a uno real en los tests, con funciones para controlar lo que devuelve | `MockV3Aggregator`, `VRFCoordinatorV2_5Mock` |
| Oráculo (*oracle*) | Sistema que lleva a la cadena un dato de fuera escribiéndolo con una transacción | Un price feed de ETH/USD |
| Precio obsoleto (*stale price*) | Precio de un feed más antiguo de lo que el contrato acepta | `StalePrice(updatedAt, maxPriceAge)` |
| Price feed | Par de contratos (proxy y agregador) que publica el precio de un activo, actualizado por una red de oráculos | ETH/USD en `0x694A…5306` (Sepolia) |
| Prueba de VRF (*VRF proof*) | Dato que acompaña al número aleatorio y demuestra, con la clave pública del nodo, que sale de la semilla y no se eligió | La comprueba el coordinador antes de llamarte |
| Recolección de basura (*garbage collection*) | Limpieza de un nodo de IPFS que borra todo lo que no está fijado | `ipfs repo gc` |
| Red de oráculos descentralizada (*DON*) | Conjunto de nodos de operadores independientes que responden al mismo dato y se combinan por mediana | La red detrás de cada price feed |
| Ronda (*round*) | Cada actualización de un feed, con su número, su respuesta y su hora | `latestRoundData()` |
| Servicio de pinning (*pinning service*) | Empresa que fija tus CID en sus nodos conectados a la red | Para que la imagen siga disponible sin tu nodo |
| Suscripción de VRF (*VRF subscription*) | Cuenta en el coordinador, con saldo en LINK o ETH, que paga las respuestas de sus consumidores | `createSubscription`, `addConsumer` |
| VRF (*Verifiable Random Function*) | Función que, con una clave privada y una semilla, da un número y una prueba que cualquiera puede comprobar | Chainlink VRF v2.5 |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | Semana 21 (próximamente) |
