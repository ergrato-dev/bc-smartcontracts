// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {TipJar} from "../src/TipJar.sol";

// ¿Qué? Tests del bote en una red limpia. Los dos primeros ya están escritos.
// ¿Para qué? Partir de una suite que pasa pero deja código sin ejecutar, y medirla.
// ¿Impacto? `forge coverage` te dice qué falta; `vm.snapshotGasLastFrame` deja el gas de
//   cada llamada en un archivo que git compara.
contract TipJarTest is Test {
    TipJar jar;
    address alice = makeAddr("alice");

    // ¿Qué? El test es el dueño del bote, así que tiene que poder recibir ETH.
    receive() external payable {}

    function setUp() public {
        jar = new TipJar();
    }

    function test_Tip() public {
        hoax(alice, 1 ether);
        jar.tip{value: 0.1 ether}("gracias");
        assertEq(jar.totalTips(), 0.1 ether);
        assertEq(jar.tipsOf(alice), 0.1 ether);
    }

    function test_RevertWhen_TipIsZero() public {
        vm.expectRevert(TipJar.ZeroTip.selector);
        jar.tip("nada");
    }

    // PASO 1: cubrir lo que `forge coverage` marca sin ejecutar.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function test_Step1_Withdraw() public {
        revert("TODO: Paso 1");
        //> vm.prank(alice);
        //> vm.expectRevert(abi.encodeWithSelector(TipJar.NotOwner.selector, alice));
        //> jar.withdraw();
        //>
        //> vm.expectRevert(TipJar.NothingToWithdraw.selector);
        //> jar.withdraw();
        //>
        //> hoax(alice, 1 ether);
        //> jar.tip{value: 0.5 ether}("hola");
        //> uint256 before = address(this).balance;
        //> jar.withdraw();
        //> assertEq(address(this).balance - before, 0.5 ether);
        //> assertEq(address(jar).balance, 0);
    }

    // PASO 2: medir el gas de una llamada y guardarlo con nombre.
    function test_Step2_TipGas() public {
        revert("TODO: Paso 2");
        //> hoax(alice, 1 ether);
        //> jar.tip{value: 0.1 ether}("primera");
        //> uint256 first = vm.snapshotGasLastFrame("tip-first");
        //>
        //> vm.prank(alice);
        //> jar.tip{value: 0.1 ether}("segunda");
        //> uint256 second = vm.snapshotGasLastFrame("tip-second");
        //>
        //> assertLt(second, first);
        //> assertLt(first, 80_000);
    }
}
