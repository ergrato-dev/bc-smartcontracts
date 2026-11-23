// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Registry} from "../src/Registry.sol";
import {RegistryV2} from "../src/RegistryV2.sol";
import {DeployProtocol} from "../script/DeployProtocol.s.sol";
import {UpgradeToV2} from "../script/UpgradeToV2.s.sol";

// ¿Qué? Despliega con DeployProtocol y actualiza con UpgradeToV2, los dos scripts reales.
// ¿Para qué? Ensayar la actualización que harás en Sepolia: qué cambia y qué se conserva.
// ¿Impacto? No los modifiques: son el contrato de esta capa.
contract UpgradeToV2Test is Test {
    UpgradeToV2 script;
    Registry registry;
    address member = makeAddr("member");
    uint256 fee;

    function setUp() public {
        registry = new DeployProtocol().deploy(50).registry;
        script = new UpgradeToV2();
        fee = registry.REGISTRATION_FEE();
        vm.deal(member, 10 * fee);
    }

    function test_UpgradesToV2() public {
        RegistryV2 v2 = script.upgrade(registry, 2);
        assertEq(address(v2), address(registry));
        assertEq(v2.version(), 2);
        assertEq(v2.maxPerAccount(), 2);
    }

    function test_ChangesOnlyTheImplementation() public {
        bytes32 before = vm.load(address(registry), ERC1967Utils.IMPLEMENTATION_SLOT);
        script.upgrade(registry, 2);
        bytes32 afterUpgrade = vm.load(address(registry), ERC1967Utils.IMPLEMENTATION_SLOT);
        assertNotEq(afterUpgrade, before);
        assertEq(registry.capacity(), 50);
    }

    function test_KeepsItemsAndAppliesTheLimit() public {
        vm.prank(member);
        registry.register{value: fee}("first");

        RegistryV2 v2 = script.upgrade(registry, 2);
        assertEq(v2.count(), 1);

        vm.startPrank(member);
        v2.register{value: fee}("second");
        vm.expectRevert(abi.encodeWithSelector(RegistryV2.TooManyItems.selector, member, 2));
        v2.register{value: fee}("third");
        vm.stopPrank();
    }

    function test_RunReadsRegistryFromEnv() public {
        vm.setEnv("REGISTRY", vm.toString(address(registry)));
        assertEq(script.run().maxPerAccount(), 3);
    }

    function test_RevertWhen_UpgradedTwice() public {
        script.upgrade(registry, 2);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        script.upgrade(registry, 2);
    }
}
