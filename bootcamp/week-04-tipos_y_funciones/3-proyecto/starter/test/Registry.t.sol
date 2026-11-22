// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Registry} from "../src/Registry.sol";

// ¿Qué? Los 10 tests del proyecto. No los modifiques: comprueban propiedades del registro
//   (dueño, capacidad, cuenta, orden, quién llama), no los nombres de tu dominio.
contract RegistryTest is Test {
    Registry registry;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        registry = new Registry(3);
    }

    function test_ProtocolNameIsSet() public view {
        assertTrue(bytes(registry.PROTOCOL_NAME()).length > 0);
    }

    function test_ResourceNameIsSet() public view {
        assertTrue(bytes(registry.RESOURCE_NAME()).length > 0);
    }

    function test_OwnerIsDeployer() public {
        vm.prank(alice);
        Registry other = new Registry(1);
        assertEq(other.OWNER(), alice);
        assertEq(registry.OWNER(), address(this));
    }

    function test_CapacityIsSetAtDeploy() public view {
        assertEq(registry.CAPACITY(), 3);
    }

    function test_StartsEmpty() public view {
        assertEq(registry.count(), 0);
        assertEq(registry.lastRegistrant(), address(0));
        assertEq(registry.remaining(), 3);
    }

    function test_FirstIdIsOne() public {
        assertEq(registry.register(), 1);
    }

    function test_IdsAreSequential() public {
        registry.register();
        registry.register();
        assertEq(registry.register(), 3);
        assertEq(registry.count(), 3);
    }

    function test_RecordsLastRegistrant() public {
        vm.prank(alice);
        registry.register();
        vm.prank(bob);
        registry.register();
        assertEq(registry.lastRegistrant(), bob);
    }

    function test_RemainingDecreases() public {
        registry.register();
        assertEq(registry.remaining(), 2);
    }

    function test_IsFullAtCapacity() public {
        registry.register();
        registry.register();
        assertEq(registry.isFull(), false);
        registry.register();
        assertTrue(registry.isFull());
    }
}
