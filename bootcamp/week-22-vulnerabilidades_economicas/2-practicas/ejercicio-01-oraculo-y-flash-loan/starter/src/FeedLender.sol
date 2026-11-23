// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Lender} from "./Lender.sol";

// ¿Qué? El prestamista corregido: valora el colateral con un price feed de Chainlink.
// ¿Para qué? Que el precio no dependa de nada que se pueda mover dentro de una transacción.
// ¿Impacto? Depende del feed: si se para o da un precio imposible, no presta (semana 20).
contract FeedLender is Lender {
    uint256 public constant MAX_PRICE_AGE = 1 hours;
    AggregatorV3Interface public immutable FEED;

    error InvalidPrice(int256 answer);
    error StalePrice(uint256 updatedAt);

    constructor(IERC20 usd, IERC20 gov, AggregatorV3Interface feed) Lender(usd, gov) {
        FEED = feed;
    }

    /// @inheritdoc Lender
    // PASO 4: el precio del feed, comprobado y llevado a 18 decimales.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function price() public view override returns (uint256) {
        revert("TODO: Paso 4");
        //> // forge-lint: disable-next-line(unused-return)
        //> (, int256 answer,, uint256 updatedAt,) = FEED.latestRoundData();
        //> if (answer <= 0) revert InvalidPrice(answer);
        //> // forge-lint: disable-next-line(block-timestamp)
        //> if (block.timestamp - updatedAt > MAX_PRICE_AGE) revert StalePrice(updatedAt);
        //> // `answer` ya es positivo: la conversión no cambia su valor.
        //> // forge-lint: disable-next-line(unsafe-typecast)
        //> return uint256(answer) * 10 ** (18 - FEED.decimals());
    }
}
