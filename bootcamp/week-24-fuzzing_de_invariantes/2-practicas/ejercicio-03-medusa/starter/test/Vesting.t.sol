// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {Vesting} from "../src/Vesting.sol";

// ¿Qué? Tests unitarios del vesting: una liberación a mitad de plazo y otra al final.
// ¿Para qué? Pasan desde el principio. No modifiques este archivo.
contract VestingTest is Test {
    Token token;
    Vesting vesting;
    address beneficiary = makeAddr("beneficiary");

    function setUp() public {
        token = new Token();
        vesting = new Vesting(token, beneficiary, 100 days, 1000e18);
        token.mint(address(vesting), 1000e18);
    }

    function test_ReleaseHalfway() public {
        skip(50 days);
        assertEq(vesting.release(), 500e18);
        assertEq(token.balanceOf(beneficiary), 500e18);
    }

    function test_ReleaseHalfwayThenAtEnd() public {
        skip(50 days);
        vesting.release();
        skip(50 days);
        assertEq(vesting.release(), 500e18);
        assertEq(token.balanceOf(beneficiary), 1000e18);
    }
}
