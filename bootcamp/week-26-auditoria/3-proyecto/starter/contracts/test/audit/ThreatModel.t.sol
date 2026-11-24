// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {DeployProtocol} from "../../script/DeployProtocol.s.sol";
import {UpgradeToV2} from "../../script/UpgradeToV2.s.sol";
import {UpgradeToV3} from "../../script/UpgradeToV3.s.sol";
import {Registry} from "../../src/Registry.sol";
import {RegistryV3} from "../../src/RegistryV3.sol";

// ¿Qué? Las amenazas del modelo de la semana 26 que ningún test anterior cubría: lo que puede hacer
//   cada rol de confianza si su clave cae en malas manos, cómo se recupera el protocolo y la firma
//   llevada a otra cadena.
// ¿Para qué? Que cada fila del modelo de amenazas del informe cite un test que falla si la defensa
//   desaparece.
contract ThreatModelTest is Test {
    DeployProtocol.Deployment d;
    RegistryV3 registry;
    address admin;
    address pauser = makeAddr("pauser");
    address treasurer = makeAddr("treasurer");
    address alice = makeAddr("alice");
    address relayer = makeAddr("relayer");
    address member;
    uint256 memberKey;

    function setUp() public {
        vm.warp(1_750_000_000);
        d = new DeployProtocol().deploy(50);
        (, admin,) = vm.readCallers();
        MockV3Aggregator feed = new MockV3Aggregator(8, 2500e8);
        registry = new UpgradeToV3()
            .upgrade(new UpgradeToV2().upgrade(d.registry, 3), AggregatorV3Interface(address(feed)), 25e18, 3 hours);
        (member, memberKey) = makeAddrAndKey("member");
        vm.startPrank(admin);
        registry.grantRole(registry.PAUSER_ROLE(), pauser);
        registry.grantRole(registry.TREASURER_ROLE(), treasurer);
        vm.stopPrank();
        vm.deal(alice, 10 ether);
        vm.deal(relayer, 10 ether);
    }

    function _unauthorized(address account, bytes32 role) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, account, role);
    }

    // La firma EIP-712 de `member` para dar de alta `label` con su nonce actual, en la cadena actual.
    function _signOrder(string memory label, uint256 deadline) internal view returns (bytes memory) {
        (, string memory name, string memory version,,,,) = registry.eip712Domain();
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(registry)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                registry.REGISTRATION_TYPEHASH(), member, keccak256(bytes(label)), registry.nonces(member), deadline
            )
        );
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(memberKey, keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash)));
        return abi.encodePacked(r, s, v);
    }

    // T-07: la clave de PAUSER_ROLE se filtra. Quien la tiene para el registro, y nada más.
    function test_PauserCannotEscalate() public {
        // TODO (semana 26): `pauser` pausa el registro. Después intenta unpause, withdrawFees,
        //   setHook, grantRole y upgradeToAndCall: cada una revierte con
        //   AccessControlUnauthorizedAccount y el rol que le falta. Al final el registro sigue en pausa.
        assertTrue(false, "TODO: test_PauserCannotEscalate");
    }

    // T-08: el administrador retira el rol a un pauser comprometido y reanuda el registro.
    function test_AdminRevokesCompromisedPauser() public {
        // TODO (semana 26): `pauser` pausa. `admin` le retira PAUSER_ROLE y reanuda. `pauser` ya
        //   no puede pausar, y `alice` vuelve a dar de alta.
        assertTrue(false, "TODO: test_AdminRevokesCompromisedPauser");
    }

    // T-09: la clave de TREASURER_ROLE se filtra. Se lleva las tasas cobradas, y nada más.
    function test_TreasurerCannotEscalate() public {
        // TODO (semana 26): `alice` da de alta y `treasurer` cobra la tasa (eso sí puede). Después
        //   intenta pause, setFeeConfig, grantRole y upgradeToAndCall: cada una revierte. Al final
        //   `treasurer` tiene la tasa y el registro, su alta.
        assertTrue(false, "TODO: test_TreasurerCannotEscalate");
    }

    // T-10: una orden firmada para esta cadena se envía en otra donde el registro tiene la misma dirección.
    function test_RevertWhen_SignedOrderFromOtherChain() public {
        // TODO (semana 26): `member` firma una orden con `_signOrder`. Cambia de cadena con
        //   `vm.chainId(10)` y `relayer` la envía: revierte con InvalidSigner.
        assertTrue(false, "TODO: test_RevertWhen_SignedOrderFromOtherChain");
    }
}
