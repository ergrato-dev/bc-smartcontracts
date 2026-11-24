// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Club} from "../src/Club.sol";

// ¿Qué? Dos tests por paso: uno de comportamiento, que pasa desde el principio y tiene que
//   seguir pasando, y uno de gas, que falla hasta que haces el paso.
// ¿Para qué? Una optimización que cambia lo que hace el contrato no es una optimización.
// ¿Impacto? Los topes de gas son los de este contrato con solc 0.8.38 sin optimizador: con
//   otro compilador u otra configuración, los números cambian.
contract ClubTest is Test {
    Club club;
    address alice = makeAddr("alice");

    function setUp() public {
        vm.warp(1_750_000_000);
        club = new Club();
        for (uint256 i = 1; i <= 10; i++) {
            vm.prank(address(uint160(i)));
            club.join();
        }
    }

    // El gas de la última llamada del test: una transacción entera, con sus 21 000 de base.
    function _lastGas() internal view returns (uint256) {
        return vm.lastFrameGas().gasTotalUsed;
    }

    function test_JoinStoresMember() public {
        vm.prank(alice);
        club.join();
        Club.Member memory m = club.memberOf(alice);
        assertEq(m.account, alice);
        assertEq(m.joinedAt, 1_750_000_000);
        assertTrue(m.active);
        assertEq(m.points, 0);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Club.AlreadyMember.selector, alice));
        club.join();
    }

    function test_Paso1_JoinFitsBudget() public {
        vm.prank(alice);
        club.join();
        assertLt(_lastGas(), 80_000, "Paso 1: join gasta demasiado");
    }

    function test_RewardAllAddsPoints() public {
        club.rewardAll(5);
        assertEq(club.totalPoints(), 50);
        assertEq(club.memberOf(address(1)).points, 5);
        assertEq(club.memberOf(address(10)).points, 5);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Club.NotOwner.selector, alice));
        club.rewardAll(5);
    }

    function test_Paso2_RewardAllFitsBudget() public {
        club.rewardAll(5);
        assertLt(_lastGas(), 276_000, "Paso 2: rewardAll gasta demasiado");
    }

    function testFuzz_ClaimMarksOnlyThatPrize(uint256 a, uint256 b) public {
        vm.assume(a != b);
        club.claim(a);
        assertTrue(club.isClaimed(a));
        assertFalse(club.isClaimed(b));
        vm.expectRevert(abi.encodeWithSelector(Club.AlreadyClaimed.selector, a));
        club.claim(a);
        club.claim(b);
        assertTrue(club.isClaimed(b));
    }

    function test_Paso3_SecondClaimFitsBudget() public {
        club.claim(0);
        club.claim(1);
        assertLt(_lastGas(), 30_000, "Paso 3: el segundo premio gasta demasiado");
    }

    function test_IsOwner() public view {
        assertTrue(club.isOwner(address(this)));
        assertFalse(club.isOwner(alice));
    }

    function test_Paso4_IsOwnerFitsBudget() public view {
        club.isOwner(alice);
        assertLt(_lastGas(), 1000, "Paso 4: isOwner gasta demasiado");
    }

    function test_PayEmitsPaid() public {
        vm.expectEmit(address(club));
        emit Club.Paid(alice, 7);
        vm.prank(alice);
        club.pay(7);
    }

    function test_Paso5_PayFitsBudget() public {
        vm.prank(alice);
        club.pay(7);
        assertLt(_lastGas(), 30_000, "Paso 5: pay gasta demasiado");
    }
}
