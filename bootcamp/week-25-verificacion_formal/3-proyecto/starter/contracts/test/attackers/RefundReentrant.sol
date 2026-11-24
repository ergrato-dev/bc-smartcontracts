// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Registry} from "../../src/Registry.sol";

// ¿Qué? Un registrante que es un contrato: paga dos tasas por un alta y, cuando el registro le
//   devuelve lo que sobra, usa esa devolución para volver a entrar en `register`.
// ¿Para qué? Comprobar que devolver el exceso no abre una reentrancy: la segunda alta paga su
//   tasa entera, y el registro acaba con las dos tasas, ni un wei menos.
contract RefundReentrant {
    Registry public immutable REGISTRY;
    /// @notice El id del alta que hizo desde `receive`.
    uint256 public secondId;

    constructor(Registry registry) {
        REGISTRY = registry;
    }

    /// @notice Da de alta "uno" con todo lo que envías, aunque sea más que la tasa.
    function attack() external payable returns (uint256) {
        return REGISTRY.register{value: msg.value}("uno");
    }

    receive() external payable {
        if (secondId == 0) secondId = REGISTRY.register{value: msg.value}("dos");
    }
}
