// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Types} from "../src/Types.sol";

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
contract TypesTest is Test {
    Types types;

    function setUp() public {
        types = new Types();
    }

    function test_Step1_MaxUint8() public view {
        assertEq(types.maxUint8(), 255);
    }

    function test_Step2_MinInt8() public view {
        assertEq(types.minInt8(), -128);
    }

    function test_Step3_IsAdult() public view {
        assertTrue(types.isAdult(18));
        assertEq(types.isAdult(17), false);
    }

    function test_Step4_ToUint8Truncates() public view {
        assertEq(types.toUint8(200), 200);
        assertEq(types.toUint8(256), 0);
        assertEq(types.toUint8(300), 44);
    }

    function test_Step5_SelectorOf() public view {
        assertEq(types.selectorOf("increment()"), bytes4(0xd09de08a));
    }

    function test_Step6_IsZeroAddress() public view {
        assertTrue(types.isZeroAddress(address(0)));
        assertEq(types.isZeroAddress(address(this)), false);
    }
}
