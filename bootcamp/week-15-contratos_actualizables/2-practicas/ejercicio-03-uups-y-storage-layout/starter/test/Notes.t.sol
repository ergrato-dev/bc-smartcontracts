// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {NotesV1, NotesV2, NotesV2Bad} from "../src/Notes.sol";

// Un contrato sin UUPS: si el proxy apuntara aquí, ya nunca podría actualizarse.
contract PlainCounter {
    uint256 public count;
}

contract NotesTest is Test {
    NotesV1 v1;
    NotesV2 v2;
    NotesV1 notes; // el proxy, visto como un NotesV1
    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        v1 = new NotesV1();
        v2 = new NotesV2();
        ERC1967Proxy proxy = new ERC1967Proxy(address(v1), abi.encodeCall(NotesV1.initialize, (owner)));
        notes = NotesV1(address(proxy));
        vm.prank(alice);
        notes.post("hello");
        vm.prank(bob);
        notes.post("world");
    }

    function _implementation() internal view returns (address) {
        return address(uint160(uint256(vm.load(address(notes), ERC1967Utils.IMPLEMENTATION_SLOT))));
    }

    // --- Dado ---

    function test_Given_StateLivesInSequentialSlots() public view {
        // `count` en el slot 0; Ownable e Initializable guardan lo suyo en slots de ERC-7201.
        assertEq(vm.load(address(notes), 0), bytes32(uint256(2)));
        assertEq(notes.owner(), owner);
    }

    function test_Given_RevertWhen_UpgradeIsCalledOnImplementation() public {
        vm.expectRevert(UUPSUpgradeable.UUPSUnauthorizedCallContext.selector);
        vm.prank(owner);
        v1.upgradeToAndCall(address(v2), "");
    }

    // --- Paso 1: _authorizeUpgrade ---

    function test_Step1_OwnerUpgradesKeepingNotes() public {
        vm.prank(owner);
        notes.upgradeToAndCall(address(v2), "");
        assertEq(_implementation(), address(v2));
        assertEq(notes.version(), 2);
        assertEq(notes.count(), 2);
        assertEq(notes.notes(1), "hello");
        assertEq(notes.notes(2), "world");
    }

    function test_Step1_RevertWhen_NotOwnerUpgrades() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        notes.upgradeToAndCall(address(v2), "");
    }

    function test_Step1_RevertWhen_ImplementationIsNotUups() public {
        address plain = address(new PlainCounter());
        vm.expectRevert(abi.encodeWithSelector(ERC1967Utils.ERC1967InvalidImplementation.selector, plain));
        vm.prank(owner);
        notes.upgradeToAndCall(plain, "");
    }

    function test_Step1_BadLayoutCorruptsState() public {
        NotesV2Bad bad = new NotesV2Bad();
        vm.prank(owner);
        notes.upgradeToAndCall(address(bad), "");
        NotesV2Bad broken = NotesV2Bad(address(notes));
        // `lastAuthor` lee el slot 0, que guardaba `count = 2`.
        assertEq(broken.lastAuthor(), address(2));
        // `count` lee el slot 1, la raíz del mapping `notes`, que siempre vale 0.
        assertEq(broken.count(), 0);
        // Y `notes` ya busca en otros slots: la nota 1 parece vacía.
        assertEq(broken.notes(1), "");
    }

    function test_Step1_NewVariableStartsEmpty() public {
        vm.prank(owner);
        notes.upgradeToAndCall(address(v2), "");
        assertEq(NotesV2(address(notes)).authorOf(1), address(0));
    }

    function test_Step1_V2CanUpgradeAgain() public {
        vm.startPrank(owner);
        notes.upgradeToAndCall(address(v2), "");
        notes.upgradeToAndCall(address(v1), "");
        vm.stopPrank();
        assertEq(notes.version(), 1);
        assertEq(notes.count(), 2);
    }

    // --- Paso 2: V2 ---

    function test_Step2_NewNoteGoesToTheSameSlots() public {
        vm.prank(owner);
        notes.upgradeToAndCall(address(v2), "");
        notes.post("again");
        assertEq(vm.load(address(notes), 0), bytes32(uint256(3)));
        assertEq(notes.notes(3), "again");
    }

    function test_Step2_V2RecordsTheAuthor() public {
        vm.prank(owner);
        notes.upgradeToAndCall(address(v2), "");
        vm.prank(alice);
        uint256 id = notes.post("again");
        assertEq(id, 3);
        assertEq(NotesV2(address(notes)).authorOf(3), alice);
    }
}
