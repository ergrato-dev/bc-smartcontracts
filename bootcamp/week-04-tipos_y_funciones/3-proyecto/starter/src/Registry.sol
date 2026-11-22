// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? El registro del recurso principal de tu protocolo, segunda versión: nombres
//   constantes, dueño y capacidad fijados al desplegar, y estado legible con getters.
// ¿Para qué? Que los datos que no cambian vivan en el bytecode y que cualquiera pueda leer
//   el estado sin funciones escritas a mano.
// ¿Impacto? La capacidad todavía no se hace cumplir: register() acepta recursos de más
//   (la regla llega en la semana 05).
contract Registry {
    // TODO: escribe el nombre de tu protocolo (el PROTOCOL de la semana 02), en inglés.
    string public constant PROTOCOL_NAME = "";
    // TODO: escribe el recurso principal de tu dominio, en inglés y en singular.
    string public constant RESOURCE_NAME = "";

    // ¿Qué? Quién desplegó el registro y cuántos recursos admite. Se fijan en el constructor.
    address public immutable OWNER;
    uint256 public immutable CAPACITY;

    // ¿Qué? Cuántos recursos hay y quién registró el último. `public` genera count() y
    //   lastRegistrant(): ya no hacen falta total() ni la variable `latest` de la semana 03.
    uint256 public count;
    address public lastRegistrant;

    /// @notice Crea el registro con su dueño y su capacidad.
    /// @param capacity Cuántos recursos admite el registro.
    constructor(uint256 capacity) {
        // TODO: guarda quién despliega en OWNER y `capacity` en CAPACITY.
        // Pista: dos asignaciones; quien despliega es msg.sender.
    }

    /// @notice Registra un recurso nuevo y devuelve su identificador (el primero es 1).
    // TODO: asigna a count el valor de _nextId(), guarda msg.sender en lastRegistrant y
    //   devuelve count.
    function register() external returns (uint256) {
        revert("TODO: register");
    }

    /// @notice Cuántos recursos caben todavía.
    // TODO: devuelve CAPACITY - count.
    function remaining() external view returns (uint256) {
        revert("TODO: remaining");
    }

    /// @notice Si el registro ya alcanzó su capacidad.
    // TODO: devuelve true si count es mayor o igual que CAPACITY.
    function isFull() external view returns (bool) {
        revert("TODO: isFull");
    }

    // TODO: devuelve el identificador que tendrá el próximo recurso (count + 1).
    // ¿Para qué? Una función interna: register() la usa y nadie de fuera puede llamarla.
    function _nextId() internal view returns (uint256) {
        revert("TODO: _nextId");
    }
}
