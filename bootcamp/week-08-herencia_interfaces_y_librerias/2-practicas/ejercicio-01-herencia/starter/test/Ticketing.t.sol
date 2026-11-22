// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Owned, Pausable, Capped, Ticketing} from "../src/Ticketing.sol";

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
contract TicketingTest is Test {
    Ticketing ticketing;
    address alice = makeAddr("alice");

    function setUp() public {
        ticketing = new Ticketing(5);
    }

    function test_Step1_OwnerPauses() public {
        vm.expectEmit();
        emit Pausable.PausedSet(true);
        ticketing.setPaused(true);
        assertTrue(ticketing.paused());

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Owned.NotOwner.selector, alice));
        ticketing.setPaused(false);
    }

    function test_Step2_Buy() public {
        vm.prank(alice);
        ticketing.buy(3);
        assertEq(ticketing.ticketsOf(alice), 3);
        assertEq(ticketing.sold(), 3);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Capped.SoldOut.selector, 5));
        ticketing.buy(3);

        ticketing.setPaused(true);
        vm.prank(alice);
        vm.expectRevert(Pausable.IsPaused.selector);
        ticketing.buy(1);
    }

    function test_Step3_TransferOwnership() public {
        vm.expectRevert(Ticketing.ZeroAddress.selector);
        ticketing.transferOwnership(address(0));

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Owned.NotOwner.selector, alice));
        ticketing.transferOwnership(alice);

        vm.expectEmit();
        emit Owned.OwnershipTransferred(address(this), alice);
        ticketing.transferOwnership(alice);
        assertEq(ticketing.owner(), alice);
    }

    function test_Step4_Layers() public view {
        assertEq(ticketing.layers(), "Ticketing > Capped > Pausable > Owned");
    }
}
