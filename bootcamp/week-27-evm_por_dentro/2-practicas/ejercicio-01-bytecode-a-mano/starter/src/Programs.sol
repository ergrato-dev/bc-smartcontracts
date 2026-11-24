// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Cinco programas de la EVM escritos a mano, byte a byte, sin compilador.
// ¿Para qué? Ver qué hace cada opcode con la pila, la memoria y el storage antes de leer el
//   bytecode que genera solc.
// ¿Impacto? Ninguno de estos programas comprueba nada que no se diga: es código de laboratorio.
//   Los tests lo instalan con `vm.etch` en una dirección de prueba y lo llaman.
//
// Cada `hex"..."` es una instrucción: el opcode y, si es un PUSH, su dato. Los literales
// seguidos se concatenan en un solo `bytes`.
library Programs {
    // PASO 1: devolver 42 como una palabra de 32 bytes.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function answer() internal pure returns (bytes memory) {
        revert("TODO: Paso 1");
        //> return hex"602a" // PUSH1 0x2a    pila: [42]
        //>     hex"5f" // PUSH0              pila: [0, 42]
        //>     hex"52" // MSTORE             memoria[0x00..0x20] = 42; pila: []
        //>     hex"6020" // PUSH1 0x20       pila: [32]
        //>     hex"5f" // PUSH0              pila: [0, 32]
        //>     hex"f3"; // RETURN            devuelve memoria[0..32]
    }

    // PASO 2: devolver el doble del primer argumento (la palabra 0 de calldata).
    function double() internal pure returns (bytes memory) {
        revert("TODO: Paso 2");
        //> return hex"5f" // PUSH0           pila: [0]
        //>     hex"35" // CALLDATALOAD       pila: [x]
        //>     hex"6002" // PUSH1 2          pila: [2, x]
        //>     hex"02" // MUL                pila: [2x]
        //>     hex"5f" // PUSH0
        //>     hex"52" // MSTORE             memoria[0x00..0x20] = 2x
        //>     hex"6020" // PUSH1 0x20
        //>     hex"5f" // PUSH0
        //>     hex"f3"; // RETURN
    }

    // PASO 3: un contador. Suma 1 al slot 0 del storage y devuelve el valor nuevo.
    function counter() internal pure returns (bytes memory) {
        revert("TODO: Paso 3");
        //> return hex"5f" // PUSH0           pila: [0]
        //>     hex"54" // SLOAD              pila: [c]
        //>     hex"6001" // PUSH1 1          pila: [1, c]
        //>     hex"01" // ADD                pila: [c+1]
        //>     hex"80" // DUP1               pila: [c+1, c+1]
        //>     hex"5f" // PUSH0              pila: [0, c+1, c+1]
        //>     hex"55" // SSTORE             storage[0] = c+1; pila: [c+1]
        //>     hex"5f" // PUSH0
        //>     hex"52" // MSTORE             memoria[0x00..0x20] = c+1
        //>     hex"6020" // PUSH1 0x20
        //>     hex"5f" // PUSH0
        //>     hex"f3"; // RETURN
    }

    // PASO 4: revertir si la llamada trae ETH; si no, devolver 1.
    // La columna de la izquierda es la posición de cada instrucción (el pc).
    function noValue() internal pure returns (bytes memory) {
        revert("TODO: Paso 4");
        //> return hex"34" // 0x00 CALLVALUE  pila: [v]
        //>     hex"600c" // 0x01 PUSH1 0x0c  pila: [0x0c, v]
        //>     hex"57" // 0x03 JUMPI         si v != 0, salta a 0x0c
        //>     hex"6001" // 0x04 PUSH1 1
        //>     hex"5f" // 0x06 PUSH0
        //>     hex"52" // 0x07 MSTORE        memoria[0x00..0x20] = 1
        //>     hex"6020" // 0x08 PUSH1 0x20
        //>     hex"5f" // 0x0a PUSH0
        //>     hex"f3" // 0x0b RETURN
        //>     hex"5b" // 0x0c JUMPDEST      único destino válido de un salto
        //>     hex"5f" // 0x0d PUSH0
        //>     hex"5f" // 0x0e PUSH0
        //>     hex"fd"; // 0x0f REVERT       revierte sin datos
    }

    // PASO 5: devolver la calldata entera, tal como llega.
    function echo() internal pure returns (bytes memory) {
        revert("TODO: Paso 5");
        //> return hex"36" // CALLDATASIZE    pila: [n]
        //>     hex"5f" // PUSH0              pila: [0, n]
        //>     hex"5f" // PUSH0              pila: [0, 0, n]
        //>     hex"37" // CALLDATACOPY       memoria[0..n] = calldata[0..n]
        //>     hex"36" // CALLDATASIZE       pila: [n]
        //>     hex"5f" // PUSH0              pila: [0, n]
        //>     hex"f3"; // RETURN            devuelve memoria[0..n]
    }
}
