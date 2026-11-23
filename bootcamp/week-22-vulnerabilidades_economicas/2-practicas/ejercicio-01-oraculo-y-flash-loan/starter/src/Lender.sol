// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// ¿Qué? Un prestamista mínimo: dejas GOV como garantía (colateral) y te presta USD hasta el
//   80 % de lo que vale, al precio que dé `price`.
// ¿Para qué? Ser el blanco del ataque. Las dos versiones solo cambian de dónde sale el precio:
//   `SpotLender` lo lee del pool y `FeedLender`, de un price feed.
// ¿Impacto? Si `price` miente, el prestamista entrega USD a cambio de un colateral que no los vale.
abstract contract Lender {
    using SafeERC20 for IERC20;

    uint256 public constant LTV_BPS = 8_000;
    IERC20 public immutable USD;
    IERC20 public immutable GOV;
    mapping(address => uint256) public collateralOf;
    mapping(address => uint256) public debtOf;

    error TooMuchDebt(uint256 debt, uint256 maxDebt);

    constructor(IERC20 usd, IERC20 gov) {
        USD = usd;
        GOV = gov;
    }

    /// @notice El precio de 1 GOV en USD, con 18 decimales.
    function price() public view virtual returns (uint256);

    /// @notice Cuánto USD se puede deber con `collateral` GOV de garantía.
    function maxDebt(uint256 collateral) public view returns (uint256) {
        return Math.mulDiv(collateral, price() * LTV_BPS, 1e18 * 10_000);
    }

    /// @notice Deja `collateral` GOV de garantía y recibe `amount` USD prestados.
    function borrow(uint256 collateral, uint256 amount) external {
        uint256 newCollateral = collateralOf[msg.sender] + collateral;
        uint256 newDebt = debtOf[msg.sender] + amount;
        uint256 max = maxDebt(newCollateral);
        if (newDebt > max) revert TooMuchDebt(newDebt, max);
        collateralOf[msg.sender] = newCollateral;
        debtOf[msg.sender] = newDebt;
        GOV.safeTransferFrom(msg.sender, address(this), collateral);
        USD.safeTransfer(msg.sender, amount);
    }
}
