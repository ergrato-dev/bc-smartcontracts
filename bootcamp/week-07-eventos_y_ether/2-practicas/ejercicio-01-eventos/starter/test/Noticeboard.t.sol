// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Noticeboard} from "../src/Noticeboard.sol";

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
// `vm.expectEmit()` + `emit ...` dice "la próxima llamada tiene que emitir este evento,
//   con estos mismos valores".
contract NoticeboardTest is Test {
    Noticeboard board;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        board = new Noticeboard();
    }

    function test_Step1_Post() public {
        vm.expectEmit();
        emit Noticeboard.Posted(1, alice, "hola");
        vm.prank(alice);
        uint256 id = board.post("hola");
        assertEq(id, 1);
        assertEq(board.authorOf(1), alice);
        assertEq(board.textOf(1), "hola");
    }

    function test_Step2_Edit() public {
        vm.prank(alice);
        board.post("hola");
        vm.expectEmit();
        emit Noticeboard.Edited(1, "hola", "adios");
        vm.prank(alice);
        board.edit(1, "adios");
        assertEq(board.textOf(1), "adios");
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Noticeboard.NotAuthor.selector, bob, 1));
        board.edit(1, "mio");
    }

    function test_Step3_Like() public {
        vm.prank(alice);
        board.post("hola");
        vm.prank(alice);
        board.like(1);
        vm.expectEmit();
        emit Noticeboard.Liked(1, bob, 2);
        vm.prank(bob);
        board.like(1);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Noticeboard.AlreadyLiked.selector, 1));
        board.like(1);
        vm.expectRevert(abi.encodeWithSelector(Noticeboard.PostNotFound.selector, 9));
        board.like(9);
    }

    function test_Step4_Remove() public {
        vm.prank(alice);
        board.post("hola");
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Noticeboard.NotAuthor.selector, bob, 1));
        board.remove(1);
        vm.expectEmit();
        emit Noticeboard.Removed(1);
        vm.prank(alice);
        board.remove(1);
        assertEq(board.authorOf(1), address(0));
        assertEq(board.textOf(1), "");
    }

    function test_Step5_PostedTopic() public view {
        assertEq(board.postedTopic(), keccak256("Posted(uint256,address,string)"));
    }
}
