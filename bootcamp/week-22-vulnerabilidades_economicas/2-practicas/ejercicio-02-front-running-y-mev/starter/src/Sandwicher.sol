// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pool} from "./Pool.sol";

// ¿Qué? El atacante de un sándwich: ve en la mempool la compra de GOV de otra cuenta, compra
//   antes (`frontRun`) para subir el precio y vende justo después (`backRun`) para quedarse
//   con la diferencia.
// ¿Para qué? Ver que quien elige el orden de las transacciones gana con tu swap si aceptas
//   cualquier precio.
contract Sandwicher {
    using SafeERC20 for IERC20;

    Pool public immutable POOL;
    IERC20 public immutable USD;
    IERC20 public immutable GOV;

    constructor(Pool pool) {
        POOL = pool;
        USD = pool.USD();
        GOV = pool.GOV();
    }

    /// @notice Antes de la víctima: compra GOV con todo su USD.
    // PASO 1: las dos mitades del sándwich.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function frontRun() external {
        revert("TODO: Paso 1");
        //> uint256 amount = USD.balanceOf(address(this));
        //> USD.forceApprove(address(POOL), amount);
        //> // Va en la misma tanda que la víctima: no necesita mínimo ni plazo.
        //> POOL.swap(USD, amount, 0, type(uint256).max);
    }

    /// @notice Después de la víctima: vende todo su GOV.
    function backRun() external {
        revert("TODO: Paso 1");
        //> uint256 amount = GOV.balanceOf(address(this));
        //> GOV.forceApprove(address(POOL), amount);
        //> POOL.swap(GOV, amount, 0, type(uint256).max);
    }
}
