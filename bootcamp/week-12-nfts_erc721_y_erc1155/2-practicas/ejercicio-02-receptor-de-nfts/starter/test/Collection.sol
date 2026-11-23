// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// ¿Qué? Una colección de prueba en la que cualquiera emite el id que quiera.
// ¿Para qué? Tener NFTs que depositar en los tests. Nunca en producción.
contract Collection is ERC721 {
    constructor() ERC721("Test Art", "ART") {}

    function mint(address to, uint256 tokenId) external {
        // forge-lint: disable-next-line(unsafe-oz-erc721-mint)
        _mint(to, tokenId);
    }
}
