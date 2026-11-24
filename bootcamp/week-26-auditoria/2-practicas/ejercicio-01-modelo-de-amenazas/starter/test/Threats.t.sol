// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";

// ¿Qué? El modelo de amenazas de Escrow convertido en tests: uno por amenaza.
// ¿Para qué? Que cada fila de la tabla del README tenga una prueba que falla si la defensa falta.
contract ThreatsTest is Test {
    Escrow escrow;
    address alice = makeAddr("alice"); // compradora
    address bob = makeAddr("bob"); // vendedor
    address arbiter = makeAddr("arbiter");
    address mallory = makeAddr("mallory"); // cualquiera de fuera
    uint256 id;
    uint64 deadline;

    function setUp() public {
        escrow = new Escrow(arbiter);
        vm.deal(alice, 10 ether);
        deadline = uint64(block.timestamp + 7 days);
        vm.prank(alice);
        id = escrow.open{value: 1 ether}(bob, deadline);
    }

    // Modelo: el camino feliz. Alice recibe lo comprado y libera el pago.
    function test_OpenAndRelease() public {
        vm.prank(alice);
        escrow.release(id);
        assertEq(bob.balance, 1 ether);
        assertEq(address(escrow).balance, 0);
    }

    // T-01: alguien de fuera mueve el ETH de un trato.
    function test_Paso1_RevertWhen_StrangerMovesFunds() public {
        // PASO 1: Mallory prueba las cuatro funciones que mueven o congelan el ETH.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 1");
        //> vm.startPrank(mallory);
        //> vm.expectRevert(Escrow.NotBuyer.selector);
        //> escrow.release(id);
        //> vm.expectRevert(Escrow.NotBuyer.selector);
        //> escrow.refund(id);
        //> vm.expectRevert(Escrow.NotParty.selector);
        //> escrow.dispute(id);
        //> vm.expectRevert(Escrow.NotArbiter.selector);
        //> escrow.resolve(id, mallory);
        //> vm.stopPrank();
        //> assertEq(address(escrow).balance, 1 ether);
    }

    // T-02: un trato se paga dos veces.
    function test_Paso2_RevertWhen_PaidTwice() public {
        // PASO 2: tras liberar, ninguna función vuelve a pagar ni a congelar el trato.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 2");
        //> vm.startPrank(alice);
        //> escrow.release(id);
        //> vm.expectRevert(Escrow.WrongStatus.selector);
        //> escrow.release(id);
        //> vm.expectRevert(Escrow.WrongStatus.selector);
        //> escrow.dispute(id);
        //> vm.warp(deadline + 1);
        //> vm.expectRevert(Escrow.WrongStatus.selector);
        //> escrow.refund(id);
        //> vm.stopPrank();
        //> assertEq(bob.balance, 1 ether);
        //> assertEq(alice.balance, 9 ether);
    }

    // T-03 y T-04: una parte se aprovecha del plazo.
    function test_Paso3_DeadlineRules() public {
        // PASO 3: Alice no recupera antes del plazo ni durante una disputa; Bob no disputa tarde.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 3");
        //> vm.prank(alice);
        //> vm.expectRevert(Escrow.TooEarly.selector);
        //> escrow.refund(id);
        //>
        //> vm.prank(bob);
        //> escrow.dispute(id);
        //> vm.warp(deadline + 1);
        //> vm.prank(alice);
        //> vm.expectRevert(Escrow.WrongStatus.selector);
        //> escrow.refund(id);
        //>
        //> vm.prank(alice);
        //> uint256 late = escrow.open{value: 1 ether}(bob, uint64(block.timestamp + 1 days));
        //> vm.warp(block.timestamp + 1 days + 1);
        //> vm.prank(bob);
        //> vm.expectRevert(Escrow.TooLate.selector);
        //> escrow.dispute(late);
        //> vm.prank(alice);
        //> escrow.refund(late);
        //> assertEq(alice.balance, 9 ether);
    }

    // T-05: el árbitro se lleva el ETH de una disputa.
    function test_Paso4_RevertWhen_ArbiterPaysThirdParty() public {
        // PASO 4: el árbitro decide, pero solo entre Alice y Bob.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 4");
        //> vm.prank(bob);
        //> escrow.dispute(id);
        //> vm.startPrank(arbiter);
        //> vm.expectRevert(Escrow.NotParty.selector);
        //> escrow.resolve(id, arbiter);
        //> escrow.resolve(id, bob);
        //> vm.stopPrank();
        //> assertEq(bob.balance, 1 ether);
        //> assertEq(arbiter.balance, 0);
    }
}
