// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {PushAuction} from "../src/PushAuction.sol";
import {Auction} from "../src/Auction.sol";
import {Blocker, IAuction} from "../src/Blocker.sol";
import {Points} from "../src/Points.sol";

contract DosAndMathTest is Test {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address mallory = makeAddr("mallory");

    function setUp() public {
        vm.warp(1_750_000_000);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(mallory, 10 ether);
    }

    function test_Paso1_BlockerFreezesPushAuction() public {
        PushAuction auction = new PushAuction();
        vm.prank(alice);
        auction.bid{value: 1 ether}();
        Blocker blocker = new Blocker();
        vm.prank(mallory);
        blocker.attack{value: 1.1 ether}(IAuction(address(auction)));
        assertEq(auction.highestBidder(), address(blocker));
        // Bob ofrece el triple y no puede pujar: la devolución al bloqueador falla.
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(PushAuction.RefundFailed.selector, address(blocker)));
        auction.bid{value: 3 ether}();
    }

    function test_Paso2_BlockerCannotFreezeAuction() public {
        Auction auction = new Auction();
        vm.prank(alice);
        auction.bid{value: 1 ether}();
        Blocker blocker = new Blocker();
        vm.prank(mallory);
        blocker.attack{value: 1.1 ether}(IAuction(address(auction)));
        vm.prank(bob);
        auction.bid{value: 3 ether}();
        assertEq(auction.highestBidder(), bob);
        assertEq(auction.pendingReturns(alice), 1 ether);
        assertEq(auction.pendingReturns(address(blocker)), 1.1 ether);
    }

    function test_Paso3_Withdraw() public {
        Auction auction = new Auction();
        vm.prank(alice);
        auction.bid{value: 1 ether}();
        vm.prank(bob);
        auction.bid{value: 2 ether}();
        vm.prank(alice);
        auction.withdraw();
        assertEq(alice.balance, 10 ether);
        assertEq(address(auction).balance, 2 ether);
        vm.prank(alice);
        vm.expectRevert(Auction.NothingToWithdraw.selector);
        auction.withdraw();
    }

    function test_Paso4_Spend() public {
        Points points = new Points();
        vm.startPrank(alice);
        points.mint(100);
        points.spend(30);
        vm.stopPrank();
        assertEq(points.balanceOf(alice), 70);
    }

    function test_Paso4_RevertWhen_SpendMoreThanBalance() public {
        Points points = new Points();
        vm.startPrank(mallory);
        points.mint(1);
        // Con `unchecked`, 1 - 2 daría 2^256 - 1 puntos.
        vm.expectRevert(stdError.arithmeticError);
        points.spend(2);
        vm.stopPrank();
        assertEq(points.balanceOf(mallory), 1);
    }

    function test_Paso5_Lock() public {
        Points points = new Points();
        vm.startPrank(alice);
        points.mint(100);
        points.lock(60, 1 days);
        vm.expectRevert(abi.encodeWithSelector(Points.StillLocked.selector, uint64(block.timestamp + 1 days)));
        points.unlock();
        vm.warp(block.timestamp + 1 days);
        points.unlock();
        vm.stopPrank();
        assertEq(points.balanceOf(alice), 100);
    }

    function test_Paso5_RevertWhen_DurationOverflowsUint64() public {
        Points points = new Points();
        // Elegida para que la suma, cortada a 64 bits, dé 0: con `uint64(...)` el bloqueo vencería ya.
        uint256 duration = 2 ** 64 - block.timestamp;
        vm.startPrank(mallory);
        points.mint(100);
        vm.expectRevert(abi.encodeWithSelector(SafeCast.SafeCastOverflowedUintDowncast.selector, 64, 2 ** 64));
        points.lock(100, duration);
        vm.stopPrank();
    }
}
