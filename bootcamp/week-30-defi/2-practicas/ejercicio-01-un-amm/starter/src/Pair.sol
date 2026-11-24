// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// ¿Qué? Un AMM de producto constante con dos tokens: quien aporta liquidez recibe LP shares
//   (este mismo contrato es su ERC-20), y quien hace un swap paga un 0,3 % que se queda en el pool.
// ¿Para qué? Ver por dentro las cuatro cuentas de un AMM: el precio con comisión, la primera
//   liquidez, la liquidez proporcional y la retirada.
// ¿Impacto? Las reservas son las que el contrato anota, no su saldo: un token enviado sin pasar
//   por aquí no cambia ningún precio.
contract Pair is ERC20 {
    using SafeERC20 for IERC20;

    /// @notice Comisión de cada swap, en puntos básicos: 30 de 10 000 son un 0,3 %.
    uint256 public constant FEE_BPS = 30;
    /// @notice LP shares de la primera liquidez que nadie puede retirar.
    uint256 public constant MINIMUM_LIQUIDITY = 1000;
    /// @notice A dónde van esas shares: una dirección sin clave conocida.
    address public constant DEAD = address(0xdead);

    IERC20 public immutable TOKEN0;
    IERC20 public immutable TOKEN1;

    uint256 public reserve0;
    uint256 public reserve1;

    event LiquidityAdded(address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidity);
    event Swapped(address indexed trader, address indexed tokenIn, uint256 amountIn, uint256 amountOut);

    error UnknownToken(address token);
    error InsufficientOutput(uint256 amountOut, uint256 minAmountOut);
    error InsufficientLiquidity();

    constructor(IERC20 token0, IERC20 token1) ERC20("Pair LP", "PLP") {
        TOKEN0 = token0;
        TOKEN1 = token1;
    }

    // PASO 1: lo que recibes por `amountIn`, con la comisión descontada de la entrada.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    /// @notice Cuánto sale del pool por `amountIn`, con reservas `reserveIn` y `reserveOut`.
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        revert("TODO: Paso 1");
        //> uint256 amountInWithFee = amountIn * (10_000 - FEE_BPS);
        //> return amountInWithFee * reserveOut / (reserveIn * 10_000 + amountInWithFee);
    }

    /// @notice Aporta `amount0` y `amount1` y recibe LP shares. Hay que aprobar los dos antes.
    function addLiquidity(uint256 amount0, uint256 amount1) external returns (uint256 liquidity) {
        uint256 supply = totalSupply();
        if (supply == 0) {
            liquidity = _firstLiquidity(amount0, amount1);
        } else {
            liquidity = _nextLiquidity(amount0, amount1, supply);
        }
        if (liquidity == 0) revert InsufficientLiquidity();

        reserve0 += amount0;
        reserve1 += amount1;
        _mint(msg.sender, liquidity);
        emit LiquidityAdded(msg.sender, amount0, amount1, liquidity);

        TOKEN0.safeTransferFrom(msg.sender, address(this), amount0);
        TOKEN1.safeTransferFrom(msg.sender, address(this), amount1);
    }

    // PASO 2: la primera liquidez fija el precio y el tamaño de una share.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function _firstLiquidity(uint256 amount0, uint256 amount1) internal returns (uint256) {
        revert("TODO: Paso 2");
        //> uint256 root = Math.sqrt(amount0 * amount1);
        //> if (root <= MINIMUM_LIQUIDITY) revert InsufficientLiquidity();
        //> _mint(DEAD, MINIMUM_LIQUIDITY);
        //> return root - MINIMUM_LIQUIDITY;
    }

    // PASO 3: después, las shares son proporcionales a lo que aportas, por el token más escaso.
    // Borra la línea del revert y descomenta la línea que empieza con `//> `.
    function _nextLiquidity(uint256 amount0, uint256 amount1, uint256 supply) internal view returns (uint256) {
        revert("TODO: Paso 3");
        //> return Math.min(amount0 * supply / reserve0, amount1 * supply / reserve1);
    }

    // PASO 4: el swap, con un mínimo a recibir.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    /// @notice Cambia `amountIn` de `tokenIn` por el otro token; revierte si recibes menos de `minAmountOut`.
    function swap(IERC20 tokenIn, uint256 amountIn, uint256 minAmountOut) external returns (uint256 amountOut) {
        revert("TODO: Paso 4");
        //> bool zeroForOne = address(tokenIn) == address(TOKEN0);
        //> if (!zeroForOne && address(tokenIn) != address(TOKEN1)) revert UnknownToken(address(tokenIn));
        //> (uint256 reserveIn, uint256 reserveOut) = zeroForOne ? (reserve0, reserve1) : (reserve1, reserve0);
        //> amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        //> if (amountOut < minAmountOut) revert InsufficientOutput(amountOut, minAmountOut);
        //> if (zeroForOne) {
        //>     (reserve0, reserve1) = (reserve0 + amountIn, reserve1 - amountOut);
        //> } else {
        //>     (reserve0, reserve1) = (reserve0 - amountOut, reserve1 + amountIn);
        //> }
        //> emit Swapped(msg.sender, address(tokenIn), amountIn, amountOut);
        //> tokenIn.safeTransferFrom(msg.sender, address(this), amountIn);
        //> (zeroForOne ? TOKEN1 : TOKEN0).safeTransfer(msg.sender, amountOut);
    }

    // PASO 5: retirar se lleva la parte de cada reserva que corresponde a tus shares.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    /// @notice Quema `liquidity` LP shares y devuelve tu parte de las dos reservas.
    function removeLiquidity(uint256 liquidity) external returns (uint256 amount0, uint256 amount1) {
        revert("TODO: Paso 5");
        //> uint256 supply = totalSupply();
        //> amount0 = liquidity * reserve0 / supply;
        //> amount1 = liquidity * reserve1 / supply;
        //> _burn(msg.sender, liquidity);
        //> reserve0 -= amount0;
        //> reserve1 -= amount1;
        //> emit LiquidityRemoved(msg.sender, amount0, amount1, liquidity);
        //> TOKEN0.safeTransfer(msg.sender, amount0);
        //> TOKEN1.safeTransfer(msg.sender, amount1);
    }
}
