// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Tickets} from "../src/Tickets.sol";

// ¿Qué? Los tests unitarios de Tickets y, al final, los contraejemplos del SMTChecker
//   convertidos en tests.
// ¿Para qué? Un contraejemplo es una afirmación: "esta secuencia rompe la propiedad". Un test la
//   comprueba en la EVM de verdad, y se queda como test de regresión cuando corriges el fallo.
contract TicketsTest is Test {
    Tickets internal tickets;
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        tickets = new Tickets();
    }

    function test_Reserve() public {
        vm.prank(alice);
        tickets.reserve(3);
        assertEq(tickets.reserved(), 3);
        assertEq(tickets.reservedOf(alice), 3);
    }

    function test_Confirm() public {
        vm.startPrank(alice);
        tickets.reserve(3);
        tickets.confirm();
        vm.stopPrank();
        assertEq(tickets.sold(), 3);
        assertEq(tickets.reserved(), 0);
        assertEq(tickets.ticketsOf(alice), 3);
    }

    function test_Cancel() public {
        vm.startPrank(alice);
        tickets.reserve(3);
        tickets.cancel();
        vm.stopPrank();
        assertEq(tickets.reserved(), 0);
        assertEq(tickets.sold(), 0);
    }

    function test_RevertWhen_OrderTooBig() public {
        vm.expectRevert();
        tickets.reserve(5);
    }

    function test_RevertWhen_SoldOut() public {
        vm.startPrank(alice);
        tickets.reserve(4);
        tickets.confirm();
        tickets.reserve(4);
        tickets.confirm();
        vm.expectRevert();
        tickets.reserve(3);
        vm.stopPrank();
    }

    // Paso 2: el primer contraejemplo del SMTChecker.
    function test_FirstCounterexample() public {
        revert("TODO: Paso 2");
        //> tickets.reserve(4);
        //> vm.expectRevert();
        //> tickets.reserve(7);
    }

    // Paso 3: el segundo contraejemplo: tres reservas pendientes que juntas pasan de 10.
    function test_SecondCounterexample() public {
        revert("TODO: Paso 3");
        //> vm.prank(alice);
        //> tickets.reserve(4);
        //> vm.prank(bob);
        //> tickets.reserve(3);
        //> vm.prank(bob);
        //> vm.expectRevert(bytes("sold out"));
        //> tickets.reserve(4);
    }
}
