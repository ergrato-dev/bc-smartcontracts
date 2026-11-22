// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Points} from "../src/Points.sol";

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
contract PointsTest is Test {
    Points p;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        p = new Points();
    }

    function test_Step1_AddPoints() public {
        p.addPoints(alice, 10);
        p.addPoints(alice, 5);
        assertEq(p.points(alice), 15);
        assertEq(p.points(bob), 0);
    }

    function test_Step2_HasPoints() public {
        assertEq(p.hasPoints(alice), false);
        p.addPoints(alice, 1);
        assertTrue(p.hasPoints(alice));
    }

    function test_Step3_TransferPoints() public {
        p.addPoints(alice, 30);
        vm.prank(alice);
        p.transferPoints(bob, 12);
        assertEq(p.points(alice), 18);
        assertEq(p.points(bob), 12);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Points.InsufficientPoints.selector, 18, 20));
        p.transferPoints(bob, 20);
    }

    function test_Step4_SetFriend() public {
        vm.prank(alice);
        p.setFriend(bob, true);
        assertTrue(p.isFriend(alice, bob));
        assertEq(p.isFriend(bob, alice), false);
        vm.prank(alice);
        p.setFriend(bob, false);
        assertEq(p.isFriend(alice, bob), false);
    }

    function test_Step5_ResetPoints() public {
        p.addPoints(alice, 7);
        vm.prank(alice);
        p.resetPoints();
        assertEq(p.points(alice), 0);
    }

    function test_Step6_Join() public {
        assertEq(p.isMember(alice), false);
        vm.prank(alice);
        p.join();
        assertTrue(p.isMember(alice));
        assertEq(p.points(alice), 0);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Points.AlreadyMember.selector, alice));
        p.join();
    }
}
