// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

// ¿Qué? Puntos de un club con ERC-2612: además de `approve`, aceptan un `permit` firmado.
// ¿Para qué? Que quien tiene puntos autorice un gasto firmando fuera de la cadena, sin una
//   transacción `approve` aparte.
// ¿Impacto? ERC20Permit trae su dominio EIP-712 (nombre del token y versión "1") y sus
//   nonces: cada `permit` gasta uno, así que una firma de permit vale una sola vez.
contract PointsToken is ERC20, ERC20Permit {
    /// @param supply Puntos que recibe quien despliega.
    constructor(uint256 supply) ERC20("Club Points", "CPT") ERC20Permit("Club Points") {
        _mint(msg.sender, supply);
    }
}
