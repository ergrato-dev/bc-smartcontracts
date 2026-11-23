# Teoría 02 — EIP-191 y replay

## 🎯 Objetivos

- Rehacer en Solidity el hash que firma `cast wallet sign` (o una wallet) con el prefijo
  EIP-191.
- Construir el mensaje de una orden firmada con `abi.encode`, no con `abi.encodePacked`.
- Reconocer las cuatro formas de replay y su defensa: marca de usado o nonce, dirección del
  contrato, `chainid` y plazo.

---

## 1. Qué problema resuelve

En la semana 01 firmaste texto con `cast wallet sign` y viste que no se firma el texto a
secas: se le antepone el prefijo de **EIP-191**, `"\x19Ethereum Signed Message:\n"` más la
longitud, para que una firma de mensaje nunca sirva como firma de transacción.

Un contrato que acepta firmas tiene que rehacer **exactamente** ese hash. Si se olvida el
prefijo, o pone otra longitud, `ecrecover` devuelve otra dirección (teoría 01) y la firma
correcta se rechaza. Y, una vez que acepta la firma correcta, tiene que impedir que se acepte
dos veces.

## 2. Cómo funciona

EIP-191 define el formato general de los datos firmados: `0x19 ‖ versión ‖ datos`. El byte
`0x19` no puede empezar una transacción válida. Hay tres versiones:

| Versión | Datos | Uso |
| ------- | ----- | --- |
| `0x45` (la `E` de `Ethereum`) | `"thereum Signed Message:\n" + longitud + mensaje` | `personal_sign`: lo que firma `cast wallet sign` y la opción "firmar mensaje" de una wallet |
| `0x01` | `domainSeparator ‖ structHash` | EIP-712, datos con estructura (teoría 03) |
| `0x00` | dirección del validador ‖ datos | Poco usada |

Para firmar una orden con la versión `0x45`, el patrón es:

1. Resumir la orden en 32 bytes: `hash = keccak256(abi.encode(campos...))`.
2. Firmar esos 32 bytes como mensaje. Lo que se firma de verdad es
   `keccak256("\x19Ethereum Signed Message:\n32" ‖ hash)`: la longitud siempre es `32`.
3. En el contrato, `MessageHashUtils.toEthSignedMessageHash(hash)` de OpenZeppelin rehace el
   paso 2, y `ECDSA.recover` saca el firmante.

## 3. Cómo se escribe

**Dónde**: dentro del contenedor, con la cuenta 0 de anvil. Primero, el hash de una orden
(aquí, de un texto cualquiera) y su firma:

```bash
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ADDR=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
HASH=$(cast keccak "cupon 1"); echo $HASH
SIG=$(cast wallet sign --private-key $PK $HASH); echo $SIG
cast wallet verify --address $ADDR $HASH $SIG
```

```
0x416761107181ad41390b969437d858288359f8c2c2d974189dbc7c12856e3849
0x392458201dbb2d9b3ae1c533ce370936516b792f4fb29db6684d15a2d2ccdca23374e8b2582b00011ca7c5329b91d3ebfbc2172f7a4a3dbd5f022cedd7497a5e1c
Validation succeeded. Address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 signed this message.
```

Como `HASH` empieza por `0x`, `cast wallet sign` lo decodifica y firma esos 32 bytes con el
prefijo `\n32`. El hash que firmó, a mano (`0a3332` son los bytes de `\n32`):

```bash
cast keccak $(cast concat-hex 0x19457468657265756d205369676e6564204d6573736167653a0a3332 $HASH)
```

```
0x5327765e60fc2e23b718f41eb74b91a999710189e3cccf355e055a14f513976c
```

Y en Solidity (en `test/Eip191.t.sol` del mismo proyecto, con `forge test -vv`):

```solidity
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

    function test_CastSignature() public pure {
        bytes32 hash = keccak256("cupon 1");
        bytes memory sig =
            hex"392458201dbb2d9b3ae1c533ce370936516b792f4fb29db6684d15a2d2ccdca23374e8b2582b00011ca7c5329b91d3ebfbc2172f7a4a3dbd5f022cedd7497a5e1c";
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(hash);
        console.logBytes32(digest);
        console.log(ECDSA.recover(digest, sig));
        console.log(ECDSA.recover(hash, sig));
    }
```

```
  0x5327765e60fc2e23b718f41eb74b91a999710189e3cccf355e055a14f513976c
  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
  0x242EF89b1e99A2d00AAE89c2D2C6f56c8222EaDD
```

El mismo hash que a mano, y la cuenta 0. La última línea es el error típico: recuperar sobre
el hash **sin** prefijo da una dirección de nadie.

> ⚠️ `cast hash-message $HASH` **no** da `0x5327…`: toma `0x4167…` como texto de 66
> caracteres, no como 32 bytes. Para el hash de una orden, usa el `cast concat-hex` de arriba.

### Por qué `abi.encode` y no `abi.encodePacked`

`abi.encodePacked` pega los valores sin separarlos ni rellenarlos (semana 10). Con dos campos
de longitud variable, órdenes distintas dan los mismos bytes: `("ab", "c")` y `("a", "bc")`
producen `"abc"`, el mismo hash y la misma firma. `abi.encode` da a cada campo su sitio y
su longitud. En un mensaje que se firma, siempre `abi.encode`.

## 4. Replay: cuatro formas y sus defensas

Una firma válida es pública en cuanto se envía. El **replay** es usarla otra vez donde quien
firmó no quería. Cada forma se cierra metiendo algo en el hash firmado o guardando algo en
el contrato:

| Replay | Ejemplo | Defensa |
| ------ | ------- | ------- |
| En el mismo contrato | Canjear dos veces el mismo cupón | Marcar el hash como usado (`used[hash] = true`) o un **nonce** por cuenta que sube con cada orden |
| En otro contrato | El mismo cupón en una segunda tienda del mismo emisor | Meter `address(this)` en el hash |
| En otra red | La orden de testnet, enviada en mainnet o en una L2 | Meter `block.chainid` en el hash |
| Fuera de tiempo | Una orden de hace un año, que el firmante olvidó | Un plazo (`deadline`) en el hash y `block.timestamp <= deadline` |

Un **nonce** aquí es lo mismo que el de las transacciones (semana 02): un contador por cuenta
que solo vale una vez. `Nonces` de OpenZeppelin lo da hecho: `nonces(cuenta)` lo lee y
`_useNonce(cuenta)` devuelve el actual y lo sube. La diferencia con `used[hash]`: con nonces
las órdenes de una cuenta van en orden (la 1 no vale hasta que se use la 0), y la cuenta
puede **anular** una orden firmada gastando su nonce sin usarla (ejercicio 02).

En el ejercicio 01 escribes un hash con las cuatro piezas:

```solidity
keccak256(abi.encode(address(this), block.chainid, to, amount, id));
```

## 5. Antipatrones y riesgos

- ❌ **Firmar o aceptar hashes en crudo.** `cast wallet sign --no-hash` firma 32 bytes sin
  prefijo, lo mismo que hacía el antiguo `eth_sign` de las wallets, que hoy lo bloquean: un
  hash en crudo puede ser el de una transacción, y quien firma no ve qué autoriza. Un
  contrato que espera firmas sin prefijo empuja a sus usuarios a firmar a ciegas.
- ❌ **Olvidar una pieza del replay.** Cada fila de la tabla es un ataque real: tiendas que
  aceptaban cupones de otra tienda, órdenes de testnet válidas en mainnet, permisos sin plazo
  usados años después.
- ❌ **Marcar como usado después de una llamada externa.** Si el contrato paga antes de
  apuntar `used[hash] = true`, una reentrada (semana 10) canjea otra vez. Primero se marca,
  después se paga.
- ❌ **Confiar en la firma para el destino.** Si la orden no incluye a quién va el beneficio
  (`to`), el relayer elige: firma "50 puntos" y el relayer pone su propia dirección.
- ❌ **Mensajes que nadie puede leer.** Con EIP-191 la wallet muestra 32 bytes en hexadecimal:
  el usuario firma sin saber qué. EIP-712 (teoría 03) existe para eso.

## 6. Trucos

- Calcula el hash de la orden con una función `view` del propio contrato (`couponHash`):
  quien firma la llama con `cast call` y firma exactamente lo que el contrato rehará.
- Para depurar una firma que no pasa, imprime en el test el hash que rehace el contrato y
  compáralo con el que firmaste. Si difieren, el fallo está en el hash, no en la firma.

## ✅ Checklist

- [ ] Rehago con `toEthSignedMessageHash` el hash que firma `cast wallet sign`.
- [ ] Explico por qué un mensaje firmado se codifica con `abi.encode`.
- [ ] Nombro las cuatro formas de replay y la defensa de cada una.
- [ ] Explico la diferencia entre marcar hashes usados y usar nonces.
- [ ] Sé por qué `cast hash-message` no sirve para el hash de una orden.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — ECDSA y ecrecover](01-ecdsa-y-ecrecover.md) | **Teoría 02 — EIP-191 y replay** | [Teoría 03 — EIP-712, datos tipados →](03-eip712-datos-tipados.md) |
