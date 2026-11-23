// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

// ¿Qué? Un tablón de anuncios con tres roles: el administrador nombra moderadores, los
//   moderadores nombran editores y retiran anuncios, y los editores publican.
// ¿Para qué? Practicar `onlyRole`, el primer `_grantRole` y una jerarquía con `_setRoleAdmin`.
// ¿Impacto? Cada rol puede menos que el de arriba: si roban la clave de un editor, el
//   atacante publica, pero no retira anuncios ni nombra a nadie.
contract Bulletin is AccessControl {
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");

    struct Post {
        address author;
        string text;
    }

    uint256 public nextId = 1;
    mapping(uint256 => Post) public posts;

    event Published(uint256 indexed id, address indexed author, string text);
    event Removed(uint256 indexed id, address indexed moderator);

    error EmptyText();
    error PostNotFound(uint256 id);

    // ¿Qué? El administrador llega por parámetro: puede ser quien despliega u otra cuenta,
    //   como un multisig (teoría 04).
    constructor(address admin) {
        // PASO 1: el primer administrador, y los moderadores como administradores de los
        //   editores. Descomenta las líneas que empiezan con `//> `.
        //> _grantRole(DEFAULT_ADMIN_ROLE, admin);
        //> _setRoleAdmin(EDITOR_ROLE, MODERATOR_ROLE);
    }

    // PASO 2: publicar. `onlyRole` ya comprueba el rol antes de entrar.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function publish(string calldata text) external onlyRole(EDITOR_ROLE) returns (uint256 id) {
        revert("TODO: Paso 2");
        //> if (bytes(text).length == 0) revert EmptyText();
        //> id = nextId++;
        //> posts[id] = Post(msg.sender, text);
        //> emit Published(id, msg.sender, text);
    }

    // PASO 3: retirar un anuncio. Un anuncio que no existe tiene `author == address(0)`.
    function remove(uint256 id) external onlyRole(MODERATOR_ROLE) {
        revert("TODO: Paso 3");
        //> if (posts[id].author == address(0)) revert PostNotFound(id);
        //> delete posts[id];
        //> emit Removed(id, msg.sender);
    }
}
