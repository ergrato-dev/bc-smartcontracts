// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Vault} from "../src/Vault.sol";

contract VaultTest is Test {
    Vault vault;
    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.prank(owner);
        vault = new Vault();
        vm.deal(alice, 10 ether);
    }

    function _deposit(uint256 amount) internal {
        vm.prank(alice);
        vault.deposit{value: amount}();
    }

    function _pause() internal {
        vm.prank(owner);
        vault.pause();
    }

    function test_Step1_OwnerPausesAndUnpauses() public {
        vm.expectEmit(address(vault));
        emit Pausable.Paused(owner);
        _pause();
        assertTrue(vault.paused());
        vm.prank(owner);
        vault.unpause();
        assertFalse(vault.paused());
    }

    function test_Step1_RevertWhen_StrangerPauses() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vault.pause();
    }

    function test_Step1_RevertWhen_DepositWhilePaused() public {
        _pause();
        vm.prank(alice);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        vault.deposit{value: 1 ether}();
    }

    function test_Step2_Deposit() public {
        vm.expectEmit(address(vault));
        emit Vault.Deposited(alice, 1 ether);
        _deposit(1 ether);
        assertEq(vault.balanceOf(alice), 1 ether);
        assertEq(address(vault).balance, 1 ether);
    }

    function test_Step2_RevertWhen_ZeroDeposit() public {
        vm.prank(alice);
        vm.expectRevert(Vault.ZeroAmount.selector);
        vault.deposit();
    }

    function test_Step3_Withdraw() public {
        _deposit(1 ether);
        vm.expectEmit(address(vault));
        emit Vault.Withdrawn(alice, 0.4 ether);
        vm.prank(alice);
        vault.withdraw(0.4 ether);
        assertEq(vault.balanceOf(alice), 0.6 ether);
        assertEq(alice.balance, 9.4 ether);
    }

    function test_Step3_WithdrawWhilePaused() public {
        _deposit(1 ether);
        _pause();
        vm.prank(alice);
        vault.withdraw(1 ether);
        assertEq(alice.balance, 10 ether);
    }

    function test_Step3_RevertWhen_WithdrawTooMuch() public {
        _deposit(1 ether);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Vault.InsufficientBalance.selector, 1 ether, 2 ether));
        vault.withdraw(2 ether);
    }

    function test_Step4_RevertWhen_Renounce() public {
        vm.prank(owner);
        vm.expectRevert(Vault.RenounceDisabled.selector);
        vault.renounceOwnership();
        assertEq(vault.owner(), owner);
    }

    function test_Inherited_TwoStepTransfer() public {
        vm.prank(owner);
        vault.transferOwnership(bob);
        assertEq(vault.owner(), owner);
        assertEq(vault.pendingOwner(), bob);
        vm.prank(bob);
        vault.acceptOwnership();
        assertEq(vault.owner(), bob);
    }

    function test_Inherited_RevertWhen_WrongAccountAccepts() public {
        vm.prank(owner);
        vault.transferOwnership(bob);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        vault.acceptOwnership();
    }
}
