// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

// ¿Qué? Los tests unitarios de Token y, al final, los contraejemplos de Halmos como tests.
contract TokenTest is Test {
    Token internal token;
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        token = new Token();
        token.mint(alice, 100);
    }

    function test_Transfer() public {
        vm.prank(alice);
        token.transfer(bob, 30);
        assertEq(token.balanceOf(alice), 70);
        assertEq(token.balanceOf(bob), 30);
    }

    function test_TransferFrom() public {
        vm.prank(alice);
        token.approve(bob, 50);
        vm.prank(bob);
        token.transferFrom(alice, bob, 50);
        assertEq(token.balanceOf(bob), 50);
        assertEq(token.allowance(alice, bob), 0);
    }

    function test_BurnFrom() public {
        vm.prank(alice);
        token.approve(bob, 40);
        vm.prank(bob);
        token.burnFrom(alice, 40);
        assertEq(token.balanceOf(alice), 60);
        assertEq(token.totalSupply(), 60);
    }

    function test_RevertWhen_StrangerMints() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Token.NotOwner.selector, bob));
        token.mint(bob, 1);
    }

    // Paso 2: el contraejemplo de check_TransferKeepsBalances.
    function test_SelfTransferKeepsBalance() public {
        revert("TODO: Paso 2");
        //> vm.prank(alice);
        //> token.transfer(alice, 100);
        //> assertEq(token.balanceOf(alice), 100);
    }

    // Paso 4: el contraejemplo de check_NobodyTakesYourTokens.
    function test_RevertWhen_BurnFromWithoutAllowance() public {
        revert("TODO: Paso 4");
        //> vm.prank(bob);
        //> vm.expectRevert(abi.encodeWithSelector(Token.InsufficientAllowance.selector, bob, 0, 1));
        //> token.burnFrom(alice, 1);
    }
}
