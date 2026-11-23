// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConsumer} from "../src/PriceConsumer.sol";

// ¿Qué? Tests del ejercicio 01 con un feed falso (MockV3Aggregator) de 8 decimales, como el
//   ETH/USD real, que empieza en 3000 dólares.
contract PriceConsumerTest is Test {
    MockV3Aggregator feed;
    PriceConsumer consumer;
    address buyer = makeAddr("buyer");

    function setUp() public {
        vm.warp(1_750_000_000);
        feed = new MockV3Aggregator(8, 3000e8);
        consumer = new PriceConsumer(AggregatorV3Interface(address(feed)), 1 hours);
        vm.deal(buyer, 1 ether);
    }

    function test_Paso1_RawPrice() public {
        assertEq(consumer.rawPrice(), 3000e8);
        feed.updateAnswer(-1);
        assertEq(consumer.rawPrice(), -1);
    }

    function test_Paso2_Price() public {
        assertEq(consumer.price(), 3000e8);
        // Justo en el límite todavía vale.
        vm.warp(block.timestamp + 1 hours);
        assertEq(consumer.price(), 3000e8);
    }

    function test_Paso2_RevertWhen_PriceNotPositive() public {
        feed.updateAnswer(0);
        vm.expectRevert(abi.encodeWithSelector(PriceConsumer.InvalidPrice.selector, int256(0)));
        consumer.price();
        feed.updateAnswer(-5);
        vm.expectRevert(abi.encodeWithSelector(PriceConsumer.InvalidPrice.selector, int256(-5)));
        consumer.price();
    }

    function test_Paso2_RevertWhen_Stale() public {
        uint256 updatedAt = block.timestamp;
        vm.warp(block.timestamp + 1 hours + 1);
        vm.expectRevert(abi.encodeWithSelector(PriceConsumer.StalePrice.selector, updatedAt));
        consumer.price();
    }

    function test_Paso3_UsdToWei() public {
        assertEq(consumer.usdToWei(30e18), 0.01 ether);
        // 25 / 3000 = 0,008333... ETH: el último wei se redondea hacia arriba.
        assertEq(consumer.usdToWei(25e18), 8333333333333334);
        // Otro feed con 18 decimales: el contrato lee los decimales, no los supone.
        MockV3Aggregator feed18 = new MockV3Aggregator(18, 2000e18);
        PriceConsumer other = new PriceConsumer(AggregatorV3Interface(address(feed18)), 1 hours);
        assertEq(other.usdToWei(30e18), 0.015 ether);
    }

    function test_Paso4_WeiToUsd() public {
        assertEq(consumer.weiToUsd(1 ether), 3000e18);
        assertEq(consumer.weiToUsd(0.01 ether), 30e18);
        // La ida y la vuelta nunca dan menos de lo que se pidió.
        assertGe(consumer.weiToUsd(consumer.usdToWei(25e18)), 25e18);
        // A 3333,33333333 dólares, 1 wei vale 3333,33333333e-18 dólares: se queda en 3333.
        feed.updateAnswer(333333333333);
        assertEq(consumer.weiToUsd(1), 3333);
    }

    function test_Paso5_Buy() public {
        uint256 required = consumer.usdToWei(25e18);
        vm.expectEmit(address(consumer));
        emit PriceConsumer.TicketSold(buyer, required);
        vm.prank(buyer);
        consumer.buy{value: 0.01 ether}();
        assertEq(address(consumer).balance, required);
        assertEq(buyer.balance, 1 ether - required);
    }

    function test_Paso5_RevertWhen_InsufficientOrStale() public {
        uint256 required = consumer.usdToWei(25e18);
        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(PriceConsumer.InsufficientPayment.selector, required, required - 1));
        consumer.buy{value: required - 1}();
        vm.warp(block.timestamp + 2 hours);
        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(PriceConsumer.StalePrice.selector, 1_750_000_000));
        consumer.buy{value: 0.01 ether}();
    }
}
