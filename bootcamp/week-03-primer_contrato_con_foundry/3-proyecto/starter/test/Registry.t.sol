// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Registry} from "../src/Registry.sol";

// ¿Qué? Los 8 tests del proyecto. No los modifiques: comprueban propiedades del registro
//   (cuenta, orden, quién llama), no los nombres de tu dominio.
contract RegistryTest is Test {
    Registry registry;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        registry = new Registry();
    }

    function test_ProtocolNameIsSet() public view {
        assertTrue(bytes(registry.protocolName()).length > 0);
    }

    function test_ResourceNameIsSet() public view {
        assertTrue(bytes(registry.resourceName()).length > 0);
    }

    function test_StartsEmpty() public view {
        assertEq(registry.total(), 0);
        assertEq(registry.lastRegistrant(), address(0));
    }

    function test_FirstIdIsOne() public {
        assertEq(registry.register(), 1);
    }

    function test_IdsAreSequential() public {
        registry.register();
        registry.register();
        assertEq(registry.register(), 3);
        assertEq(registry.total(), 3);
    }

    function test_RecordsCaller() public {
        vm.prank(alice);
        registry.register();
        assertEq(registry.lastRegistrant(), alice);
    }

    function test_LastRegistrantIsTheLatest() public {
        vm.prank(alice);
        registry.register();
        vm.prank(bob);
        registry.register();
        assertEq(registry.lastRegistrant(), bob);
        assertEq(registry.total(), 2);
    }

    function test_DeploymentsAreIndependent() public {
        Registry other = new Registry();
        registry.register();
        assertEq(other.total(), 0);
    }
}
