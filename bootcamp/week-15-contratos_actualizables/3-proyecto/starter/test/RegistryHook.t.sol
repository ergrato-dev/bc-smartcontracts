// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Registry} from "../src/Registry.sol";
import {DeployRegistry} from "./DeployRegistry.sol";
import {IERC165} from "../src/IERC165.sol";
import {IRegistrationHook} from "../src/IRegistrationHook.sol";
import {LoyaltyToken} from "../src/LoyaltyToken.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

// ¿Qué? Hooks de prueba: declaran la interfaz, pero fallan al recibir el aviso.
abstract contract TestHook is IERC165, IRegistrationHook {
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IRegistrationHook).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}

contract BrokenHook is TestHook {
    error Broken(uint256 id);

    function onItemRegistered(uint256 id, address, string calldata) external pure {
        revert Broken(id);
    }
}

contract GasBurnerHook is TestHook {
    function onItemRegistered(uint256, address, string calldata) external pure {
        while (true) {}
    }
}

// ¿Qué? Un contrato sin supportsInterface.
contract NotAHook {}

// ¿Qué? El hook del registro: quién puede ponerlo y qué pasa cuando avisa.
// ¿Para qué? Comprobar que el registro avisa a otro contrato sin depender de él.
// ¿Impacto? No los modifiques: son el contrato de esta capa.
contract RegistryHookTest is Test, DeployRegistry {
    Registry registry;
    LoyaltyToken points;
    uint256 fee;
    address alice = makeAddr("alice");

    function setUp() public {
        registry = deployRegistry(10);
        points = registry.loyalty();
        fee = registry.REGISTRATION_FEE();
        vm.deal(alice, 1 ether);
    }

    function _labels(uint256 n) internal pure returns (string[] memory labels) {
        labels = new string[](n);
        for (uint256 i = 0; i < n; i++) {
            labels[i] = "item";
        }
    }

    function test_SetHook() public {
        vm.expectEmit(address(registry));
        emit Registry.HookChanged(address(points));
        registry.setHook(address(points));
        assertEq(registry.hook(), address(points));
    }

    function test_RevertWhen_StrangerSetsHook() public {
        bytes32 role = registry.DEFAULT_ADMIN_ROLE();
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, role));
        registry.setHook(address(points));
    }

    function test_RevertWhen_HookIsZero() public {
        vm.expectRevert(Registry.ZeroAddress.selector);
        registry.setHook(address(0));
    }

    function test_RevertWhen_HookHasNoCode() public {
        vm.expectRevert(abi.encodeWithSelector(Registry.InvalidHook.selector, alice));
        registry.setHook(alice);
    }

    function test_RevertWhen_HookIsNotAHook() public {
        address notAHook = address(new NotAHook());
        vm.expectRevert(abi.encodeWithSelector(Registry.InvalidHook.selector, notAHook));
        registry.setHook(notAHook);

        // El registro declara ERC-165, pero no IRegistrationHook.
        vm.expectRevert(abi.encodeWithSelector(Registry.InvalidHook.selector, address(registry)));
        registry.setHook(address(registry));
    }

    function test_RemoveHook() public {
        registry.setHook(address(points));
        vm.expectEmit(address(registry));
        emit Registry.HookChanged(address(0));
        registry.removeHook();
        assertEq(registry.hook(), address(0));

        vm.prank(alice);
        registry.register{value: fee}("north");
        assertEq(points.balanceOf(alice), 0);
    }

    function test_RegisterNotifiesHook() public {
        registry.setHook(address(points));
        vm.startPrank(alice);
        registry.register{value: fee}("north");
        registry.registerBatch{value: 3 * fee}(_labels(3));
        vm.stopPrank();
        assertEq(points.balanceOf(alice), 4 * points.REWARD());
    }

    function test_RegisterSurvivesBrokenHook() public {
        registry.setHook(address(new BrokenHook()));
        vm.expectEmit(address(registry));
        emit Registry.HookFailed(1, abi.encodeWithSelector(BrokenHook.Broken.selector, 1));
        vm.prank(alice);
        uint256 id = registry.register{value: fee}("north");
        assertEq(id, 1);
        assertEq(registry.count(), 1);
    }

    function test_RegisterSurvivesGasBurner() public {
        registry.setHook(address(new GasBurnerHook()));
        vm.expectEmit(address(registry));
        emit Registry.HookFailed(1, "");
        vm.prank(alice);
        uint256 before = gasleft();
        registry.register{value: fee}("north");
        assertLt(before - gasleft(), 400_000);
        assertEq(registry.count(), 1);
    }

    function test_Loyalty_RevertWhen_CallerIsNotRegistry() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(LoyaltyToken.NotRegistry.selector, alice));
        points.onItemRegistered(1, alice, "north");
    }

    function test_Loyalty_SupportsInterface() public view {
        assertTrue(points.supportsInterface(type(IRegistrationHook).interfaceId));
        assertTrue(points.supportsInterface(type(IERC165).interfaceId));
        assertFalse(points.supportsInterface(0xffffffff));
    }
}
