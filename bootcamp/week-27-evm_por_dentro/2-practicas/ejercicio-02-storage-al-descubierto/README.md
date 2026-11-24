# Ejercicio 02 — Storage al descubierto

> Al terminar sabrás encontrar cualquier dato de un contrato en su storage sin usar su getter:
> variables empaquetadas, mappings, mappings anidados, arrays, strings cortos y largos, structs y
> una variable `private`.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 03 — El storage por dentro](../../1-teoria/03-el-storage-por-dentro.md)
leída y el [ejercicio 01](../ejercicio-01-bytecode-a-mano/README.md) en verde.

## Contexto

Proyecto Foundry. `Club` es un club con cuotas: cada socio paga con un nonce que no se repite, y
el club apunta saldos, pagos, socios y un secreto.

| Archivo | Qué es |
| ------- | ------ |
| `src/Club.sol` | El contrato. No lo cambies |
| `test/Storage.t.sol` | Los tests, ya escritos, y los ayudantes `_...` que calculan slots: tu trabajo, pasos 1 a 6 |

Cada test lee un dato dos veces: con el getter de `Club` y con tu ayudante, que usa `_word(slot)`
(un `vm.load` del slot) y la fórmula de la teoría 03. Si las dos lecturas coinciden, tu fórmula
es la buena.

El `setUp` deja este estado: Alice paga 1 ETH con el nonce 7; diez minutos después, Bob paga
0,25 ETH con el nonce 7; y Alice paga 2 ETH con el nonce 8.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-27-evm_por_dentro/2-practicas/ejercicio-02-storage-al-descubierto/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 passed; 6 failed`, cada uno con su `TODO: Paso N`.

Antes de escribir nada, saca el mapa de slots:

```bash
forge inspect Club storageLayout
```

```text
| Name        | Type                                         | Slot | Offset | Bytes | Contract          |
| totalPaid   | uint128                                      | 0    | 0      | 16    | src/Club.sol:Club |
| lastPayment | uint64                                       | 0    | 16     | 8     | src/Club.sol:Club |
| open        | bool                                         | 0    | 24     | 1     | src/Club.sol:Club |
| owner       | address                                      | 1    | 0      | 20    | src/Club.sol:Club |
| balanceOf   | mapping(address => uint256)                  | 2    | 0      | 32    | src/Club.sol:Club |
| usedNonce   | mapping(address => mapping(uint256 => bool)) | 3    | 0      | 32    | src/Club.sol:Club |
| payments    | uint256[]                                    | 4    | 0      | 32    | src/Club.sol:Club |
| name        | string                                       | 5    | 0      | 32    | src/Club.sol:Club |
| members     | mapping(uint256 => struct Club.Member)       | 6    | 0      | 32    | src/Club.sol:Club |
| secret      | bytes32                                      | 7    | 0      | 32    | src/Club.sol:Club |
```

Es un extracto: la salida real lleva bordes y separadores entre filas. Las columnas que importan
son las tres numéricas: slot, offset (en bytes, desde la derecha) y tamaño en bytes.

## Paso 1: El slot empaquetado

**Por qué**: `totalPaid`, `lastPayment` y `open` suman 16 + 8 + 1 bytes y comparten el slot 0. Para
sacar cada una, desplazas la palabra a la derecha tantos bits como su offset (`offset · 8`) y te
quedas con sus bytes. Convertir a un tipo más pequeño corta los bytes altos: `uint128(word)` son
los 16 bytes bajos.

```solidity
uint256 word = uint256(_word(0));
totalPaid = uint128(word);
lastPayment = uint64(word >> 128);
open = (word >> 192) & 0xff == 1;
```

**Abre** `test/Storage.t.sol`, borra el `revert` de `_slot0` y descomenta sus líneas. Ejecuta
`forge test`.

**Verifica**: `1 passed; 5 failed`. `test_Paso1_PackedSlot` comprueba los tres valores y, de paso,
`owner` en los 20 bytes bajos del slot 1.

## Paso 2: Una clave de mapping

**Por qué**: el saldo de `who` está en `keccak256(abi.encode(who, 2))`: la clave y el slot del
mapping, cada uno en una palabra. Es lo que calcula `cast index address <who> 2`.

**Abre** `test/Storage.t.sol` y resuelve `_balanceSlot`.

**Verifica**: `2 passed; 4 failed`. El test comprueba también que el slot 2 está vacío: el mapping
no guarda nada en su slot, solo lo usa como semilla.

## Paso 3: Un mapping anidado

**Por qué**: `usedNonce[who]` es a su vez un mapping. Su "valor" no se guarda en ningún sitio,
pero su slot, `keccak256(abi.encode(who, 3))`, es la semilla del segundo hash.

**Abre** `test/Storage.t.sol` y resuelve `_usedNonceSlot`.

**Verifica**: `3 passed; 3 failed`. Alice usó los nonces 7 y 8; Bob, solo el 7. Un `bool` verdadero
es la palabra `1`.

## Paso 4: Un array dinámico

**Por qué**: el slot 4 guarda la longitud de `payments`. Los elementos van seguidos a partir de
`keccak256(abi.encode(4))`, uno por slot porque cada `uint256` ocupa 32 bytes.

**Abre** `test/Storage.t.sol` y resuelve `_paymentSlot`.

**Verifica**: `4 passed; 2 failed`. Tres pagos: 1, 0,25 y 2 ETH. El slot del cuarto está a cero.

## Paso 5: Un string corto y uno largo

**Por qué**: "Club de ajedrez" tiene 15 bytes: cabe en el slot 5 con su longitud por 2 en el
último byte. El nombre nuevo del test tiene 50: el slot guarda `50 · 2 + 1 = 101` y los datos van
desde `keccak256(abi.encode(5))`, en dos slots. El último bit de la palabra dice qué forma es.

Tu ayudante lee los dos casos. En el largo, el byte `i` está en el slot `datos + i / 32`, en la
posición `i % 32` de esa palabra (`bytes32` se indexa desde la izquierda).

**Abre** `test/Storage.t.sol` y resuelve `_name`.

**Verifica**: `5 passed; 1 failed`. `test_Paso5_ShortAndLongString` lee el nombre corto, lo
cambia por el largo y vuelve a leerlo.

## Paso 6: Un struct y una variable `private`

**Por qué**: un `Member` ocupa dos slots desde `keccak256(abi.encode(id, 6))`. En el primero van
`account` (20 bytes) y `points` (12 bytes), empaquetados como si fueran variables sueltas; en el
segundo, `since`. Y `secret` es `private`: no tiene getter, pero está en el slot 7 como cualquier
otra variable.

**Abre** `test/Storage.t.sol` y resuelve `_member` y `_secret`.

**Verifica**: `6 passed; 0 failed`. `_secret()` devuelve `keccak256("la clave del club")`, el
"secreto" que pasó el constructor.

## Para pensar

- Si `Club` estuviera detrás de un proxy y una versión nueva añadiera `uint256 fee;` justo después
  de `owner`, ¿en qué slot leería `balanceOf` sus datos? ¿Qué test de este ejercicio fallaría?
- `points` es un `uint96` empaquetado con `account`. ¿Cuántos `SSTORE` hace `join`? Compruébalo con
  una traza de anvil, como en la teoría 03.
- El constructor recibió el secreto en la calldata de la transacción de despliegue. Aunque no
  estuviera en storage, ¿seguiría siendo secreto?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Bytecode a mano](../ejercicio-01-bytecode-a-mano/README.md) | **Ejercicio 02 — Storage al descubierto** | [Ejercicio 03 — Calldata y memoria →](../ejercicio-03-calldata-y-memoria/README.md) |
