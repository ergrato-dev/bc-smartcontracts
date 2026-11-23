// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ¿Qué? El pool de producto constante del ejercicio 01, con las dos defensas del swap frente
//   a quien ordena las transacciones: un mínimo a recibir y un plazo.
// ¿Para qué? Que tu swap revierta si alguien mueve el precio antes que tú (sándwich) o si la
//   transacción espera en la mempool hasta que ya no te conviene.
// ¿Impacto? Sin ellas, el swap acepta cualquier precio en cualquier momento.
contract Pool {
    using SafeERC20 for IERC20;

    IERC20 public immutable USD;
    IERC20 public immutable GOV;
    uint256 public reserveUsd;
    uint256 public reserveGov;

    error UnknownToken(address token);
    error InsufficientOutput(uint256 amountOut, uint256 minAmountOut);
    error Expired(uint256 deadline);

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

    /// @notice Lo que daría hoy un swap de `amountIn` de `tokenIn`.
    function quote(IERC20 tokenIn, uint256 amountIn) public view returns (uint256) {
        if (address(tokenIn) == address(USD)) return reserveGov * amountIn / (reserveUsd + amountIn);
        if (address(tokenIn) == address(GOV)) return reserveUsd * amountIn / (reserveGov + amountIn);
        revert UnknownToken(address(tokenIn));
    }

    /// @notice Cambia `amountIn` de `tokenIn` por el otro token. Antes hay que aprobar `tokenIn`.
    /// @param minAmountOut Lo mínimo que aceptas recibir; si sale menos, revierte.
    /// @param deadline Último timestamp en el que vale el swap.
    function swap(IERC20 tokenIn, uint256 amountIn, uint256 minAmountOut, uint256 deadline)
        external
        returns (uint256 amountOut)
    {
        // PASO 3: el plazo. Descomenta las líneas que empiezan con `//> `.
        //> // Un validador mueve el timestamp unos segundos: con plazos de minutos da igual.
        //> // forge-lint: disable-next-line(block-timestamp)
        //> if (block.timestamp > deadline) revert Expired(deadline);
        amountOut = quote(tokenIn, amountIn);
        // PASO 2: el mínimo a recibir. Descomenta la línea que empieza con `//> `.
        //> if (amountOut < minAmountOut) revert InsufficientOutput(amountOut, minAmountOut);
        (IERC20 tokenOut, bool usdIn) = address(tokenIn) == address(USD) ? (GOV, true) : (USD, false);
        if (usdIn) {
            reserveUsd += amountIn;
            reserveGov -= amountOut;
        } else {
            reserveGov += amountIn;
            reserveUsd -= amountOut;
        }
        tokenIn.safeTransferFrom(msg.sender, address(this), amountIn);
        tokenOut.safeTransfer(msg.sender, amountOut);
    }
}
