// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IERC165, IPriceFeed} from "../src/IPriceFeed.sol";
import {BaseFeed, FixedFeed, ManualFeed} from "../src/Feeds.sol";
import {Converter} from "../src/Converter.sol";

// ¿Qué? Una fuente escrita aquí, sin heredar de BaseFeed: solo cumple la interfaz.
contract HalfFeed is IPriceFeed {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestPrice() external pure returns (uint256) {
        return 1500e8;
    }
}

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
contract ConverterTest is Test {
    uint256 constant PRICE = 3000e8;
    address alice = makeAddr("alice");

    function test_Step1_TemplateRejectsZero() public {
        ManualFeed feed = new ManualFeed();
        vm.expectRevert(BaseFeed.InvalidPrice.selector);
        feed.latestPrice();
    }

    function test_Step2_FixedFeed() public {
        FixedFeed feed = new FixedFeed(PRICE);
        assertEq(feed.latestPrice(), PRICE);
        assertEq(feed.decimals(), 8);
    }

    function test_Step3_ManualFeed() public {
        ManualFeed feed = new ManualFeed();
        vm.expectEmit();
        emit ManualFeed.PriceUpdated(PRICE);
        feed.setPrice(PRICE);
        assertEq(feed.latestPrice(), PRICE);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ManualFeed.NotUpdater.selector, alice));
        feed.setPrice(1);

        feed.setPrice(0);
        vm.expectRevert(BaseFeed.InvalidPrice.selector);
        feed.latestPrice();
    }

    function test_Step4_ConverterWorksWithAnyFeed() public {
        Converter fixedConverter = new Converter(new FixedFeed(PRICE));
        assertEq(fixedConverter.toUsd(2 ether), 6000e8);
        assertEq(fixedConverter.toUsd(0.5 ether), 1500e8);

        Converter halfConverter = new Converter(new HalfFeed());
        assertEq(halfConverter.toUsd(2 ether), 3000e8);
    }

    function test_Step5_SupportsInterface() public {
        FixedFeed feed = new FixedFeed(PRICE);
        assertTrue(feed.supportsInterface(type(IPriceFeed).interfaceId));
        assertTrue(feed.supportsInterface(type(IERC165).interfaceId));
        assertFalse(feed.supportsInterface(0xffffffff));
    }
}
