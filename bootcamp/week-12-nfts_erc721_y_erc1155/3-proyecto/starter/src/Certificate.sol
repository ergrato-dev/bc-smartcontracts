// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IRegistry} from "./IRegistry.sol";

// ¿Qué? El certificado de cada recurso: un ERC-721 cuyo `tokenId` es el id del recurso.
// ¿Para qué? Que la titularidad de un recurso se pueda ver en una wallet y transferir, y que
//   su metadata salga del propio registro (etiqueta y estado), sin servidores.
// ¿Impacto? Solo el registro que lo desplegó puede emitir. Quien tiene el certificado es
//   quien puede retirar el recurso.
contract Certificate is ERC721 {
    using Strings for uint256;

    IRegistry public immutable REGISTRY;

    error NotRegistry(address caller);

    /// @notice Lo despliega el registro en su constructor: quien despliega es el registro.
    // TODO: el nombre y el símbolo de la colección de tu dominio.
    constructor() ERC721("", "") {
        REGISTRY = IRegistry(msg.sender);
    }

    /// @notice Emite el certificado del recurso `id` para `to`. Solo el registro.
    /// @dev `_mint` y no `_safeMint`: `to` es quien registra, y así el registro no da el
    ///   control a nadie en medio de un alta.
    /// @param to Quien registró el recurso.
    /// @param id El id del recurso, que es también el del certificado.
    // TODO: `NotRegistry(msg.sender)` si no llama el registro; si no, emite el token `id`
    //   para `to` con `_mint`.
    function mint(address to, uint256 id) external {
        revert("TODO: mint");
    }

    /// @notice La metadata del certificado, en JSON y Base64, construida con el estado actual
    ///   del recurso en el registro.
    /// @param id El id del certificado.
    /// @return Una URI `data:application/json;base64,...`.
    // TODO: revierte si el token no existe; si no, lee el recurso en el registro y devuelve
    //   el JSON de la tabla del README, en Base64. Escapa la etiqueta con `Strings.escapeJSON`.
    function tokenURI(uint256 id) public view override returns (string memory) {
        revert("TODO: tokenURI");
    }
}
