// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";

// ¿Qué? Un contrato sin `receive` ni `fallback`: rechaza todo ETH que le envíen.
contract Rejector {
    function depositTo(Vault vault) external payable {
        vault.deposit{value: msg.value}();
    }

    function withdrawFrom(Vault vault, uint256 amount) external {
        vault.withdraw(amount);
    }
}

// ¿Qué? Un atacante: cuando recibe ETH, vuelve a llamar a `withdrawAll` mientras a la
//   caja le quede dinero.
contract Reentrant {
    Vault vault;

    constructor(Vault target) {
        vault = target;
    }

    function attack() external payable {
        vault.deposit{value: msg.value}();
        vault.withdrawAll();
    }

    receive() external payable {
        if (address(vault).balance >= 1 ether) vault.withdrawAll();
    }
}

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
contract VaultTest is Test {
    Vault vault;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vault = new Vault();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function test_Step1_Deposit() public {
        vm.expectEmit();
        emit Vault.Deposited(alice, 2 ether);
        vm.prank(alice);
        vault.deposit{value: 2 ether}();
        assertEq(vault.balanceOf(alice), 2 ether);
        assertEq(vault.totalDeposits(), 2 ether);
        assertEq(address(vault).balance, 2 ether);
        vm.prank(alice);
        vm.expectRevert(Vault.ZeroAmount.selector);
        vault.deposit();
    }

    function test_Step2_Withdraw() public {
        vm.prank(alice);
        vault.deposit{value: 2 ether}();
        vm.expectEmit();
        emit Vault.Withdrawn(alice, 0.5 ether);
        vm.prank(alice);
        vault.withdraw(0.5 ether);
        assertEq(vault.balanceOf(alice), 1.5 ether);
        assertEq(alice.balance, 8.5 ether);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Vault.InsufficientBalance.selector, 1.5 ether, 3 ether));
        vault.withdraw(3 ether);

        Rejector rejector = new Rejector();
        rejector.depositTo{value: 1 ether}(vault);
        vm.expectRevert(abi.encodeWithSelector(Vault.TransferFailed.selector, address(rejector), 1 ether));
        rejector.withdrawFrom(vault, 1 ether);
        assertEq(vault.balanceOf(address(rejector)), 1 ether);
    }

    function test_Step3_WithdrawAllResistsReentrancy() public {
        vm.prank(bob);
        vault.deposit{value: 5 ether}();
        Reentrant attacker = new Reentrant(vault);
        vm.expectRevert(abi.encodeWithSelector(Vault.TransferFailed.selector, address(attacker), 1 ether));
        attacker.attack{value: 1 ether}();
        assertEq(address(vault).balance, 5 ether);

        vm.prank(bob);
        vault.withdrawAll();
        assertEq(bob.balance, 10 ether);
        vm.prank(bob);
        vm.expectRevert(Vault.NothingToWithdraw.selector);
        vault.withdrawAll();
    }

    function test_Step4_IsSolvent() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();
        assertTrue(vault.isSolvent());
        vm.deal(address(vault), 3 ether);
        assertTrue(vault.isSolvent());
        assertEq(vault.totalDeposits(), 1 ether);
    }
}
