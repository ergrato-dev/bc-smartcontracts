// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Vault} from "./Vault.sol";

// ¿Qué? La bóveda con participaciones virtuales: calcula la proporción como si siempre hubiera
//   VIRTUAL_SHARES participaciones y 1 token más de los que hay, que no son de nadie.
// ¿Para qué? Que nadie pueda fijar la proporción con un depósito diminuto y una donación: la
//   donación se reparte también con las participaciones virtuales, y el atacante pierde.
// ¿Impacto? Cada token da 1000 participaciones, y una parte mínima de cada ganancia se queda
//   para siempre en la bóveda. Es lo que hace ERC4626 de OpenZeppelin con `_decimalsOffset`.
contract VirtualVault is Vault {
    uint256 public constant VIRTUAL_SHARES = 1e3;

    constructor(IERC20 asset) Vault(asset) {}

    // PASO 4: la proporción con la parte virtual.
    // Borra la línea del revert y descomenta la línea que empieza con `//> `.
    function _totals() internal view override returns (uint256 shares, uint256 assets) {
        revert("TODO: Paso 4");
        //> return (totalShares + VIRTUAL_SHARES, totalAssets() + 1);
    }
}
