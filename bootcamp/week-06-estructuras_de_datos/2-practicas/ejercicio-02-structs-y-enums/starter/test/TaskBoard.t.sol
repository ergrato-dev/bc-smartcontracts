// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {TaskBoard} from "../src/TaskBoard.sol";

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
contract TaskBoardTest is Test {
    TaskBoard board;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        board = new TaskBoard();
    }

    function test_Step1_CreateTask() public {
        vm.prank(alice);
        assertEq(board.createTask("write tests", 2), 1);
        assertEq(board.createTask("deploy", 1), 2);
        // El getter público de un mapping de structs devuelve los campos sueltos.
        (string memory title, address owner, uint8 priority, TaskBoard.Status status) = board.tasks(1);
        assertEq(title, "write tests");
        assertEq(owner, alice);
        assertEq(priority, 2);
        assertTrue(status == TaskBoard.Status.Todo);
    }

    function test_Step2_GetTask() public {
        vm.prank(alice);
        board.createTask("write tests", 2);
        TaskBoard.Task memory task = board.getTask(1);
        assertEq(task.title, "write tests");
        assertEq(task.owner, alice);
        vm.expectRevert(abi.encodeWithSelector(TaskBoard.TaskNotFound.selector, 2));
        board.getTask(2);
    }

    function test_Step3_Start() public {
        vm.prank(alice);
        board.createTask("write tests", 2);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(TaskBoard.NotTaskOwner.selector, bob));
        board.start(1);
        vm.prank(alice);
        board.start(1);
        (,,, TaskBoard.Status status) = board.tasks(1);
        assertTrue(status == TaskBoard.Status.Doing);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(TaskBoard.InvalidStatus.selector, TaskBoard.Status.Doing));
        board.start(1);
    }

    function test_Step4_Finish() public {
        vm.prank(alice);
        board.createTask("write tests", 2);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(TaskBoard.InvalidStatus.selector, TaskBoard.Status.Todo));
        board.finish(1);
        vm.prank(alice);
        board.start(1);
        vm.prank(alice);
        board.finish(1);
        (,,, TaskBoard.Status status) = board.tasks(1);
        assertTrue(status == TaskBoard.Status.Done);
    }

    function test_Step5_StatusCode() public {
        vm.prank(alice);
        board.createTask("write tests", 2);
        (uint8 code, uint8 maxCode) = board.statusCode(1);
        assertEq(code, 0);
        assertEq(maxCode, 2);
        vm.prank(alice);
        board.start(1);
        (code,) = board.statusCode(1);
        assertEq(code, 1);
    }

    function test_Step6_RemoveTask() public {
        vm.prank(alice);
        board.createTask("write tests", 2);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(TaskBoard.NotTaskOwner.selector, bob));
        board.removeTask(1);
        vm.prank(alice);
        board.removeTask(1);
        (string memory title, address owner,,) = board.tasks(1);
        assertEq(title, "");
        assertEq(owner, address(0));
        assertEq(board.taskCount(), 1);
    }
}
