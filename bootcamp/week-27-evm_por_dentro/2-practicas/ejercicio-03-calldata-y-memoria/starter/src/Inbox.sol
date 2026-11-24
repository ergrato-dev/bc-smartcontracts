// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un buzón de notas: cada nota lleva destinatario, importe y texto.
// ¿Para qué? Tener funciones con argumentos estáticos, dinámicos y anidados para codificar su
//   calldata a mano, y errores de los tres formatos para decodificar su returndata.
// ¿Impacto? Ninguno: no guarda ETH. `allocate` reserva memoria a petición de quien llama, que
//   es justo lo que un contrato real no debe permitir sin límite.
contract Inbox {
    uint256 public constant MAX_NOTE = 64;

    uint256 public posted;

    event Posted(address indexed to, uint256 amount, string note);

    error NoteTooLong(uint256 length, uint256 max);

    /// @notice Deja una nota para `to`.
    function post(address to, uint256 amount, string calldata note) external returns (uint256) {
        require(to != address(0), "Inbox: zero address");
        if (bytes(note).length > MAX_NOTE) revert NoteTooLong(bytes(note).length, MAX_NOTE);
        emit Posted(to, amount, note);
        return ++posted;
    }

    /// @notice Cuántos bytes suman todas las notas.
    function totalLength(string[] calldata notes) external pure returns (uint256 total) {
        for (uint256 i = 0; i < notes.length; i++) {
            total += bytes(notes[i]).length;
        }
    }

    /// @notice Reparte `amount` entre `parts`. Con `parts == 0` revierte con Panic(0x12).
    function split(uint256 amount, uint256 parts) external pure returns (uint256) {
        return amount / parts;
    }

    /// @notice Reserva `size` bytes de memoria y devuelve cuántos reservó.
    function allocate(uint256 size) external pure returns (uint256) {
        return new bytes(size).length;
    }
}
