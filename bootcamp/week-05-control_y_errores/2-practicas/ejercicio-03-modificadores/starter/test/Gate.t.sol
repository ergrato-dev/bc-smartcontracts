// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Gate} from "../src/Gate.sol";

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
contract GateTest is Test {
    Gate gate;
    address alice = makeAddr("alice");

    function setUp() public {
        gate = new Gate();
    }

    function test_Step1_OnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Gate.NotOwner.selector, alice));
        gate.setOpen(true);
        gate.setOpen(true);
        assertTrue(gate.isOpen());
    }

    function test_Step2_WhenOpen() public {
        vm.expectRevert(Gate.Closed.selector);
        gate.enter();
    }

    function test_Step3_WithinLimit() public {
        gate.setOpen(true);
        for (uint256 i = 0; i < 10; i++) {
            gate.enter();
        }
        assertEq(gate.count(), 10);
        vm.expectRevert(abi.encodeWithSelector(Gate.LimitExceeded.selector, 11, 10));
        gate.enter();
        assertEq(gate.count(), 10);
    }

    function test_Step4_ValidAmount() public {
        gate.setOpen(true);
        vm.expectRevert(abi.encodeWithSelector(Gate.InvalidAmount.selector, 0));
        gate.enterMany(0);
        vm.expectRevert(abi.encodeWithSelector(Gate.InvalidAmount.selector, 4));
        gate.enterMany(4);
    }

    function test_Step5_EnterMany() public {
        gate.setOpen(true);
        gate.enterMany(3);
        assertEq(gate.count(), 3);
        for (uint256 i = 0; i < 6; i++) {
            gate.enter();
        }
        vm.expectRevert(abi.encodeWithSelector(Gate.LimitExceeded.selector, 12, 10));
        gate.enterMany(3);
        assertEq(gate.count(), 9);
    }

    function test_Step6_Close() public {
        gate.setOpen(true);
        gate.enter();
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Gate.NotOwner.selector, alice));
        gate.close();
        gate.close();
        assertEq(gate.isOpen(), false);
        assertEq(gate.count(), 0);
    }
}
