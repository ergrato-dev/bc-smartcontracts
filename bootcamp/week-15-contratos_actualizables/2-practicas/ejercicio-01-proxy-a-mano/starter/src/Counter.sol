// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? La lógica de un contador, en dos versiones. Ninguna tiene constructor ni guarda la
//   dirección de nadie: solo `count`, en el slot 0.
// ¿Para qué? Ser la implementación detrás de un proxy: el proxy guarda `count`, esta lógica
//   lo cambia.
// ¿Impacto? V2 conserva `count` en el mismo slot y añade funciones: con el proxy apuntando a
//   V2, el contador sigue donde estaba.
contract CounterV1 {
    uint256 public count;

    event Incremented(address indexed by, uint256 count);

    error NothingToDecrement();

    function increment() external {
        count++;
        emit Incremented(msg.sender, count);
    }

    function version() external pure virtual returns (uint256) {
        return 1;
    }
}

contract CounterV2 is CounterV1 {
    function decrement() external {
        if (count == 0) revert NothingToDecrement();
        count--;
    }

    function version() external pure override returns (uint256) {
        return 2;
    }
}
