// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @title El precio de ETH en dólares, leído en una L2
/// @notice Antes del precio, mira el feed de disponibilidad del secuenciador de Chainlink.
/// @dev ¿Qué? En una L2 el secuenciador ordena las transacciones; si se cae, el feed de precios
///   deja de actualizarse pero el último precio sigue ahí.
///   ¿Para qué? No usar un precio viejo mientras el secuenciador está caído, ni justo después,
///   cuando entran de golpe las transacciones que esperaban.
///   ¿Impacto? Mientras dure la caída y el plazo de gracia, las lecturas revierten.
contract L2PriceReader {
    /// @notice Lo que se espera desde que el secuenciador vuelve antes de fiarse del precio.
    uint256 public constant GRACE_PERIOD = 1 hours;
    /// @notice La antigüedad máxima de un precio (semana 20).
    uint256 public constant MAX_PRICE_AGE = 3 hours;

    /// @notice Respuesta 0: secuenciador en marcha; 1: caído. `startedAt`: desde cuándo.
    AggregatorV3Interface public immutable sequencerUptimeFeed;
    AggregatorV3Interface public immutable priceFeed;

    error SequencerDown();
    error GracePeriodNotOver(uint256 upSince);
    error InvalidPrice(int256 answer);
    error StalePrice(uint256 updatedAt);

    constructor(AggregatorV3Interface sequencerUptimeFeed_, AggregatorV3Interface priceFeed_) {
        sequencerUptimeFeed = sequencerUptimeFeed_;
        priceFeed = priceFeed_;
    }

    /// @notice El precio de 1 ETH en dólares, con los decimales del feed.
    function ethUsd() external view returns (uint256) {
        (, int256 status, uint256 statusSince,,) = sequencerUptimeFeed.latestRoundData();
        (status, statusSince); // <- Paso 3
        // PASO 3: con el secuenciador caído, no hay precio.
        //> if (status != 0) revert SequencerDown();
        // PASO 4: recién vuelto, tampoco: el plazo de gracia cuenta desde `statusSince`.
        //> if (block.timestamp - statusSince <= GRACE_PERIOD) revert GracePeriodNotOver(statusSince);
        (, int256 answer,, uint256 updatedAt,) = priceFeed.latestRoundData();
        if (answer <= 0) revert InvalidPrice(answer);
        if (block.timestamp - updatedAt > MAX_PRICE_AGE) revert StalePrice(updatedAt);
        return uint256(answer);
    }
}
