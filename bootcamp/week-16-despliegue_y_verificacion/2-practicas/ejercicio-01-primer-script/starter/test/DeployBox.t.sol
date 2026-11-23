// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Box} from "../src/Box.sol";
import {DeployBox} from "../script/DeployBox.s.sol";

// ¿Qué? Ejecuta el script dentro de un test, como si fuera un contrato más.
// ¿Para qué? Saber que el despliegue hace lo que debe antes de lanzarlo contra una red.
// ¿Impacto? No los modifiques: son el contrato del ejercicio. En un test, lo que el script
//   emite lo firma DEFAULT_SENDER, el remitente por defecto de Foundry.
contract DeployBoxTest is Test {
    DeployBox script;

    function setUp() public {
        script = new DeployBox();
    }

    // Paso 1
    function test_DeploysBox() public {
        Box box = script.deploy(5);
        assertGt(address(box).code.length, 0);
    }

    function test_OwnerIsTheSigner() public {
        Box box = script.deploy(5);
        assertEq(box.OWNER(), DEFAULT_SENDER);
        assertNotEq(box.OWNER(), address(script));
    }

    // Paso 2
    function test_StoresInitialValue() public {
        assertEq(script.deploy(5).value(), 5);
    }

    function test_StoreIsSignedByTheOwner() public {
        uint64 nonce = vm.getNonce(DEFAULT_SENDER);
        script.deploy(5);
        assertEq(vm.getNonce(DEFAULT_SENDER), nonce + 2);
    }

    // Paso 3
    function test_RevertWhen_InitialIsZero() public {
        vm.expectRevert(DeployBox.ZeroInitialValue.selector);
        script.deploy(0);
    }

    // Paso 4
    function test_RunUsesDefaultValue() public {
        assertEq(script.run().value(), 1);
    }
}
