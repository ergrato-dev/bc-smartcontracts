// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Seis funciones `pure`, una por estructura de control: ternario, if/else, for,
//   do-while, continue y break.
// ¿Para qué? Practicar el control de flujo antes de usarlo para rechazar llamadas.
// ¿Impacto? Cada vuelta de un bucle gasta gas: el número de vueltas lo decide quien llama.
contract Flow {
    // PASO 1: devolver el mayor de `a` y `b` con el operador ternario.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function max(uint256 a, uint256 b) external pure returns (uint256) {
        revert("TODO: Paso 1");
        //> return a >= b ? a : b;
    }

    // PASO 2: devolver -1 si `x` es negativo, 0 si es cero y 1 si es positivo.
    function sign(int256 x) external pure returns (int8) {
        revert("TODO: Paso 2");
        //> if (x < 0) {
        //>     return -1;
        //> } else if (x == 0) {
        //>     return 0;
        //> } else {
        //>     return 1;
        //> }
    }

    // PASO 3: sumar los números de 1 a `n` con un bucle for.
    function sumTo(uint256 n) external pure returns (uint256 total) {
        revert("TODO: Paso 3");
        //> for (uint256 i = 1; i <= n; i++) {
        //>     total += i;
        //> }
    }

    // PASO 4: contar las cifras de `n` con do-while. El 0 tiene una cifra.
    function countDigits(uint256 n) external pure returns (uint256 digits) {
        revert("TODO: Paso 4");
        //> do {
        //>     digits++;
        //>     n /= 10;
        //> } while (n > 0);
    }

    // PASO 5: sumar solo los impares de 1 a `n`, saltando los pares con continue.
    function sumOdds(uint256 n) external pure returns (uint256 total) {
        revert("TODO: Paso 5");
        //> for (uint256 i = 1; i <= n; i++) {
        //>     if (i % 2 == 0) continue;
        //>     total += i;
        //> }
    }

    // PASO 6: devolver el menor divisor de `n` mayor que 1, parando con break al encontrarlo.
    // Si `n` es primo, el resultado es el propio `n`.
    function smallestDivisor(uint256 n) external pure returns (uint256 divisor) {
        revert("TODO: Paso 6");
        //> divisor = n;
        //> for (uint256 i = 2; i * i <= n; i++) {
        //>     if (n % i == 0) {
        //>         divisor = i;
        //>         break;
        //>     }
        //> }
    }
}
