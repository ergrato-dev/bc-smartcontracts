// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {Vault} from "../src/Vault.sol";
import {VirtualVault} from "../src/VirtualVault.sol";

contract RoundingTest is Test {
    Token token;
    Vault vault;
    VirtualVault virtualVault;
    address alice = makeAddr("alice");
    address mallory = makeAddr("mallory");

    function setUp() public {
        token = new Token("Dollar", "USD");
        vault = new Vault(token);
        virtualVault = new VirtualVault(token);
        token.mint(alice, 100_000e18);
        token.mint(mallory, 100_000e18);
        vm.prank(alice);
        token.approve(address(vault), type(uint256).max);
        vm.prank(alice);
        token.approve(address(virtualVault), type(uint256).max);
        vm.prank(mallory);
        token.approve(address(vault), type(uint256).max);
        vm.prank(mallory);
        token.approve(address(virtualVault), type(uint256).max);
    }

    // Alice deposita 100 y la bóveda gana otros 100: cada participación vale 2 tokens.
    function _vaultWithYield() internal {
        vm.prank(alice);
        vault.deposit(100e18);
        token.mint(address(vault), 100e18);
    }

    function test_Paso1_Conversions() public {
        _vaultWithYield();
        assertEq(vault.convertToShares(50e18), 25e18);
        assertEq(vault.convertToAssets(25e18), 50e18);
        // 1 token vale media participación: se redondea a 0, a favor de la bóveda.
        assertEq(vault.convertToShares(1), 0);
        assertEq(vault.convertToAssets(1), 2);
    }

    function test_Paso2_PreviewWithdraw() public {
        _vaultWithYield();
        assertEq(vault.previewWithdraw(50e18), 25e18);
        assertEq(vault.previewWithdraw(1), 1);
        vm.prank(alice);
        assertEq(vault.withdraw(50e18), 25e18);
        assertEq(vault.sharesOf(alice), 75e18);
    }

    function test_Paso2_RevertWhen_WithdrawingForFree() public {
        _vaultWithYield();
        // Mallory no tiene participaciones: sacar 1 token cuesta 1, no 0.
        vm.prank(mallory);
        vm.expectRevert(abi.encodeWithSelector(Vault.InsufficientShares.selector, 0, 1));
        vault.withdraw(1);
    }

    function test_Paso3_RevertWhen_DepositGivesNoShares() public {
        // Mallory es la primera: deposita 1 wei y dona 10 000 tokens sin depositar.
        vm.startPrank(mallory);
        vault.deposit(1);
        token.transfer(address(vault), 10_000e18);
        vm.stopPrank();
        // 10 000e18 * 1 / (10 000e18 + 1) = 0,99...: Alice recibiría 0 participaciones.
        vm.prank(alice);
        vm.expectRevert(Vault.ZeroShares.selector);
        vault.deposit(10_000e18);
    }

    function test_Paso3_ZeroSharesIsNotEnough() public {
        vm.startPrank(mallory);
        vault.deposit(1);
        token.transfer(address(vault), 10_000e18);
        vm.stopPrank();
        // Con 15 000, Alice recibe 1 participación (1,49...), la misma que tiene Mallory.
        vm.prank(alice);
        assertEq(vault.deposit(15_000e18), 1);
        vm.prank(mallory);
        assertEq(vault.redeem(1), 12_500e18);
        // Mallory puso 10 000 y saca 12 500: los 2500 de más son de Alice.
        assertEq(token.balanceOf(mallory), 100_000e18 + 2500e18 - 1);
    }

    function test_Paso4_VirtualSharesMakeAttackLose() public {
        vm.startPrank(mallory);
        assertEq(virtualVault.deposit(1), 1000);
        token.transfer(address(virtualVault), 10_000e18);
        vm.stopPrank();
        vm.prank(alice);
        assertEq(virtualVault.deposit(15_000e18), 2999);
        vm.prank(mallory);
        uint256 got = virtualVault.redeem(1000);
        // Mallory puso 10 000 y saca 5001: la mitad de su donación se queda en la bóveda.
        assertEq(got, 5001_000200040008001600);
        vm.prank(alice);
        uint256 aliceGot = virtualVault.redeem(2999);
        // Alice puso 15 000 y saca 14 997,99...: pierde un 0,013 %.
        assertEq(aliceGot, 14_997_999599919983996801);
    }

    function test_Paso4_VirtualVaultNormalUse() public {
        vm.prank(alice);
        assertEq(virtualVault.deposit(100e18), 100e21);
        vm.prank(alice);
        assertEq(virtualVault.redeem(100e21), 100e18);
    }
}
