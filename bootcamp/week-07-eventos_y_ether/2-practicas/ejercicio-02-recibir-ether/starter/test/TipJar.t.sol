// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {TipJar} from "../src/TipJar.sol";

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
// `vm.deal(cuenta, cantidad)` le da ETH de prueba a una cuenta.
// `address(jar).call{value: x}(datos)` envía ETH y datos sin pasar por una función con
//   nombre: así llegan `receive` y `fallback`. Devuelve si salió bien y lo que respondió.
contract TipJarTest is Test {
    TipJar jar;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        jar = new TipJar(7 days);
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
    }

    function test_Step1_Tip() public {
        vm.expectEmit();
        emit TipJar.Tipped(alice, 0.01 ether);
        vm.prank(alice);
        jar.tip{value: 0.01 ether}();
        assertEq(jar.tipsOf(alice), 0.01 ether);
        assertEq(jar.totalTips(), 0.01 ether);
        assertEq(alice.balance, 0.99 ether);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(TipJar.TipTooSmall.selector, 0.001 ether, 1 gwei));
        jar.tip{value: 1 gwei}();
        TipJar closed = new TipJar(0);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(TipJar.JarClosed.selector, block.timestamp));
        closed.tip{value: 0.01 ether}();
    }

    function test_Step2_Receive() public {
        vm.prank(alice);
        (bool ok,) = address(jar).call{value: 0.002 ether}("");
        assertTrue(ok);
        assertEq(jar.tipsOf(alice), 0.002 ether);
        vm.prank(bob);
        (ok,) = address(jar).call{value: 1 wei}("");
        assertEq(ok, false);
    }

    function test_Step3_Fallback() public {
        vm.prank(alice);
        (bool ok, bytes memory reason) = address(jar).call(hex"12345678");
        assertEq(ok, false);
        assertEq(reason, abi.encodeWithSelector(TipJar.UnknownFunction.selector, bytes4(0x12345678)));
        vm.prank(alice);
        (ok,) = address(jar).call{value: 0.01 ether}(hex"12345678");
        assertEq(ok, false);
        assertEq(alice.balance, 1 ether);
    }

    function test_Step4_Balance() public {
        vm.prank(alice);
        jar.tip{value: 0.01 ether}();
        vm.prank(bob);
        jar.tip{value: 0.02 ether}();
        assertEq(jar.balance(), 0.03 ether);
        assertEq(jar.balance(), address(jar).balance);
    }

    function test_Step5_Stats() public {
        vm.prank(alice);
        jar.tip{value: 0.0015 ether}();
        (uint256 tipsInGwei, uint256 daysLeft) = jar.stats(alice);
        assertEq(tipsInGwei, 1_500_000);
        assertEq(daysLeft, 7);
        (, daysLeft) = new TipJar(36 hours).stats(alice);
        assertEq(daysLeft, 1);
        (, daysLeft) = new TipJar(0).stats(alice);
        assertEq(daysLeft, 0);
    }
}
