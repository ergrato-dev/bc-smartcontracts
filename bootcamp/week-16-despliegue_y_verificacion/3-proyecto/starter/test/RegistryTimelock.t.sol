// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {Registry} from "../src/Registry.sol";
import {RegistryV2} from "../src/RegistryV2.sol";
import {DeployRegistry} from "./DeployRegistry.sol";

// ¿Qué? El registro con un TimelockController como único administrador, como lo dejas en
//   anvil: la configuración pasa por el plazo y la pausa no.
// ¿Para qué? Comprobar que, tras el traspaso, nadie se salta el plazo, tampoco quien desplegó.
// ¿Impacto? No los modifiques: son el contrato de esta capa.
contract RegistryTimelockTest is Test, DeployRegistry {
    uint256 constant DELAY = 1 days;

    Registry registry;
    TimelockController timelock;
    bytes32 ADMIN;
    address ops = makeAddr("ops");
    address guardian = makeAddr("guardian");

    function setUp() public {
        registry = deployRegistry(10);
        ADMIN = registry.DEFAULT_ADMIN_ROLE();
        address[] memory proposers = new address[](1);
        proposers[0] = ops;
        address[] memory executors = new address[](1);
        executors[0] = address(0);
        timelock = new TimelockController(DELAY, proposers, executors, address(0));

        registry.grantRole(registry.PAUSER_ROLE(), guardian);
        registry.grantRole(ADMIN, address(timelock));
        registry.renounceRole(ADMIN, address(this));
    }

    function _schedule(bytes memory data) internal returns (bytes32 id) {
        vm.prank(ops);
        timelock.schedule(address(registry), 0, data, bytes32(0), bytes32(0), DELAY);
        return timelock.hashOperation(address(registry), 0, data, bytes32(0), bytes32(0));
    }

    function _execute(bytes memory data) internal {
        timelock.execute(address(registry), 0, data, bytes32(0), bytes32(0));
    }

    function test_DeployerIsNoLongerAdmin() public {
        assertFalse(registry.hasRole(ADMIN, address(this)));
        assertTrue(registry.hasRole(ADMIN, address(timelock)));
        address points = address(registry.loyalty());
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), ADMIN)
        );
        registry.setHook(points);
    }

    function test_SetHookAfterTheDelay() public {
        bytes memory data = abi.encodeCall(Registry.setHook, (address(registry.loyalty())));
        bytes32 id = _schedule(data);
        assertEq(uint8(timelock.getOperationState(id)), uint8(TimelockController.OperationState.Waiting));
        vm.warp(block.timestamp + DELAY);
        _execute(data);
        assertEq(registry.hook(), address(registry.loyalty()));
    }

    function test_RevertWhen_ExecuteBeforeTheDelay() public {
        bytes memory data = abi.encodeCall(Registry.setHook, (address(registry.loyalty())));
        bytes32 id = _schedule(data);
        vm.warp(block.timestamp + DELAY - 1);
        bytes32 ready = bytes32(1 << uint8(TimelockController.OperationState.Ready));
        vm.expectRevert(abi.encodeWithSelector(TimelockController.TimelockUnexpectedOperationState.selector, id, ready));
        _execute(data);
    }

    function test_GuardianPausesNowAndTimelockUnpausesLater() public {
        vm.prank(guardian);
        registry.pause();
        assertTrue(registry.paused());
        bytes memory data = abi.encodeCall(Registry.unpause, ());
        _schedule(data);
        vm.warp(block.timestamp + DELAY);
        _execute(data);
        assertFalse(registry.paused());
    }

    function test_RevertWhen_StrangerSchedules() public {
        bytes memory data = abi.encodeCall(Registry.removeHook, ());
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), timelock.PROPOSER_ROLE()
            )
        );
        timelock.schedule(address(registry), 0, data, bytes32(0), bytes32(0), DELAY);
    }

    function test_UpgradeOnlyThroughTheTimelock() public {
        RegistryV2 v2 = new RegistryV2();
        bytes memory data =
            abi.encodeCall(registry.upgradeToAndCall, (address(v2), abi.encodeCall(RegistryV2.initializeV2, (3))));
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), ADMIN)
        );
        registry.upgradeToAndCall(address(v2), "");
        _schedule(data);
        vm.warp(block.timestamp + DELAY);
        _execute(data);
        assertEq(registry.version(), 2);
        assertEq(RegistryV2(address(registry)).maxPerAccount(), 3);
    }
}
