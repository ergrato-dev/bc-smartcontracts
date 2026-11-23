// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Registry} from "../../src/Registry.sol";

// ¿Qué? Un tesorero que es un contrato y, al cobrar las tasas, vuelve a llamar a `withdrawFees`.
// ¿Para qué? Comprobar que `withdrawFees` sigue checks-effects-interactions: la segunda
//   entrada no encuentra nada que cobrar, aunque quien entra tenga TREASURER_ROLE.
contract ReentrantTreasury {
    Registry public immutable REGISTRY;
    /// @notice Todo el ETH que ha recibido, sumando cada entrada.
    uint256 public received;
    /// @notice El error con el que revirtió la segunda entrada.
    bytes public reentryError;

    constructor(Registry registry) {
        REGISTRY = registry;
    }

    /// @notice Cobra las tasas del registro hacia este contrato.
    function attack() external {
        REGISTRY.withdrawFees(payable(address(this)));
    }

    receive() external payable {
        // TODO: suma `msg.value` a `received`. Después vuelve a llamar a
        //   `REGISTRY.withdrawFees(payable(address(this)))` dentro de un `try`, y en el
        //   `catch (bytes memory reason)` guarda `reason` en `reentryError`. Sin el `try`, el
        //   error de la segunda entrada revertiría también la primera.
        revert("TODO: ReentrantTreasury");
    }
}
