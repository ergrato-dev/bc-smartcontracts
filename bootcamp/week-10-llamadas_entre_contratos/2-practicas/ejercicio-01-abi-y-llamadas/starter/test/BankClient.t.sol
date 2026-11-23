// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";
import {BankClient} from "../src/BankClient.sol";

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
contract BankClientTest is Test {
    Bank bank;
    BankClient client;
    address alice = makeAddr("alice");

    function setUp() public {
        bank = new Bank();
        client = new BankClient(address(bank));
    }

    function test_Step1_WithdrawCalldata() public view {
        // La salida de `cast calldata "withdraw(uint256)" 1000000000000000000`.
        assertEq(
            client.withdrawCalldata(1 ether),
            hex"2e1a7d4d0000000000000000000000000000000000000000000000000de0b6b3a7640000"
        );
    }

    function test_Step2_Deposit() public {
        hoax(alice, 1 ether);
        client.deposit{value: 1 ether}();
        assertEq(bank.balanceOf(address(client)), 1 ether);
        assertEq(address(bank).balance, 1 ether);
    }

    function test_Step2_RevertWhen_BankReverts() public {
        bytes memory reason = abi.encodeWithSelector(Bank.ZeroAmount.selector);
        vm.expectRevert(abi.encodeWithSelector(BankClient.CallFailed.selector, reason));
        client.deposit();
    }

    function test_Step3_Balance() public {
        assertEq(client.balance(), 0);
        hoax(alice, 1 ether);
        client.deposit{value: 1 ether}();
        assertEq(client.balance(), 1 ether);
    }

    function test_Step4_TryWithdraw() public {
        hoax(alice, 1 ether);
        client.deposit{value: 1 ether}();

        (bool ok, bytes memory reason) = client.tryWithdraw(2 ether);
        assertFalse(ok);
        assertEq(reason, abi.encodeWithSelector(Bank.InsufficientBalance.selector, 1 ether, 2 ether));

        (ok, reason) = client.tryWithdraw(0.4 ether);
        assertTrue(ok);
        assertEq(reason.length, 0);
        assertEq(address(client).balance, 0.4 ether);
        assertEq(client.balance(), 0.6 ether);
    }

    function test_Step5_RevertWhen_BankHasNoCode() public {
        address nobody = makeAddr("nobody");
        vm.expectRevert(abi.encodeWithSelector(BankClient.NoCode.selector, nobody));
        new BankClient(nobody);
    }
}
