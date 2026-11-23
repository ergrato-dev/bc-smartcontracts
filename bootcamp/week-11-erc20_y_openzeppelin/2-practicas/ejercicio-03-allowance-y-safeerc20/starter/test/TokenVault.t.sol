// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TokenVault} from "../src/TokenVault.sol";
import {TestToken, FeeToken, NoReturnToken, FalseToken} from "./Tokens.sol";

contract TokenVaultTest is Test {
    TokenVault vault;
    address alice = makeAddr("alice");

    function setUp() public {
        vault = new TokenVault();
    }

    function test_Step1_DepositsANormalToken() public {
        TestToken token = new TestToken();
        token.mint(alice, 100 ether);
        vm.startPrank(alice);
        token.approve(address(vault), 100 ether);
        vault.deposit(IERC20(address(token)), 100 ether);
        vm.stopPrank();
        assertEq(token.balanceOf(address(vault)), 100 ether);
    }

    function test_Step1_DepositsATokenWithoutReturn() public {
        NoReturnToken token = new NoReturnToken();
        token.mint(alice, 100 ether);
        vm.startPrank(alice);
        token.approve(address(vault), 100 ether);
        vault.deposit(IERC20(address(token)), 100 ether);
        vm.stopPrank();
        assertEq(token.balanceOf(address(vault)), 100 ether);
    }

    function test_Step1_RevertWhen_TokenReturnsFalse() public {
        FalseToken token = new FalseToken();
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(SafeERC20.SafeERC20FailedOperation.selector, address(token)));
        vault.deposit(IERC20(address(token)), 100 ether);
    }

    function test_Step2_CreditsWhatArrived() public {
        FeeToken token = new FeeToken();
        token.mint(alice, 100 ether);
        vm.startPrank(alice);
        token.approve(address(vault), 100 ether);
        uint256 received = vault.deposit(IERC20(address(token)), 100 ether);
        vm.stopPrank();
        assertEq(received, 99 ether);
        assertEq(vault.deposited(IERC20(address(token)), alice), 99 ether);
        assertEq(token.balanceOf(address(vault)), 99 ether);
    }

    function test_Step2_RevertWhen_NothingArrives() public {
        TestToken token = new TestToken();
        vm.prank(alice);
        vm.expectRevert(TokenVault.NothingReceived.selector);
        vault.deposit(IERC20(address(token)), 0);
    }

    function test_Step3_Withdraw() public {
        NoReturnToken token = new NoReturnToken();
        token.mint(alice, 100 ether);
        vm.startPrank(alice);
        token.approve(address(vault), 100 ether);
        vault.deposit(IERC20(address(token)), 100 ether);
        vault.withdraw(IERC20(address(token)), 40 ether);
        vm.stopPrank();
        assertEq(token.balanceOf(alice), 40 ether);
        assertEq(vault.deposited(IERC20(address(token)), alice), 60 ether);
    }

    function test_Step3_RevertWhen_WithdrawingTooMuch() public {
        TestToken token = new TestToken();
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(TokenVault.InsufficientDeposit.selector, 0, 1));
        vault.withdraw(IERC20(address(token)), 1);
    }
}
