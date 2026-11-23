// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// ¿Qué? Un ERC-20 de prueba que cualquiera puede emitir.
// ¿Impacto? Solo para los tests: nunca en una red real.
contract Token is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /// @notice Crea `amount` tokens para `to`.
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
