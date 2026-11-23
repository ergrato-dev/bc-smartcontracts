// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Registry} from "../src/Registry.sol";
import {IRegistry} from "../src/IRegistry.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

// ¿Qué? El multicall del registro: varias llamadas en una transacción, como quien llama.
// ¿Para qué? Comprobar que delegatecall conserva a quien llama y que nada puede pagar dos veces.
// ¿Impacto? No los modifiques: son el contrato de esta capa.
contract RegistryMulticallTest is Test {
    Registry registry;
    uint256 fee;
    address alice = makeAddr("alice");

    function setUp() public {
        registry = new Registry(10);
        fee = registry.REGISTRATION_FEE();
        vm.deal(alice, 1 ether);
    }

    function test_MulticallRetiresSeveral() public {
        vm.startPrank(alice);
        registry.register{value: fee}("north");
        registry.register{value: fee}("south");

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(Registry.retire, (1));
        calls[1] = abi.encodeCall(Registry.retire, (2));
        registry.multicall(calls);
        vm.stopPrank();

        assertEq(uint256(registry.getItem(1).status), uint256(IRegistry.Status.Retired));
        assertEq(uint256(registry.getItem(2).status), uint256(IRegistry.Status.Retired));
        assertEq(registry.activeCount(), 0);
    }

    function test_MulticallReturnsResults() public {
        vm.prank(alice);
        registry.register{value: fee}("north");

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(Registry.getItem, (1));
        calls[1] = abi.encodeCall(Registry.remaining, ());
        bytes[] memory results = registry.multicall(calls);

        IRegistry.Item memory item = abi.decode(results[0], (IRegistry.Item));
        assertEq(item.registrant, alice);
        assertEq(item.label, "north");
        assertEq(abi.decode(results[1], (uint256)), 9);
    }

    function test_MulticallForThePauser() public {
        registry.grantRole(registry.PAUSER_ROLE(), address(this));
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeCall(Registry.pause, ());
        registry.multicall(calls);
        assertTrue(registry.paused());
    }

    function test_RevertWhen_MulticallByStranger() public {
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeCall(Registry.pause, ());
        bytes memory reason = abi.encodeWithSelector(
            IAccessControl.AccessControlUnauthorizedAccount.selector, alice, registry.PAUSER_ROLE()
        );
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Registry.CallFailed.selector, 0, reason));
        registry.multicall(calls);
    }

    function test_RevertWhen_MulticallRegisters() public {
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeCall(Registry.register, ("north"));
        bytes memory reason = abi.encodeWithSelector(IRegistry.WrongFee.selector, fee, 0);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Registry.CallFailed.selector, 0, reason));
        registry.multicall(calls);
    }

    function test_MulticallRejectsEther() public {
        bytes[] memory calls = new bytes[](0);
        vm.prank(alice);
        (bool ok,) = address(registry).call{value: fee}(abi.encodeCall(Registry.multicall, (calls)));
        assertFalse(ok);
        assertEq(address(registry).balance, 0);
    }
}
