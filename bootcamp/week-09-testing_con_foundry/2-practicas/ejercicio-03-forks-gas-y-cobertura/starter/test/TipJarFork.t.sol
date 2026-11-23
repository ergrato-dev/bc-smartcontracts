// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {TipJar} from "../src/TipJar.sol";

// ¿Qué? Tests sobre una copia (fork) de una red en marcha: tu anvil, con el bote desplegado
//   y con propinas que dejaste con `cast`.
// ¿Para qué? Probar contra el estado real de una red, que tú no creaste en `setUp`.
// ¿Impacto? Lo que hace el test pasa solo en la copia: la red original no cambia.
contract TipJarForkTest is Test {
    TipJar jar;

    // PASO 3: abrir el fork. Sin FORK_URL el test se salta, para no depender de una red.
    function setUp() public {
        revert("TODO: Paso 3");
        //> string memory url = vm.envOr("FORK_URL", string(""));
        //> vm.skip(bytes(url).length == 0, "sin FORK_URL");
        //> vm.createSelectFork(url);
        //> jar = TipJar(vm.envAddress("TIP_JAR"));
    }

    // PASO 3: leer el estado que dejaste en anvil y escribir sobre la copia.
    function test_Step3_TipOnFork() public {
        uint256 before = jar.totalTips();
        assertGt(before, 0);

        address carol = makeAddr("carol");
        hoax(carol, 1 ether);
        jar.tip{value: 0.2 ether}("desde el fork");
        assertEq(jar.totalTips(), before + 0.2 ether);
    }

    // PASO 4: viajar a un bloque anterior al despliegue.
    function test_Step4_RollFork() public {
        revert("TODO: Paso 4");
        //> uint256 deployBlock = vm.envUint("DEPLOY_BLOCK");
        //> vm.rollFork(deployBlock - 1);
        //> assertEq(address(jar).code.length, 0);
        //> vm.rollFork(deployBlock);
        //> assertGt(address(jar).code.length, 0);
        //> assertEq(jar.totalTips(), 0);
    }
}
