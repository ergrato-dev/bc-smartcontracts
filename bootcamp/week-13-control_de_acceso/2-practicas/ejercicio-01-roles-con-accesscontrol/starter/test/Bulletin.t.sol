// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Bulletin} from "../src/Bulletin.sol";

contract BulletinTest is Test {
    Bulletin board;
    address admin = makeAddr("admin");
    address mod = makeAddr("mod");
    address editor = makeAddr("editor");
    address stranger = makeAddr("stranger");
    bytes32 MODERATOR;
    bytes32 EDITOR;

    function setUp() public {
        board = new Bulletin(admin);
        MODERATOR = board.MODERATOR_ROLE();
        EDITOR = board.EDITOR_ROLE();
    }

    // El administrador nombra a `mod` y `mod` nombra a `editor`.
    function _staff() internal {
        vm.prank(admin);
        board.grantRole(MODERATOR, mod);
        vm.prank(mod);
        board.grantRole(EDITOR, editor);
    }

    function _unauthorized(address account, bytes32 role) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, account, role);
    }

    function test_Step1_AdminIsTheParameter() public view {
        assertTrue(board.hasRole(board.DEFAULT_ADMIN_ROLE(), admin));
        assertFalse(board.hasRole(board.DEFAULT_ADMIN_ROLE(), address(this)));
    }

    function test_Step1_ModeratorsAdministerEditors() public view {
        assertEq(board.getRoleAdmin(EDITOR), MODERATOR);
        assertEq(board.getRoleAdmin(MODERATOR), board.DEFAULT_ADMIN_ROLE());
    }

    function test_Step1_ModeratorGrantsAndRevokesEditor() public {
        _staff();
        assertTrue(board.hasRole(EDITOR, editor));
        vm.prank(mod);
        board.revokeRole(EDITOR, editor);
        assertFalse(board.hasRole(EDITOR, editor));
    }

    function test_Step1_RevertWhen_AdminGrantsEditor() public {
        vm.prank(admin);
        vm.expectRevert(_unauthorized(admin, MODERATOR));
        board.grantRole(EDITOR, editor);
    }

    function test_Step2_EditorPublishes() public {
        _staff();
        vm.expectEmit(address(board));
        emit Bulletin.Published(1, editor, "hola");
        vm.prank(editor);
        assertEq(board.publish("hola"), 1);
        (address author, string memory text) = board.posts(1);
        assertEq(author, editor);
        assertEq(text, "hola");
        assertEq(board.nextId(), 2);
    }

    function test_Step2_RevertWhen_EmptyText() public {
        _staff();
        vm.prank(editor);
        vm.expectRevert(Bulletin.EmptyText.selector);
        board.publish("");
    }

    function test_Step2_RevertWhen_StrangerPublishes() public {
        vm.prank(stranger);
        vm.expectRevert(_unauthorized(stranger, EDITOR));
        board.publish("spam");
    }

    function test_Step3_ModeratorRemoves() public {
        _staff();
        vm.prank(editor);
        board.publish("hola");
        vm.expectEmit(address(board));
        emit Bulletin.Removed(1, mod);
        vm.prank(mod);
        board.remove(1);
        (address author,) = board.posts(1);
        assertEq(author, address(0));
    }

    function test_Step3_RevertWhen_PostNotFound() public {
        _staff();
        vm.prank(mod);
        vm.expectRevert(abi.encodeWithSelector(Bulletin.PostNotFound.selector, 7));
        board.remove(7);
    }

    function test_Step3_RevertWhen_EditorRemoves() public {
        vm.prank(editor);
        vm.expectRevert(_unauthorized(editor, MODERATOR));
        board.remove(1);
    }

    function test_Inherited_SupportsInterface() public view {
        assertTrue(board.supportsInterface(type(IAccessControl).interfaceId));
    }
}
