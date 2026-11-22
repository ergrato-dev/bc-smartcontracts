// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un marcador: suma y resta puntos, y recuerda quién anotó por última vez.
// ¿Para qué? Tener un contrato ya escrito y correcto sobre el que practicar tests.
// ¿Impacto? Este archivo no se toca en el ejercicio: lo que escribes son los tests.
contract Scoreboard {
    uint256 total;
    address lastPlayer;

    function addPoints(uint256 points) external {
        total += points;
        lastPlayer = msg.sender;
    }

    // ¿Qué? Resta puntos.
    // ¿Impacto? Si points > total, la resta daría negativo: la transacción revierte sola.
    function removePoints(uint256 points) external {
        total -= points;
    }

    function getTotal() external view returns (uint256) {
        return total;
    }

    function getLastPlayer() external view returns (address) {
        return lastPlayer;
    }
}
