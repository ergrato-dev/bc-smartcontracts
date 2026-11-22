// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Registry} from "../src/Registry.sol";

// ¿Qué? Los 23 tests del proyecto. No los modifiques: comprueban las reglas y los datos del
//   registro (capacidad, apertura, dueño, lotes, recursos y retiro), no los nombres de tu
//   dominio.
contract RegistryTest is Test {
    Registry registry;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        registry = new Registry(3);
    }

    function _labels(uint256 n) internal pure returns (string[] memory labels) {
        labels = new string[](n);
        for (uint256 i = 0; i < n; i++) {
            labels[i] = "item";
        }
    }

    // --- Lo que ya hacía la semana 05 ---

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
        assertEq(registry.activeCount(), 0);
        assertEq(registry.remaining(), 3);
        assertTrue(registry.isOpen());
    }

    function test_RevertWhen_CapacityIsZero() public {
        vm.expectRevert(Registry.InvalidCapacity.selector);
        new Registry(0);
    }

    function test_RevertWhen_Full() public {
        registry.register("a");
        registry.register("b");
        registry.register("c");
        assertTrue(registry.isFull());
        assertEq(registry.remaining(), 0);
        vm.expectRevert(abi.encodeWithSelector(Registry.RegistryFull.selector, 3));
        registry.register("d");
    }

    function test_OwnerCanCloseAndReopen() public {
        registry.setOpen(false);
        assertEq(registry.isOpen(), false);
        registry.setOpen(true);
        assertEq(registry.register("a"), 1);
    }

    function test_RevertWhen_NotOwnerSetsOpen() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Registry.NotOwner.selector, alice));
        registry.setOpen(false);
    }

    function test_RevertWhen_RegisterWhileClosed() public {
        registry.setOpen(false);
        vm.expectRevert(Registry.RegistryClosed.selector);
        registry.register("a");
    }

    // --- Cada recurso es un struct ---

    function test_RegisterStoresItem() public {
        vm.prank(alice);
        uint256 id = registry.register("north");
        Registry.Item memory item = registry.getItem(id);
        assertEq(item.id, 1);
        assertEq(item.registrant, alice);
        assertTrue(item.status == Registry.Status.Active);
        assertEq(item.label, "north");
    }

    function test_IdsAreSequential() public {
        assertEq(registry.register("a"), 1);
        assertEq(registry.register("b"), 2);
        assertEq(registry.count(), 2);
        assertEq(registry.activeCount(), 2);
    }

    function test_RevertWhen_LabelIsEmpty() public {
        vm.expectRevert(Registry.InvalidLabel.selector);
        registry.register("");
    }

    function test_RevertWhen_LabelTooLong() public {
        // 33 bytes: uno más que MAX_LABEL_LENGTH.
        vm.expectRevert(Registry.InvalidLabel.selector);
        registry.register("123456789012345678901234567890123");
        assertEq(registry.register("12345678901234567890123456789012"), 1);
    }

    function test_RevertWhen_ItemNotFound() public {
        vm.expectRevert(abi.encodeWithSelector(Registry.ItemNotFound.selector, 1));
        registry.getItem(1);
    }

    function test_IdsOfListsEachRegistrant() public {
        vm.prank(alice);
        registry.register("a");
        vm.prank(bob);
        registry.register("b");
        vm.prank(alice);
        registry.register("c");
        uint256[] memory ids = registry.idsOf(alice);
        assertEq(ids.length, 2);
        assertEq(ids[0], 1);
        assertEq(ids[1], 3);
        assertEq(registry.idsOf(bob).length, 1);
    }

    // --- Lotes ---

    function test_RegisterBatch() public {
        registry.register("a");
        vm.prank(alice);
        assertEq(registry.registerBatch(_labels(2)), 2);
        assertEq(registry.count(), 3);
        assertEq(registry.getItem(3).registrant, alice);
        assertEq(registry.idsOf(alice).length, 2);
    }

    function test_RevertWhen_BatchIsEmpty() public {
        vm.expectRevert(abi.encodeWithSelector(Registry.InvalidAmount.selector, 0));
        registry.registerBatch(_labels(0));
    }

    function test_RevertWhen_BatchAboveMax() public {
        Registry big = new Registry(100);
        uint256 tooMany = big.MAX_BATCH() + 1;
        vm.expectRevert(abi.encodeWithSelector(Registry.InvalidAmount.selector, tooMany));
        big.registerBatch(_labels(tooMany));
    }

    function test_RevertWhen_BatchExceedsCapacity() public {
        registry.register("a");
        vm.expectRevert(abi.encodeWithSelector(Registry.RegistryFull.selector, 3));
        registry.registerBatch(_labels(3));
        assertEq(registry.count(), 1);
    }

    function test_RevertWhen_BatchHasInvalidLabel() public {
        string[] memory labels = _labels(3);
        labels[2] = "";
        vm.expectRevert(Registry.InvalidLabel.selector);
        registry.registerBatch(labels);
        assertEq(registry.count(), 0);
        assertEq(registry.idsOf(address(this)).length, 0);
    }

    // --- Retiro ---

    function test_RetireFreesCapacity() public {
        vm.prank(alice);
        registry.register("a");
        registry.register("b");
        registry.register("c");
        vm.prank(alice);
        registry.retire(1);
        assertTrue(registry.getItem(1).status == Registry.Status.Retired);
        assertEq(registry.activeCount(), 2);
        assertEq(registry.remaining(), 1);
        assertEq(registry.isFull(), false);
    }

    function test_RetiredIdsAreNotReused() public {
        registry.register("a");
        registry.retire(1);
        assertEq(registry.register("b"), 2);
        assertEq(registry.getItem(1).label, "a");
    }

    function test_RevertWhen_NotRegistrantRetires() public {
        vm.prank(alice);
        registry.register("a");
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Registry.NotRegistrant.selector, bob, 1));
        registry.retire(1);
    }

    function test_RevertWhen_RetireTwiceOrMissing() public {
        registry.register("a");
        registry.retire(1);
        vm.expectRevert(abi.encodeWithSelector(Registry.ItemNotActive.selector, 1));
        registry.retire(1);
        vm.expectRevert(abi.encodeWithSelector(Registry.ItemNotFound.selector, 9));
        registry.retire(9);
    }
}
