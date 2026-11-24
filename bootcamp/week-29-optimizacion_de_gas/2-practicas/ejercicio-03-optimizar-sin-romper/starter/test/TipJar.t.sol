// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {TipJar} from "../src/TipJar.sol";

// Retira su saldo y, al recibir el ETH, intenta retirarlo otra vez antes de que el bote lo apunte.
contract Reenterer {
    TipJar immutable JAR;
    bool entered;

    constructor(TipJar jar) {
        JAR = jar;
    }

    function attack(uint256 amount) external {
        JAR.withdraw(amount);
    }

    receive() external payable {
        if (entered) return;
        entered = true;
        // Si la segunda retirada revierte, el atacante se queda con la primera.
        try JAR.withdraw(msg.value) {} catch {}
    }
}

// ¿Qué? Los tests del bote: los de comportamiento normal pasan desde el principio; los de cada
//   paso fallan con el fallo que metió su optimización.
// ¿Para qué? Ver que una optimización sin tests que miren sus bordes es un bug esperando.
// ¿Impacto? Ninguno fuera del ejercicio.
contract TipJarTest is Test {
    TipJar jar;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.warp(1_750_000_000);
        jar = new TipJar();
        vm.deal(alice, 10 ether);
        // Bob tiene 5 ether en el bote: lo que un fallo podría llevarse.
        vm.prank(alice);
        jar.tip{value: 5 ether}(bob);
    }

    function _balance(address account) internal view returns (uint256 balance) {
        (balance,) = jar.accounts(account);
    }

    function test_TipAndWithdraw() public {
        vm.prank(alice);
        jar.tip{value: 1 ether}(alice);
        assertEq(_balance(alice), 1 ether);
        vm.prank(alice);
        jar.withdraw(0.4 ether);
        assertEq(_balance(alice), 0.6 ether);
        assertEq(alice.balance, 4.4 ether);
    }

    function test_Paso1_RevertWhen_TipTooLarge() public {
        uint256 huge = uint256(type(uint96).max) + 1;
        vm.deal(alice, huge);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(TipJar.TooLarge.selector, huge));
        jar.tip{value: huge}(alice);
    }

    function test_Paso2_RevertWhen_WithdrawMoreThanBalance() public {
        vm.prank(alice);
        jar.tip{value: 1 ether}(alice);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(TipJar.InsufficientBalance.selector, 2 ether, 1 ether));
        jar.withdraw(2 ether);
    }

    function test_Paso3_ReentrancyCannotDrain() public {
        Reenterer attacker = new Reenterer(jar);
        vm.prank(alice);
        jar.tip{value: 1 ether}(address(attacker));
        attacker.attack(1 ether);
        assertEq(address(attacker).balance, 1 ether);
        assertEq(address(jar).balance, 5 ether);
    }

    function test_Paso4_BadgesDoNotCollide() public {
        jar.claimBadge(0);
        jar.claimBadge(128);
        vm.expectRevert(abi.encodeWithSelector(TipJar.BadgeTaken.selector, 128));
        jar.claimBadge(128);
    }

    function test_Paso5_TipManyPaysEveryone() public {
        address[] memory to = new address[](300);
        for (uint256 i = 0; i < 300; i++) {
            to[i] = address(uint160(i + 1));
        }
        vm.prank(alice);
        jar.tipMany{value: 3 ether}(to);
        assertEq(_balance(address(1)), 0.01 ether);
        assertEq(_balance(address(300)), 0.01 ether);
    }
}
