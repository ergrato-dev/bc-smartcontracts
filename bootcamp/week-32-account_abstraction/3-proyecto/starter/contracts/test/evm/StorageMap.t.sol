// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {DeployProtocol} from "../../script/DeployProtocol.s.sol";
import {UpgradeToV2} from "../../script/UpgradeToV2.s.sol";
import {UpgradeToV3} from "../../script/UpgradeToV3.s.sol";
import {IRegistry} from "../../src/IRegistry.sol";
import {RegistryV3} from "../../src/RegistryV3.sol";

// ¿Qué? El mapa de storage del registro, comprobado slot a slot: cada dato se lee del proxy con
//   `vm.load` en la posición que calcula el test, y se compara con su getter.
// ¿Para qué? Una actualización solo es segura si la versión nueva encuentra cada dato donde lo
//   dejó la anterior. Los demás tests despliegan un proxy nuevo y no ven si una variable cambió
//   de slot; estos sí.
// ¿Impacto? Si un test de aquí falla tras cambiar un contrato, ese cambio movió el storage: con
//   el proxy ya desplegado, la versión nueva leería datos de otra variable.
contract StorageMapTest is Test {
    RegistryV3 registry;
    MockV3Aggregator feed;
    address admin;
    address pauser = makeAddr("pauser");
    address alice = makeAddr("alice");

    function setUp() public {
        vm.warp(1_750_000_000);
        DeployProtocol.Deployment memory d = new DeployProtocol().deploy(50);
        (, admin,) = vm.readCallers();
        feed = new MockV3Aggregator(8, 2500e8);
        registry = new UpgradeToV3()
            .upgrade(new UpgradeToV2().upgrade(d.registry, 3), AggregatorV3Interface(address(feed)), 25e18, 3 hours);
        bytes32 pauserRole = registry.PAUSER_ROLE();
        vm.prank(admin);
        registry.grantRole(pauserRole, pauser);
        vm.deal(alice, 10 ether);
        uint256 fee = registry.registrationFee();
        vm.startPrank(alice);
        registry.register{value: fee}("ajedrez");
        registry.register{value: fee}("un nombre de treinta y dos bytes");
        vm.stopPrank();
    }

    function _word(uint256 slot) internal view returns (uint256) {
        return uint256(vm.load(address(registry), bytes32(slot)));
    }

    // La raíz de un espacio de nombres ERC-7201 (semana 15).
    function _namespace(string memory id) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(uint256(keccak256(bytes(id))) - 1))) & ~uint256(0xff);
    }

    function test_ImplementationAtEip1967Slot() public view {
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        address implementation = address(uint160(uint256(vm.load(address(registry), slot))));
        assertTrue(implementation != address(registry));
        assertEq(RegistryV3(implementation).version(), 3);
        assertEq(UUPSUpgradeable(implementation).proxiableUUID(), slot);
    }

    function test_StateVariablesAtTheirSlots() public view {
        assertEq(_word(0), registry.capacity());
        assertEq(address(uint160(_word(1))), address(registry.loyalty()));
        assertEq(address(uint160(_word(2))), address(registry.certificate()));
        assertEq(_word(3), registry.count());
        assertEq(_word(4), registry.activeCount());
        assertEq(address(uint160(_word(7))), registry.hook());
        assertEq(_word(8), registry.maxPerAccount());
        assertEq(address(uint160(_word(9))), address(registry.priceFeed()));
        assertEq(_word(10), registry.usdFee());
        assertEq(_word(11), registry.maxPriceAge());
        assertEq(_word(0), 50);
        assertEq(_word(3), 2);
        assertEq(_word(4), 2);
        assertEq(_word(8), 3);
        assertEq(address(uint160(_word(9))), address(feed));
        assertEq(_word(10), 25e18);
        assertEq(_word(11), 3 hours);
    }

    function test_ItemAtMappingSlot() public view {
        uint256 base = uint256(keccak256(abi.encode(uint256(1), uint256(5))));
        IRegistry.Item memory item = registry.getItem(1);
        // El primer slot es el del id, que desde la semana 29 no se escribe: el id es la clave.
        assertEq(_word(base), 0);
        assertEq(item.id, 1);
        uint256 packed = _word(base + 1);
        assertEq(address(uint160(packed)), alice);
        assertEq(uint8(packed >> 160), uint8(IRegistry.Status.Active));
        assertEq(_word(base + 2), item.registeredAt);
        // String corto: los datos alineados a la izquierda y la longitud por 2 en el último byte.
        bytes memory label = bytes(item.label);
        assertEq(_word(base + 3) & 0xff, label.length * 2);
        assertEq(bytes32(_word(base + 3) & ~uint256(0xff)), bytes32(label));

        uint256 base2 = uint256(keccak256(abi.encode(uint256(2), uint256(5))));
        bytes memory long = bytes(registry.getItem(2).label);
        assertEq(long.length, 32);
        assertEq(_word(base2 + 3), 32 * 2 + 1);
        assertEq(bytes32(_word(uint256(keccak256(abi.encode(base2 + 3))))), bytes32(long));
    }

    function test_IdsOfAtArraySlot() public view {
        uint256 slot = uint256(keccak256(abi.encode(alice, uint256(6))));
        uint256[] memory ids = registry.idsOf(alice);
        assertEq(_word(slot), ids.length);
        uint256 data = uint256(keccak256(abi.encode(slot)));
        for (uint256 i; i < ids.length; ++i) {
            assertEq(_word(data + i), ids[i]);
        }
    }

    function test_RolesAndPauseInNamespacedStorage() public {
        uint256 root = _namespace("openzeppelin.storage.AccessControl");
        bytes32 pauserRole = registry.PAUSER_ROLE();
        uint256 roleData = uint256(keccak256(abi.encode(pauserRole, root)));
        assertEq(_word(uint256(keccak256(abi.encode(pauser, roleData)))), 1);
        assertEq(_word(uint256(keccak256(abi.encode(alice, roleData)))), 0);
        assertEq(bytes32(_word(roleData + 1)), registry.DEFAULT_ADMIN_ROLE());

        uint256 pausable = _namespace("openzeppelin.storage.Pausable");
        assertEq(_word(pausable), 0);
        vm.prank(pauser);
        registry.pause();
        assertEq(_word(pausable), 1);
    }
}
