// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? El contador del ejercicio 01, ya resuelto, listo para desplegar en anvil.
contract Counter {
    uint256 number;

    function get() external view returns (uint256) {
        return number;
    }

    function increment() external {
        number += 1;
    }

    function set(uint256 newNumber) external {
        number = newNumber;
    }
}
