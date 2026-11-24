// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title La representación en L2 de un token de L1
/// @notice Cada unidad está respaldada por una bloqueada en el puente de L1. Solo el puente de L2
///         acuña (al llegar un depósito) y quema (al salir una retirada).
contract BridgedToken is ERC20 {
    address public immutable bridge;

    error NotBridge(address caller);

    constructor(address bridge_) ERC20("Puntos en L2", "L2PTS") {
        bridge = bridge_;
    }

    // PASO 1: acuñar y quemar, solo el puente.
    modifier onlyBridge() {
        revert("TODO: Paso 1");
        //> if (msg.sender != bridge) revert NotBridge(msg.sender);
        _;
    }

    /// @notice Acuña `amount` para `to`. Solo el puente.
    function mint(address to, uint256 amount) external onlyBridge {
        _mint(to, amount);
    }

    /// @notice Quema `amount` de `from`. Solo el puente.
    function burn(address from, uint256 amount) external onlyBridge {
        _burn(from, amount);
    }
}
