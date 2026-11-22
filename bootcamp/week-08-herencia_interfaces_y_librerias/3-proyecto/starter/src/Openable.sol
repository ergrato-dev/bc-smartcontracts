// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Owned} from "./Owned.sol";

// ¿Qué? Un interruptor de abierto o cerrado que solo mueve el dueño.
// ¿Para qué? Que un hijo bloquee sus funciones con `whenOpen` sin reescribir la lógica.
// ¿Impacto? Empieza abierto. Cerrar no detiene las funciones sin `whenOpen`.
abstract contract Openable is Owned {
    bool public isOpen;

    event OpenChanged(bool isOpen);

    error RegistryClosed();

    modifier whenOpen() {
        // TODO: RegistryClosed() si está cerrado.
        _;
    }

    constructor() {
        isOpen = true;
    }

    /// @notice Abre o cierra. Solo el dueño.
    /// @param open `true` para abrir, `false` para cerrar.
    function setOpen(bool open) external onlyOwner {
        // TODO: guardar `open` y emitir OpenChanged. Cópialo de Registry.sol.
    }
}
