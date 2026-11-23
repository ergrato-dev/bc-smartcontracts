// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Owned} from "./Owned.sol";

// ¿Qué? El carné de un gremio: un ERC-721 que emite el dueño, que no se puede transferir
//   (soulbound) y cuya metadata se construye en el contrato.
// ¿Para qué? Ver los puntos de extensión de ERC721 de OpenZeppelin: `_safeMint`, `_burn`,
//   `tokenURI` y `_update`.
// ¿Impacto? Un carné intransferible acredita a una cuenta concreta: no se puede vender ni
//   prestar. Si la cuenta pierde su clave, el dueño del gremio revoca y emite uno nuevo.
contract GuildPass is ERC721, Owned {
    using Strings for uint256;

    uint256 public nextId = 1;
    mapping(uint256 => uint256) public joinedAt;

    error Soulbound(uint256 tokenId);

    constructor() ERC721("Guild Pass", "PASS") {}

    // PASO 1: emitir un carné para `to`, con el siguiente id y la hora de alta.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function issue(address to) external onlyOwner returns (uint256 id) {
        revert("TODO: Paso 1");
        //> id = nextId++;
        //> joinedAt[id] = block.timestamp;
        //> _safeMint(to, id);
    }

    // PASO 2: revocar un carné. `_burn` revierte si no existe.
    function revoke(uint256 id) external onlyOwner {
        revert("TODO: Paso 2");
        //> delete joinedAt[id];
        //> _burn(id);
    }

    // PASO 3: la metadata, en JSON y Base64, construida al llamar.
    function tokenURI(uint256 id) public view override returns (string memory) {
        revert("TODO: Paso 3");
        //> _requireOwned(id);
        //> string memory json = string.concat(
        //>     '{"name":"Guild Pass #',
        //>     id.toString(),
        //>     '","attributes":[{"trait_type":"joined","display_type":"date","value":',
        //>     joinedAt[id].toString(),
        //>     "}]}"
        //> );
        //> return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    // ¿Qué? Mint, burn y transfer pasan por `_update`: `to` es el destino y `auth` quien pide
    //   el movimiento (o `address(0)` si no hay que comprobarlo). Devuelve el dueño anterior.
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        // PASO 4: solo se emite (sin dueño anterior) o se quema (hacia address(0)).
        //   Descomenta las líneas que empiezan con `//> `.
        //> address from = _ownerOf(tokenId);
        //> if (from != address(0) && to != address(0)) revert Soulbound(tokenId);
        return super._update(to, tokenId, auth);
    }
}
