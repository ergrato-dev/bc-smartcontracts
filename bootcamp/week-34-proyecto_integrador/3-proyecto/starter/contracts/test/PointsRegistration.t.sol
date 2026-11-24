// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {DeployProtocol} from "../script/DeployProtocol.s.sol";
import {UpgradeToV2} from "../script/UpgradeToV2.s.sol";
import {UpgradeToV3} from "../script/UpgradeToV3.s.sol";
import {LoyaltyToken} from "../src/LoyaltyToken.sol";
import {RegistryV3} from "../src/RegistryV3.sol";

// ¿Qué? El alta pagada con puntos de fidelidad, sobre el protocolo actualizado a V3.
// ¿Para qué? Que cambiar el orden de `_registerWithPoints` (semana 23) no cambie lo que hace:
//   quema los puntos, da el alta y, si no hay puntos suficientes, no deja nada a medias.
contract PointsRegistrationTest is Test {
    RegistryV3 registry;
    LoyaltyToken loyalty;
    address alice = makeAddr("alice");

    function setUp() public {
        vm.warp(1_750_000_000);
        DeployProtocol.Deployment memory d = new DeployProtocol().deploy(50);
        loyalty = d.loyalty;
        MockV3Aggregator feed = new MockV3Aggregator(8, 2500e8);
        // Hasta 5 altas por cuenta: el primer test necesita 4.
        registry = new UpgradeToV3()
            .upgrade(new UpgradeToV2().upgrade(d.registry, 5), AggregatorV3Interface(address(feed)), 25e18, 3 hours);
        vm.deal(alice, 10 ether);
    }

    // Cada alta pagada en ETH da REWARD puntos a quien registra.
    function _registerWithEth(uint256 times) internal {
        uint256 fee = registry.registrationFee();
        for (uint256 i = 0; i < times; i++) {
            vm.prank(alice);
            registry.register{value: fee}("eth");
        }
    }

    function test_RegisterWithPointsBurnsPoints() public {
        _registerWithEth(3);
        assertEq(loyalty.balanceOf(alice), 30 ether);

        vm.startPrank(alice);
        loyalty.approve(address(registry), registry.POINTS_PRICE());
        uint256 id = registry.registerWithPoints("puntos");
        vm.stopPrank();

        assertEq(id, 4);
        assertEq(registry.idsOf(alice).length, 4);
        // Quema 30 y el hook da 10 por la nueva alta.
        assertEq(loyalty.balanceOf(alice), 10 ether);
    }

    function test_RevertWhen_NotEnoughPoints() public {
        _registerWithEth(1);
        uint256 remaining = registry.remaining();

        vm.startPrank(alice);
        loyalty.approve(address(registry), registry.POINTS_PRICE());
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 10 ether, 30 ether)
        );
        registry.registerWithPoints("puntos");
        vm.stopPrank();

        assertEq(registry.remaining(), remaining, "the reverted register leaves nothing behind");
        assertEq(registry.idsOf(alice).length, 1);
    }
}
