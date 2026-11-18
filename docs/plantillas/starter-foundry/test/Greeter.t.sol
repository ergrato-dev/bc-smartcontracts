// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Greeter} from "../src/Greeter.sol";

contract GreeterTest is Test {
    function test_greet() public {
        Greeter greeter = new Greeter();
        assertEq(greeter.greet(), "Hola, blockchain");
    }
}
