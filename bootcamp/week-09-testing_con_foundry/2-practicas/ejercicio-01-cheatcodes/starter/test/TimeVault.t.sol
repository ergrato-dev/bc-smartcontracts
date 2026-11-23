// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test, Vm} from "forge-std/Test.sol";
import {TimeVault} from "../src/TimeVault.sol";

// ¿Qué? Los tests del ejercicio. Aquí trabajas: cada test es un paso.
// ¿Para qué? Practicar los cheatcodes que fijan quién llama, cuánto ETH tiene, qué hora es y
//   qué debe pasar (revert, evento, llamada).
// ¿Impacto? Un test que no controla esas cosas prueba solo el caso que le tocó por azar.
contract TimeVaultTest is Test {
    TimeVault vault;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vault = new TimeVault();
        vm.label(address(vault), "TimeVault");
    }

    // PASO 1: alice deposita 1 ether con `hoax`.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function test_Step1_Deposit() public {
        revert("TODO: Paso 1");
        //> hoax(alice, 5 ether);
        //> vault.deposit{value: 1 ether}();
        //> assertEq(vault.balanceOf(alice), 1 ether);
        //> assertEq(alice.balance, 4 ether);
        //> assertEq(vault.unlockAt(alice), block.timestamp + 7 days);
    }

    // PASO 2: varias llamadas seguidas de bob con `startPrank`.
    function test_Step2_SeveralCalls() public {
        revert("TODO: Paso 2");
        //> vm.deal(bob, 3 ether);
        //> vm.startPrank(bob);
        //> vault.deposit{value: 1 ether}();
        //> vault.deposit{value: 2 ether}();
        //> vm.stopPrank();
        //> assertEq(vault.balanceOf(bob), 3 ether);
        //> assertEq(vault.balanceOf(address(this)), 0);
    }

    // PASO 3: mover el reloj con `vm.warp`.
    function test_Step3_Time() public {
        revert("TODO: Paso 3");
        //> hoax(alice, 1 ether);
        //> vault.deposit{value: 1 ether}();
        //> uint256 until = vault.unlockAt(alice);
        //>
        //> vm.warp(until - 1);
        //> vm.prank(alice);
        //> vm.expectRevert(abi.encodeWithSelector(TimeVault.StillLocked.selector, until));
        //> vault.withdraw();
        //>
        //> vm.warp(until);
        //> vm.prank(alice);
        //> vault.withdraw();
        //> assertEq(alice.balance, 1 ether);
    }

    // PASO 4: comprobar eventos con `vm.expectEmit` y con `vm.recordLogs`.
    function test_Step4_Events() public {
        revert("TODO: Paso 4");
        //> vm.deal(alice, 1 ether);
        //> vm.expectEmit(address(vault));
        //> emit TimeVault.Deposited(alice, 1 ether, block.timestamp + 7 days);
        //> vm.prank(alice);
        //> vault.deposit{value: 1 ether}();
        //>
        //> skip(7 days);
        //> vm.recordLogs();
        //> vm.prank(alice);
        //> vault.withdraw();
        //> Vm.Log[] memory logs = vm.getRecordedLogs();
        //> assertEq(logs.length, 1);
        //> assertEq(logs[0].emitter, address(vault));
        //> assertEq(logs[0].topics[0], TimeVault.Withdrawn.selector);
        //> assertEq(logs[0].topics[1], bytes32(uint256(uint160(alice))));
        //> assertEq(abi.decode(logs[0].data, (uint256)), 1 ether);
    }

    // PASO 5: exigir que el contrato haga una llamada con `vm.expectCall`.
    function test_Step5_ExpectCall() public {
        revert("TODO: Paso 5");
        //> hoax(alice, 2 ether);
        //> vault.deposit{value: 2 ether}();
        //> skip(7 days);
        //> vm.expectCall(alice, 2 ether, "");
        //> vm.prank(alice);
        //> vault.withdraw();
    }
}
