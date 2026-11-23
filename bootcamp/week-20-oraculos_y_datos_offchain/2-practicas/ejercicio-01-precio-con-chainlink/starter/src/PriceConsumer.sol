// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// ¿Qué? Una taquilla que cobra en ETH una entrada con precio fijo en dólares, usando el precio
//   ETH/USD de un price feed de Chainlink.
// ¿Para qué? Que la entrada cueste siempre 25 dólares aunque el ETH suba o baje.
// ¿Impacto? Si el feed se para o da un precio imposible, la taquilla deja de vender en vez de
//   vender mal.
contract PriceConsumer {
    /// @notice El precio de la entrada: 25 dólares, con 18 decimales.
    uint256 public constant PRICE_USD = 25e18;

    /// @notice El price feed ETH/USD.
    AggregatorV3Interface public immutable FEED;
    /// @notice Cuántos segundos puede tener el último precio para usarlo.
    uint256 public immutable MAX_AGE;

    event TicketSold(address indexed buyer, uint256 paidWei);

    error InvalidPrice(int256 answer);
    error StalePrice(uint256 updatedAt);
    error InsufficientPayment(uint256 required, uint256 sent);
    error RefundFailed();

    /// @param feed La dirección del price feed ETH/USD.
    /// @param maxAge Antigüedad máxima del precio, en segundos.
    constructor(AggregatorV3Interface feed, uint256 maxAge) {
        FEED = feed;
        MAX_AGE = maxAge;
    }

    // PASO 1: el precio tal cual lo da el feed, sin comprobar nada.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    /// @notice La respuesta del último round del feed.
    function rawPrice() external view returns (int256) {
        revert("TODO: Paso 1");
        //> (, int256 answer,,,) = FEED.latestRoundData();
        //> return answer;
    }

    // PASO 2: el precio, solo si es positivo y reciente.
    /// @notice El precio ETH/USD con los decimales del feed.
    function price() public view returns (uint256) {
        revert("TODO: Paso 2");
        //> (, int256 answer,, uint256 updatedAt,) = FEED.latestRoundData();
        //> if (answer <= 0) revert InvalidPrice(answer);
        //> if (block.timestamp - updatedAt > MAX_AGE) revert StalePrice(updatedAt);
        //> return uint256(answer);
    }

    // PASO 3: dólares a wei, redondeando hacia arriba.
    /// @notice Cuántos wei valen `usdAmount` dólares.
    /// @param usdAmount Dólares con 18 decimales.
    function usdToWei(uint256 usdAmount) public view returns (uint256) {
        revert("TODO: Paso 3");
        //> return Math.mulDiv(usdAmount, 10 ** FEED.decimals(), price(), Math.Rounding.Ceil);
    }

    // PASO 4: wei a dólares, redondeando hacia abajo.
    /// @notice Cuántos dólares, con 18 decimales, valen `weiAmount` wei.
    /// @param weiAmount Cantidad de ETH en wei.
    function weiToUsd(uint256 weiAmount) external view returns (uint256) {
        revert("TODO: Paso 4");
        //> return Math.mulDiv(weiAmount, price(), 10 ** FEED.decimals());
    }

    // PASO 5: vender una entrada y devolver lo que sobra.
    /// @notice Compra una entrada pagando al menos `usdToWei(PRICE_USD)`; el resto vuelve.
    function buy() external payable {
        revert("TODO: Paso 5");
        //> uint256 required = usdToWei(PRICE_USD);
        //> if (msg.value < required) revert InsufficientPayment(required, msg.value);
        //> emit TicketSold(msg.sender, required);
        //> uint256 change = msg.value - required;
        //> if (change > 0) {
        //>     (bool ok,) = msg.sender.call{value: change}("");
        //>     if (!ok) revert RefundFailed();
        //> }
    }
}
