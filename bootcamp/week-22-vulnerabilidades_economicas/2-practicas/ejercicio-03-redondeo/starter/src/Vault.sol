// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// ¿Qué? Una bóveda (vault) mínima: depositas un token y recibes participaciones (shares) que
//   dan derecho a una parte proporcional de todo lo que hay dentro. Si la bóveda gana tokens,
//   cada participación vale más.
// ¿Para qué? Ver dónde redondea una división entera y a favor de quién. La semana 30 estudia
//   el estándar de estas bóvedas, ERC-4626.
// ¿Impacto? Cada conversión entre tokens y participaciones pierde decimales. Si los pierde a
//   favor de quien llama, se puede repetir hasta vaciar la bóveda; si alguien controla la
//   proporción, se queda con lo que otros depositan.
contract Vault {
    using SafeERC20 for IERC20;

    IERC20 public immutable ASSET;
    uint256 public totalShares;
    mapping(address => uint256) public sharesOf;

    error ZeroShares();
    error InsufficientShares(uint256 balance, uint256 needed);

    constructor(IERC20 asset) {
        ASSET = asset;
    }

    /// @notice Todos los tokens de la bóveda, también los que alguien envió sin depositar.
    function totalAssets() public view returns (uint256) {
        return ASSET.balanceOf(address(this));
    }

    /// @notice Cuántas participaciones da un depósito de `assets` tokens, redondeando hacia abajo.
    // PASO 1: las dos conversiones, multiplicando antes de dividir y redondeando hacia abajo.
    // Borra las líneas del revert y descomenta las líneas que empiezan con `//> `.
    function convertToShares(uint256 assets) public view returns (uint256) {
        revert("TODO: Paso 1");
        //> (uint256 shares, uint256 total) = _totals();
        //> if (shares == 0) return assets;
        //> return Math.mulDiv(assets, shares, total);
    }

    /// @notice Cuántos tokens valen `shares` participaciones, redondeando hacia abajo.
    function convertToAssets(uint256 shares) public view returns (uint256) {
        revert("TODO: Paso 1");
        //> (uint256 supply, uint256 total) = _totals();
        //> if (supply == 0) return shares;
        //> return Math.mulDiv(shares, total, supply);
    }

    /// @notice Cuántas participaciones cuesta sacar exactamente `assets` tokens, redondeando hacia arriba.
    // PASO 2: lo que paga quien retira se redondea hacia arriba.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function previewWithdraw(uint256 assets) public view returns (uint256) {
        revert("TODO: Paso 2");
        //> (uint256 shares, uint256 total) = _totals();
        //> if (shares == 0) return assets;
        //> return Math.mulDiv(assets, shares, total, Math.Rounding.Ceil);
    }

    /// @notice Deposita `assets` tokens y recibe sus participaciones. Antes hay que aprobarlos.
    function deposit(uint256 assets) external returns (uint256 shares) {
        shares = convertToShares(assets);
        // PASO 3: un depósito que no da participaciones es un regalo. Descomenta la línea.
        //> if (shares == 0) revert ZeroShares();
        totalShares += shares;
        sharesOf[msg.sender] += shares;
        ASSET.safeTransferFrom(msg.sender, address(this), assets);
    }

    /// @notice Quema `shares` participaciones y recibe los tokens que valen.
    function redeem(uint256 shares) external returns (uint256 assets) {
        assets = convertToAssets(shares);
        _burn(msg.sender, shares);
        ASSET.safeTransfer(msg.sender, assets);
    }

    /// @notice Saca exactamente `assets` tokens y quema las participaciones que cuestan.
    function withdraw(uint256 assets) external returns (uint256 shares) {
        shares = previewWithdraw(assets);
        _burn(msg.sender, shares);
        ASSET.safeTransfer(msg.sender, assets);
    }

    // Las participaciones y los tokens con que se calcula la proporción. VirtualVault les suma
    // una parte virtual.
    function _totals() internal view virtual returns (uint256 shares, uint256 assets) {
        return (totalShares, totalAssets());
    }

    function _burn(address from, uint256 shares) internal {
        uint256 balance = sharesOf[from];
        if (balance < shares) revert InsufficientShares(balance, shares);
        sharesOf[from] = balance - shares;
        totalShares -= shares;
    }
}
