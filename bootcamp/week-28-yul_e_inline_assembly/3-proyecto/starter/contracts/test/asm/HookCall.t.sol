// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test, Vm} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {DeployProtocol} from "../../script/DeployProtocol.s.sol";
import {UpgradeToV2} from "../../script/UpgradeToV2.s.sol";
import {UpgradeToV3} from "../../script/UpgradeToV3.s.sol";
import {Registry} from "../../src/Registry.sol";
import {RegistryV3} from "../../src/RegistryV3.sol";
import {ReturnBombHook} from "../attackers/ReturnBombHook.sol";
import {RevertDataHook} from "../attackers/RevertDataHook.sol";
import {MemoryBombHook} from "../attackers/MemoryBombHook.sol";

// ¿Qué? La llamada al hook, escrita en assembly, comparada con lo que hacía la versión en
//   Solidity: el mismo evento para cualquier motivo de revert, y un gas que no depende de cuántos
//   bytes devuelva el hook.
// ¿Para qué? El assembly no tiene comprobaciones de solc: cada una que haga falta la escribes tú, y
//   cada una que olvides solo la ve un test.
// ¿Impacto? Si un test de aquí falla tras tocar `_notifyHook`, el assembly cambió el
//   comportamiento o volvió a copiar lo que decide el hook.
contract HookCallTest is Test {
    RegistryV3 registry;
    address admin;
    address alice = makeAddr("alice");

    function setUp() public {
        vm.warp(1_750_000_000);
        DeployProtocol.Deployment memory d = new DeployProtocol().deploy(50);
        (, admin,) = vm.readCallers();
        MockV3Aggregator feed = new MockV3Aggregator(8, 2500e8);
        registry = new UpgradeToV3()
            .upgrade(new UpgradeToV2().upgrade(d.registry, 10), AggregatorV3Interface(address(feed)), 25e18, 3 hours);
        vm.deal(alice, 10 ether);
    }

    function _setHook(address newHook) internal {
        vm.prank(admin);
        registry.setHook(newHook);
    }

    // El gas de un alta de `alice`, medido desde fuera.
    function _registerGas(string memory label) internal returns (uint256 used) {
        uint256 fee = registry.registrationFee();
        vm.prank(alice);
        uint256 before = gasleft();
        registry.register{value: fee}(label);
        used = before - gasleft();
    }

    // La referencia: lo que emitía la versión en Solidity para cada motivo.
    function _expectedReason(bytes memory data) internal pure returns (bytes memory) {
        return data.length < 4 ? bytes("") : abi.encodePacked(bytes4(data));
    }

    function test_ReturnBombCostsAtMostHookGas() public {
        _setHook(address(new RevertDataHook(abi.encodePacked(ReturnBombHook.Junk.selector))));
        _registerGas("calentar");
        uint256 small = _registerGas("uno");

        _setHook(address(new MemoryBombHook()));
        _registerGas("calentar de nuevo");
        uint256 bomb = _registerGas("dos");

        emit log_named_uint("alta con un revert de 4 bytes", small);
        emit log_named_uint("alta con la return bomb", bomb);
        // Lo que gasta el hook ya lo limita HOOK_GAS; la copia de su returndata, no.
        assertLt(bomb, small + registry.HOOK_GAS());
    }

    function testFuzz_FailedHookEmitsSelector(bytes memory data) public {
        _setHook(address(new RevertDataHook(data)));
        uint256 fee = registry.registrationFee();

        vm.expectEmit(address(registry));
        emit Registry.HookFailed(1, _expectedReason(data));
        vm.prank(alice);
        registry.register{value: fee}("uno");
    }

    function test_ShortRevertsEmitEmptyReason() public {
        for (uint256 n = 0; n < 6; n++) {
            _setHook(address(new RevertDataHook(new bytes(n))));
            vm.recordLogs();
            vm.prank(alice);
            uint256 id = registry.register{value: registry.registrationFee()}("corto");
            Vm.Log[] memory logs = vm.getRecordedLogs();
            bytes memory reason = abi.decode(logs[logs.length - 1].data, (bytes));
            assertEq(logs[logs.length - 1].topics[0], Registry.HookFailed.selector);
            assertEq(logs[logs.length - 1].topics[1], bytes32(id));
            assertEq(reason.length, n < 4 ? 0 : 4);
        }
    }

    function test_SucceedingHookEmitsNothing() public {
        vm.recordLogs();
        _registerGas("uno");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            assertTrue(logs[i].topics[0] != Registry.HookFailed.selector);
        }
        // El hook del despliegue es el token: si recibió el aviso, `alice` tiene sus puntos.
        assertGt(registry.loyalty().balanceOf(alice), 0);
    }

    function test_BatchWithBombHookKeepsReturnValue() public {
        _setHook(address(new ReturnBombHook()));
        string[] memory labels = new string[](3);
        labels[0] = "uno";
        labels[1] = "dos";
        labels[2] = "tres";
        uint256 fee = registry.registrationFee() * 3;

        vm.prank(alice);
        uint256 first = registry.registerBatch{value: fee}(labels);

        assertEq(first, 1);
        assertEq(registry.idsOf(alice).length, 3);
        assertEq(registry.getItem(3).label, "tres");
    }
}
