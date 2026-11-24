// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {MathAsm} from "../src/MathAsm.sol";

// ¿Qué? Cada función en assembly contra la misma cuenta en Solidity, con entradas al azar.
// ¿Para qué? Un test diferencial: Solidity es la referencia y el assembly tiene que dar lo mismo,
//   también en los bordes (máximos, negativos, desbordamientos).
contract MathAsmTest is Test {
    MathAsm math;

    function setUp() public {
        math = new MathAsm();
    }

    function testFuzz_Paso1_AddUncheckedWraps(uint256 a, uint256 b) public view {
        uint256 expected;
        unchecked {
            expected = a + b;
        }
        assertEq(math.addUnchecked(a, b), expected);
    }

    function test_Paso1_MaxPlusOneIsZero() public view {
        assertEq(math.addUnchecked(type(uint256).max, 1), 0);
    }

    function testFuzz_Paso2_AddCheckedLikeSolidity(uint256 a, uint256 b) public {
        uint256 wrapped;
        unchecked {
            wrapped = a + b;
        }
        if (wrapped < a) {
            vm.expectRevert(stdError.arithmeticError);
            math.addChecked(a, b);
        } else {
            assertEq(math.addChecked(a, b), wrapped);
        }
    }

    function testFuzz_Paso3_Sign(int256 x) public view {
        int256 expected = x > 0 ? int256(1) : x < 0 ? -1 : int256(0);
        assertEq(math.sign(x), expected);
    }

    function testFuzz_Paso4_Sum(uint128[] memory small) public view {
        uint256[] memory xs = new uint256[](small.length);
        uint256 expected;
        for (uint256 i = 0; i < small.length; i++) {
            xs[i] = small[i];
            expected += small[i];
        }
        assertEq(math.sum(xs), expected);
    }

    function test_Paso4_SumOverflows() public {
        uint256[] memory xs = new uint256[](3);
        xs[0] = 1;
        xs[1] = type(uint256).max;
        vm.expectRevert(stdError.arithmeticError);
        math.sum(xs);
    }
}
