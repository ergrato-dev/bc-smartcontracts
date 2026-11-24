// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {DeployProtocol} from "../../script/DeployProtocol.s.sol";
import {UpgradeToV2} from "../../script/UpgradeToV2.s.sol";
import {UpgradeToV3} from "../../script/UpgradeToV3.s.sol";
import {RegistryV3} from "../../src/RegistryV3.sol";

// ¿Qué? El gas de las altas y de la retirada, guardado con nombre en snapshots/RegisterGasTest.json,
//   y la optimización de la semana 29: el alta no escribe el id del recurso, que ya es su clave.
// ¿Para qué? Que el gas que cita el informe sea el del código actual: test.sh ejecuta esta suite
//   con FORGE_SNAPSHOT_CHECK=true, y si un número cambió sin regenerar el archivo, falla.
// ¿Impacto? Cada cambio en el camino de un alta cambia el archivo: haz commit de él con el cambio.
contract RegisterGasTest is Test {
    // El slot 5 es el de `_items` (test/evm/StorageMap.t.sol).
    uint256 constant ITEMS_SLOT = 5;

    RegistryV3 registry;
    address alice = makeAddr("alice");
    uint256 fee;

    function setUp() public {
        vm.warp(1_750_000_000);
        DeployProtocol.Deployment memory d = new DeployProtocol().deploy(50);
        MockV3Aggregator feed = new MockV3Aggregator(8, 2500e8);
        registry = new UpgradeToV3()
            .upgrade(new UpgradeToV2().upgrade(d.registry, 10), AggregatorV3Interface(address(feed)), 25e18, 3 hours);
        fee = registry.registrationFee();
        vm.deal(alice, 10 ether);
        // La primera alta de `alice` paga además su primer certificado, sus primeros puntos y
        // su array de ids: lo que se mide es un alta normal, la segunda.
        vm.prank(alice);
        registry.register{value: fee}("primero");
    }

    // El slot donde empieza el struct `Item` del recurso `id`.
    function _itemSlot(uint256 id) internal pure returns (bytes32) {
        return keccak256(abi.encode(id, ITEMS_SLOT));
    }

    // Revierte si alguna escritura en storage del proxy fue al primer slot de un recurso de `ids`.
    function _assertIdsNotWritten(uint256 firstId, uint256 amount) internal view {
        (, bytes32[] memory writes) = vm.accesses(address(registry));
        for (uint256 i = 0; i < writes.length; i++) {
            for (uint256 id = firstId; id < firstId + amount; id++) {
                assertNotEq(writes[i], _itemSlot(id), "el alta escribe el id del recurso");
            }
        }
    }

    function test_RegisterDoesNotWriteItemId() public {
        vm.record();
        vm.prank(alice);
        uint256 id = registry.register{value: fee}("segundo");
        vm.snapshotGasLastFrame("register");
        _assertIdsNotWritten(id, 1);
        assertEq(registry.getItem(id).id, id);
    }

    function test_BatchDoesNotWriteItemIds() public {
        string[] memory labels = new string[](3);
        labels[0] = "a";
        labels[1] = "b";
        labels[2] = "c";
        vm.record();
        vm.prank(alice);
        uint256 firstId = registry.registerBatch{value: fee * 3}(labels);
        vm.snapshotGasLastFrame("registerBatch3");
        _assertIdsNotWritten(firstId, 3);
        for (uint256 i = 0; i < 3; i++) {
            assertEq(registry.getItem(firstId + i).id, firstId + i);
        }
    }

    // Lo que haya en el primer slot (el id que escribía el código anterior, o cualquier otra
    // cosa) no cambia lo que devuelve `getItem`.
    function test_GetItemIdComesFromTheKey() public {
        vm.store(address(registry), _itemSlot(1), bytes32(uint256(999)));
        assertEq(registry.getItem(1).id, 1);
    }

    function test_RetireGas() public {
        vm.prank(alice);
        registry.retire(1);
        vm.snapshotGasLastFrame("retire");
    }
}
