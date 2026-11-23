// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ¿Qué? Un pool mínimo de dos tokens, USD y GOV, que cambia uno por otro con la fórmula de
//   producto constante (reserveUsd * reserveGov no baja), sin comisión.
// ¿Para qué? Ser el "oráculo" ingenuo del ejercicio: su precio sale de sus reservas, y las
//   reservas las mueve cualquiera que haga un swap. La semana 30 construye un AMM de verdad.
// ¿Impacto? Quien mete mucho USD de golpe sube el precio de GOV tanto como quiera.
contract Pool {
    using SafeERC20 for IERC20;

    IERC20 public immutable USD;
    IERC20 public immutable GOV;
    uint256 public reserveUsd;
    uint256 public reserveGov;

    error UnknownToken(address token);

    constructor(IERC20 usd, IERC20 gov) {
        USD = usd;
        GOV = gov;
    }

    /// @notice Deposita los dos tokens en el pool. Antes hay que aprobarlos.
    function addLiquidity(uint256 usdAmount, uint256 govAmount) external {
        reserveUsd += usdAmount;
        reserveGov += govAmount;
        USD.safeTransferFrom(msg.sender, address(this), usdAmount);
        GOV.safeTransferFrom(msg.sender, address(this), govAmount);
    }

    /// @notice El precio de 1 GOV en USD, con 18 decimales, según las reservas de ahora.
    // PASO 1: el precio al contado.
    // Borra la línea del revert y descomenta la línea que empieza con `//> `.
    function spotPrice() public view returns (uint256) {
        revert("TODO: Paso 1");
        //> return reserveUsd * 1e18 / reserveGov;
    }

    /// @notice Cambia `amountIn` de `tokenIn` por el otro token. Antes hay que aprobar `tokenIn`.
    /// @return amountOut Lo que recibes: lo que deja `reserveUsd * reserveGov` igual o mayor.
    function swap(IERC20 tokenIn, uint256 amountIn) external returns (uint256 amountOut) {
        if (address(tokenIn) == address(USD)) {
            amountOut = reserveGov * amountIn / (reserveUsd + amountIn);
            reserveUsd += amountIn;
            reserveGov -= amountOut;
            USD.safeTransferFrom(msg.sender, address(this), amountIn);
            GOV.safeTransfer(msg.sender, amountOut);
        } else if (address(tokenIn) == address(GOV)) {
            amountOut = reserveUsd * amountIn / (reserveGov + amountIn);
            reserveGov += amountIn;
            reserveUsd -= amountOut;
            GOV.safeTransferFrom(msg.sender, address(this), amountIn);
            USD.safeTransfer(msg.sender, amountOut);
        } else {
            revert UnknownToken(address(tokenIn));
        }
    }
}
