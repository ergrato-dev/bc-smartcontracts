// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Bookings} from "../src/Bookings.sol";

// ¿Qué? Los tests unitarios de Bookings y, al final, el contraejemplo de Halmos como test.
contract BookingsTest is Test {
    Bookings internal bookings;

    function setUp() public {
        bookings = new Bookings();
    }

    function test_Book() public {
        assertEq(bookings.book(10, 14), 0);
        assertEq(bookings.book(20, 21), 1);
        assertEq(bookings.count(), 2);
    }

    function test_RevertWhen_Overlaps() public {
        bookings.book(10, 14);
        vm.expectRevert(abi.encodeWithSelector(Bookings.Overlaps.selector, 0));
        bookings.book(12, 18);
    }

    function test_RevertWhen_InvalidRange() public {
        vm.expectRevert(abi.encodeWithSelector(Bookings.InvalidRange.selector, 5, 4));
        bookings.book(5, 4);
    }

    // Paso 1: el contraejemplo de Halmos, con tus valores.
    function test_HalmosCounterexample() public {
        revert("TODO: Paso 1");
        //> bookings.book(0, 0);
        //> vm.expectRevert(abi.encodeWithSelector(Bookings.Overlaps.selector, 0));
        //> bookings.book(0, 0);
    }
}
