// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @title El feed de precios de una L2, con el secuenciador en marcha
/// @notice Responde lo mismo que el feed de precios de Chainlink, pero revierte mientras el
///         secuenciador de la L2 está caído y durante el plazo de gracia después de volver.
/// @dev ¿Qué? Un AggregatorV3Interface delante de otro.
///   ¿Para qué? Que RegistryV3 lo use sin cambiar una línea: `setFeeConfig` acepta cualquier feed.
///   ¿Impacto? Con el secuenciador caído o recién vuelto, `registrationFee` revierte, y con ella
///   las altas que pagan en ETH.
contract SequencerAwareFeed is AggregatorV3Interface {
    /// @notice Lo que se espera desde que el secuenciador vuelve antes de fiarse del precio.
    uint256 public constant GRACE_PERIOD = 1 hours;

    /// @notice El feed de disponibilidad de Chainlink: 0 en marcha, 1 caído; `startedAt`, desde cuándo.
    AggregatorV3Interface public immutable sequencerUptimeFeed;
    /// @notice El feed de precios al que envuelve.
    AggregatorV3Interface public immutable priceFeed;

    error SequencerDown();
    error GracePeriodNotOver(uint256 upSince);
    /// @notice El feed de disponibilidad aún no tiene ninguna ronda (`startedAt` = 0).
    error UptimeFeedNotStarted();

    constructor(AggregatorV3Interface sequencerUptimeFeed_, AggregatorV3Interface priceFeed_) {
        sequencerUptimeFeed = sequencerUptimeFeed_;
        priceFeed = priceFeed_;
    }

    /// @inheritdoc AggregatorV3Interface
    function decimals() external view returns (uint8) {
        return priceFeed.decimals();
    }

    /// @inheritdoc AggregatorV3Interface
    function description() external view returns (string memory) {
        return priceFeed.description();
    }

    /// @inheritdoc AggregatorV3Interface
    function version() external view returns (uint256) {
        return priceFeed.version();
    }

    /// @inheritdoc AggregatorV3Interface
    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80) {
        _checkSequencer();
        // Devuelve la ronda entera: Slither no ve que reenviar es usar.
        // slither-disable-next-line unused-return
        return priceFeed.getRoundData(roundId);
    }

    /// @inheritdoc AggregatorV3Interface
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        _checkSequencer();
        // Devuelve la ronda entera: Slither no ve que reenviar es usar.
        // slither-disable-next-line unused-return
        return priceFeed.latestRoundData();
    }

    // forge-lint: disable-next-item(unused-return, block-timestamp)
    function _checkSequencer() internal view {
        // Del feed de disponibilidad solo importan el estado y desde cuándo.
        // slither-disable-next-line unused-return
        (, int256 status, uint256 statusSince,,) = sequencerUptimeFeed.latestRoundData();
        if (status != 0) revert SequencerDown();
        // TODO (semana 34): el hallazgo H-06 de la auditoría cruzada. En Arbitrum, el feed sin
        //   inicializar responde 0 con `startedAt` = 0, y `block.timestamp - 0` siempre supera el
        //   plazo de gracia. Si `statusSince` es 0, UptimeFeedNotStarted().
        // Unos segundos de un validador no cambian un plazo de una hora.
        // slither-disable-next-line timestamp
        if (block.timestamp - statusSince <= GRACE_PERIOD) revert GracePeriodNotOver(statusSince);
    }
}
