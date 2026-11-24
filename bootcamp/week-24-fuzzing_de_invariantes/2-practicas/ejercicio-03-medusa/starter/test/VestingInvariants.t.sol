// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {VestingProperties} from "./VestingProperties.sol";

// ¿Qué? La misma propiedad con el fuzzer de forge: el harness es el objetivo y cada `invariant_`
//   comprueba una `property_`. No modifiques este archivo.
contract VestingInvariantsTest is Test {
    VestingProperties props;

    function setUp() public {
        props = new VestingProperties();
        targetContract(address(props));
    }

    function invariant_ReceivedWithinVested() public view {
        assertTrue(props.property_receivedWithinVested());
    }
}
