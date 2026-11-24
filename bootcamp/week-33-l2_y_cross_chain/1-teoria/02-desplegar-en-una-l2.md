# Teoría 02 — Desplegar en una L2

## 🎯 Objetivos

- Saber qué cambia y qué no cuando el mismo contrato corre en L1 y en una L2.
- Desplegar con `forge script` en dos cadenas y conseguir la misma dirección con CREATE2.
- Proteger las firmas EIP-712 para que no valgan en otra cadena.
- Leer el feed de disponibilidad del secuenciador de Chainlink antes de usar un precio.
- Reconocer las suposiciones de L1 que no se cumplen en una L2.

## Qué problema resuelve

Tu protocolo funciona en anvil y en Sepolia (semana 16). Ahora quieres que también funcione en
una L2, donde las altas cuestan céntimos. El código compila igual, los scripts se ejecutan igual y
`cast` habla con la L2 por el mismo JSON-RPC. Lo que cambia son detalles que en L1 nadie pensaba:
que la dirección de un contrato sea la misma en las dos cadenas, que una firma valga en las dos,
que el secuenciador esté en marcha o qué significa `block.number`.

## Cómo funciona

### Lo que no cambia

El OP Stack (OP Mainnet, Base) es **equivalente a la EVM**: los mismos opcodes, el mismo gas por
opcode, las mismas direcciones de precompilados. Arbitrum es **compatible**: ejecuta el mismo
bytecode, con algunas diferencias documentadas. Tu Solidity, OpenZeppelin y forge funcionan sin
cambios; un contrato de L1 se despliega en la L2 tal cual.

### Lo que sí cambia

| En L1 | En una L2 |
| ----- | --------- |
| `block.chainid` es 1 (o 11155111 en Sepolia) | El de la L2: 10, 8453, 42161... |
| `block.number` avanza cada 12 s | En el OP Stack, cada 2 s. En Arbitrum devuelve un número de bloque **de L1** aproximado |
| `block.timestamp` lo pone el validador | Lo pone el secuenciador, dentro de unos márgenes |
| El gas paga la ejecución | El gas paga la ejecución y además la tarifa de datos de L1 (teoría 01) |
| Los oráculos se actualizan mientras haya bloques | Si el secuenciador se cae, no hay bloques ni actualizaciones |
| USDC, WETH, Chainlink en sus direcciones | Otras direcciones, a veces dos versiones del mismo token (nativa y puenteada) |

### La misma dirección en dos cadenas

Con `new Contrato()`, la dirección sale de quien despliega y de su nonce (semana 10). En otra
cadena, tu nonce es otro y la dirección también. Para que coincidan hay dos caminos:

- **El mismo nonce.** Una cuenta nueva que despliega lo mismo en el mismo orden en cada cadena.
  Funciona hasta que una transacción falla o se cuela otra.
- **CREATE2 desde la misma fábrica.** La dirección depende de la fábrica, la sal y el hash del
  código de creación (con los argumentos del constructor). La **fábrica de Nick**, en
  `0x4e59b44847b379578588920cA78FbF26c0B4956C`, existe en esa dirección en Ethereum, en casi todas
  las L2 y en anvil. `forge script` la usa sola cuando escribes `new Contrato{salt: ...}()`.

La misma dirección no es el mismo contrato: cada cadena tiene su copia, con su storage. Y si tu
contrato no está desplegado en una cadena, esa dirección está libre para quien llegue primero con
el mismo código de creación y la misma sal... o con otro camino a la misma dirección.

### Firmas que valen en una sola cadena

Una transacción firmada lleva el chain id desde EIP-155: no se puede repetir en otra cadena. Una
firma para un contrato (un permit, un voto, un vale) lleva lo que su dominio EIP-712 diga
(semana 14). El dominio incluye `chainId` y `verifyingContract`, y con la misma dirección en dos
cadenas solo el `chainId` las distingue. Además, hay que calcularlo con `block.chainid` en el
momento de verificar: si una cadena se divide (un hard fork que crea otra con otro chain id), un
dominio guardado al desplegar seguiría aceptando las firmas en las dos. `EIP712` de OpenZeppelin
guarda el separador y lo recalcula si `block.chainid` cambió.

### El secuenciador y los precios

Si el secuenciador se cae, el feed ETH/USD de la L2 se queda con su último precio. Tu contrato lo
leería como válido mientras no pase de `maxPriceAge`, aunque en L1 el precio se haya movido. Y
cuando vuelve, entran de golpe las transacciones que esperaban: quien pudo enviar por L1 (la
inclusión forzada de la teoría 01) ya tiene ventaja.

Chainlink publica en cada L2 un **feed de disponibilidad del secuenciador** (L2 Sequencer Uptime
Feed): un `AggregatorV3Interface` cuyo `answer` es 0 si el secuenciador está en marcha y 1 si
está caído, y cuyo `startedAt` dice desde cuándo. Antes de usar un precio: si `answer` no es 0,
nada; si volvió hace menos de un **plazo de gracia** (una hora en el ejemplo de Chainlink),
tampoco.

## Cómo se escribe

### Desplegar en dos cadenas con la misma dirección

**Dónde**: un proyecto Foundry con la plantilla de `docs/plantillas/starter-foundry/`, este
contador en `src/Counter.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Counter {
    uint256 public number;

    function increment() external {
        number++;
    }
}
```

y este script en `script/DeployCounter.s.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Script} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract DeployCounter is Script {
    function run() external returns (Counter counter) {
        vm.startBroadcast();
        // Con `salt`, forge despliega por la fábrica CREATE2 de Nick, no desde tu cuenta.
        counter = new Counter{salt: bytes32(uint256(1))}();
        vm.stopBroadcast();
    }
}
```

**Ejecuta**, en el contenedor: un anvil hace de L1 y otro, con el chain id de Base, de L2. En la
L2 la cuenta envía antes una transacción, para que su nonce sea distinto:

```bash
anvil --silent &
anvil --port 8546 --chain-id 8453 --silent &
K=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
cast send 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 --value 1 --private-key $K --rpc-url http://127.0.0.1:8546
forge script script/DeployCounter.s.sol --rpc-url http://127.0.0.1:8545 --private-key $K --broadcast
forge script script/DeployCounter.s.sol --rpc-url http://127.0.0.1:8546 --private-key $K --broadcast
```

**Salida** (de cada `forge script`, las líneas que importan):

```text
counter: contract Counter 0x9Ee4Be3f9278224a60C5d4AF96B2aD05170Ea48b
Chain 31337
...
counter: contract Counter 0x9Ee4Be3f9278224a60C5d4AF96B2aD05170Ea48b
Chain 8453
```

La misma dirección con nonces distintos (1 y 2 al acabar). Son dos contratos: incrementa en una
cadena y mira la otra.

```bash
cast send 0x9Ee4Be3f9278224a60C5d4AF96B2aD05170Ea48b "increment()" --private-key $K
cast call 0x9Ee4Be3f9278224a60C5d4AF96B2aD05170Ea48b "number()(uint256)"
cast call 0x9Ee4Be3f9278224a60C5d4AF96B2aD05170Ea48b "number()(uint256)" --rpc-url http://127.0.0.1:8546
```

Imprime `1` y `0`. forge guarda cada despliegue en `broadcast/DeployCounter.s.sol/<chain id>/`,
con `"transactionType": "CREATE2"`.

### En una testnet L2

Con la cuenta y la clave de Etherscan de la semana 16, solo cambia la red. En `foundry.toml`:

```toml
[rpc_endpoints]
op_sepolia = "${OP_SEPOLIA_RPC_URL}"

[etherscan]
op_sepolia = { key = "${ETHERSCAN_API_KEY}", chain = 11155420 }
```

y en `.env`, `OP_SEPOLIA_RPC_URL=https://sepolia.optimism.io`. El ETH de OP Sepolia sale de un
faucet o del puente de Sepolia (teoría 03). Después, el mismo comando de siempre:

```bash
forge script script/DeployCounter.s.sol --rpc-url op_sepolia --account sepolia-dev --broadcast --verify
```

### Leer el feed del secuenciador

Del ejercicio 01, `L2PriceReader.ethUsd()`:

```solidity
(, int256 status, uint256 statusSince,,) = sequencerUptimeFeed.latestRoundData();
if (status != 0) revert SequencerDown();
if (block.timestamp - statusSince <= GRACE_PERIOD) revert GracePeriodNotOver(statusSince);
(, int256 answer,, uint256 updatedAt,) = priceFeed.latestRoundData();
if (answer <= 0) revert InvalidPrice(answer);
if (block.timestamp - updatedAt > MAX_PRICE_AGE) revert StalePrice(updatedAt);
```

Primero el secuenciador, después el precio con las comprobaciones de la semana 20. Las direcciones
de los feeds de cada L2 están en la [página de Chainlink](https://docs.chain.link/data-feeds/l2-sequencer-feeds).

## Antipatrones y riesgos

- **`block.number` como reloj.** Un plazo de "7200 bloques" dura un día en L1, cuatro horas en el
  OP Stack y otra cosa en Arbitrum. Para plazos, `block.timestamp`.
- **Copiar direcciones de L1.** USDC, WETH o un feed de Chainlink tienen otra dirección en cada
  cadena, y a veces hay dos USDC (el nativo y uno puenteado). Una dirección de L1 en un contrato
  de L2 apunta a nada, o a algo de otro.
- **Dar por hecho que tu dirección es tuya en otra cadena.** En 2022, un market maker recibió 20
  millones de tokens OP en una dirección de Optimism donde su multisig aún no existía; alguien
  repitió allí las transacciones de la fábrica que lo habían creado en L1 y se quedó la dirección.
  Antes de recibir nada en una cadena, despliega allí.
- **Un dominio EIP-712 sin `chainId`, o guardado al desplegar.** Con la misma dirección en dos
  cadenas, cada firma vale en las dos. Calcula el separador con `block.chainid` o usa `EIP712` de
  OpenZeppelin.
- **Usar el precio sin mirar el secuenciador.** Un precio de hace dos horas, de antes de la
  caída, liquida posiciones que no debía. Y un precio leído justo al volver, también.
- **Esperar el mismo `evm_version`.** Una L2 puede ir un hard fork por detrás de L1. Antes de
  desplegar, mira qué opcodes admite y fija `evm_version` en `foundry.toml` si hace falta.

## Trucos

- `cast chain-id --rpc-url <red>` antes de un `--broadcast`: si no es el que esperas, para.
- En `broadcast/<script>/<chain id>/run-latest.json` mira `"transactionType"` y
  `"contractAddress"`: dicen cómo y dónde se desplegó de verdad. Con forge 1.9 y anvil, con los
  chain id 10 y 11155420 el script despliega con `CREATE` aunque escribas `salt`, y la dirección
  cambia. Si la dirección importa, llama a la fábrica tú mismo, como `CrossChainAddress.deploy`
  del ejercicio 01.
- En un test, `vm.chainId(10)` cambia `block.chainid`, y `vm.snapshotState()` y
  `vm.revertToState(id)` deshacen un despliegue para repetirlo "en la otra cadena".
- Un `foundry.toml` con `[rpc_endpoints]` para cada red y los scripts sin direcciones escritas
  dentro (`vm.envAddress`) despliegan lo mismo en todas.

## ✅ Checklist

- [ ] Sé qué cambia entre L1 y una L2 del OP Stack o Arbitrum.
- [ ] Sé desplegar con la misma dirección en dos cadenas y comprobarlo en `broadcast/`.
- [ ] Sé por qué una firma EIP-712 tiene que llevar el chain id actual.
- [ ] Sé leer el feed de disponibilidad del secuenciador y aplicar el plazo de gracia.
- [ ] Sé por qué `block.number` no sirve de reloj en una L2.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — Rollups](01-rollups.md) | **Teoría 02 — Desplegar en una L2** | [Teoría 03 — Puentes →](03-puentes.md) |
