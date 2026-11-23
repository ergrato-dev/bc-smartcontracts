// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {DeployProtocol} from "../script/DeployProtocol.s.sol";
import {UpgradeToV2} from "../script/UpgradeToV2.s.sol";
import {UpgradeToV3} from "../script/UpgradeToV3.s.sol";
import {Registry} from "../src/Registry.sol";
import {RegistryV3} from "../src/RegistryV3.sol";
import {LoyaltyToken} from "../src/LoyaltyToken.sol";
import {Certificate} from "../src/Certificate.sol";
import {ReentrantTreasury} from "./attackers/ReentrantTreasury.sol";
import {StateSpyHook} from "./attackers/StateSpyHook.sol";
import {Phisher} from "./attackers/Phisher.sol";
import {GasBurnerHook} from "./attackers/GasBurnerHook.sol";
import {ReturnBombHook} from "./attackers/ReturnBombHook.sol";
import {PatchV3} from "../script/PatchV3.s.sol";

// ¿Qué? Los ataques clásicos de la semana 21 contra el protocolo desplegado con tus scripts y
//   actualizado a V3: reentrancy al cobrar, lectura a mitad de un alta, phishing con
//   `tx.origin`, hooks que bloquean o encarecen las altas, llamadas de un extraño a todo lo
//   privilegiado y la actualización que lleva las correcciones.
// ¿Para qué? Que cada clase de vulnerabilidad deje un test que falle si un cambio futuro la abre.
contract ClassicAttacksTest is Test {
    DeployProtocol.Deployment d;
    RegistryV3 registry;
    address admin;
    address alice = makeAddr("alice");
    address mallory = makeAddr("mallory");

    function setUp() public {
        vm.warp(1_750_000_000);
        d = new DeployProtocol().deploy(50);
        (, admin,) = vm.readCallers();
        MockV3Aggregator feed = new MockV3Aggregator(8, 2500e8);
        registry = new UpgradeToV3()
            .upgrade(new UpgradeToV2().upgrade(d.registry, 3), AggregatorV3Interface(address(feed)), 25e18, 3 hours);
        vm.deal(alice, 10 ether);
        vm.deal(mallory, 10 ether);
    }

    function _register(address who, string memory label) internal returns (uint256) {
        uint256 fee = registry.registrationFee();
        vm.prank(who);
        return registry.register{value: fee}(label);
    }

    function test_ReentrantTreasuryCollectsOnce() public {
        _register(alice, "uno");
        _register(alice, "dos");
        uint256 fees = address(registry).balance;
        ReentrantTreasury treasury = new ReentrantTreasury(registry);
        vm.startPrank(admin);
        registry.grantRole(registry.TREASURER_ROLE(), address(treasury));
        vm.stopPrank();

        treasury.attack();

        assertEq(treasury.received(), fees);
        assertEq(address(treasury).balance, fees);
        assertEq(address(registry).balance, 0);
        // La segunda entrada encontró el saldo ya enviado.
        assertEq(treasury.reentryError(), abi.encodeWithSelector(Registry.NothingToWithdraw.selector));
    }

    function test_HookSeesFinalState() public {
        _register(alice, "antes");
        StateSpyHook spy = new StateSpyHook(registry);
        vm.prank(admin);
        registry.setHook(address(spy));

        uint256 id = _register(alice, "espiado");

        assertEq(spy.seenCount(), id);
        assertEq(spy.seenActive(), 2);
        assertEq(spy.seenRegistrant(), alice);
        assertEq(spy.seenCertificateOwner(), alice);
    }

    function test_PhisherCannotUseAdminOrigin() public {
        vm.prank(mallory);
        Phisher phisher = new Phisher(registry);
        bytes32 role = registry.DEFAULT_ADMIN_ROLE();

        // El administrador firma la transacción y llama al cebo.
        vm.prank(admin, admin);
        phisher.claimPrize();

        assertEq(
            phisher.lastError(),
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(phisher), role)
        );
        assertFalse(registry.hasRole(role, mallory));
    }

    function test_GasBurningHookCannotBlockRegister() public {
        GasBurnerHook burner = new GasBurnerHook();
        vm.prank(admin);
        registry.setHook(address(burner));
        uint256 points = d.loyalty.balanceOf(alice);

        // Quedarse sin gas no deja motivo: el evento lleva `reason` vacío.
        vm.expectEmit(address(registry));
        emit Registry.HookFailed(1, "");
        uint256 id = _register(alice, "uno");

        assertEq(d.certificate.ownerOf(id), alice);
        // Sin hook que funcione no hay puntos, pero el alta está hecha.
        assertEq(d.loyalty.balanceOf(alice), points);
    }

    function test_ReturnBombHookCannotInflateGas() public {
        ReturnBombHook bomb = new ReturnBombHook();
        vm.prank(admin);
        registry.setHook(address(bomb));
        uint256 fee = registry.registrationFee();

        // Del motivo solo queda el selector del error.
        vm.expectEmit(address(registry));
        emit Registry.HookFailed(1, abi.encodePacked(ReturnBombHook.Junk.selector));
        vm.prank(alice);
        uint256 before = gasleft();
        registry.register{value: fee}("uno");
        uint256 used = before - gasleft();

        // Con el motivo entero en el log, el alta gasta más de 900 000 de gas.
        assertLt(used, 500_000);
    }

    function test_PatchKeepsState() public {
        _register(alice, "antes del parche");
        uint256 fee = registry.registrationFee();
        bytes32 slot = vm.load(address(registry), ERC1967Utils.IMPLEMENTATION_SLOT);
        address old = address(uint160(uint256(slot)));

        address implementation = new PatchV3().patch(registry);

        assertTrue(implementation != old);
        assertEq(registry.version(), 3);
        assertEq(registry.getItem(1).label, "antes del parche");
        assertEq(registry.registrationFee(), fee);
        assertEq(registry.maxPerAccount(), 3);
    }

    function test_RevertWhen_StrangerCallsPrivileged() public {
        bytes32 adminRole = registry.DEFAULT_ADMIN_ROLE();
        bytes memory notAdmin =
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, mallory, adminRole);

        vm.startPrank(mallory);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, mallory, registry.PAUSER_ROLE()
            )
        );
        registry.pause();
        vm.expectRevert(notAdmin);
        registry.unpause();
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, mallory, registry.TREASURER_ROLE()
            )
        );
        registry.withdrawFees(payable(mallory));
        vm.expectRevert(notAdmin);
        registry.setHook(address(d.loyalty));
        vm.expectRevert(notAdmin);
        registry.removeHook();
        vm.expectRevert(notAdmin);
        registry.setFeeConfig(AggregatorV3Interface(address(1)), 1, 1);
        vm.expectRevert(notAdmin);
        registry.grantRole(adminRole, mallory);
        vm.expectRevert(notAdmin);
        registry.upgradeToAndCall(address(new RegistryV3()), "");

        // Los inicializadores ya se usaron, en el proxy y en la implementación.
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        registry.initialize(1, d.loyalty, d.certificate);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        registry.initializeV2(100);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        Registry(d.implementation).initialize(1, d.loyalty, d.certificate);

        // El token y el certificado solo obedecen al registro.
        vm.expectRevert(abi.encodeWithSelector(LoyaltyToken.NotRegistry.selector, mallory));
        d.loyalty.onItemRegistered(1, mallory, "uno");
        vm.expectRevert(abi.encodeWithSelector(Certificate.NotRegistry.selector, mallory));
        d.certificate.mint(mallory, 99);
        vm.stopPrank();
    }
}
