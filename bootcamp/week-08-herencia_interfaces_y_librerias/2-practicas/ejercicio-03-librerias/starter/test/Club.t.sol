// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Bps} from "../src/Bps.sol";
import {AddressList} from "../src/AddressList.sol";
import {Club} from "../src/Club.sol";

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
// ¿Para qué? Los pasos 1 a 3 usan las librerías desde el propio test: también es un
//   contrato, con su storage (`list`).
contract ClubTest is Test {
    using Bps for uint256;
    using AddressList for address[];

    Club club;
    address[] list;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");

    function setUp() public {
        club = new Club();
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.deal(carol, 1 ether);
    }

    function test_Step1_Bps() public pure {
        assertEq(uint256(1 ether).bps(2_500), 0.25 ether);
        assertEq(uint256(999).bps(2_500), 249);
        assertEq(uint256(7).bps(10_000), 7);
    }

    function test_Step2_Contains() public {
        list.push(alice);
        list.push(bob);
        assertTrue(list.contains(bob));
        assertFalse(list.contains(carol));
    }

    function test_Step3_Remove() public {
        list.push(alice);
        list.push(bob);
        list.push(carol);
        assertTrue(list.remove(alice));
        assertEq(list.length, 2);
        assertEq(list[0], carol);
        assertEq(list[1], bob);
        assertFalse(list.remove(alice));
    }

    function test_Step4_Join() public {
        vm.prank(alice);
        vm.expectEmit();
        emit Club.Joined(alice, 0.0025 ether);
        club.join{value: 0.01 ether}();
        assertEq(club.treasury(), 0.0025 ether);
        assertEq(club.prizePool(), 0.0075 ether);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Club.AlreadyMember.selector, alice));
        club.join{value: 0.01 ether}();

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Club.WrongFee.selector, 0.01 ether, 0.02 ether));
        club.join{value: 0.02 ether}();
    }

    function test_Step5_Resign() public {
        vm.prank(alice);
        club.join{value: 0.01 ether}();
        vm.prank(bob);
        club.join{value: 0.01 ether}();

        vm.prank(alice);
        club.resign();
        address[] memory current = club.members();
        assertEq(current.length, 1);
        assertEq(current[0], bob);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Club.NotMember.selector, alice));
        club.resign();
    }
}
