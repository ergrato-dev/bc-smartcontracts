// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Una configuración con los cuatro sitios donde puede vivir un valor: una constante, un
//   valor inmutable fijado al desplegar, una variable de estado y una variable privada.
// ¿Para qué? Desplegarla con un argumento y comprobar con cast dónde queda cada valor.
// ¿Impacto? `constant` e `immutable` van dentro del bytecode, no en el storage: leerlas es
//   más barato y nadie puede cambiarlas.
contract Config {
    uint256 public constant MAX_LIMIT = 1000;
    address public immutable OWNER;
    uint256 public limit;
    uint256 private secret = 7;

    /// @notice Fija el dueño (quien despliega) y el límite inicial.
    /// @param initialLimit Límite con el que empieza la configuración.
    constructor(uint256 initialLimit) {
        OWNER = msg.sender;
        limit = initialLimit;
    }

    /// @notice Cambia el límite. Cualquiera puede llamarla: el control llega en la semana 05.
    function setLimit(uint256 newLimit) external {
        limit = newLimit;
    }
}
