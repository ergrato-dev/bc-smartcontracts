// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Readings} from "../src/Readings.sol";

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
contract ReadingsTest is Test {
    Readings r;

    function setUp() public {
        r = new Readings();
    }

    function _fill(uint256 n) internal {
        for (uint256 i = 1; i <= n; i++) {
            r.add(i * 10);
        }
    }

    function test_Step1_Add() public {
        _fill(3);
        assertEq(r.getAll().length, 3);
        assertEq(r.values(0), 10);
        assertEq(r.values(2), 30);
        _fill(7);
        vm.expectRevert(abi.encodeWithSelector(Readings.ListFull.selector, 10));
        r.add(1);
    }

    function test_Step2_RemoveLast() public {
        _fill(2);
        r.removeLast();
        assertEq(r.getAll().length, 1);
        r.removeLast();
        vm.expectRevert(Readings.EmptyList.selector);
        r.removeLast();
    }

    function test_Step3_RemoveAt() public {
        _fill(4); // [10, 20, 30, 40]
        r.removeAt(1); // [10, 40, 30]
        uint256[] memory all = r.getAll();
        assertEq(all.length, 3);
        assertEq(all[0], 10);
        assertEq(all[1], 40);
        assertEq(all[2], 30);
        vm.expectRevert(abi.encodeWithSelector(Readings.IndexOutOfBounds.selector, 3, 3));
        r.removeAt(3);
    }

    function test_Step4_Sum() public {
        assertEq(r.sum(), 0);
        _fill(4);
        assertEq(r.sum(), 100);
    }

    function test_Step5_SetPodium() public {
        r.setPodium([uint256(90), 80, 70]);
        assertEq(r.podium(0), 90);
        assertEq(r.podium(2), 70);
    }

    function test_Step6_FirstN() public {
        _fill(4);
        uint256[] memory firstTwo = r.firstN(2);
        assertEq(firstTwo.length, 2);
        assertEq(firstTwo[1], 20);
        assertEq(r.firstN(0).length, 0);
        vm.expectRevert(abi.encodeWithSelector(Readings.IndexOutOfBounds.selector, 5, 4));
        r.firstN(5);
    }
}
