// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un tablón de anuncios: cada anuncio tiene autor, texto y "me gusta".
// ¿Para qué? Practicar eventos: declararlos, emitirlos, marcar parámetros `indexed` y
//   calcular su identificador.
// ¿Impacto? Un contrato no puede leer sus propios eventos: quedan en el recibo de la
//   transacción para que los lea quien está fuera (una dApp, un indexador, `cast`).
contract Noticeboard {
    uint256 public postCount;
    mapping(uint256 => address) public authorOf;
    mapping(uint256 => string) public textOf;
    mapping(uint256 => uint256) public likes;
    mapping(uint256 => mapping(address => bool)) public hasLiked;

    event Posted(uint256 indexed id, address indexed author, string text);
    event Edited(uint256 indexed id, string oldText, string newText);
    event Liked(uint256 indexed id, address indexed by, uint256 total);
    event Removed(uint256 indexed id);

    error NotAuthor(address caller, uint256 id);
    error PostNotFound(uint256 id);
    error AlreadyLiked(uint256 id);

    // PASO 1: guardar el anuncio y emitir `Posted` con el id, el autor y el texto.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function post(string calldata text) external returns (uint256 id) {
        revert("TODO: Paso 1");
        //> id = ++postCount;
        //> authorOf[id] = msg.sender;
        //> textOf[id] = text;
        //> emit Posted(id, msg.sender, text);
    }

    // PASO 2: cambiar el texto y emitir el texto viejo y el nuevo. El viejo hay que
    //   leerlo antes de sobrescribirlo.
    function edit(uint256 id, string calldata newText) external {
        revert("TODO: Paso 2");
        //> if (authorOf[id] != msg.sender) revert NotAuthor(msg.sender, id);
        //> string memory oldText = textOf[id];
        //> textOf[id] = newText;
        //> emit Edited(id, oldText, newText);
    }

    // PASO 3: un "me gusta" por cuenta; el evento lleva el total ya actualizado.
    function like(uint256 id) external {
        revert("TODO: Paso 3");
        //> if (authorOf[id] == address(0)) revert PostNotFound(id);
        //> if (hasLiked[id][msg.sender]) revert AlreadyLiked(id);
        //> hasLiked[id][msg.sender] = true;
        //> uint256 total = ++likes[id];
        //> emit Liked(id, msg.sender, total);
    }

    // PASO 4: borrar el anuncio y dejar constancia con `Removed`. Si revierte, no queda
    //   ningún evento.
    function remove(uint256 id) external {
        revert("TODO: Paso 4");
        //> if (authorOf[id] != msg.sender) revert NotAuthor(msg.sender, id);
        //> delete authorOf[id];
        //> delete textOf[id];
        //> emit Removed(id);
    }

    // PASO 5: devolver el identificador del evento `Posted` (su topic 0).
    function postedTopic() external pure returns (bytes32) {
        revert("TODO: Paso 5");
        //> return Posted.selector;
    }
}
