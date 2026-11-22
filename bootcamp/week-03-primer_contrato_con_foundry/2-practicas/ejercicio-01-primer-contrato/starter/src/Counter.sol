// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un contador: guarda un número en la cadena, lo lee y lo cambia.
// ¿Para qué? Ver en el contrato más pequeño posible las tres cosas que hace todo contrato:
//   guardar estado, leerlo y cambiarlo con una transacción.
contract Counter {
    // PASO 2: declarar la variable de estado `number` (un entero sin signo de 256 bits).
    // Descomenta la línea que empieza con `//> `.
    //> uint256 number;

    // PASO 6: declarar la variable de estado `lastCaller` (una dirección).
    //> address lastCaller;

    // PASO 1: devolver siempre 42, como el contrato de bytecode de la semana 02.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function answer() external pure returns (uint256) {
        revert("TODO: Paso 1");
        //> return 42;
    }

    // PASO 2: devolver el valor guardado en `number`.
    function get() external view returns (uint256) {
        revert("TODO: Paso 2");
        //> return number;
    }

    // PASO 3: sumar 1 a `number`.
    function increment() external {
        revert("TODO: Paso 3");
        //> number += 1;
    }

    // PASO 4: guardar `newNumber` en `number`.
    function set(uint256 newNumber) external {
        revert("TODO: Paso 4");
        //> number = newNumber;
    }

    // PASO 5: devolver a + b sin leer ni escribir estado.
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        revert("TODO: Paso 5");
        //> return a + b;
    }

    // PASO 6: guardar quién llamó y devolverlo.
    function touch() external {
        revert("TODO: Paso 6");
        //> lastCaller = msg.sender;
    }

    function getLastCaller() external view returns (address) {
        revert("TODO: Paso 6");
        //> return lastCaller;
    }
}
