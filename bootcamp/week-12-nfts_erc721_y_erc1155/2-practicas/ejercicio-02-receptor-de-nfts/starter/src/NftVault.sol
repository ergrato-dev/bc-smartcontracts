// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Owned} from "./Owned.sol";

// ¿Qué? Una caja que guarda NFTs de una colección y los devuelve a quien los depositó.
// ¿Para qué? Recibir NFTs con `safeTransferFrom` (`onERC721Received`) y apuntar de quién es
//   cada uno, como haría un mercado o un contrato de préstamos.
// ¿Impacto? `onERC721Received` es una función pública: si no comprueba quién la llama,
//   cualquiera apunta depósitos que nunca llegaron.
contract NftVault is IERC721Receiver, Owned {
    IERC721 public immutable COLLECTION;
    mapping(uint256 => address) public depositorOf;

    event Deposited(address indexed depositor, uint256 indexed tokenId);
    event Withdrawn(address indexed depositor, uint256 indexed tokenId);
    event Rescued(address indexed to, uint256 indexed tokenId);

    error WrongCollection(address caller);
    error NotDepositor(address caller, uint256 tokenId);
    error NotStuck(uint256 tokenId);

    constructor(IERC721 collection) {
        COLLECTION = collection;
    }

    /// @inheritdoc IERC721Receiver
    // PASO 1: aceptar solo la colección, apuntar al dueño anterior y devolver el selector.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external returns (bytes4) {
        revert("TODO: Paso 1");
        //> if (msg.sender != address(COLLECTION)) revert WrongCollection(msg.sender);
        //> depositorOf[tokenId] = from;
        //> emit Deposited(from, tokenId);
        //> return IERC721Receiver.onERC721Received.selector;
    }

    // PASO 2: devolver el NFT a quien lo depositó. Primero se borra, después se envía.
    function withdraw(uint256 tokenId) external {
        revert("TODO: Paso 2");
        //> if (depositorOf[tokenId] != msg.sender) revert NotDepositor(msg.sender, tokenId);
        //> delete depositorOf[tokenId];
        //> emit Withdrawn(msg.sender, tokenId);
        //> COLLECTION.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    // PASO 3: sacar un NFT que llegó con `transferFrom`, sin aviso y sin depositante. Solo el dueño.
    function rescue(uint256 tokenId, address to) external onlyOwner {
        revert("TODO: Paso 3");
        //> if (depositorOf[tokenId] != address(0)) revert NotStuck(tokenId);
        //> emit Rescued(to, tokenId);
        //> COLLECTION.safeTransferFrom(address(this), to, tokenId);
    }
}
