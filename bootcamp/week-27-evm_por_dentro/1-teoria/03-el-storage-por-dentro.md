# Teoría 03 — El storage por dentro

## 🎯 Objetivos

- Calcular el slot de cualquier dato de un contrato: variables empaquetadas, mappings, mappings
  anidados, arrays dinámicos, strings y structs.
- Leer esos slots desde fuera con `cast storage` y `cast index`, y desde un test con `vm.load`.
- Reconocer los espacios de nombres ERC-7201 en `forge inspect ... storageLayout`.
- Explicar el precio de `SLOAD` y `SSTORE`: slots fríos y calientes, crear, cambiar y borrar.
- Usar el *transient storage*, que solo dura una transacción, y conocer sus riesgos.

## Qué problema resuelve

En la semana 04 viste que cada variable de estado ocupa un **slot** (una posición de 32 bytes del
**storage**, el almacén permanente de cada contrato) y que las pequeñas se empaquetan. En la 06,
que un mapping guarda sus valores "en una posición calculada con keccak256". En la 15, que un proxy
y su implementación comparten el storage y que reordenar variables lo rompe.

Falta la fórmula. Sin ella no puedes leer el saldo de una cuenta en un mapping sin getter,
comprobar que una actualización deja cada dato en su sitio ni entender por qué una función gasta
20 000 de gas en una línea. Esta teoría te da la fórmula de cada tipo y el precio de cada acceso.

## Cómo funciona: slots fijos y slots calculados

El storage de un contrato es un mapa de 2²⁵⁶ slots, todos a cero hasta que alguien escribe. solc
reparte las variables así:

- **Tipos de tamaño fijo** (`uint`, `address`, `bool`, `bytesN`, structs y arrays de tamaño fijo):
  slots consecutivos desde el 0, en el orden en que se declaran. Las que caben juntas en 32 bytes
  comparten slot, alineadas a la **derecha**: la primera ocupa los bytes bajos.
- **Tipos dinámicos** (mappings, arrays dinámicos, `bytes` y `string`): ocupan un slot fijo,
  pero sus datos van a slots calculados con keccak256 a partir de él.

![Cómo se calculan los slots. Un mapping en el slot p guarda el valor de la clave k en keccak256(k . p): el slot p queda vacío. Un mapping anidado repite el cálculo con el slot del primero como semilla. Un array dinámico en el slot p guarda ahí su longitud y sus elementos a partir de keccak256(p), uno por slot. Un string corto, de hasta 31 bytes, va entero en su slot con la longitud por dos en el último byte; uno largo guarda en el slot la longitud por dos más uno y sus datos a partir de keccak256(p).](../0-assets/03-slots-calculados.svg)

| Tipo en el slot `p` | Dónde van los datos |
| ------------------- | ------------------- |
| `mapping(K => V)` | El valor de la clave `k`, en `keccak256(abi.encode(k, p))`. El slot `p` queda vacío |
| `mapping(K1 => mapping(K2 => V))` | `keccak256(abi.encode(k2, keccak256(abi.encode(k1, p))))` |
| `T[]` | En `p`, la longitud. El elemento `i`, en `keccak256(abi.encode(p)) + i` (si `T` ocupa 32 bytes) |
| `string`, `bytes` cortos (≤ 31 bytes) | En `p`: los bytes desde la izquierda y `longitud · 2` en el último byte |
| `string`, `bytes` largos | En `p`: `longitud · 2 + 1`. Los datos, desde `keccak256(abi.encode(p))` |
| `struct` | Sus campos, en slots seguidos desde el suyo, empaquetados como variables sueltas |

El último bit de un string dice cuál de las dos formas es: par, corto; impar, largo.

## Cómo se lee: `cast storage` y `cast index`

Con este contrato, el del ejercicio 02:

```solidity
uint128 public totalPaid;
uint64 public lastPayment;
bool public open;
address public owner;
mapping(address => uint256) public balanceOf;
mapping(address => mapping(uint256 => bool)) public usedNonce;
uint256[] public payments;
string public name;
```

`forge inspect Club storageLayout` da la tabla de slots:

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
```

Desplegado en anvil, con dos pagos de 1 ETH de la cuenta 0 (`pay(7)` y `pay(8)`) y el nombre
"Club de ajedrez", el slot 0:

```bash
cast storage $C 0
```

```text
0x0000000000000001000000006b051aac00000000000000001bc16d674ec80000
```

Se lee de derecha a izquierda: los 16 bytes bajos, `1bc16d674ec80000`, son `totalPaid`, 2 ETH en
wei; los 8 siguientes, `6b051aac`, `lastPayment`, la hora del bloque; el siguiente, `01`, es `open`.

`cast index <tipo> <clave> <slot>` calcula el slot de una clave de mapping. El saldo de la cuenta 0:

```bash
A=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
cast index address $A 2
cast storage $C $(cast index address $A 2) | cast to-dec
```

```text
0xbc40fbf4394cd00f78fae9763b0c2c71b21ea442c42fdadc5b720537240ebac1
2000000000000000000
```

Para el anidado, el resultado de uno es el slot del siguiente:

```bash
cast storage $C $(cast index uint256 7 $(cast index address $A 3))
```

```text
0x0000000000000000000000000000000000000000000000000000000000000001
```

El array guarda su longitud, 2, en el slot 4, y sus elementos desde el keccak256 del número 4
escrito como palabra:

```bash
cast keccak 0x0000000000000000000000000000000000000000000000000000000000000004
```

```text
0x8a35acfbc15ff81a39ae7d344fd709f28e8600b4aa8c65c6b64bfe7fe36bd19b
```

El segundo pago está en el slot siguiente, `...bd19c`. Y el nombre, corto:

```bash
cast storage $C 5
```

```text
0x436c756220646520616a656472657a000000000000000000000000000000001e
```

`436c...7a` es "Club de ajedrez" en UTF-8, y `0x1e` (30) es su longitud, 15, por 2.

En un test, `vm.load(contrato, bytes32(slot))` hace lo mismo que `cast storage`, y la fórmula se
escribe con `keccak256(abi.encode(...))`. Es el ejercicio 02.

## Espacios de nombres: ERC-7201

Las bases *upgradeable* de OpenZeppelin 5 no usan los slots 0, 1, 2...: cada una guarda su struct
en un slot calculado a partir de un nombre, con la fórmula de **ERC-7201** (semana 15):

```text
keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControl")) - 1)) & ~bytes32(uint256(0xff))
```

Así el orden de herencia no mueve nada y tus variables pueden empezar en el slot 0. `forge
inspect` lista esos slots con el resto, en decimal. En el registro del proyecto:

```text
11 0 maxPriceAge
1295953201772911215391058989745868821651057887752387839782086074958115661824 0 openzeppelin.storage.AccessControl._roles
92891662540554778686986514950364265630913525426840345632122912437671245656832 0 openzeppelin.storage.Pausable._paused
```

## El precio de cada acceso

El storage es caro porque cada nodo de la red lo guarda para siempre. Desde **EIP-2929**, el
precio depende además de si el slot ya se tocó en la transacción: el primer acceso es **frío**
(*cold*) y los siguientes, **calientes** (*warm*). Con anvil en `--steps-tracing`, la traza del
primer `pay` del club:

```bash
cast rpc debug_traceTransaction $TX \
  | jq -r '.structLogs[] | select(.op=="SLOAD" or .op=="SSTORE") | "\(.op) \(.gasCost) key=\(.stack[-1])"'
```

```text
SLOAD 2100 key=0x0
SLOAD 2100 key=0xd1918bb415d076db332835da34c87072d357b01ca04776307549c3a3ce348d98
SLOAD 100 key=0xd1918bb415d076db332835da34c87072d357b01ca04776307549c3a3ce348d98
SSTORE 20000 key=0xd1918bb415d076db332835da34c87072d357b01ca04776307549c3a3ce348d98
SLOAD 2100 key=0xbc40fbf4394cd00f78fae9763b0c2c71b21ea442c42fdadc5b720537240ebac1
SSTORE 20000 key=0xbc40fbf4394cd00f78fae9763b0c2c71b21ea442c42fdadc5b720537240ebac1
SLOAD 100 key=0x0
SLOAD 100 key=0x0
SSTORE 2900 key=0x0
SLOAD 100 key=0x0
SSTORE 100 key=0x0
SLOAD 2100 key=0x4
SSTORE 20000 key=0x4
SSTORE 22100 key=0x8a35acfbc15ff81a39ae7d344fd709f28e8600b4aa8c65c6b64bfe7fe36bd19b
```

| Acceso | Gas | En la traza |
| ------ | --- | ----------- |
| `SLOAD` frío | 2100 | Primera lectura de cada slot |
| `SLOAD` caliente | 100 | El slot 0 por segunda vez |
| `SSTORE` de 0 a otro valor | 20 000 | El nonce usado, el saldo y la longitud del array |
| `SSTORE` de un valor a otro | 2900 | `totalPaid`, en el slot 0 |
| `SSTORE` en un slot que ya cambió en esta transacción | 100 | `lastPayment`: el slot 0 ya lo había cambiado `totalPaid` |
| `SSTORE` frío | + 2100 | El elemento del array: se escribe sin leerlo antes, 20 000 + 2100 |

Borrar (poner a cero un valor que no lo era) cuesta 2900, o 5000 en frío, pero devuelve 4800 de
**reembolso** (*refund*) al acabar la transacción. Desde **EIP-3529**, el reembolso no pasa de un
quinto del gas usado. En un contrato que pone a cero un slot frío, la traza da `SSTORE 5000` y,
al final, `refund 4800`.

## Transient storage

**EIP-1153** añadió una zona como el storage, con sus propios slots, que se borra al acabar cada
transacción: el **transient storage**. `TLOAD` y `TSTORE` cuestan siempre 100. Solidity la usa
para variables de tipo de valor marcadas `transient`:

```solidity
contract Lock {
    uint256 public value = 1;
    bool transient locked;

    error Reentered();

    function clear() external {
        if (locked) revert Reentered();
        locked = true;
        value = 0;
        locked = false;
    }
}
```

`locked` no aparece en `forge inspect Lock storageLayout`, sino en `transientStorageLayout`:

```text
| Name   | Type | Slot | Offset | Bytes | Contract          |
| locked | bool | 0    | 0      | 1     | src/Lock.sol:Lock |
```

Ocupa el slot 0, igual que `value`, sin chocar: son zonas distintas. Es el cerrojo de reentrancy
de la semana 21 sin pagar 20 000 por escribirlo: OpenZeppelin lo da hecho en
`ReentrancyGuardTransient`.

## ⚠️ Antipatrones y riesgos

- **`private` no es secreto.** `cast storage` lee cualquier slot de cualquier contrato. Una clave,
  una respuesta o una semilla en storage es pública desde que se escribe.
- **Mover el storage de un proxy.** Insertar una variable antes de otras, cambiar un tipo o
  reordenar los campos de un struct deja cada dato en el slot de otro. Ningún test de
  comportamiento lo ve si despliega un proxy nuevo; solo lo ve un test que lee los slots del proxy
  ya usado. Es el proyecto de esta semana.
- **El transient storage dura toda la transacción, no la llamada.** Si un contrato deja un valor
  transitorio sin limpiar, la siguiente llamada de la misma transacción (un `multicall`, un lote)
  lo encuentra. Limpia siempre al terminar, como `locked = false`.
- **Empaquetar no siempre ahorra.** Escribir un `uint64` dentro de un slot compartido es leer el
  slot, cambiar sus bytes y escribirlo entero. Ahorra cuando los campos se leen y escriben juntos;
  la semana 29 lo mide.

## 💡 Trucos

- `cast storage <dirección> <slot>` lee un slot; `cast index <tipo> <clave> <slot>` calcula el de
  un mapping.
- `forge inspect <Contrato> storageLayout` para el storage y `transientStorageLayout` para el
  transitorio. Con `--json`, para procesarlo con `jq`.
- En los tests, `vm.load` lee un slot y `vm.store` lo escribe: útil para preparar un estado
  difícil de alcanzar, nunca para tapar un fallo.

## ✅ Checklist

- [ ] Sé calcular el slot de una variable empaquetada, una clave de mapping, un mapping anidado,
  un elemento de array y un string corto o largo.
- [ ] Sé leer esos slots con `cast storage`, `cast index` y `vm.load`.
- [ ] Sé qué es un espacio de nombres ERC-7201 y por qué las bases de OpenZeppelin lo usan.
- [ ] Sé cuánto cuesta un `SLOAD` frío y uno caliente, y un `SSTORE` que crea, cambia o borra.
- [ ] Sé cuándo usar `transient` y por qué hay que limpiarlo.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — La memoria](02-la-memoria.md) | **Teoría 03 — El storage por dentro** | [Teoría 04 — Calldata y returndata →](04-calldata-y-returndata.md) |
