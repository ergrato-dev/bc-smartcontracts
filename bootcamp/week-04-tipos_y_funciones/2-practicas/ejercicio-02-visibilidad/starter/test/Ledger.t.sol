// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Ledger} from "../src/Ledger.sol";

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
contract LedgerTest is Test {
    Ledger ledger;
    address alice = makeAddr("alice");

    function setUp() public {
        ledger = new Ledger();
    }

    function test_Step1_QuoteFee() public view {
        assertEq(ledger.quoteFee(1000), 10);
        assertEq(ledger.quoteFee(99), 0);
    }

    function test_Step2_Add() public {
        ledger.add(100);
        assertEq(ledger.total(), 99);
    }

    function test_Step3_AddTwice() public {
        ledger.addTwice(100);
        assertEq(ledger.total(), 198);
    }

    function test_Step4_Summary() public {
        vm.prank(alice);
        ledger.add(200);
        (uint256 total, address writer) = ledger.summary();
        assertEq(total, 198);
        assertEq(writer, alice);
    }

    function test_Step5_Preview() public view {
        (uint256 net, uint256 fee) = ledger.preview(500);
        assertEq(net, 495);
        assertEq(fee, 5);
    }

    function test_Step6_WasWrittenBy() public {
        vm.prank(alice);
        ledger.add(1);
        assertTrue(ledger.wasWrittenBy(alice));
        assertEq(ledger.wasWrittenBy(address(this)), false);
    }
}
