// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Una función por tipo de valor: enteros con y sin signo, booleanos, conversiones,
//   bytes de tamaño fijo y direcciones.
// ¿Para qué? Ver cada tipo con su rango y sus trampas antes de usarlos en el protocolo.
// ¿Impacto? Ninguna función lee ni escribe estado: todas son `pure`.
contract Types {
    // PASO 1: devolver el mayor valor que cabe en un uint8.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function maxUint8() external pure returns (uint8) {
        revert("TODO: Paso 1");
        //> return type(uint8).max;
    }

    // PASO 2: devolver el menor valor que cabe en un int8 (entero con signo).
    function minInt8() external pure returns (int8) {
        revert("TODO: Paso 2");
        //> return type(int8).min;
    }

    // PASO 3: devolver true si `age` es 18 o más.
    function isAdult(uint256 age) external pure returns (bool) {
        revert("TODO: Paso 3");
        //> return age >= 18;
    }

    // PASO 4: convertir un uint256 a uint8. Si no cabe, se pierden los bits altos.
    function toUint8(uint256 value) external pure returns (uint8) {
        revert("TODO: Paso 4");
        //> return uint8(value);
    }

    // PASO 5: calcular el selector de una firma: los 4 primeros bytes de su keccak256.
    function selectorOf(string memory signature) external pure returns (bytes4) {
        revert("TODO: Paso 5");
        //> return bytes4(keccak256(bytes(signature)));
    }

    // PASO 6: devolver true si `account` es la dirección cero.
    function isZeroAddress(address account) external pure returns (bool) {
        revert("TODO: Paso 6");
        //> return account == address(0);
    }
}
