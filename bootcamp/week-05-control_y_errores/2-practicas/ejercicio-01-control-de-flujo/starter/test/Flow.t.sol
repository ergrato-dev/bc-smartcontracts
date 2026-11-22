// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Flow} from "../src/Flow.sol";

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
contract FlowTest is Test {
    Flow flow;

    function setUp() public {
        flow = new Flow();
    }

    function test_Step1_Max() public view {
        assertEq(flow.max(3, 7), 7);
        assertEq(flow.max(7, 3), 7);
        assertEq(flow.max(5, 5), 5);
    }

    function test_Step2_Sign() public view {
        assertEq(flow.sign(-42), -1);
        assertEq(flow.sign(0), 0);
        assertEq(flow.sign(42), 1);
    }

    function test_Step3_SumTo() public view {
        assertEq(flow.sumTo(0), 0);
        assertEq(flow.sumTo(10), 55);
    }

    function test_Step4_CountDigits() public view {
        assertEq(flow.countDigits(0), 1);
        assertEq(flow.countDigits(9), 1);
        assertEq(flow.countDigits(2026), 4);
    }

    function test_Step5_SumOdds() public view {
        assertEq(flow.sumOdds(10), 25);
        assertEq(flow.sumOdds(1), 1);
    }

    function test_Step6_SmallestDivisor() public view {
        assertEq(flow.smallestDivisor(91), 7);
        assertEq(flow.smallestDivisor(97), 97);
        assertEq(flow.smallestDivisor(4), 2);
    }
}
