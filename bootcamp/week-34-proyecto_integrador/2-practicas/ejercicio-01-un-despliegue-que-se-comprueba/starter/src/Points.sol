// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

/// @title Los puntos de la tienda
/// @notice Un ERC-20 que solo acuña quien tiene MINTER_ROLE: la tienda, en cada compra.
/// @dev ¿Qué? AccessControlEnumerable y no AccessControl.
///   ¿Para qué? Poder contar quién tiene cada rol: un despliegue se comprueba también por lo que no
///   debería estar (una cuenta de pruebas que se quedó de minter).
contract Points is ERC20, AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Points", "PTS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Acuña `amount` puntos para `to`. Solo MINTER_ROLE.
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
