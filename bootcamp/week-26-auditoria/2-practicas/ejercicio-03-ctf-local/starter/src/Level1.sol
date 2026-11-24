// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

/// @title Nivel 1 — Caja fuerte
/// @notice ¿Qué? Una caja fuerte con dueño: solo el dueño retira su ETH.
contract Safe {
    address public owner;
    bool private initialized;

    error AlreadyInitialized();
    error NotOwner();
    error TransferFailed();

    /// @notice Fija el dueño. Pensada para llamarse una sola vez, justo después de desplegar.
    function initialize(address newOwner) external {
        if (initialized) revert AlreadyInitialized();
        owner = newOwner;
    }

    /// @notice El dueño retira todo el ETH a `to`.
    function withdraw(address payable to) external {
        if (msg.sender != owner) revert NotOwner();
        (bool ok,) = to.call{value: address(this).balance}("");
        if (!ok) revert TransferFailed();
    }

    receive() external payable {}
}

/// @notice ¿Qué? Despliega el nivel: una caja fuerte con 10 ETH cuyo dueño es este contrato.
/// @dev ¿Para qué? `isSolved` es la condición de victoria: la caja vacía.
contract Level1Setup {
    Safe public immutable SAFE;

    constructor() payable {
        SAFE = new Safe();
        SAFE.initialize(address(this));
        (bool ok,) = address(SAFE).call{value: msg.value}("");
        require(ok, "fund");
    }

    function isSolved() external view returns (bool) {
        return address(SAFE).balance == 0;
    }
}
