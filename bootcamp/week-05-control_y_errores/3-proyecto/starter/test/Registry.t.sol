// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Registry} from "../src/Registry.sol";

// ¿Qué? Los 18 tests del proyecto. No los modifiques: comprueban las reglas del registro
//   (capacidad, apertura, dueño, lotes), no los nombres de tu dominio.
contract RegistryTest is Test {
    Registry registry;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        registry = new Registry(3);
    }

    // --- Lo que ya hacía la semana 04 ---

    function test_NamesAreSet() public view {
        assertTrue(bytes(registry.PROTOCOL_NAME()).length > 0);
        assertTrue(bytes(registry.RESOURCE_NAME()).length > 0);
    }

    function test_OwnerAndCapacityAreSetAtDeploy() public {
        vm.prank(alice);
        Registry other = new Registry(1);
        assertEq(other.OWNER(), alice);
        assertEq(other.CAPACITY(), 1);
    }

    function test_StartsEmptyAndOpen() public view {
        assertEq(registry.count(), 0);
        assertEq(registry.remaining(), 3);
        assertTrue(registry.isOpen());
    }

    function test_IdsAreSequential() public {
        assertEq(registry.register(), 1);
        assertEq(registry.register(), 2);
        assertEq(registry.count(), 2);
    }

    function test_RecordsLastRegistrant() public {
        vm.prank(alice);
        registry.register();
        vm.prank(bob);
        registry.register();
        assertEq(registry.lastRegistrant(), bob);
    }

    // --- Capacidad ---

    function test_RevertWhen_CapacityIsZero() public {
        vm.expectRevert(Registry.InvalidCapacity.selector);
        new Registry(0);
    }

    function test_RevertWhen_Full() public {
        registry.register();
        registry.register();
        registry.register();
        assertTrue(registry.isFull());
        vm.expectRevert(abi.encodeWithSelector(Registry.RegistryFull.selector, 3));
        registry.register();
    }

    function test_RemainingIsZeroWhenFull() public {
        registry.register();
        registry.register();
        registry.register();
        assertEq(registry.remaining(), 0);
    }

    // --- Apertura y dueño ---

    function test_OwnerCanClose() public {
        registry.setOpen(false);
        assertEq(registry.isOpen(), false);
    }

    function test_RevertWhen_NotOwnerSetsOpen() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Registry.NotOwner.selector, alice));
        registry.setOpen(false);
    }

    function test_RevertWhen_RegisterWhileClosed() public {
        registry.setOpen(false);
        vm.expectRevert(Registry.RegistryClosed.selector);
        registry.register();
    }

    function test_OwnerCanReopen() public {
        registry.setOpen(false);
        registry.setOpen(true);
        assertEq(registry.register(), 1);
    }

    // --- Lotes ---

    function test_RegisterBatch() public {
        registry.register();
        vm.prank(alice);
        assertEq(registry.registerBatch(2), 2);
        assertEq(registry.count(), 3);
        assertEq(registry.lastRegistrant(), alice);
    }

    function test_RevertWhen_BatchIsZero() public {
        vm.expectRevert(abi.encodeWithSelector(Registry.InvalidAmount.selector, 0));
        registry.registerBatch(0);
    }

    function test_RevertWhen_BatchAboveMax() public {
        Registry big = new Registry(100);
        uint256 tooMany = big.MAX_BATCH() + 1;
        vm.expectRevert(abi.encodeWithSelector(Registry.InvalidAmount.selector, tooMany));
        big.registerBatch(tooMany);
    }

    function test_RevertWhen_BatchExceedsCapacity() public {
        registry.register();
        vm.expectRevert(abi.encodeWithSelector(Registry.RegistryFull.selector, 3));
        registry.registerBatch(3);
        assertEq(registry.count(), 1);
    }

    function test_RevertWhen_BatchWhileClosed() public {
        registry.setOpen(false);
        vm.expectRevert(Registry.RegistryClosed.selector);
        registry.registerBatch(1);
    }

    function test_FailedCallChangesNothing() public {
        vm.prank(alice);
        registry.register();
        registry.setOpen(false);
        vm.prank(bob);
        vm.expectRevert(Registry.RegistryClosed.selector);
        registry.register();
        assertEq(registry.count(), 1);
        assertEq(registry.lastRegistrant(), alice);
    }
}
