// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Registry} from "../src/Registry.sol";
import {IRegistry} from "../src/IRegistry.sol";
import {Certificate} from "../src/Certificate.sol";
import {IERC165} from "../src/IERC165.sol";

// ¿Qué? Los roles y la pausa del registro: quién puede qué, y qué sigue funcionando en pausa.
// ¿Para qué? Comprobar la capa de la semana 13 sin repetir los tests de OpenZeppelin.
// ¿Impacto? No los modifiques: son el contrato de esta capa.
contract RegistryRolesTest is Test {
    Registry registry;
    uint256 fee;
    bytes32 ADMIN;
    bytes32 PAUSER;
    bytes32 TREASURER;
    address guardian = makeAddr("guardian");
    address treasurer = makeAddr("treasurer");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        registry = new Registry(10);
        fee = registry.REGISTRATION_FEE();
        (ADMIN, PAUSER, TREASURER) = (registry.DEFAULT_ADMIN_ROLE(), registry.PAUSER_ROLE(), registry.TREASURER_ROLE());
        registry.grantRole(PAUSER, guardian);
        registry.grantRole(TREASURER, treasurer);
        vm.deal(alice, 1 ether);
    }

    function _unauthorized(address account, bytes32 role) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, account, role);
    }

    function _register(string memory label) internal returns (uint256) {
        vm.prank(alice);
        return registry.register{value: fee}(label);
    }

    function test_RoleIdsAreTheHashOfTheirNames() public view {
        assertEq(PAUSER, keccak256("PAUSER_ROLE"));
        assertEq(TREASURER, keccak256("TREASURER_ROLE"));
        assertEq(registry.getRoleAdmin(PAUSER), ADMIN);
        assertEq(registry.getRoleAdmin(TREASURER), ADMIN);
    }

    function test_DeployerOnlyGetsAdmin() public {
        vm.prank(bob);
        Registry other = new Registry(1);
        assertTrue(other.hasRole(ADMIN, bob));
        assertFalse(other.hasRole(PAUSER, bob));
        assertFalse(other.hasRole(TREASURER, bob));
    }

    function test_RevertWhen_AdminPausesWithoutRole() public {
        vm.expectRevert(_unauthorized(address(this), PAUSER));
        registry.pause();
    }

    function test_RevertWhen_GuardianUnpauses() public {
        vm.prank(guardian);
        registry.pause();
        vm.prank(guardian);
        vm.expectRevert(_unauthorized(guardian, ADMIN));
        registry.unpause();
    }

    function test_RevertWhen_GuardianWithdraws() public {
        _register("a");
        vm.prank(guardian);
        vm.expectRevert(_unauthorized(guardian, TREASURER));
        registry.withdrawFees(payable(guardian));
    }

    function test_RevertWhen_TreasurerSetsHook() public {
        address points = address(registry.LOYALTY());
        vm.prank(treasurer);
        vm.expectRevert(_unauthorized(treasurer, ADMIN));
        registry.setHook(points);
    }

    function test_RevertWhen_BatchWhilePaused() public {
        vm.prank(guardian);
        registry.pause();
        string[] memory labels = new string[](1);
        labels[0] = "a";
        vm.prank(alice);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        registry.registerBatch{value: fee}(labels);
    }

    function test_RetireAndTransferWhilePaused() public {
        _register("a");
        _register("b");
        vm.prank(guardian);
        registry.pause();
        vm.prank(alice);
        registry.retire(1);
        Certificate certificate = registry.CERTIFICATE();
        vm.prank(alice);
        certificate.transferFrom(alice, bob, 2);
        assertEq(certificate.ownerOf(2), bob);
        assertEq(registry.activeCount(), 1);
    }

    function test_RevokedGuardianCannotPause() public {
        registry.revokeRole(PAUSER, guardian);
        vm.prank(guardian);
        vm.expectRevert(_unauthorized(guardian, PAUSER));
        registry.pause();
    }

    function test_SupportsAccessControl() public view {
        assertTrue(registry.supportsInterface(type(IRegistry).interfaceId));
        assertTrue(registry.supportsInterface(type(IAccessControl).interfaceId));
        assertTrue(registry.supportsInterface(type(IERC165).interfaceId));
        assertFalse(registry.supportsInterface(0xffffffff));
    }
}
