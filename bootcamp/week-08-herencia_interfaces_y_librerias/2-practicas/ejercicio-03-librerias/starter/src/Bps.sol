// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Porcentajes en puntos básicos (basis points): 10 000 es el 100 % y 2 500, el 25 %.
// ¿Para qué? Repartir importes en wei, que son enteros, sin decimales.
// ¿Impacto? La división entera redondea hacia abajo: el orden de las operaciones decide
//   cuánto se pierde por el camino.
library Bps {
    uint256 internal constant MAX = 10_000;

    // PASO 1: la parte de `amount` que corresponde a `rate` puntos básicos.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function bps(uint256 amount, uint256 rate) internal pure returns (uint256) {
        revert("TODO: Paso 1");
        //> return amount * rate / MAX;
    }
}
