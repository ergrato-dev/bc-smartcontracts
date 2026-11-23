// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {MiniToken} from "../src/MiniToken.sol";

contract MiniTokenTest is Test {
    MiniToken token;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address shop = makeAddr("shop");

    function setUp() public {
        vm.prank(alice);
        token = new MiniToken(100 ether);
    }

    function test_Step1_Transfer() public {
        vm.expectEmit(address(token));
        emit MiniToken.Transfer(alice, bob, 30 ether);
        vm.prank(alice);
        assertTrue(token.transfer(bob, 30 ether));
        assertEq(token.balanceOf(alice), 70 ether);
        assertEq(token.balanceOf(bob), 30 ether);
        assertEq(token.totalSupply(), 100 ether);
    }

    function test_Step1_RevertWhen_BalanceTooLow() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(MiniToken.InsufficientBalance.selector, bob, 0, 1));
        token.transfer(alice, 1);
    }

    function test_Step1_RevertWhen_ToIsZero() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(MiniToken.InvalidReceiver.selector, address(0)));
        token.transfer(address(0), 1 ether);
    }

    function test_Step2_Approve() public {
        vm.expectEmit(address(token));
        emit MiniToken.Approval(alice, shop, 20 ether);
        vm.prank(alice);
        assertTrue(token.approve(shop, 20 ether));
        assertEq(token.allowance(alice, shop), 20 ether);
        // Aprobar no mueve tokens.
        assertEq(token.balanceOf(alice), 100 ether);
    }

    function test_Step3_TransferFrom() public {
        vm.prank(alice);
        token.approve(shop, 20 ether);
        vm.prank(shop);
        assertTrue(token.transferFrom(alice, bob, 15 ether));
        assertEq(token.balanceOf(bob), 15 ether);
        assertEq(token.allowance(alice, shop), 5 ether);
    }

    function test_Step3_RevertWhen_AllowanceTooLow() public {
        vm.prank(alice);
        token.approve(shop, 5 ether);
        vm.prank(shop);
        vm.expectRevert(abi.encodeWithSelector(MiniToken.InsufficientAllowance.selector, shop, 5 ether, 6 ether));
        token.transferFrom(alice, bob, 6 ether);
    }

    function test_Step3_InfiniteAllowance() public {
        vm.prank(alice);
        token.approve(shop, type(uint256).max);
        vm.prank(shop);
        token.transferFrom(alice, bob, 40 ether);
        assertEq(token.allowance(alice, shop), type(uint256).max);
    }
}
