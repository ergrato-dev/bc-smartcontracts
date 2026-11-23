// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {RegistryV2} from "./RegistryV2.sol";

// ¿Qué? La versión 3 del registro: la tasa de alta se fija en dólares y se cobra en ETH, al
//   precio ETH/USD de un price feed de Chainlink.
// ¿Para qué? Que dar de alta un recurso cueste lo mismo en dólares aunque el ETH suba o baje.
// ¿Impacto? Las altas con ETH dependen del feed: si se para o da un precio imposible, revierten
//   (StalePrice, InvalidPrice) en vez de cobrar mal. Las altas con puntos siguen igual. Las tres
//   variables nuevas van al final del storage, detrás de las de V2.
contract RegistryV3 is RegistryV2 {
    /// @notice El price feed ETH/USD.
    AggregatorV3Interface public priceFeed;
    /// @notice La tasa de alta en dólares, con 18 decimales (25e18 son 25 dólares).
    uint256 public usdFee;
    /// @notice Cuántos segundos puede tener el último precio del feed para usarlo.
    uint256 public maxPriceAge;

    event FeeConfigChanged(address indexed feed, uint256 usdFee, uint256 maxPriceAge);

    error InvalidPrice(int256 answer);
    error StalePrice(uint256 updatedAt, uint256 maxPriceAge);

    /// @notice Inicializa lo que trae V3. Se llama una vez, en `upgradeToAndCall`.
    /// @param feed El price feed ETH/USD de la red.
    /// @param newUsdFee La tasa en dólares, con 18 decimales. Mayor que 0.
    /// @param newMaxPriceAge Antigüedad máxima del precio, en segundos. Mayor que 0.
    function initializeV3(AggregatorV3Interface feed, uint256 newUsdFee, uint256 newMaxPriceAge)
        external
        reinitializer(3)
    {
        _setFeeConfig(feed, newUsdFee, newMaxPriceAge);
    }

    /// @notice Cambia el feed, la tasa en dólares o la antigüedad máxima. Solo el administrador.
    function setFeeConfig(AggregatorV3Interface feed, uint256 newUsdFee, uint256 newMaxPriceAge)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setFeeConfig(feed, newUsdFee, newMaxPriceAge);
    }

    /// @inheritdoc RegistryV2
    function version() external pure override returns (uint256) {
        return 3;
    }

    /// @notice El precio ETH/USD del feed, comprobado, y sus decimales.
    function ethUsdPrice() public view returns (uint256 price, uint8 decimals) {
        // TODO: lee `priceFeed.latestRoundData()`. Si la respuesta no es positiva,
        //   InvalidPrice(answer). Si `updatedAt` tiene más de `maxPriceAge` segundos,
        //   StalePrice(updatedAt, maxPriceAge). Devuelve la respuesta como uint256 y
        //   `priceFeed.decimals()`.
        revert("TODO: ethUsdPrice");
    }

    /// @notice La tasa de un alta en wei: `usdFee` dólares al precio del feed.
    function registrationFee() public view override returns (uint256) {
        // TODO: wei = usdFee * 10**decimals / price, con `Math.mulDiv` y redondeo hacia arriba
        //   (`Math.Rounding.Ceil`): el redondeo nunca cobra de menos.
        revert("TODO: registrationFee");
    }

    function _setFeeConfig(AggregatorV3Interface feed, uint256 newUsdFee, uint256 newMaxPriceAge) internal {
        // TODO: con `address(feed) == address(0)`, ZeroAddress(). Con `newUsdFee == 0` o
        //   `newMaxPriceAge == 0`, InvalidAmount con el valor que es 0. Si no, guarda los tres y
        //   emite FeeConfigChanged.
        revert("TODO: _setFeeConfig");
    }
}
