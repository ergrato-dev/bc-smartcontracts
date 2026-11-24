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
        // TODO (semana 27): calcula el slot de implementación de ERC-1967,
        //   keccak256("eip1967.proxy.implementation") - 1, y lee la dirección que guarda el proxy.
        //   Comprueba que no es el proxy, que `version()` llamada directamente a esa dirección da 3
        //   y que su `proxiableUUID()` es ese mismo slot.
        assertTrue(false, "TODO: test_ImplementationAtEip1967Slot");
    }

    function test_StateVariablesAtTheirSlots() public view {
        // TODO (semana 27): con `forge inspect RegistryV3 storageLayout`, lee cada variable de V1,
        //   V2 y V3 de su slot con `_word` y compárala con su getter. Las direcciones son los 20
        //   bytes bajos: `address(uint160(_word(n)))`. Añade los valores que conoces del `setUp`
        //   (dos altas, `maxPerAccount` 3, tasa de 25 dólares, 3 horas de antigüedad máxima).
        assertTrue(false, "TODO: test_StateVariablesAtTheirSlots");
    }

    function test_ItemAtMappingSlot() public view {
        // TODO (semana 27): el `Item` 1 empieza en keccak256(abi.encode(1, slot de _items)) y ocupa
        //   cuatro slots: `id`; `registrant` y `status` empaquetados (status en el byte 20);
        //   `registeredAt`; y la etiqueta corta "ajedrez", con la longitud por 2 en el último byte.
        //   El `Item` 2 tiene una etiqueta de 32 bytes: comprueba que es un string largo (su slot
        //   guarda 32 * 2 + 1) y lee sus datos en keccak256(abi.encode(su slot)).
        assertTrue(false, "TODO: test_ItemAtMappingSlot");
    }

    function test_IdsOfAtArraySlot() public view {
        // TODO (semana 27): la longitud de `_idsOf[alice]` está en keccak256(abi.encode(alice, slot
        //   de _idsOf)), y sus elementos, a partir del keccak256 de ese slot. Compáralos con
        //   `idsOf(alice)`.
        assertTrue(false, "TODO: test_IdsOfAtArraySlot");
    }

    function test_RolesAndPauseInNamespacedStorage() public {
        // TODO (semana 27): con `_namespace`, la raíz de "openzeppelin.storage.AccessControl".
        //   `_roles` es un mapping en su offset 0: `RoleData` de PAUSER_ROLE en keccak256(abi.encode(
        //   rol, raíz)); su `hasRole` es otro mapping en ese slot, y su `adminRole`, en el siguiente.
        //   Comprueba que `pauser` tiene el rol, que alice no, y que el admin del rol es
        //   DEFAULT_ADMIN_ROLE. Después, la raíz de "openzeppelin.storage.Pausable": 0, `pause()`, 1.
        assertTrue(false, "TODO: test_RolesAndPauseInNamespacedStorage");
    }
}
