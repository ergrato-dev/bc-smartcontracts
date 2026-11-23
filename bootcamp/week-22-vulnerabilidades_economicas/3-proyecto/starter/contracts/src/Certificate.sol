// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IRegistry} from "./IRegistry.sol";

// ¿Qué? El certificado de cada recurso: un ERC-721 cuyo `tokenId` es el id del recurso.
// ¿Para qué? Que la titularidad de un recurso se pueda ver en una wallet y transferir, y que
//   su metadata salga del propio registro (etiqueta y estado), sin servidores.
// ¿Impacto? Solo el registro cuya dirección recibe el constructor puede emitir. Quien tiene el certificado es
//   quien puede retirar el recurso.
contract Certificate is ERC721 {
    using Strings for uint256;

    IRegistry public immutable REGISTRY;

    error NotRegistry(address caller);

    /// @notice Se despliega antes que el proxy del registro, con la dirección que tendrá.
    /// @param registry El proxy del registro: el único que puede emitir certificados.
    constructor(IRegistry registry) ERC721("", "") {
        REGISTRY = registry;
    }

    /// @notice Emite el certificado del recurso `id` para `to`. Solo el registro.
    /// @dev `_mint` y no `_safeMint`: `to` es quien registra, y así el registro no da el
    ///   control a nadie en medio de un alta.
    /// @param to Quien registró el recurso.
    /// @param id El id del recurso, que es también el del certificado.
    function mint(address to, uint256 id) external {
        if (msg.sender != address(REGISTRY)) revert NotRegistry(msg.sender);
        // forge-lint: disable-next-line(unsafe-oz-erc721-mint)
        _mint(to, id);
    }

    /// @notice La metadata del certificado, en JSON y Base64, construida con el estado actual
    ///   del recurso en el registro.
    /// @param id El id del certificado.
    /// @return Una URI `data:application/json;base64,...`.
    function tokenURI(uint256 id) public view override returns (string memory) {
        _requireOwned(id);
        IRegistry.Item memory item = REGISTRY.getItem(id);
        string memory status = item.status == IRegistry.Status.Active ? "Active" : "Retired";
        // La etiqueta la escribió quien registró: se escapa para que no pueda cerrar el campo.
        string memory json = string.concat(
            '{"name":"',
            Strings.escapeJSON(item.label),
            '","description":"Certificate #',
            id.toString(),
            '","attributes":[{"trait_type":"status","value":"',
            status,
            '"},{"trait_type":"registeredAt","display_type":"date","value":',
            item.registeredAt.toString(),
            "}]}"
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }
}
