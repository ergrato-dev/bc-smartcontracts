// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {VulnerableBank} from "../src/VulnerableBank.sol";
import {Bank} from "../src/Bank.sol";
import {Attacker} from "../src/Attacker.sol";
import {CrossAttacker, IBank} from "../src/CrossAttacker.sol";

// Un receptor que, al cobrar de `withdraw`, intenta `transfer` y guarda el error que recibe.
contract Probe {
    Bank public immutable BANK;
    bytes public lastError;

    constructor(Bank bank) {
        BANK = bank;
    }

    function depositAndWithdraw() external payable {
        BANK.deposit{value: msg.value}();
        BANK.withdraw();
    }

    receive() external payable {
        try BANK.transfer(address(1), 1) {}
        catch (bytes memory reason) {
            lastError = reason;
        }
    }
}

contract ReentrancyTest is Test {
    VulnerableBank vulnerable;
    Bank bank;
    address alice = makeAddr("alice");
    address mallory = makeAddr("mallory");
    address accomplice = makeAddr("accomplice");

    function setUp() public {
        vulnerable = new VulnerableBank();
        bank = new Bank();
        // Alice tiene 10 ETH en cada banco; Mallory, 1 ETH para atacar.
        vm.deal(alice, 20 ether);
        vm.startPrank(alice);
        vulnerable.deposit{value: 10 ether}();
        bank.deposit{value: 10 ether}();
        vm.stopPrank();
        vm.deal(mallory, 1 ether);
    }

    function test_Paso1_AttackDepositsAndWithdraws() public {
        vm.startPrank(mallory);
        Attacker attacker = new Attacker(vulnerable);
        attacker.attack{value: 1 ether}();
        vm.stopPrank();
        assertEq(attacker.stake(), 1 ether);
        // Sin el paso 2, el atacante solo recupera lo suyo.
        assertGe(address(attacker).balance, 1 ether);
        assertEq(vulnerable.balanceOf(address(attacker)), 0);
    }

    function test_Paso2_DrainsVulnerableBank() public {
        vm.startPrank(mallory);
        Attacker attacker = new Attacker(vulnerable);
        attacker.attack{value: 1 ether}();
        attacker.collect();
        vm.stopPrank();
        // 1 ETH de Mallory + los 10 de Alice.
        assertEq(mallory.balance, 11 ether);
        assertEq(address(vulnerable).balance, 0);
        // Y el banco cree que Alice todavía tiene sus 10 ETH.
        assertEq(vulnerable.balanceOf(alice), 10 ether);
    }

    function test_Paso3_Withdraw() public {
        vm.prank(alice);
        bank.withdraw();
        assertEq(alice.balance, 10 ether);
        assertEq(bank.balanceOf(alice), 0);
        vm.prank(alice);
        vm.expectRevert(Bank.NothingToWithdraw.selector);
        bank.withdraw();
    }

    function test_Paso3_RevertWhen_ReentrantWithdraw() public {
        vm.startPrank(mallory);
        Attacker attacker = new Attacker(VulnerableBank(address(bank)));
        // La segunda entrada encuentra el saldo a 0, el envío falla y todo se deshace.
        vm.expectRevert(Bank.TransferFailed.selector);
        attacker.attack{value: 1 ether}();
        vm.stopPrank();
        assertEq(address(bank).balance, 10 ether);
    }

    function test_Paso4_CrossFunctionDrainsVulnerableBank() public {
        vm.prank(mallory);
        CrossAttacker attacker = new CrossAttacker(IBank(address(vulnerable)), accomplice);
        vm.prank(mallory);
        attacker.attack{value: 1 ether}();
        // El cómplice tiene 1 ETH apuntado que nadie depositó, y lo retira.
        assertEq(vulnerable.balanceOf(accomplice), 1 ether);
        vm.prank(accomplice);
        vulnerable.withdraw();
        assertEq(address(attacker).balance + accomplice.balance, 2 ether);
        assertEq(address(vulnerable).balance, 9 ether);
    }

    function test_Paso3_CrossFunctionGetsNothingFromBank() public {
        vm.prank(mallory);
        CrossAttacker attacker = new CrossAttacker(IBank(address(bank)), accomplice);
        vm.prank(mallory);
        attacker.attack{value: 1 ether}();
        // Cuando el atacante recibe, su saldo ya es 0: no hay nada que pasar al cómplice.
        assertEq(address(attacker).balance, 1 ether);
        assertEq(bank.balanceOf(accomplice), 0);
        assertEq(address(bank).balance, 10 ether);
    }

    function test_Paso5_GuardBlocksReentry() public {
        Probe probe = new Probe(bank);
        vm.deal(address(probe), 1 ether);
        vm.prank(mallory);
        probe.depositAndWithdraw{value: 1 ether}();
        // Con el paso 3 solo, `transfer` llegaría a mirar el saldo y fallaría por saldo 0.
        assertEq(
            probe.lastError(), abi.encodeWithSelector(ReentrancyGuardTransient.ReentrancyGuardReentrantCall.selector)
        );
    }
}
