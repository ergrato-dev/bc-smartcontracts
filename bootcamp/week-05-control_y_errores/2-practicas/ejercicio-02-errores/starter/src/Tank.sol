// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un depósito con nivel y capacidad. Cada función rechaza lo que no tiene sentido con
//   una forma distinta de revertir.
// ¿Para qué? Comparar require, revert, errores personalizados, assert y unchecked.
// ¿Impacto? Una llamada rechazada no cambia nada del estado, pero sí paga el gas gastado.
contract Tank {
    uint256 public constant CAPACITY = 100;

    uint256 public level;
    uint256 public alarm;

    // ¿Qué? Errores personalizados: nombre y datos de cada fallo, declarados una vez.
    error InsufficientLevel(uint256 available, uint256 requested);
    error InvalidAlarm(uint256 alarm);
    error AlreadyEmpty();

    // PASO 1: rechazar con require y un mensaje si el nivel pasaría de CAPACITY.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function fill(uint256 amount) external {
        revert("TODO: Paso 1");
        //> require(level + amount <= CAPACITY, "tank overflow");
        //> level += amount;
    }

    // PASO 2: rechazar con el error InsufficientLevel si no hay nivel suficiente.
    function drain(uint256 amount) external {
        revert("TODO: Paso 2");
        //> if (amount > level) revert InsufficientLevel(level, amount);
        //> level -= amount;
    }

    // PASO 3: require con un error personalizado: la alarma no puede superar CAPACITY.
    function setAlarm(uint256 newAlarm) external {
        revert("TODO: Paso 3");
        //> require(newAlarm <= CAPACITY, InvalidAlarm(newAlarm));
        //> alarm = newAlarm;
    }

    // PASO 4: vaciar el depósito; si ya está vacío, revertir con AlreadyEmpty.
    function empty() external {
        revert("TODO: Paso 4");
        //> if (level == 0) revert AlreadyEmpty();
        //> level = 0;
    }

    // PASO 5: devolver la capacidad libre. Antes, assert del invariante: el nivel nunca
    // supera la capacidad. Si falla, hay un error en el propio contrato.
    function freeSpace() external view returns (uint256) {
        revert("TODO: Paso 5");
        //> assert(level <= CAPACITY);
        //> return CAPACITY - level;
    }

    // PASO 6: sumar dos uint8 sin comprobar el desbordamiento, dentro de unchecked.
    function wrappingAdd(uint8 a, uint8 b) external pure returns (uint8) {
        revert("TODO: Paso 6");
        //> unchecked {
        //>     return a + b;
        //> }
    }
}
