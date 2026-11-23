# Ejercicio 02 — Votos con EIP-712

> Al terminar tendrás una votación en la que se vota firmando: el votante firma un `Vote`
> con sus campos legibles, otra cuenta lo envía y paga el gas, y el votante puede anular un
> voto firmado antes de que nadie lo envíe. En anvil firmarás el voto desde un JSON con
> `cast`.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 03](../../1-teoria/03-eip712-datos-tipados.md) leída y el
[ejercicio 01](../ejercicio-01-cupones-firmados/README.md) terminado.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Poll.sol` | La votación: hereda de `EIP712` y `Nonces`, con `VOTE_TYPEHASH`, `voteDigest`, `voteBySig`, `cancelNonce` y `_vote`. Aquí trabajas |
| `test/Poll.t.sol` | Los tests de cada paso. No lo modifiques |

`_vote` ya está escrita: comprueba la opción, que nadie vote dos veces, cuenta el voto y
emite `Voted`. El test `_expectedDigest` monta el digest **a mano**, campo a campo, sin la
librería: si tu `voteDigest` no sigue EIP-712, no coinciden.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-14-firmas_eip712_y_permit/2-practicas/ejercicio-02-votos-con-eip712/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5667)` y `(2018)`.

**Verifica**: `1 tests passed, 12 failed, 0 skipped (13 total tests)`. Pasa
`test_Inherited_DomainIsReadable`: el constructor `EIP712("Poll", "1")` ya fija el dominio, y
`eip712Domain()` lo devuelve.

## Paso 1: El digest

**Por qué**: el digest es lo que firma la wallet. Primero el struct hash: el typehash y cada
campo en su orden, con el `string` como su keccak256. Después `_hashTypedDataV4` le pega
`0x19 0x01` y el domain separator (teoría 03).

**Abre** `src/Poll.sol` y, en `voteDigest`, borra el `revert` y descomenta:

```solidity
bytes32 structHash =
    keccak256(abi.encode(VOTE_TYPEHASH, voter, option, keccak256(bytes(comment)), nonce, deadline));
return _hashTypedDataV4(structHash);
```

**Verifica**: `3 tests passed, 10 failed`. `test_Step1_DigestFollowsEip712` compara con el
digest montado a mano; `test_Step1_DigestDependsOnEveryField` cambia los campos uno a uno.
Prueba a quitar el `keccak256(bytes(...))` del comentario: el primero falla.

## Paso 2: Votar con firma

**Por qué**: cuatro comprobaciones antes de contar el voto. El plazo, primero, porque es la
más barata. Después el digest con `_useNonce(voter)`, que devuelve el nonce actual y lo sube:
rehace el hash y, a la vez, gasta el nonce. Si la firma es de otro, o de otro voto, o de un
nonce ya gastado, `ECDSA.recover` devuelve una dirección que no es `voter`.

En `voteBySig`, borra el `revert` y descomenta:

```solidity
if (block.timestamp > deadline) revert ExpiredSignature(deadline);
bytes32 digest = voteDigest(voter, option, comment, _useNonce(voter), deadline);
address signer = ECDSA.recover(digest, signature);
if (signer != voter) revert InvalidSigner(signer, voter);
_vote(voter, option, comment);
```

**Verifica**: `10 tests passed, 3 failed`. Tres de los que pasan:

- `test_Step2_RelayerSendsTheVote`: envía `relayer`, el voto cuenta para `voter`, y
  `nonces(voter)` pasa de 0 a 1.
- `test_Step2_RevertWhen_RelayerChangesTheOption`: el relayer no puede cambiar el voto; con
  otra opción, otro hash.
- `test_Step2_RevertWhen_SentToOtherPoll`: la firma no vale en otra votación, aunque nadie
  haya escrito `address(this)` en el struct: lo pone el dominio.

## Paso 3: Anular un voto firmado

**Por qué**: el votante firmó y dio la firma a un relayer, pero cambia de idea antes de que se
envíe. Como la firma lleva su nonce, basta con gastar el nonce: la firma queda inútil para
siempre. Solo puede gastar el nonce de `msg.sender`, nunca el de otro.

En `cancelNonce`, borra el `revert` y descomenta:

```solidity
_useNonce(msg.sender);
```

**Verifica**:

```bash
forge test --deny warnings
```

`13 tests passed, 0 failed, 0 skipped (13 total tests)`, sin warnings.
`test_Step3_NewSignatureWorksAfterCancel`: tras anular, una firma nueva con el nonce 1 vale.

## Paso 4: En anvil

**Por qué**: firmar un `Vote` como lo haría una wallet, desde un JSON de datos tipados, y ver
que el contrato rehace el mismo digest.

Este paso no tiene código. Despliega con la cuenta 0 y lee el dominio:

```bash
anvil --silent &
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1); PK2=$(cast wallet private-key "$M" 2)
A2=$(cast wallet address "$PK2")
forge create src/Poll.sol:Poll --private-key "$PK0" --broadcast
P=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast call $P "eip712Domain()(bytes1,string,string,uint256,address,bytes32,uint256[])"
```

```
0x0f
"Poll"
"1"
31337 [3.133e4]
0x5FbDB2315678afecb367f032d93F642f64180aa3
0x0000000000000000000000000000000000000000000000000000000000000000
[]
```

La cuenta 2 vota la opción 2 con el comentario `yes`, con nonce 0 y plazo `2000000000` (un
timestamp de 2033). Crea `vote.json` en `starter/`:

```json
{
  "types": {
    "EIP712Domain": [
      {"name": "name", "type": "string"},
      {"name": "version", "type": "string"},
      {"name": "chainId", "type": "uint256"},
      {"name": "verifyingContract", "type": "address"}
    ],
    "Vote": [
      {"name": "voter", "type": "address"},
      {"name": "option", "type": "uint256"},
      {"name": "comment", "type": "string"},
      {"name": "nonce", "type": "uint256"},
      {"name": "deadline", "type": "uint256"}
    ]
  },
  "primaryType": "Vote",
  "domain": {"name": "Poll", "version": "1", "chainId": 31337, "verifyingContract": "0x5FbDB2315678afecb367f032d93F642f64180aa3"},
  "message": {"voter": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", "option": 2, "comment": "yes", "nonce": 0, "deadline": 2000000000}
}
```

Firma con la cuenta 2 y comprueba la firma sin tocar la cadena:

```bash
SIG=$(cast wallet sign --private-key "$PK2" --data --from-file vote.json); echo $SIG
cast wallet verify --address $A2 --data --from-file vote.json $SIG
```

```
0xabdf1cc9c750d9440260214356980f22d36f6365fa75c2a2c9ba14b391e6412101bf33baa08447b8b4d61e502b3748b8bfd48774eadaa97647a30942af77c7141b
Validation succeeded. Address 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC signed this message.
```

La cuenta 1 hace de relayer. Primero intenta cambiar el voto a la opción 0, después envía el
voto tal cual, y después lo reenvía:

```bash
DL=2000000000
cast send $P "voteBySig(address,uint256,string,uint256,bytes)" $A2 0 yes $DL $SIG --private-key "$PK1"
cast send $P "voteBySig(address,uint256,string,uint256,bytes)" $A2 2 yes $DL $SIG --private-key "$PK1" --json | jq -c '[.status, .from]'
cast call $P "votesFor(uint256)(uint256)" 2
cast call $P "nonces(address)(uint256)" $A2
cast send $P "voteBySig(address,uint256,string,uint256,bytes)" $A2 2 yes $DL $SIG --private-key "$PK1"
```

```
Error: ... custom error 0x7ba5ffb5: ...: InvalidSigner(0xc3a479A94435B9FD622FD1A5f681DA5e8B0967Cb, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)
["0x1","0x70997970c51812dc3a010c7d01b50e0d17dc79c8"]
1
1
Error: ... custom error 0x7ba5ffb5: ...: InvalidSigner(0xFc27aa1399D682F57a1dA51CB55E6d735C9d947A, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)
```

**Verifica**: la cuenta 2 votó sin enviar ninguna transacción (la envió `0x7099…`, la cuenta
1). Los dos fallos son `InvalidSigner` con una dirección distinta cada vez: con la opción
cambiada, el struct es otro; con el reenvío, el nonce ya es 1. En ninguno de los dos casos
hizo falta un `used[...]`.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 13 tests.
- Explicas por qué `comment` entra en el struct hash como su keccak256.
- Explicas por qué la firma no vale en otra votación sin poner `address(this)` en `Vote`.
- Explicas qué pasa con una firma pendiente cuando el votante llama a `cancelNonce`.
- Explicas qué ve el votante en su wallet al firmar, frente al cupón del ejercicio 01.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Cupones firmados](../ejercicio-01-cupones-firmados/README.md) | **Ejercicio 02 — Votos con EIP-712** | [Ejercicio 03 — Permit →](../ejercicio-03-permit/README.md) |
