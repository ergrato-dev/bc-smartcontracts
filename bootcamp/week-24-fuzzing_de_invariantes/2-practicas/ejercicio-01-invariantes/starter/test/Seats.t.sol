// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Seats} from "../src/Seats.sol";

// ¿Qué? Tests unitarios de Seats: un caso cada uno, con valores elegidos a mano.
// ¿Para qué? Pasan desde el principio. No prueban ninguna secuencia que rompa los contadores.
// No modifiques este archivo.
contract SeatsTest is Test {
    Seats seats;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        seats = new Seats();
    }

    function test_Book() public {
        vm.prank(alice);
        seats.book(3);
        assertEq(seats.holderOf(3), alice);
        assertEq(seats.seatsOf(alice), 1);
        assertEq(seats.booked(), 1);
    }

    function test_Cancel() public {
        vm.startPrank(alice);
        seats.book(3);
        seats.cancel(3);
        vm.stopPrank();
        assertEq(seats.holderOf(3), address(0));
        assertEq(seats.booked(), 0);
    }

    function test_TransferSeat() public {
        vm.startPrank(alice);
        seats.book(3);
        seats.transferSeat(3, bob);
        vm.stopPrank();
        assertEq(seats.holderOf(3), bob);
        assertEq(seats.booked(), 1);
    }

    function test_RevertWhen_SeatTaken() public {
        vm.prank(alice);
        seats.book(3);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Seats.SeatTaken.selector, 3));
        seats.book(3);
    }

    function test_RevertWhen_TooManySeats() public {
        vm.startPrank(alice);
        seats.book(1);
        seats.book(2);
        vm.expectRevert(abi.encodeWithSelector(Seats.TooManySeats.selector, alice));
        seats.book(3);
        vm.stopPrank();
    }
}
