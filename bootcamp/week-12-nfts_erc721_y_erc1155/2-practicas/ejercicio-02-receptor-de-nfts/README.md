# Ejercicio 02 — Receptor de NFTs

> Al terminar tendrás una caja que recibe NFTs de una colección con `safeTransferFrom`,
> apunta de quién es cada uno y se los devuelve. No se dejará engañar por llamadas falsas, y
> el dueño podrá rescatar los que lleguen sin aviso.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 02](../../1-teoria/02-transferencias-seguras-y-receptores.md)
leída y [ejercicio 01](../ejercicio-01-coleccion-erc721/README.md) terminado.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Owned.sol` | El dueño fijo de la semana 08. Terminado |
| `src/NftVault.sol` | La caja: `onERC721Received`, `withdraw` y `rescue`. Aquí trabajas |
| `test/Collection.sol` | Una colección de prueba en la que cualquiera emite. No lo modifiques |
| `test/NftVault.t.sol` | Los tests de cada paso. No lo modifiques |

La caja acepta una sola colección, `COLLECTION`, fijada al desplegar. `IERC721` es la
interfaz del estándar en OpenZeppelin: con ella la caja llama a la colección sin conocer su
código (semana 10).

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-12-nfts_erc721_y_erc1155/2-practicas/ejercicio-02-receptor-de-nfts/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5667)` y `(2018)`.

**Verifica**: `1 tests passed, 8 failed, 0 skipped (9 total tests)`. Solo pasa
`test_Step3_RevertWhen_StrangerRescues`, por `onlyOwner`.

## Paso 1: Recibir

**Por qué**: `onERC721Received` es `external`: la llama la colección al final de un
`safeTransferFrom`, pero también puede llamarla cualquiera, sin enviar nada. Por eso la
primera línea comprueba que `msg.sender` es la colección. El depositante es `from`, el
dueño anterior: si un operador movió el NFT, `operator` es el operador, y el NFT no es suyo
(teoría 02). Devolver el selector es lo que hace que la colección acepte el envío.

**Abre** `src/NftVault.sol`, en `onERC721Received`, borra el `revert` y descomenta:

```solidity
if (msg.sender != address(COLLECTION)) revert WrongCollection(msg.sender);
depositorOf[tokenId] = from;
emit Deposited(from, tokenId);
return IERC721Receiver.onERC721Received.selector;
```

**Verifica**: `5 tests passed, 4 failed`. Pasan los cuatro `test_Step1_*`. Mira el que deposita
con un operador:

```bash
forge test --match-test test_Step1_OperatorDepositCreditsOwner -vvvv
```

```
    ├─ [92105] Collection::safeTransferFrom(alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], NftVault: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 7)
    │   ├─ emit Transfer(from: alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], to: NftVault: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], tokenId: 7)
    │   ├─ [25092] NftVault::onERC721Received(bob: [0x1D96F2f6BeF1202E4Ce1Ff6Dad0c2CB002861d3e], alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], 7, 0x)
    │   │   ├─ emit Deposited(depositor: alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], tokenId: 7)
    │   │   └─ ← [Return] 0x150b7a02
```

El `Transfer` sale **antes** del aviso: cuando la caja se ejecuta, ya es la dueña. La llama
`Collection` (es el `msg.sender`), con `bob` de operador y `alice` de dueña anterior.
`test_Step1_RevertWhen_OtherCollection` comprueba que otra colección recibe
`WrongCollection` y su envío entero revierte: OpenZeppelin devuelve el error del receptor
tal cual.

## Paso 2: Devolver

**Por qué**: solo el depositante retira. Se borra el apunte **antes** de enviar: si el envío
llamara de vuelta a la caja (`safeTransferFrom` avisa a `msg.sender` si es un contrato), el
NFT ya no constaría como depositado. Es el orden de la semana 07.

```solidity
if (depositorOf[tokenId] != msg.sender) revert NotDepositor(msg.sender, tokenId);
delete depositorOf[tokenId];
emit Withdrawn(msg.sender, tokenId);
COLLECTION.safeTransferFrom(address(this), msg.sender, tokenId);
```

`address(this)` es el `from`: la caja es la dueña y llama ella, así que no necesita permiso.

**Verifica**: `7 tests passed, 2 failed`.

## Paso 3: Rescatar

**Por qué**: con `transferFrom` el NFT llega sin aviso (teoría 02). La caja es su dueña pero
no sabe de quién era: `depositorOf` está a 0 y nadie puede retirarlo. Solo el dueño de la
caja puede sacarlo, y solo si no tiene depositante: si lo tuviera, sería quitárselo.

```solidity
if (depositorOf[tokenId] != address(0)) revert NotStuck(tokenId);
emit Rescued(to, tokenId);
COLLECTION.safeTransferFrom(address(this), to, tokenId);
```

**Verifica**:

```bash
forge test --deny warnings
```

`9 tests passed, 0 failed, 0 skipped (9 total tests)`, sin warnings. `test_Step3_RescueStuck`
envía con `transferFrom`, comprueba que nadie consta como depositante y rescata el NFT para
alice.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 9 tests.
- Explicas qué pasaría sin la comprobación de `msg.sender` en `onERC721Received`.
- Explicas por qué el depositante es `from` y no `operator`.
- Explicas por qué `withdraw` borra el apunte antes de enviar.
- Explicas qué confianza exige `rescue` en el dueño de la caja, y por qué no puede sacar un
  NFT que tiene depositante.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Colección ERC-721](../ejercicio-01-coleccion-erc721/README.md) | **Ejercicio 02 — Receptor de NFTs** | [Ejercicio 03 — Multi-token ERC-1155 →](../ejercicio-03-multi-token-erc1155/README.md) |
