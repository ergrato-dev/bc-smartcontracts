// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// ¿Qué? Un vault ERC-4626 de OpenZeppelin con una comisión de salida del 1 % que se queda dentro
//   (la reparten quienes siguen) y un tope de depósitos.
// ¿Para qué? Ver qué funciones del estándar hay que cambiar a la vez para que una comisión y un
//   tope no rompan lo que el estándar promete: que `preview*` dé lo que hará la llamada y que
//   `max*` dé un importe que la llamada acepte.
// ¿Impacto? Cada paso cambia una línea, y cada una redondea a favor del vault.
contract FeeVault is ERC4626 {
    using Math for uint256;

    /// @notice Comisión de salida, en puntos básicos sobre lo que recibes: 100 son un 1 %.
    uint256 public constant EXIT_FEE_BPS = 100;
    /// @notice Máximo de activos que puede guardar el vault.
    uint256 public immutable CAP;

    constructor(IERC20 asset_, uint256 cap) ERC20("Fee Vault", "fvTKN") ERC4626(asset_) {
        CAP = cap;
    }

    // PASO 1: shares virtuales contra el ataque de inflación (semana 22).
    // Cada paso sustituye: borra la línea que acaba en `// <- Paso N` y descomenta la de debajo.
    function _decimalsOffset() internal pure override returns (uint8) {
        return 0; // <- Paso 1
        //> return 3;
    }

    // PASO 2: al canjear shares, lo que recibes es su valor menos la comisión.
    /// @notice Lo que recibe quien canjea `shares`, con la comisión ya descontada.
    function previewRedeem(uint256 shares) public view override returns (uint256) {
        uint256 assets = super.previewRedeem(shares);
        return assets; // <- Paso 2
        //> return assets - assets.mulDiv(EXIT_FEE_BPS, EXIT_FEE_BPS + 10_000, Math.Rounding.Ceil);
    }

    // PASO 3: al retirar un importe, se queman las shares de ese importe más la comisión.
    /// @notice Las shares que se queman para que recibas `assets`, con la comisión.
    function previewWithdraw(uint256 assets) public view override returns (uint256) {
        return super.previewWithdraw(assets); // <- Paso 3
        //> uint256 fee = assets.mulDiv(EXIT_FEE_BPS, 10_000, Math.Rounding.Ceil);
        //> return super.previewWithdraw(assets + fee);
    }

    // PASO 4: el tope, en las dos funciones que dicen cuánto cabe.
    /// @notice El mayor importe que se puede depositar ahora.
    function maxDeposit(address) public view override returns (uint256) {
        return type(uint256).max; // <- Paso 4
        //> uint256 assets = totalAssets();
        //> return assets >= CAP ? 0 : CAP - assets;
    }

    /// @notice El mayor número de shares que se puede emitir con `mint` ahora.
    function maxMint(address receiver) public view override returns (uint256) {
        return type(uint256).max; // <- Paso 4
        //> return _convertToShares(maxDeposit(receiver), Math.Rounding.Floor);
    }
}
