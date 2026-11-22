# Teoría 04 — Transacciones

## 🎯 Objetivos

- Explicar qué es una transacción y nombrar sus campos.
- Seguir el ciclo de vida de una transacción: construir, firmar, enviar, minar, recibo.
- Firmar una transacción sin enviarla, decodificarla y publicarla con `cast`.
- Calcular el hash de una transacción antes de enviarla.
- Leer una transacción y su recibo, y distinguir uno de otro.

---

## 1. Qué problema resuelve una transacción

El estado de Ethereum (Teoría 02) solo cambia de una forma: con una **transacción**, una
petición firmada por una cuenta externa que dice "cambia el estado así". La firma
(semana 01) demuestra que la pidió el dueño de la clave; el resto de la red la valida y,
si es correcta, la aplica.

Una transferencia de ETH, la creación de un contrato y la llamada a una función de un
contrato son transacciones. Esta semana trabajas con la más simple: mover ETH de una cuenta
a otra.

## 2. Los campos de una transacción

El tipo actual es el **tipo 2** (definido en el [EIP-1559](https://eips.ethereum.org/EIPS/eip-1559);
un **EIP**, *Ethereum Improvement Proposal*, es un documento que propone un cambio a
Ethereum). Sus campos:

| Campo | Qué es | Teoría |
| ----- | ------ | ------ |
| `chainId` | La red para la que vale (`31337` en anvil) | 05 |
| `nonce` | Número de orden de la transacción dentro de la cuenta que la envía | 05 |
| `maxPriorityFeePerGas` | Propina máxima por unidad de gas, en wei | 06 |
| `maxFeePerGas` | Precio máximo total por unidad de gas, en wei | 06 |
| `gas` (*gas limit*) | Gas máximo que puede consumir | 06 |
| `to` | Dirección de destino. Vacía si crea un contrato | 07 |
| `value` | Cuánto ETH envía, en wei | 02 |
| `input` (*data*) | Bytes extra: la llamada a un contrato. `0x` en una transferencia | 07 |
| `accessList` | Lista opcional de direcciones que va a tocar; aquí siempre vacía | — |
| `r`, `s`, `yParity` | La firma (semana 01) | — |

No hay campo `from`. Quien envía se **recupera de la firma**: nadie puede enviar una
transacción en nombre de otra cuenta sin su clave.

## 3. Ciclo de vida

![Ciclo de vida de una transacción: la cuenta construye los campos, los firma con su clave privada, envía los bytes firmados al nodo con eth_sendRawTransaction, el nodo la valida y la deja en el mempool, quien construye el bloque la incluye y se genera un recibo con status, gasUsed y effectiveGasPrice](../0-assets/03-ciclo-de-vida-transaccion.svg)

1. **Construir**: rellenar los campos.
2. **Firmar**: con la clave privada, sobre los campos codificados. El resultado es la
   **transacción en bruto** (*raw transaction*): unos bytes que contienen campos y firma.
3. **Enviar**: se mandan esos bytes a un nodo con el método `eth_sendRawTransaction`.
4. **Mempool**: el nodo comprueba firma, nonce y saldo, y la guarda en su **mempool**
   (*memory pool*, la sala de espera de transacciones válidas aún no incluidas en un
   bloque). La reenvía a otros nodos.
5. **Incluir**: quien construye el siguiente bloque elige transacciones del mempool y las
   ejecuta en orden.
6. **Recibo**: cada transacción incluida produce un **recibo** (*receipt*) con el resultado.

anvil hace los pasos 4 y 5 al instante: mina un bloque con tu transacción en cuanto llega.

## 4. Firmar sin enviar

Separar los pasos ayuda a ver qué ocurre en cada uno. `cast mktx` construye y firma, sin
tocar la red.

**Dónde**: en el contenedor, con anvil recién arrancado (`anvil --silent &`).

```bash
cast mktx --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 --value 1ether \
  --nonce 0 --gas-limit 21000 --gas-price 2gwei --priority-gas-price 1gwei --chain 31337
```

Salida, la transacción en bruto:

```
0x02f874827a6980843b9aca0084773594008252089470997970c51812dc3a010c7d01b50e0d17dc79c8880de0b6b3a764000080c080a074128fd7d42631897474d93692787a2e56b813754468caaca4993c641c986a37a06d5a3b027177cc2841199b70400fece0a29ac5eabee2fa9cbf9b6aa213716c48
```

El primer byte, `02`, es el tipo. Dentro reconoces `7a69` (31337), la dirección de destino
y `0de0b6b3a7640000` (10¹⁸, 1 ether). Todos los campos van fijos para que la firma salga
siempre igual: con `--nonce`, `--gas-limit` y los precios, `cast` no pregunta nada al nodo.

`cast decode-transaction` la abre:

```bash
cast decode-transaction 0x02f874827a69...716c48   # pega la transacción entera
```

```json
{
  "signer": "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
  "type": "0x2",
  "chainId": "0x7a69",
  "nonce": "0x0",
  "gas": "0x5208",
  "maxFeePerGas": "0x77359400",
  "maxPriorityFeePerGas": "0x3b9aca00",
  "to": "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
  "value": "0xde0b6b3a7640000",
  "accessList": [],
  "input": "0x",
  "r": "0x74128fd7d42631897474d93692787a2e56b813754468caaca4993c641c986a37",
  "s": "0x6d5a3b027177cc2841199b70400fece0a29ac5eabee2fa9cbf9b6aa213716c48",
  "yParity": "0x0",
  "v": "0x0",
  "hash": "0x7d4c13ed95c0cee830d7457ec5a5976db1fc301cfa7a23fef0039a7ccf6aea87"
}
```

`signer` no está en los bytes: `cast` lo **recupera de la firma**, igual que hará el nodo.

## 5. El hash de una transacción

El **hash de la transacción** es su identificador: el keccak256 de la transacción en bruto.
Se conoce **antes** de enviarla:

```bash
cast keccak 0x02f874827a69...716c48   # la misma transacción en bruto
```

```
0x7d4c13ed95c0cee830d7457ec5a5976db1fc301cfa7a23fef0039a7ccf6aea87
```

Coincide con el campo `hash` de arriba. Con ese hash buscas la transacción en cualquier
nodo o explorador de bloques.

## 6. Publicar y leer el recibo

`cast publish` envía la transacción en bruto (`eth_sendRawTransaction`) y espera al
recibo:

```bash
cast publish 0x02f874827a69...716c48 | jq -r .status
```

```
0x1
```

`status` `0x1` significa éxito; `0x0`, que la transacción se incluyó pero falló al
ejecutarse (lo verás con contratos en la semana 05).

Lo habitual es hacerlo todo de una vez con `cast send`: pregunta al nodo el nonce y los
precios, construye, firma, envía y espera. Para ver la misma salida que aquí, reinicia
antes anvil (`kill %1` y `anvil --silent &`): la cuenta 0 vuelve a tener nonce 0.

```bash
cast send --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  0x70997970C51812dc3A010C7d01b50e0d17dc79C8 --value 1ether
```

Imprime el recibo. Las líneas que importan esta semana (en anvil recién arrancado):

```
blockNumber          1
effectiveGasPrice    1000000001
from                 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
gasUsed              21000
status               1 (success)
transactionHash      0xce09985d94caad02fc26f64a68a95d3ae7ec58fa0ef5208c672d4f42052488dc
type                 2
to                   0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

El `blockHash` cambia en cada arranque de anvil (depende de la hora del bloque); el
`transactionHash` no, porque solo depende de los campos y la firma.

## 7. Transacción y recibo no son lo mismo

| | Transacción (`cast tx HASH`) | Recibo (`cast receipt HASH`) |
| - | ---------------------------- | ---------------------------- |
| Qué es | Lo que se **pidió** | Lo que **pasó** al ejecutarla |
| Existe | Desde que se envía | Solo cuando se incluye en un bloque |
| Campos clave | `nonce`, `to`, `value`, `gas`, `maxFeePerGas` | `status`, `gasUsed`, `effectiveGasPrice`, `blockNumber` |

Un campo suelto se pide por su nombre:

```bash
H=0xce09985d94caad02fc26f64a68a95d3ae7ec58fa0ef5208c672d4f42052488dc
cast tx "$H" nonce
cast receipt "$H" gasUsed
cast receipt "$H" status
```

```
0
21000
true
```

Con `--json`, `cast send` y `cast publish` imprimen el recibo en JSON: `jq -r .status` da
`0x1`, y `jq -r .transactionHash`, el hash.

## 8. Antipatrones y riesgos

- ❌ **Dar por hecho que una transacción enviada está hecha.** Hasta que hay recibo puede no
  incluirse nunca, y con recibo puede tener `status` 0. Comprueba siempre el recibo.
- ❌ **Firmar bytes que no entiendes.** Una transacción en bruto puede mover todo tu saldo.
  Decodifícala antes (`cast decode-transaction`). Las billeteras muestran los campos por
  este motivo.
- ❌ **Publicar la clave privada para "firmar en el servidor".** Quien tiene la clave firma
  lo que quiera. Desde la semana 16 las claves de testnet van en un keystore cifrado.
- ❌ **Creer que una transacción es privada.** Desde que llega al mempool, cualquiera la ve
  antes de que se mine. Semana 22.

## 9. Trucos

- `cast send --async` envía y devuelve el hash sin esperar al recibo.
- `cast decode-transaction RAW | jq -r .signer` comprueba quién firmó, sin enviar nada.
- Un explorador como [etherscan.io](https://etherscan.io) muestra cualquier transacción real
  de mainnet a partir de su hash.

## ✅ Checklist

- [ ] Nombro los campos de una transacción tipo 2 y sé por qué no hay `from`.
- [ ] Recorro el ciclo de vida: construir, firmar, enviar, mempool, bloque, recibo.
- [ ] Firmo sin enviar, decodifico y publico con `cast`.
- [ ] Calculo el hash de una transacción antes de enviarla.
- [ ] Distingo transacción de recibo y leo campos de cada uno.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — JSON-RPC](03-json-rpc.md) | **Teoría 04 — Transacciones** | [Teoría 05 — El nonce →](05-el-nonce.md) |
