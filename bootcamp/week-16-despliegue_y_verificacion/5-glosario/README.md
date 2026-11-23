# 📖 Glosario — Semana 16

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| **Alias de red** (*RPC endpoint alias*) | Nombre corto de `[rpc_endpoints]` en `foundry.toml` que sustituye a una URL RPC | `--rpc-url sepolia` |
| **Argumentos del constructor** (*constructor arguments*) | Valores codificados en ABI al final de la transacción de creación; no están en el código desplegado | `cast abi-encode "constructor(address)" 0x90F7…` |
| **Chain id** | Número que identifica una red y va dentro de cada transacción firmada (EIP-155) | `11155111` en Sepolia, `31337` en anvil |
| **Emitir** (*broadcast*) | Firmar y enviar a la red las transacciones que anotó un script | `forge script ... --broadcast` |
| **Explorador de bloques** (*block explorer*) | Web que muestra bloques, transacciones y contratos de una red | `sepolia.etherscan.io` |
| **Faucet** | Web que regala ETH de testnet | Sepolia PoW Faucet |
| **Keystore** | Archivo JSON con una clave privada cifrada con una contraseña | `~/.foundry/keystores/sepolia-dev` |
| **KDF** (*key derivation function*) | Función que convierte una contraseña en una clave de cifrado, lenta a propósito | `scrypt` |
| **MAC** (*message authentication code*) | Comprobación del keystore que detecta una contraseña equivocada | `Mac Mismatch` |
| **Metadatos de solc** (*contract metadata*) | Bloque CBOR al final del bytecode con el hash IPFS de los ajustes y la versión de solc | `…64736f6c6343000826 0033` |
| **Proveedor RPC** (*RPC provider*) | Servicio que te da la URL de un nodo para hablar con una red | `ethereum-sepolia-rpc.publicnode.com` |
| **Registro de ejecución** (*broadcast log*) | JSON que deja `forge script` con las transacciones, direcciones y recibos | `broadcast/DeployBox.s.sol/31337/run-latest.json` |
| **Script de despliegue** (*deployment script*) | Contrato que hereda de `Script` y cuyo `run()` describe un despliegue | `script/DeployProtocol.s.sol` |
| **Simulación** (*dry run*) | Ejecución de un script contra la red sin enviar nada, para estimar gas y detectar fallos | `forge script ... --rpc-url sepolia` |
| **Standard JSON input** | Entrada de solc con todo el código fuente y los ajustes; es lo que se envía al verificador | `--show-standard-json-input` |
| **Testnet** | Red pública de Ethereum en la que el ETH no tiene valor | Sepolia |
| **Verificación** (*contract verification*) | Publicar el código fuente y demostrar que compila al bytecode de una dirección | `forge script ... --verify` |
| **Verificador** (*verifier*) | Servicio que recompila y compara para verificar un contrato | Etherscan, Sourcify, Blockscout |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 17 — Frontend con viem →](../../week-17-frontend_con_viem/README.md) |
