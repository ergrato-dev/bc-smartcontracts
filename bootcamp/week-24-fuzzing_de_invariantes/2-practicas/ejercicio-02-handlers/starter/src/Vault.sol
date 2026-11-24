// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ¿Qué? Una bóveda de un token (semana 22): guarda lo que depositas y te da participaciones
//   proporcionales. Lo que alguien añade sin depositar (rendimiento) sube el valor de todas.
// ¿Para qué? El contrato del ejercicio 02. Sus tests unitarios pasan, con precio 1:1.
// ¿Impacto? `totalShares` tiene que ser siempre la suma de `sharesOf`: si no, las participaciones
//   de alguien valen más de lo que deberían y las de otro, menos.
contract Vault {
    using SafeERC20 for IERC20;

    IERC20 public immutable ASSET;
    uint256 public totalShares;
    mapping(address account => uint256) public sharesOf;

    error ZeroShares();

    constructor(IERC20 asset) {
        ASSET = asset;
    }

    function totalAssets() public view returns (uint256) {
        return ASSET.balanceOf(address(this));
    }

    function deposit(uint256 assets) external returns (uint256 shares) {
        shares = totalShares == 0 ? assets : assets * totalShares / totalAssets();
        if (shares == 0) revert ZeroShares();
        sharesOf[msg.sender] += shares;
        totalShares += shares;
        ASSET.safeTransferFrom(msg.sender, address(this), assets);
    }

    function withdraw(uint256 shares) external returns (uint256 assets) {
        assets = shares * totalAssets() / totalShares;
        sharesOf[msg.sender] -= shares;
        // PASO 4: se queman las participaciones, no los tokens.
        totalShares -= assets; // <- Paso 4
        //> totalShares -= shares;
        ASSET.safeTransfer(msg.sender, assets);
    }
}
