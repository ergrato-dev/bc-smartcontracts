// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Cuatro funciones de aritmética con el cuerpo en assembly (Yul dentro de Solidity).
// ¿Para qué? Practicar la sintaxis de Yul (`let`, `:=`, `if`, `for`, funciones) y ver qué deja de
//   hacer solc por ti cuando escribes assembly: comprobar desbordamientos y el signo.
// ¿Impacto? Ninguno fuera del ejercicio: es una biblioteca de prueba, no la uses en producción.
contract MathAsm {
    /// @notice `a + b` sin comprobar desbordamiento, como hace `add` de la EVM.
    function addUnchecked(uint256 a, uint256 b) external pure returns (uint256 c) {
        // PASO 1: sumar con el opcode `add`.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 1");
        //> assembly {
        //>     c := add(a, b)
        //> }
    }

    /// @notice `a + b`; si se desborda, revierte con `Panic(0x11)`, como `a + b` en Solidity.
    function addChecked(uint256 a, uint256 b) external pure returns (uint256 c) {
        // PASO 2: sumar y, si el resultado es menor que `a`, revertir con el mismo error que solc.
        revert("TODO: Paso 2");
        //> assembly {
        //>     c := add(a, b)
        //>     if lt(c, a) {
        //>         // Panic(uint256): el selector 0x4e487b71 en los 4 primeros bytes y el código
        //>         //   0x11 (desbordamiento aritmético) en la palabra siguiente.
        //>         mstore(0, shl(224, 0x4e487b71))
        //>         mstore(4, 0x11)
        //>         revert(0, 0x24)
        //>     }
        //> }
    }

    /// @notice -1, 0 o 1 según el signo de `x`.
    function sign(int256 x) external pure returns (int256 s) {
        // PASO 3: comparar con signo. `sgt` y `slt` leen la palabra en complemento a dos.
        revert("TODO: Paso 3");
        //> assembly {
        //>     s := sub(sgt(x, 0), slt(x, 0))
        //> }
    }

    /// @notice La suma de `xs`; revierte con `Panic(0x11)` si se desborda.
    function sum(uint256[] calldata xs) external pure returns (uint256 total) {
        // PASO 4: recorrer la calldata con `for` y sumar con una función de Yul que comprueba.
        revert("TODO: Paso 4");
        //> assembly {
        //>     function checkedAdd(a, b) -> c {
        //>         c := add(a, b)
        //>         if lt(c, a) {
        //>             mstore(0, shl(224, 0x4e487b71))
        //>             mstore(4, 0x11)
        //>             revert(0, 0x24)
        //>         }
        //>     }
        //>     for { let i := 0 } lt(i, xs.length) { i := add(i, 1) } {
        //>         // El elemento `i` está `i * 32` bytes después del primero: `shl(5, i)` es `i * 32`.
        //>         total := checkedAdd(total, calldataload(add(xs.offset, shl(5, i))))
        //>     }
        //> }
    }
}
