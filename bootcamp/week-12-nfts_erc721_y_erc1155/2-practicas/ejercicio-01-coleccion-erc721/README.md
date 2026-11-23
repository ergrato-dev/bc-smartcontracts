# Ejercicio 01 — Colección ERC-721

> Al terminar tendrás el carné de un gremio: un ERC-721 de OpenZeppelin que emite el dueño,
> que se puede revocar, con su metadata construida en el contrato, y que no se puede
> transferir. Y lo habrás emitido y revocado en anvil.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teorías 01 a 03](../../1-teoria/01-nfts-y-erc721.md) leídas.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Owned.sol` | El dueño fijo de la semana 08, con `onlyOwner`. Terminado |
| `src/GuildPass.sol` | El carné: hereda `ERC721` y `Owned`. Aquí trabajas |
| `test/GuildPass.t.sol` | Tests de tus pasos (`test_Step*`) y de lo heredado (`test_Inherited_*`). No lo modifiques |

Un token **soulbound** (ligado al alma) es un NFT que no se puede transferir: acredita algo
de una cuenta concreta, como un título o una membresía.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-12-nfts_erc721_y_erc1155/2-practicas/ejercicio-01-coleccion-erc721/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5667)` (parámetros sin usar) y `(2018)`, los de las funciones que
solo revierten.

**Verifica**: `2 tests passed, 7 failed, 0 skipped (9 total tests)`. Ya pasan
`test_Step1_RevertWhen_StrangerIssues` (`onlyOwner` revierte antes del `TODO`) y
`test_Inherited_SupportsInterface`: ERC-165 llega hecho con `ERC721`.

## Paso 1: Emitir

**Por qué**: el id sale de un contador, y la hora de alta se guarda **antes** de emitir.
`_safeMint` llama a `onERC721Received` si `to` es un contrato (teoría 02): el dueño del
gremio emite para otra cuenta, y si esa cuenta es un contrato que no sabe guardar NFTs, el
carné se perdería. Como esa llamada da el control a `to`, el estado tiene que estar escrito
antes.

**Abre** `src/GuildPass.sol`, en `issue`, borra el `revert` y descomenta:

```solidity
id = nextId++;
joinedAt[id] = block.timestamp;
_safeMint(to, id);
```

**Verifica**: `4 tests passed, 5 failed`. `test_Step1_RevertWhen_ReceiverCannotHold` emite
para un contrato vacío y espera `ERC721InvalidReceiver(locker)`: el carné no llega a
existir.

## Paso 2: Revocar

**Por qué**: si un miembro deja el gremio o pierde su clave, el dueño quema su carné.
`_burn` es `internal`, no comprueba permisos (de eso se encarga `onlyOwner`) y revierte con
`ERC721NonexistentToken` si el id no existe. `delete` devuelve `joinedAt[id]` a 0, para
que no quede un dato de un token que ya no está.

```solidity
delete joinedAt[id];
_burn(id);
```

**Verifica**: `5 tests passed, 4 failed`. `test_Step2_Revoke` comprueba que, después,
`ownerOf` revierte y el saldo de alice es 0.

## Paso 3: La metadata

**Por qué**: la fecha de alta ya está en el contrato. Si el JSON se construye al llamar,
nadie tiene que mantener un servidor y la metadata no se puede desincronizar (teoría 03).
`display_type: "date"` le dice a quien lo pinte que el número es una fecha en segundos.

```solidity
_requireOwned(id);
string memory json = string.concat(
    '{"name":"Guild Pass #',
    id.toString(),
    '","attributes":[{"trait_type":"joined","display_type":"date","value":',
    joinedAt[id].toString(),
    "}]}"
);
return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
```

Aquí no hay texto que escriba un usuario: el id y la fecha son números, y no hace falta
`escapeJSON`.

**Verifica**: `7 tests passed, 2 failed`. Quedan los dos `test_Step4_*`, con
`[FAIL: next call did not revert as expected]`: el carné aún se puede transferir.

## Paso 4: Intransferible

**Por qué**: `transferFrom`, `safeTransferFrom`, `_mint` y `_burn` pasan todos por
`_update(to, tokenId, auth)`, como en ERC-20 (semana 11). Una regla allí vale para todos los
caminos. Con el dueño anterior (`_ownerOf`, que devuelve `address(0)` si no existe, sin
revertir) se distinguen los tres casos:

| `from` | `to` | Qué es | ¿Se permite? |
| ------ | ---- | ------ | ------------ |
| `address(0)` | una cuenta | Emitir | Sí |
| una cuenta | `address(0)` | Quemar | Sí |
| una cuenta | otra cuenta | Transferir | No |

**En** `_update`, descomenta, antes de `super`:

```solidity
address from = _ownerOf(tokenId);
if (from != address(0) && to != address(0)) revert Soulbound(tokenId);
```

**Verifica**:

```bash
forge test --deny warnings
```

`9 tests passed, 0 failed, 0 skipped (9 total tests)`, sin warnings.
`test_Step4_RevertWhen_ApprovedTransfers` comprueba que tampoco un operador con
`setApprovalForAll` puede moverlo.

## Paso 5: En anvil

**Por qué**: ver el JSON tal como lo leería una wallet, y el error que vería quien
intenta vender su carné.

Este paso no tiene código. Arranca anvil y despliega desde la cuenta 0:

```bash
anvil --silent &
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1)
A1=$(cast wallet address "$PK1"); A2=$(cast wallet address $(cast wallet private-key "$M" 2))
forge create src/GuildPass.sol:GuildPass --private-key "$PK0" --broadcast
P=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast send $P "issue(address)" $A1 --private-key "$PK0"
cast call $P "tokenURI(uint256)(string)" 1 | tr -d '"' | sed 's/^data:application\/json;base64,//' | base64 -d | jq -c .
```

```
{"name":"Guild Pass #1","attributes":[{"trait_type":"joined","display_type":"date","value":1795405920}]}
```

Tu `value` será otro: es la hora del bloque en tu anvil. La cuenta 1 intenta pasárselo a
la 2:

```bash
cast send $P "transferFrom(address,address,uint256)" $A1 $A2 1 --private-key "$PK1"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0xcd4d8627: , data: "0xcd4d8627...": Soulbound(1)
```

**Verifica**: el dueño lo revoca y el carné deja de existir:

```bash
cast send $P "revoke(uint256)" 1 --private-key "$PK0"
cast call $P "ownerOf(uint256)(address)" 1
cast call $P "balanceOf(address)(uint256)" $A1
```

```
Error: execution reverted: ERC721NonexistentToken(1)
0
```

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 9 tests.
- Explicas por qué `issue` usa `_safeMint` y por qué el estado se escribe antes.
- Explicas cómo distingue `_update` un mint, un burn y una transferencia.
- Explicas qué pierde un miembro con un carné intransferible, y qué hace el dueño si ese
  miembro pierde su clave.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — ERC-1155](../../1-teoria/04-erc1155.md) | **Ejercicio 01 — Colección ERC-721** | [Ejercicio 02 — Receptor de NFTs →](../ejercicio-02-receptor-de-nfts/README.md) |
