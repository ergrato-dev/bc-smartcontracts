// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {AsmCaller} from "../src/AsmCaller.sol";
import {SimpleToken, SilentToken, RevertingToken, Target, Unbuildable} from "./Targets.sol";

// ¿Qué? AsmCaller contra contratos que responden bien, mal, con nada o con demasiado.
// ¿Para qué? Cada caso que Solidity resuelve solo en una llamada (sin código, sin datos, error
//   del otro, returndata enorme) tiene aquí su test, porque en assembly lo resuelves tú.
contract AsmCallerTest is Test {
    AsmCaller caller;
    Target target;
    address stranger = makeAddr("stranger");

    function setUp() public {
        caller = new AsmCaller();
        target = new Target();
    }

    function test_Paso1_OwnerPasses() public view {
        caller.checkOwner();
    }

    function test_Paso1_StrangerReverts() public {
        vm.expectRevert(abi.encodeWithSelector(AsmCaller.NotOwner.selector, stranger));
        vm.prank(stranger);
        caller.checkOwner();
    }

    function testFuzz_Paso2_BalanceOf(address account, uint256 amount) public {
        SimpleToken token = new SimpleToken();
        token.setBalance(account, amount);
        assertEq(caller.balanceOf(address(token), account), amount);
    }

    function test_Paso2_RejectsWhatIsNotAToken() public {
        address[3] memory bad = [makeAddr("sin codigo"), address(new SilentToken()), address(new RevertingToken())];
        for (uint256 i = 0; i < bad.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(AsmCaller.BadToken.selector, bad[i]));
            caller.balanceOf(bad[i], stranger);
        }
    }

    function testFuzz_Paso3_ForwardReturnsSameBytes(bytes memory data) public {
        bytes memory result = caller.forward(address(target), abi.encodeCall(Target.echo, (data)));
        assertEq(result, abi.encode(data));
    }

    function test_Paso3_ForwardBubblesError() public {
        vm.expectRevert(abi.encodeWithSelector(Target.Nope.selector, 42));
        caller.forward(address(target), abi.encodeCall(Target.fail, (42)));
    }

    function test_Paso3_OnlyOwnerForwards() public {
        vm.expectRevert(abi.encodeWithSelector(AsmCaller.NotOwner.selector, stranger));
        vm.prank(stranger);
        caller.forward(address(target), "");
    }

    function testFuzz_Paso4_CopiesAtMostMaxCopy(bytes memory data, uint8 maxCopy) public {
        bytes memory full = abi.encode(data);
        (bool ok, bytes memory head) = caller.callCapped(address(target), abi.encodeCall(Target.echo, (data)), maxCopy);
        assertTrue(ok);
        uint256 expected = full.length < maxCopy ? full.length : maxCopy;
        assertEq(head.length, expected);
        for (uint256 i = 0; i < expected; i++) {
            assertEq(head[i], full[i]);
        }
    }

    function test_Paso4_BombCostsLittle() public {
        bytes memory data = abi.encodeCall(Target.bomb, (100_000));
        uint256 before = gasleft();
        (bool ok, bytes memory head) = caller.callCapped(address(target), data, 4);
        uint256 capped = before - gasleft();
        assertFalse(ok);
        assertEq(head.length, 4);

        before = gasleft();
        caller.callCapped(address(target), data, 100_000);
        uint256 full = before - gasleft();

        emit log_named_uint("gas copiando 4 bytes", capped);
        emit log_named_uint("gas copiando 100 000 bytes", full);
        assertLt(capped * 2, full);
    }

    function test_Paso5_DeployAtPredictedAddress() public {
        bytes memory initCode = type(Target).creationCode;
        bytes32 salt = keccak256("ejercicio 03");
        address predicted = vm.computeCreate2Address(salt, keccak256(initCode), address(caller));
        address deployed = caller.deploy(initCode, salt);
        assertEq(deployed, predicted);
        assertGt(deployed.code.length, 0);
    }

    function test_Paso5_FailedDeployReverts() public {
        bytes32 salt = keccak256("ejercicio 03");
        caller.deploy(type(Target).creationCode, salt);
        // La misma dirección otra vez: ya hay un contrato.
        vm.expectRevert(AsmCaller.DeployFailed.selector);
        caller.deploy(type(Target).creationCode, salt);
        // Un constructor que revierte.
        vm.expectRevert(AsmCaller.DeployFailed.selector);
        caller.deploy(type(Unbuildable).creationCode, salt);
    }
}
