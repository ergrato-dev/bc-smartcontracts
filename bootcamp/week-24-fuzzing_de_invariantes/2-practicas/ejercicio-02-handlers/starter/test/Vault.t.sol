// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {Vault} from "../src/Vault.sol";

// ¿Qué? Tests unitarios del vault, todos con precio 1:1 (sin rendimiento).
// ¿Para qué? Pasan desde el principio. No modifiques este archivo.
contract VaultTest is Test {
    Token token;
    Vault vault;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        token = new Token();
        vault = new Vault(token);
        token.mint(alice, 1000e18);
        token.mint(bob, 1000e18);
        vm.prank(alice);
        token.approve(address(vault), type(uint256).max);
        vm.prank(bob);
        token.approve(address(vault), type(uint256).max);
    }

    function test_Deposit() public {
        vm.prank(alice);
        assertEq(vault.deposit(100e18), 100e18);
        assertEq(vault.sharesOf(alice), 100e18);
        assertEq(vault.totalShares(), 100e18);
    }

    function test_Withdraw() public {
        vm.startPrank(alice);
        vault.deposit(100e18);
        assertEq(vault.withdraw(40e18), 40e18);
        vm.stopPrank();
        assertEq(vault.sharesOf(alice), 60e18);
        assertEq(vault.totalShares(), 60e18);
        assertEq(token.balanceOf(alice), 940e18);
    }

    function test_TwoDepositors() public {
        vm.prank(alice);
        vault.deposit(100e18);
        vm.prank(bob);
        vault.deposit(50e18);
        vm.prank(bob);
        vault.withdraw(50e18);
        assertEq(vault.totalShares(), 100e18);
        assertEq(token.balanceOf(bob), 1000e18);
    }
}
