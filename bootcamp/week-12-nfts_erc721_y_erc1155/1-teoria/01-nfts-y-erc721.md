# Teoría 01 — NFTs y ERC-721

## 🎯 Objetivos

- Explicar qué es un token no fungible y qué guarda de verdad un contrato ERC-721.
- Nombrar las funciones, los eventos y los dos niveles de permiso del estándar.
- Crear una colección con OpenZeppelin y moverla entre cuentas de anvil con `cast`.
- Distinguir en los logs una transferencia de ERC-721 de una de ERC-20.

---

## 1. Qué problema resuelve

Un ERC-20 cuenta cantidades: tus 10 tokens valen lo mismo que mis 10 (semana 11). Pero
muchas cosas no se cuentan, se identifican: la entrada de la fila 7, asiento 12; el
certificado de un curso a tu nombre; la escritura de una parcela. Dos entradas del mismo
concierto no valen lo mismo si una es de primera fila.

Un **token no fungible** (NFT, *non-fungible token*) es un token donde cada unidad es
única. En vez de `dirección → cantidad`, el contrato guarda `identificador → dueño`. El
identificador, `tokenId`, es un `uint256`; el contrato decide cómo se asignan (1, 2, 3...
es lo habitual).

**ERC-721** ([EIP-721](https://eips.ethereum.org/EIPS/eip-721), 2018) es la interfaz que
tienen que cumplir esos contratos para que una wallet o un mercado los manejen sin leer
su código. Se usa *colección* para el contrato y *token* para cada `tokenId`.

Lo que **no** guarda un NFT: una imagen. El contrato guarda quién tiene cada `tokenId`.
La descripción, la imagen y los atributos son la *metadata*, que el contrato apunta con
una URL (teoría 03). Comprar un NFT es pasar a ser el `ownerOf` de un número en un
contrato concreto, no comprar un archivo.

## 2. Cómo funciona

### Las funciones

| Función | Qué hace |
| ------- | -------- |
| `balanceOf(owner)` | Cuántos tokens de la colección tiene `owner` (no cuáles) |
| `ownerOf(tokenId)` | Quién tiene ese token. **Revierte** si no existe |
| `transferFrom(from, to, tokenId)` | Mueve el token. Lo puede llamar el dueño o alguien con permiso |
| `safeTransferFrom(from, to, tokenId)` | Igual, pero comprueba que el destino sabe recibir NFTs (teoría 02). Hay una versión con un cuarto argumento `bytes data` |
| `approve(to, tokenId)` | Da permiso a `to` sobre **un** token |
| `getApproved(tokenId)` | Quién tiene permiso sobre ese token |
| `setApprovalForAll(operator, approved)` | Da (o quita) permiso a `operator` sobre **todos** tus tokens de la colección |
| `isApprovedForAll(owner, operator)` | Si `operator` tiene ese permiso |

Y, opcionales pero casi universales (la extensión *metadata*): `name()`, `symbol()` y
`tokenURI(tokenId)`. No hay `decimals`: un NFT no se divide.

### Dos niveles de permiso

En ERC-20, el permiso es una cantidad (semana 11). Aquí no hay cantidades, así que hay
dos permisos distintos:

- **`approve`**: un `spender` sobre un `tokenId`. Solo uno a la vez por token, y se borra
  solo cuando el token cambia de dueño.
- **`setApprovalForAll`**: un **operador** sobre todos los tokens que tienes y que tendrás
  en esa colección. Es lo que pide un mercado para poder vender cualquiera de los tuyos.

`transferFrom` acepta al dueño, al aprobado de ese token o a un operador del dueño.

### Los eventos

```solidity
event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
```

Como en ERC-20, emitir (*mint*) es un `Transfer` desde `address(0)` y quemar (*burn*) uno
hacia `address(0)`. La diferencia está en el tercer `indexed`: el `tokenId` va en los
topics, para poder buscar la historia de un token concreto.

### ERC-165 obligatorio

Un ERC-721 **tiene** que responder `true` a `supportsInterface(0x80ac58cd)`, el
`interfaceId` de `IERC721` (semana 10). Es la forma de saber que una dirección es una
colección antes de tratarla como tal.

## 3. Cómo se escribe

OpenZeppelin trae `ERC721`, con las funciones, los eventos, los errores de ERC-6093 y
ERC-165 hechos. En `src/Ticket.sol`, las entradas de un concierto:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Ticket is ERC721 {
    address public immutable ORGANIZER;
    uint256 public nextId = 1;

    error NotOrganizer(address caller);

    constructor() ERC721("Concert Ticket", "TIX") {
        ORGANIZER = msg.sender;
    }

    function mint(address to) external returns (uint256 id) {
        if (msg.sender != ORGANIZER) revert NotOrganizer(msg.sender);
        id = nextId++;
        _mint(to, id);
    }
}
```

`_mint(to, tokenId)` es `internal`, como en ERC-20: crea el token y revierte con
`ERC721InvalidSender(address(0))` si ese `tokenId` ya existe. `nextId++` devuelve el valor
actual y después lo suma: el primer token es el 1.

### En anvil

**Dónde**: en el contenedor, en la carpeta del proyecto, con `anvil --silent &` recién
arrancado. La cuenta 0 es la organizadora; la 1 y la 2, el público:

```bash
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1); PK2=$(cast wallet private-key "$M" 2)
A0=$(cast wallet address "$PK0"); A1=$(cast wallet address "$PK1"); A2=$(cast wallet address "$PK2")
forge create src/Ticket.sol:Ticket --private-key "$PK0" --broadcast
T=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast send $T "mint(address)" $A1 --private-key "$PK0"
cast send $T "mint(address)" $A1 --private-key "$PK0"
cast call $T "ownerOf(uint256)(address)" 1
cast call $T "balanceOf(address)(uint256)" $A1
```

```
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
2
```

La cuenta 1 tiene dos entradas, la 1 y la 2. El log del primer `mint`, en el recibo:

```
"topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
          "0x0000000000000000000000000000000000000000000000000000000000000000",
          "0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8",
          "0x0000000000000000000000000000000000000000000000000000000000000001"],
"data":"0x"
```

Cuatro topics y `data` vacío: `from` es `address(0)` (un mint), `to` la cuenta 1 y el
último, el `tokenId` 1. El primer topic es **el mismo** que el `Transfer` de ERC-20:
`cast sig-event "Transfer(address,address,uint256)"` da `0xddf252ad...` en los dos. Lo que
los distingue es el número de topics: tres en ERC-20, con la cantidad en `data`, y cuatro
aquí.

### Mover con permiso

La cuenta 0 intenta mover la entrada 1 de la cuenta 1 sin permiso:

```bash
cast send $T "transferFrom(address,address,uint256)" $A1 $A2 1 --private-key "$PK0"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x177e802f: ..., data: "0x177e802f...": ERC721InsufficientApproval(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 1)
```

La cuenta 1 le da permiso sobre esa entrada y la cuenta 0 la mueve:

```bash
cast send $T "approve(address,uint256)" $A0 1 --private-key "$PK1"
cast call $T "getApproved(uint256)(address)" 1
cast send $T "transferFrom(address,address,uint256)" $A1 $A2 1 --private-key "$PK0"
cast call $T "ownerOf(uint256)(address)" 1
cast call $T "getApproved(uint256)(address)" 1
```

```
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
0x0000000000000000000000000000000000000000
```

La entrada es ahora de la cuenta 2, y el permiso se borró al cambiar de dueño: el nuevo
dueño no hereda los permisos del anterior.

Un token que no existe no tiene dueño, y `ownerOf` no devuelve `address(0)`:

```bash
cast call $T "ownerOf(uint256)(address)" 99
```

```
Error: execution reverted: ERC721NonexistentToken(99)
```

## 4. Antipatrones y riesgos

**Firmar un `setApprovalForAll` sin saber a quién.** Es el permiso más amplio que existe en
una colección: todos tus tokens, también los que recibas después, sin límite de tiempo.
Muchos robos de NFTs son eso: una web falsa pide firmar `setApprovalForAll` para un
operador del atacante. Revócalo con `setApprovalForAll(operator, false)` cuando no lo
necesites.

**Esperar que `ownerOf` devuelva `address(0)`.** Revierte con `ERC721NonexistentToken`. Un
contrato que pregunte por tokens que quizá no existen tiene que contar con ese revert.

**Usar `balanceOf` para saber qué tokens tiene alguien.** Da cuántos, no cuáles. El
estándar no tiene una lista por dueño: se reconstruye leyendo los `Transfer` (como en la
semana 11 con `cast logs`) o se paga una extensión que la guarda en storage
(`ERC721Enumerable`), que encarece cada transferencia.

**Confundir los selectores.** `approve(address,uint256)` y `transferFrom(address,address,uint256)`
tienen el mismo selector en ERC-20 y en ERC-721 (`0x095ea7b3` y `0x23b872dd`), pero el
`uint256` es una cantidad en uno y un `tokenId` en el otro. Un contrato que acepte
"cualquier token" sin comprobar cuál es (ERC-165) puede tratar un NFT como una cantidad.

**Dejar `mint` sin control.** Igual que en ERC-20: `_mint` es interno, y la función pública
que lo llama decide quién puede crear tokens.

## 5. Trucos

- `cast logs --from-block 0 --address $T "Transfer(address indexed,address indexed,uint256 indexed)"`
  lista la historia de la colección, con el `tokenId` en el cuarto topic. Escribe los tres
  `indexed`: el topic 0 es el mismo con o sin ellos, pero `cast` los necesita para saber
  que el `tokenId` va en un topic y no en `data`.
- `cast call $T "supportsInterface(bytes4)(bool)" 0x80ac58cd` comprueba que una dirección
  es un ERC-721.
- `forge inspect Ticket methods` lista las funciones heredadas, como en el ejercicio 02 de
  la semana 11.

## ✅ Checklist

- [ ] Explico qué guarda un ERC-721 y por qué la imagen no está en el contrato.
- [ ] Distingo `approve` de `setApprovalForAll` y sé cuándo se borra cada uno.
- [ ] Creo una colección con `ERC721` de OpenZeppelin y controlo quién emite.
- [ ] Leo en un log de `Transfer` si es de ERC-20 o de ERC-721.
- [ ] Sé que `ownerOf` revierte con un token que no existe.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 12](../README.md) | **Teoría 01 — NFTs y ERC-721** | [Teoría 02 — Transferencias seguras y receptores →](02-transferencias-seguras-y-receptores.md) |
