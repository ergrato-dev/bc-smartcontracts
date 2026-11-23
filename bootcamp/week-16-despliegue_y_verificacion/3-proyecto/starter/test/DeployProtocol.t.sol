// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Registry} from "../src/Registry.sol";
import {LoyaltyToken} from "../src/LoyaltyToken.sol";
import {Certificate} from "../src/Certificate.sol";
import {DeployProtocol} from "../script/DeployProtocol.s.sol";

// ¿Qué? Ejecuta el script de despliegue dentro de un test y comprueba lo que deja en la cadena.
// ¿Para qué? Que el script que vas a lanzar en Sepolia esté probado antes, como un contrato más.
// ¿Impacto? No los modifiques: son el contrato de esta capa. En un test, quien firma lo que
//   emite el script es DEFAULT_SENDER, el remitente por defecto de Foundry.
contract DeployProtocolTest is Test {
    DeployProtocol script;
    DeployProtocol.Deployment d;

    function setUp() public {
        script = new DeployProtocol();
        d = script.deploy(50);
    }

    function test_ProxyPointsToImplementation() public view {
        bytes32 slot = vm.load(address(d.registry), ERC1967Utils.IMPLEMENTATION_SLOT);
        assertEq(address(uint160(uint256(slot))), d.implementation);
        assertEq(d.registry.version(), 1);
    }

    function test_TokenAndCertificatePointToTheProxy() public view {
        assertEq(d.loyalty.REGISTRY(), address(d.registry));
        assertEq(address(d.certificate.REGISTRY()), address(d.registry));
        assertEq(address(d.registry.loyalty()), address(d.loyalty));
        assertEq(address(d.registry.certificate()), address(d.certificate));
    }

    function test_TokenIsTheHook() public view {
        assertEq(d.registry.hook(), address(d.loyalty));
    }

    function test_SignerIsAdmin() public view {
        assertTrue(d.registry.hasRole(d.registry.DEFAULT_ADMIN_ROLE(), DEFAULT_SENDER));
        assertFalse(d.registry.hasRole(d.registry.DEFAULT_ADMIN_ROLE(), address(script)));
    }

    function test_CapacityFromArgument() public {
        assertEq(d.registry.capacity(), 50);
        assertEq(script.deploy(7).registry.capacity(), 7);
    }

    function test_RunUsesDefaultCapacity() public {
        assertEq(script.run().registry.capacity(), 50);
    }

    function test_ImplementationIsClosed() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        Registry(d.implementation).initialize(50, d.loyalty, d.certificate);
    }

    function test_MemberRegistersAndEarnsPoints() public {
        address member = makeAddr("member");
        uint256 fee = d.registry.REGISTRATION_FEE();
        hoax(member, fee);
        uint256 id = d.registry.register{value: fee}("first");
        assertEq(d.certificate.ownerOf(id), member);
        assertGt(d.loyalty.balanceOf(member), 0);
    }

    function test_RevertWhen_CapacityIsZero() public {
        vm.expectRevert(Registry.InvalidCapacity.selector);
        script.deploy(0);
    }
}
