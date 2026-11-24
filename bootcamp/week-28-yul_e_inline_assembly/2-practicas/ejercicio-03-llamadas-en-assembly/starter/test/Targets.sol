// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Los contratos a los que llama AsmCaller en los tests. Hechos: no tienes que tocarlos.

// Un token mínimo: solo `balanceOf`, con saldos que pone el test.
contract SimpleToken {
    mapping(address => uint256) public balanceOf;

    function setBalance(address account, uint256 amount) external {
        balanceOf[account] = amount;
    }
}

// Un "token" cuya `balanceOf` acaba bien sin devolver nada.
contract SilentToken {
    fallback() external {}
}

// Un "token" cuya `balanceOf` revierte siempre.
contract RevertingToken {
    fallback() external {
        revert("no");
    }
}

// Un contrato de destino: devuelve lo que recibe, revierte con un custom error o con un motivo
//   del tamaño que se le pida.
contract Target {
    error Nope(uint256 code);

    function echo(bytes calldata data) external pure returns (bytes memory) {
        return data;
    }

    function fail(uint256 code) external pure {
        revert Nope(code);
    }

    // Revierte con `size` bytes de ceros, sin escribirlos: `revert(0, size)` devuelve la
    //   memoria tal cual, y la memoria nueva vale cero.
    function bomb(uint256 size) external pure {
        assembly {
            revert(0, size)
        }
    }
}

// Un constructor que siempre falla: `create2` con este código devuelve la dirección 0.
contract Unbuildable {
    constructor() {
        revert("no");
    }
}
