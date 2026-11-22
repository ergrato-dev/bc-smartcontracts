# 📖 Glosario — Semana 02

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| anvil | Nodo local de Foundry: una blockchain Ethereum de pruebas en un solo proceso | `anvil --silent &` |
| Base fee | Precio mínimo por unidad de gas de un bloque; lo calcula la red y se quema | `cast base-fee pending` → `875175000` |
| Bytecode | Secuencia de bytes que ejecuta la EVM; cada byte es un opcode o un dato | `0x602a60005260206000f3` |
| Chain id | Número que identifica una red y va dentro de lo firmado (EIP-155) | `31337` en anvil, `1` en mainnet |
| Cliente (*client*) | Programa que habla con un nodo para leer datos o enviar transacciones | `cast`, `curl`, una billetera |
| Código de creación (*init code*) | Bytecode que se ejecuta una vez al crear un contrato y devuelve el código desplegado | `0x600a600c6000396...` |
| Código desplegado (*runtime code*) | Bytecode que queda guardado en la cuenta del contrato | `cast code DIR` |
| Cuenta (*account*) | Fila del estado asociada a una dirección: nonce, saldo, código y storage | La cuenta 0 de anvil |
| Cuenta de contrato (*contract account*) | Cuenta con código; la controla su código, no una clave | `0x5FbDB2315678afecb367f032d93F642f64180aa3` |
| Cuenta externa, EOA (*Externally Owned Account*) | Cuenta sin código controlada por una clave privada; la única que inicia transacciones | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` |
| EIP (*Ethereum Improvement Proposal*) | Documento que propone un cambio o estándar de Ethereum | EIP-1559, EIP-155 |
| Estado (*state*) | Conjunto de todas las cuentas con sus datos en un momento de la cadena | Cambia con cada bloque |
| ETH, ether | Moneda nativa de Ethereum; 1 ether = 10¹⁸ wei | `cast to-wei 1` |
| EVM (*Ethereum Virtual Machine*) | Máquina virtual idéntica en todos los nodos que ejecuta el bytecode de forma determinista | Ejecuta `PUSH1`, `MSTORE`, `RETURN` |
| Gas | Unidad que mide el trabajo de ejecutar una transacción | Una transferencia usa 21 000 |
| Gas limit | Máximo de gas que aceptas consumir en una transacción (o que cabe en un bloque) | `--gas-limit 21000` |
| Gas usado (*gas used*) | Gas que consumió de verdad una transacción; está en el recibo | `cast receipt H gasUsed` |
| Génesis (*genesis*) | Primer bloque de una cadena, el número 0 | `cast block-number` → `0` en anvil nuevo |
| Gwei | 10⁹ wei; unidad habitual de los precios del gas | `cast to-wei 1 gwei` → `1000000000` |
| JSON-RPC | Protocolo con el que los clientes piden operaciones a un nodo, en JSON sobre HTTP | `{"method":"eth_chainId",...}` |
| Mainnet | Red principal de Ethereum, donde el ETH tiene valor real | Chain id `1` |
| Mempool (*memory pool*) | Sala de espera del nodo con las transacciones válidas aún no minadas | `cast rpc txpool_status` |
| Método (*method*) | Operación de un nodo que se pide por JSON-RPC | `eth_getBalance` |
| Minar (*to mine*) | Crear un bloque nuevo con transacciones; en anvil, al instante | `cast rpc anvil_mine 3` |
| Nodo (*node*) | Computadora de la red que guarda la cadena, valida bloques y atiende peticiones | anvil en el puerto 8545 |
| Nonce | Contador de transacciones de una cuenta; cada transacción lleva el siguiente número | `cast nonce DIR` |
| Opcode | Instrucción de la EVM, con un coste de gas fijo | `MSTORE`, `RETURN` |
| Precio efectivo (*effective gas price*) | Lo que se paga por unidad de gas: mínimo(tope, base fee + propina) | `1000000001` wei |
| Propina (*priority fee*) | Pago por unidad de gas para quien construye el bloque | `--priority-gas-price 2gwei` |
| Recibo (*receipt*) | Resultado de una transacción incluida: estado, gas usado, precio efectivo, bloque | `cast receipt H` |
| Repetición, ataque de (*replay attack*) | Volver a enviar una transacción firmada ajena; lo impiden el nonce y el chain id | `nonce too low` |
| Smart contract (contrato inteligente) | Programa que vive en la blockchain y ejecutan todos los nodos | El contrato que devuelve 42 |
| Testnet | Red pública de pruebas, con ETH sin valor | Sepolia |
| Transacción (*transaction*) | Petición firmada por una EOA para cambiar el estado | `cast send` |
| Transacción en bruto (*raw transaction*) | Bytes de la transacción ya firmada, listos para enviar | `cast mktx ...` → `0x02f874...` |
| Wei | Unidad mínima de ETH; toda cantidad en la cadena está en wei | `--value 1` envía 1 wei |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | Semana 03 (próximamente) |
