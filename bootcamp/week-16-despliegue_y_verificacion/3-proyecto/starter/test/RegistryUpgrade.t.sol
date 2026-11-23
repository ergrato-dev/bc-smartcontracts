// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Registry} from "../src/Registry.sol";
import {RegistryV2} from "../src/RegistryV2.sol";
import {IRegistry} from "../src/IRegistry.sol";
import {LoyaltyToken} from "../src/LoyaltyToken.sol";
import {Certificate} from "../src/Certificate.sol";
import {DeployRegistry} from "./DeployRegistry.sol";

// ¿Qué? El registro detrás de su ERC1967Proxy: inicialización, quién actualiza y qué
//   conserva la actualización a RegistryV2.
// ¿Para qué? Comprobar que el proxy es el registro (el token, el certificado y el dominio
//   EIP-712 apuntan a él) y que actualizar no pierde nada.
// ¿Impacto? No los modifiques: son el contrato de esta capa.
contract RegistryUpgradeTest is Test, DeployRegistry {
    Registry registry;
    RegistryV2 v2;
    bytes32 ADMIN;
    uint256 fee;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    event Upgraded(address indexed implementation);

    function setUp() public {
        registry = deployRegistry(10);
        v2 = new RegistryV2();
        ADMIN = registry.DEFAULT_ADMIN_ROLE();
        fee = registry.REGISTRATION_FEE();
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
    }

    function _implementation() internal view returns (address) {
        return address(uint160(uint256(vm.load(address(registry), ERC1967Utils.IMPLEMENTATION_SLOT))));
    }

    function _register(address who, string memory label) internal returns (uint256) {
        vm.prank(who);
        return registry.register{value: fee}(label);
    }

    function _upgradeToV2(uint256 maxPerAccount) internal {
        registry.upgradeToAndCall(address(v2), abi.encodeCall(RegistryV2.initializeV2, (maxPerAccount)));
    }

    // --- El proxy es el registro ---

    function test_TokenAndCertificatePointToTheProxy() public view {
        assertEq(registry.loyalty().REGISTRY(), address(registry));
        assertEq(address(registry.certificate().REGISTRY()), address(registry));
    }

    function test_DomainUsesTheProxyAddress() public view {
        (, string memory name, string memory version,, address verifyingContract,,) =
            IERC5267(address(registry)).eip712Domain();
        assertEq(name, registry.PROTOCOL_NAME());
        assertEq(version, "1");
        assertEq(verifyingContract, address(registry));
    }

    function test_ImplementationIsClosed() public {
        Registry implementation = Registry(_implementation());
        (LoyaltyToken token, Certificate nft) = (registry.loyalty(), registry.certificate());
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        implementation.initialize(1, token, nft);
        assertFalse(implementation.hasRole(ADMIN, address(this)));
    }

    function test_RevertWhen_InitializedTwice() public {
        (LoyaltyToken token, Certificate nft) = (registry.loyalty(), registry.certificate());
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        registry.initialize(1, token, nft);
    }

    function test_RevertWhen_TokenPointsToAnotherRegistry() public {
        Registry implementation = new Registry();
        LoyaltyToken token = new LoyaltyToken(alice);
        Certificate nft = new Certificate(IRegistry(alice));
        vm.expectRevert(abi.encodeWithSelector(Registry.WrongRegistry.selector, address(token)));
        new ERC1967Proxy(address(implementation), abi.encodeCall(Registry.initialize, (1, token, nft)));
    }

    // --- Quién actualiza ---

    function test_RevertWhen_NotAdminUpgrades() public {
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, ADMIN));
        vm.prank(alice);
        registry.upgradeToAndCall(address(v2), "");
    }

    function test_RevertWhen_UpgradeToNonUups() public {
        address plain = address(new Certificate(IRegistry(address(registry))));
        vm.expectRevert(abi.encodeWithSelector(ERC1967Utils.ERC1967InvalidImplementation.selector, plain));
        registry.upgradeToAndCall(plain, "");
    }

    function test_RevertWhen_UpgradeIsCalledOnImplementation() public {
        vm.expectRevert(UUPSUpgradeable.UUPSUnauthorizedCallContext.selector);
        Registry(_implementation()).upgradeToAndCall(address(v2), "");
    }

    // --- La actualización a V2 ---

    function test_UpgradeEmitsUpgraded() public {
        vm.expectEmit(address(registry));
        emit Upgraded(address(v2));
        _upgradeToV2(2);
        assertEq(_implementation(), address(v2));
        assertEq(registry.version(), 2);
    }

    function test_UpgradeKeepsItemsPointsAndCertificates() public {
        uint256 id = _register(alice, "first");
        LoyaltyToken token = registry.loyalty();
        Certificate nft = registry.certificate();
        uint256 points = token.balanceOf(alice);

        _upgradeToV2(2);

        assertEq(registry.count(), 1);
        assertEq(registry.activeCount(), 1);
        assertEq(registry.capacity(), 10);
        assertEq(registry.getItem(id).registrant, alice);
        assertEq(registry.getItem(id).label, "first");
        assertEq(address(registry.loyalty()), address(token));
        assertEq(address(registry.certificate()), address(nft));
        assertEq(token.balanceOf(alice), points);
        assertEq(nft.ownerOf(id), alice);
        assertTrue(registry.hasRole(ADMIN, address(this)));
        assertEq(address(registry).balance, fee);
    }

    function test_V2LimitsItemsPerAccount() public {
        _register(alice, "first");
        _upgradeToV2(2);
        _register(alice, "second");
        vm.expectRevert(abi.encodeWithSelector(RegistryV2.TooManyItems.selector, alice, 2));
        vm.prank(alice);
        registry.register{value: fee}("third");
        // Otra cuenta sí puede.
        _register(bob, "bob");
        assertEq(RegistryV2(address(registry)).maxPerAccount(), 2);
    }

    function test_V2LimitAppliesToBatches() public {
        _upgradeToV2(2);
        string[] memory labels = new string[](3);
        labels[0] = "a";
        labels[1] = "b";
        labels[2] = "c";
        vm.expectRevert(abi.encodeWithSelector(RegistryV2.TooManyItems.selector, alice, 2));
        vm.prank(alice);
        registry.registerBatch{value: fee * 3}(labels);
    }

    function test_RevertWhen_InitializeV2Twice() public {
        _upgradeToV2(2);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        RegistryV2(address(registry)).initializeV2(100);
    }

    function test_RevertWhen_V2LimitIsZero() public {
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidAmount.selector, 0));
        _upgradeToV2(0);
    }

    function test_V2ImplementationIsClosed() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        v2.initializeV2(1);
    }
}
