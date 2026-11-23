// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Registry} from "../../src/Registry.sol";

// ¿Qué? Un cebo para el administrador: si lo llama, intenta darse DEFAULT_ADMIN_ROLE en el
//   registro dentro de esa misma transacción.
// ¿Para qué? Comprobar que el registro autoriza con `msg.sender` (AccessControl) y no con
//   `tx.origin`: que el administrador firme la transacción no basta.
contract Phisher {
    Registry public immutable REGISTRY;
    address public immutable THIEF;
    /// @notice El error con el que el registro rechazó el intento.
    bytes public lastError;

    constructor(Registry registry) {
        REGISTRY = registry;
        THIEF = msg.sender;
    }

    /// @notice El cebo.
    function claimPrize() external {
        try REGISTRY.grantRole(REGISTRY.DEFAULT_ADMIN_ROLE(), THIEF) {}
        catch (bytes memory reason) {
            lastError = reason;
        }
    }
}
