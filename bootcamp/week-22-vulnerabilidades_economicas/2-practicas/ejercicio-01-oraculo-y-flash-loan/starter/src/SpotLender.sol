// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Lender} from "./Lender.sol";
import {Pool} from "./Pool.sol";

// ¿Qué? El prestamista que valora el colateral con el precio al contado del pool.
// ¿Para qué? Ser el blanco del ataque. **No lo arregles**: los tests lo necesitan roto.
// ¿Impacto? Quien mueve las reservas del pool en la misma transacción decide cuánto le prestan.
contract SpotLender is Lender {
    Pool public immutable POOL;

    constructor(IERC20 usd, IERC20 gov, Pool pool) Lender(usd, gov) {
        POOL = pool;
    }

    /// @inheritdoc Lender
    function price() public view override returns (uint256) {
        return POOL.spotPrice();
    }
}
