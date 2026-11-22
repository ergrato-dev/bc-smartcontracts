// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Registry} from "../src/Registry.sol";
import {IRegistry} from "../src/IRegistry.sol";
import {IERC165} from "../src/IERC165.sol";
import {Owned} from "../src/Owned.sol";
import {Openable} from "../src/Openable.sol";
import {LabelLib} from "../src/LabelLib.sol";

// ¿Qué? Un contrato sin `receive` ni `fallback`: rechaza todo ETH.
contract NoReceive {}

// ¿Qué? Contratos mínimos que heredan las piezas o usan la librería, para probarlas solas.
contract OwnedHarness is Owned {
    function guarded() external view onlyOwner returns (bool) {
        return true;
    }
}

contract OpenableHarness is Openable {
    function guarded() external view whenOpen returns (bool) {
        return true;
    }
}

contract LabelHarness {
    function isValid(string calldata label) external pure returns (bool) {
        return LabelLib.isValid(label);
    }
}

// ¿Qué? Los 44 tests del proyecto. No los modifiques: comprueban las reglas, los datos, los
//   eventos, los pagos y las piezas del registro, no los nombres de tu dominio.
// ¿Para qué? Cada error y cada evento se nombra por la pieza que lo declara (IRegistry,
//   Owned, Openable o Registry), y los recursos se leen a través de IRegistry.
contract RegistryTest is Test {
    Registry registry;
    uint256 fee;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        registry = new Registry(3);
        fee = registry.REGISTRATION_FEE();
        vm.deal(address(this), 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    function _labels(uint256 n) internal pure returns (string[] memory labels) {
        labels = new string[](n);
        for (uint256 i = 0; i < n; i++) {
            labels[i] = "item";
        }
    }

    function _item(uint256 id) internal view returns (IRegistry.Item memory) {
        return IRegistry(address(registry)).getItem(id);
    }

    // --- Lo que ya hacía la semana 06, ahora pagando la tasa ---

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
        registry.register{value: fee}("a");
        registry.register{value: fee}("b");
        registry.register{value: fee}("c");
        assertTrue(registry.isFull());
        assertEq(registry.remaining(), 0);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.RegistryFull.selector, 3));
        registry.register{value: fee}("d");
    }

    function test_OwnerCanCloseAndReopen() public {
        registry.setOpen(false);
        assertEq(registry.isOpen(), false);
        registry.setOpen(true);
        assertEq(registry.register{value: fee}("a"), 1);
    }

    function test_RevertWhen_NotOwnerSetsOpen() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Owned.NotOwner.selector, alice));
        registry.setOpen(false);
    }

    function test_RevertWhen_RegisterWhileClosed() public {
        registry.setOpen(false);
        vm.expectRevert(Openable.RegistryClosed.selector);
        registry.register{value: fee}("a");
    }

    function test_RegisterStoresItem() public {
        vm.prank(alice);
        uint256 id = registry.register{value: fee}("north");
        IRegistry.Item memory item = _item(id);
        assertEq(item.id, 1);
        assertEq(item.registrant, alice);
        assertTrue(item.status == IRegistry.Status.Active);
        assertEq(item.registeredAt, block.timestamp);
        assertEq(item.label, "north");
    }

    function test_IdsAreSequential() public {
        assertEq(registry.register{value: fee}("a"), 1);
        assertEq(registry.register{value: fee}("b"), 2);
        assertEq(registry.count(), 2);
        assertEq(registry.activeCount(), 2);
    }

    function test_RevertWhen_LabelIsEmpty() public {
        vm.expectRevert(IRegistry.InvalidLabel.selector);
        registry.register{value: fee}("");
    }

    function test_RevertWhen_LabelTooLong() public {
        // 33 bytes: uno más que MAX_LABEL_LENGTH.
        vm.expectRevert(IRegistry.InvalidLabel.selector);
        registry.register{value: fee}("123456789012345678901234567890123");
        assertEq(registry.register{value: fee}("12345678901234567890123456789012"), 1);
    }

    function test_RevertWhen_ItemNotFound() public {
        vm.expectRevert(abi.encodeWithSelector(IRegistry.ItemNotFound.selector, 1));
        _item(1);
    }

    function test_IdsOfListsEachRegistrant() public {
        vm.prank(alice);
        registry.register{value: fee}("a");
        vm.prank(bob);
        registry.register{value: fee}("b");
        vm.prank(alice);
        registry.register{value: fee}("c");
        uint256[] memory ids = registry.idsOf(alice);
        assertEq(ids.length, 2);
        assertEq(ids[0], 1);
        assertEq(ids[1], 3);
        assertEq(registry.idsOf(bob).length, 1);
    }

    function test_RegisterBatch() public {
        registry.register{value: fee}("a");
        vm.prank(alice);
        assertEq(registry.registerBatch{value: 2 * fee}(_labels(2)), 2);
        assertEq(registry.count(), 3);
        assertEq(_item(3).registrant, alice);
        assertEq(registry.idsOf(alice).length, 2);
    }

    function test_RevertWhen_BatchIsEmpty() public {
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidAmount.selector, 0));
        registry.registerBatch(_labels(0));
    }

    function test_RevertWhen_BatchAboveMax() public {
        Registry big = new Registry(100);
        uint256 tooMany = big.MAX_BATCH() + 1;
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidAmount.selector, tooMany));
        big.registerBatch{value: tooMany * fee}(_labels(tooMany));
    }

    function test_RevertWhen_BatchExceedsCapacity() public {
        registry.register{value: fee}("a");
        vm.expectRevert(abi.encodeWithSelector(IRegistry.RegistryFull.selector, 3));
        registry.registerBatch{value: 3 * fee}(_labels(3));
        assertEq(registry.count(), 1);
    }

    function test_RevertWhen_BatchHasInvalidLabel() public {
        string[] memory labels = _labels(3);
        labels[2] = "";
        vm.expectRevert(IRegistry.InvalidLabel.selector);
        registry.registerBatch{value: 3 * fee}(labels);
        assertEq(registry.count(), 0);
        assertEq(address(registry).balance, 0);
    }

    function test_RetireFreesCapacity() public {
        vm.prank(alice);
        registry.register{value: fee}("a");
        registry.register{value: fee}("b");
        registry.register{value: fee}("c");
        vm.prank(alice);
        registry.retire(1);
        assertTrue(_item(1).status == IRegistry.Status.Retired);
        assertEq(registry.activeCount(), 2);
        assertEq(registry.remaining(), 1);
        assertEq(registry.isFull(), false);
    }

    function test_RetiredIdsAreNotReused() public {
        registry.register{value: fee}("a");
        registry.retire(1);
        assertEq(registry.register{value: fee}("b"), 2);
        assertEq(_item(1).label, "a");
    }

    function test_RevertWhen_NotRegistrantRetires() public {
        vm.prank(alice);
        registry.register{value: fee}("a");
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.NotRegistrant.selector, bob, 1));
        registry.retire(1);
    }

    function test_RevertWhen_RetireTwiceOrMissing() public {
        registry.register{value: fee}("a");
        registry.retire(1);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.ItemNotActive.selector, 1));
        registry.retire(1);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.ItemNotFound.selector, 9));
        registry.retire(9);
    }

    // --- Tasa en ETH ---

    function test_FeeIsPositive() public view {
        assertTrue(fee > 0);
    }

    function test_RegisterKeepsTheFee() public {
        vm.prank(alice);
        registry.register{value: fee}("a");
        assertEq(address(registry).balance, fee);
        assertEq(alice.balance, 100 ether - fee);
    }

    function test_RevertWhen_FeeIsWrong() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.WrongFee.selector, fee, 0));
        registry.register("a");
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.WrongFee.selector, fee, fee + 1));
        registry.register{value: fee + 1}("a");
        assertEq(alice.balance, 100 ether);
    }

    function test_BatchChargesOneFeePerItem() public {
        vm.prank(alice);
        registry.registerBatch{value: 3 * fee}(_labels(3));
        assertEq(address(registry).balance, 3 * fee);
        Registry other = new Registry(5);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.WrongFee.selector, 2 * fee, fee));
        other.registerBatch{value: fee}(_labels(2));
    }

    function test_RevertWhen_DirectPayment() public {
        vm.prank(alice);
        (bool ok,) = address(registry).call{value: 1 ether}("");
        assertEq(ok, false);
        assertEq(address(registry).balance, 0);
    }

    // --- Eventos ---

    function test_RegisterEmitsEvent() public {
        vm.expectEmit();
        emit IRegistry.ItemRegistered(1, alice, "north");
        vm.prank(alice);
        registry.register{value: fee}("north");
    }

    function test_BatchEmitsOneEventPerItem() public {
        vm.expectEmit();
        emit IRegistry.ItemRegistered(1, alice, "item");
        vm.expectEmit();
        emit IRegistry.ItemRegistered(2, alice, "item");
        vm.prank(alice);
        registry.registerBatch{value: 2 * fee}(_labels(2));
    }

    function test_RetireEmitsEvent() public {
        vm.prank(alice);
        registry.register{value: fee}("a");
        vm.expectEmit();
        emit IRegistry.ItemRetired(1, alice);
        vm.prank(alice);
        registry.retire(1);
    }

    function test_SetOpenEmitsEvent() public {
        vm.expectEmit();
        emit Openable.OpenChanged(false);
        registry.setOpen(false);
    }

    // --- Retirada de tasas ---

    function test_OwnerWithdrawsFees() public {
        vm.prank(alice);
        registry.register{value: fee}("a");
        vm.prank(bob);
        registry.register{value: fee}("b");
        vm.expectEmit();
        emit Registry.FeesWithdrawn(bob, 2 * fee);
        registry.withdrawFees(payable(bob));
        assertEq(address(registry).balance, 0);
        assertEq(bob.balance, 100 ether + fee);
    }

    function test_RevertWhen_NotOwnerWithdraws() public {
        registry.register{value: fee}("a");
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Owned.NotOwner.selector, alice));
        registry.withdrawFees(payable(alice));
    }

    function test_RevertWhen_NothingToWithdraw() public {
        vm.expectRevert(Registry.NothingToWithdraw.selector);
        registry.withdrawFees(payable(bob));
    }

    function test_RevertWhen_WithdrawToZeroAddress() public {
        registry.register{value: fee}("a");
        vm.expectRevert(Registry.ZeroAddress.selector);
        registry.withdrawFees(payable(address(0)));
    }

    function test_RevertWhen_FeeTransferFails() public {
        registry.register{value: fee}("a");
        NoReceive sink = new NoReceive();
        vm.expectRevert(abi.encodeWithSelector(Registry.TransferFailed.selector, address(sink), fee));
        registry.withdrawFees(payable(address(sink)));
        assertEq(address(registry).balance, fee);
    }

    // --- Las piezas de la semana 08 ---

    function test_OwnedRejectsOthers() public {
        OwnedHarness owned = new OwnedHarness();
        assertTrue(owned.guarded());
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Owned.NotOwner.selector, alice));
        owned.guarded();
    }

    function test_OpenableBlocksWhenClosed() public {
        OpenableHarness openable = new OpenableHarness();
        assertTrue(openable.guarded());
        vm.expectEmit();
        emit Openable.OpenChanged(false);
        openable.setOpen(false);
        vm.expectRevert(Openable.RegistryClosed.selector);
        openable.guarded();
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Owned.NotOwner.selector, alice));
        openable.setOpen(true);
    }

    function test_LabelLibAcceptsValidLabels() public {
        LabelHarness labels = new LabelHarness();
        assertTrue(labels.isValid("a"));
        assertTrue(labels.isValid("abcdefghijklmnopqrstuvwxyz012345"));
    }

    function test_LabelLibRejectsInvalidLabels() public {
        LabelHarness labels = new LabelHarness();
        assertFalse(labels.isValid(""));
        assertFalse(labels.isValid("abcdefghijklmnopqrstuvwxyz0123456"));
    }

    function test_InterfaceDeclaresTheRegistryFunctions() public view {
        bytes4 expected = registry.register.selector ^ registry.registerBatch.selector ^ registry.retire.selector
            ^ registry.getItem.selector ^ registry.idsOf.selector ^ registry.remaining.selector
            ^ registry.isFull.selector;
        assertEq(type(IRegistry).interfaceId, expected);
    }

    function test_SupportsIRegistryAndERC165() public view {
        assertTrue(registry.supportsInterface(type(IRegistry).interfaceId));
        assertTrue(registry.supportsInterface(type(IERC165).interfaceId));
    }

    function test_DoesNotSupportOtherInterfaces() public view {
        assertFalse(registry.supportsInterface(0xffffffff));
        assertFalse(registry.supportsInterface(0x12345678));
    }
}
