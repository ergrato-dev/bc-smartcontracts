// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Una caja que guarda un número que solo su dueño puede cambiar.
// ¿Para qué? Tener algo pequeño que desplegar con un script: un constructor con argumento y
//   una función que exige una transacción del dueño.
// ¿Impacto? El dueño es `immutable`: queda escrito en el código desplegado (lo verás en el
//   ejercicio 03).
contract Box {
    /// @notice Quien puede cambiar el número.
    address public immutable OWNER;
    /// @notice El número guardado.
    uint256 public value;

    error NotOwner(address caller);

    constructor(address owner) {
        OWNER = owner;
    }

    /// @notice Guarda un número nuevo.
    /// @param newValue El número.
    function store(uint256 newValue) external {
        if (msg.sender != OWNER) revert NotOwner(msg.sender);
        value = newValue;
    }
}
