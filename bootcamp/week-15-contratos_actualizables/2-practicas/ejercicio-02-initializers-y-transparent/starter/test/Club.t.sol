// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ClubV1, ClubV2} from "../src/Club.sol";

contract ClubTest is Test {
    bytes32 constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    event Initialized(uint64 version);

    ClubV1 v1;
    ClubV2 v2;
    ClubV1 club; // el proxy, visto como un ClubV1
    ProxyAdmin proxyAdmin;
    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");

    function setUp() public {
        v1 = new ClubV1();
        v2 = new ClubV2();
        // El proxy llama a `initialize` en su constructor: nadie puede adelantarse.
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(v1), owner, abi.encodeCall(ClubV1.initialize, (owner, "Chess")));
        club = ClubV1(address(proxy));
        // El proxy creó su ProxyAdmin, cuyo dueño es `owner`, y lo guardó en el slot de administrador.
        proxyAdmin = ProxyAdmin(address(uint160(uint256(vm.load(address(proxy), ADMIN_SLOT)))));
    }

    function _upgradeToV2(uint256 maxMembers) internal {
        vm.prank(owner);
        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(club)), address(v2), abi.encodeCall(ClubV2.initializeV2, (maxMembers))
        );
    }

    // --- Dado ---

    function test_Given_ProxyAdminBelongsToOwner() public view {
        assertEq(proxyAdmin.owner(), owner);
    }

    function test_Given_ProxyAdminCannotUseTheClub() public {
        vm.prank(address(proxyAdmin));
        vm.expectRevert(TransparentUpgradeableProxy.ProxyDeniedAdminAccess.selector);
        club.members();
    }

    function test_Given_RevertWhen_InitializedTwice() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        club.initialize(alice, "Mine");
    }

    function test_Given_RevertWhen_NotOwnerUpgrades() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(club)), address(v2), "");
    }

    // --- Paso 1: initialize ---

    function test_Step1_ProxyIsInitialized() public view {
        assertEq(club.owner(), owner);
        assertEq(club.name(), "Chess");
    }

    function test_Step1_OwnerRenames() public {
        vm.prank(owner);
        club.rename("Go");
        assertEq(club.name(), "Go");
    }

    function test_Step1_RevertWhen_NotOwnerRenames() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        club.rename("Mine");
    }

    // --- Paso 2: cerrar la implementación ---

    function test_Step2_ImplementationIsClosedOnDeploy() public {
        vm.expectEmit();
        emit Initialized(type(uint64).max);
        new ClubV1();
    }

    function test_Step2_RevertWhen_ImplementationIsInitialized() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        v1.initialize(alice, "Mine");
    }

    // --- Paso 3: V2 con reinitializer ---

    function test_Step3_UpgradeKeepsMembersAndSetsMax() public {
        vm.prank(alice);
        club.join();
        _upgradeToV2(2);
        ClubV2 upgraded = ClubV2(address(club));
        assertEq(upgraded.members(), 1);
        assertTrue(upgraded.isMember(alice));
        assertEq(upgraded.name(), "Chess");
        assertEq(upgraded.owner(), owner);
        assertEq(upgraded.maxMembers(), 2);
    }

    function test_Step3_V2LimitsMembers() public {
        vm.prank(alice);
        club.join();
        _upgradeToV2(2);
        vm.prank(bob);
        club.join();
        vm.expectRevert(abi.encodeWithSelector(ClubV2.ClubFull.selector, 2));
        vm.prank(carol);
        club.join();
    }

    function test_Step3_RevertWhen_InitializeV2Twice() public {
        _upgradeToV2(2);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        ClubV2(address(club)).initializeV2(100);
    }
}
