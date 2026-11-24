// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {SequencerAwareFeed} from "../../src/SequencerAwareFeed.sol";

/// @notice Un feed de disponibilidad sin ninguna ronda: lo que responde en Arbitrum antes de
///   inicializarse. Todo a cero, `startedAt` incluido.
contract UninitializedUptimeFeed {
    function latestRoundData() external pure returns (uint80, int256, uint256, uint256, uint80) {
        return (0, 0, 0, 0, 0);
    }
}

// ¿Qué? Los tests de regresión de los hallazgos que te llegan en la auditoría cruzada: uno por
//   hallazgo, con su id del informe en el nombre del comentario. El primero es el del protocolo
//   de referencia; los demás, los tuyos.
// ¿Para qué? Que cada hallazgo corregido tenga un test que vuelve a fallar si el fallo vuelve.
contract ReceivedFindingsTest is Test {
    MockV3Aggregator priceFeed;

    function setUp() public {
        vm.warp(1_750_000_000);
        priceFeed = new MockV3Aggregator(8, 2500e8);
    }

    // H-06: el feed de disponibilidad sin inicializar se toma por "en marcha desde siempre".
    function test_RevertWhen_TheUptimeFeedHasNotStarted() public {
        SequencerAwareFeed feed = new SequencerAwareFeed(
            AggregatorV3Interface(address(new UninitializedUptimeFeed())), AggregatorV3Interface(address(priceFeed))
        );
        vm.expectRevert(SequencerAwareFeed.UptimeFeedNotStarted.selector);
        feed.latestRoundData();
    }

    // H-06: con el feed ya inicializado, nada cambia.
    function test_ReadsThePriceOnceTheUptimeFeedStarted() public {
        MockV3Aggregator uptime = new MockV3Aggregator(0, 0);
        SequencerAwareFeed feed =
            new SequencerAwareFeed(AggregatorV3Interface(address(uptime)), AggregatorV3Interface(address(priceFeed)));
        vm.warp(block.timestamp + 2 hours);
        (, int256 price,,,) = feed.latestRoundData();
        assertEq(price, 2500e8);
    }
}
