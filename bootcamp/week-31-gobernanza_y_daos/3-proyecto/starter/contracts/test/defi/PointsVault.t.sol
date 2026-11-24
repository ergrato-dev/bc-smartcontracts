// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {DeployProtocol} from "../../script/DeployProtocol.s.sol";
import {UpgradeToV2} from "../../script/UpgradeToV2.s.sol";
import {UpgradeToV3} from "../../script/UpgradeToV3.s.sol";
import {RegistryV3} from "../../src/RegistryV3.sol";
import {LoyaltyToken} from "../../src/LoyaltyToken.sol";
import {PointsVault} from "../../src/PointsVault.sol";

// ¿Qué? El vault de puntos de la semana 30: que el despliegue lo conecta, que cada alta le da su
//   bonus, que ese bonus lo ganan quienes tienen shares y que ni un regalo ni el bonus acumulado
//   con el vault vacío se los lleva quien llega primero.
// ¿Para qué? Que el vault cumpla lo que promete ERC-4626 con el token y el registro de verdad,
//   desplegados con el mismo script que usas en anvil.
contract PointsVaultTest is Test {
    RegistryV3 registry;
    LoyaltyToken loyalty;
    PointsVault vault;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    uint256 fee;

    function setUp() public {
        vm.warp(1_750_000_000);
        DeployProtocol.Deployment memory d = new DeployProtocol().deploy(50);
        MockV3Aggregator feed = new MockV3Aggregator(8, 2500e8);
        registry = new UpgradeToV3()
            .upgrade(new UpgradeToV2().upgrade(d.registry, 10), AggregatorV3Interface(address(feed)), 25e18, 3 hours);
        loyalty = d.loyalty;
        vault = d.vault;
        fee = registry.registrationFee();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.prank(alice);
        loyalty.approve(address(vault), type(uint256).max);
    }

    // `who` da de alta `amount` recursos: recibe 10 puntos por cada uno y el vault, 1.
    function _register(address who, uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            vm.prank(who);
            registry.register{value: fee}("recurso");
        }
    }

    function _deposit(address who, uint256 assets) internal returns (uint256 shares) {
        vm.prank(who);
        shares = vault.deposit(assets, who);
    }

    function test_DeployConnectsTheVault() public view {
        assertEq(loyalty.stakingVault(), address(vault));
        assertEq(vault.asset(), address(loyalty));
        assertEq(vault.decimals(), 24);
    }

    function test_RegistrationPaysTheVaultBonus() public {
        _register(alice, 1);
        assertEq(loyalty.balanceOf(alice), loyalty.REWARD());
        assertEq(loyalty.balanceOf(address(vault)), loyalty.STAKING_BONUS());
    }

    function test_StakersEarnTheBonus() public {
        _register(alice, 1);
        uint256 shares = _deposit(alice, 10 ether);
        _register(bob, 5);
        // 5 de bonus mientras alice tiene casi todas las shares.
        assertGt(vault.previewRedeem(shares), 14.5 ether);
        uint256 expected = vault.previewRedeem(shares);
        vm.prank(alice);
        assertEq(vault.redeem(shares, alice, alice), expected);
        assertEq(loyalty.balanceOf(alice), expected);
    }

    function test_FirstDepositorDoesNotTakeTheEarlyBonus() public {
        // Tres altas con el vault vacío: 3 puntos de bonus que no son de nadie.
        _register(bob, 3);
        _register(alice, 1);
        uint256 shares = _deposit(alice, 10 ether);
        assertLe(vault.previewRedeem(shares), 10 ether);
    }

    function test_DonationAttackDoesNotPay() public {
        // `bob` deposita 1 wei y regala 20 puntos antes de que `alice` deposite.
        _register(bob, 3);
        vm.startPrank(bob);
        loyalty.approve(address(vault), 1);
        vault.deposit(1, bob);
        assertTrue(loyalty.transfer(address(vault), 20 ether));
        vm.stopPrank();

        _register(alice, 1);
        uint256 shares = _deposit(alice, 10 ether);
        assertGe(vault.previewRedeem(shares), 9.99 ether, "alice pierde su deposito");
        assertLt(vault.previewRedeem(vault.balanceOf(bob)), 20 ether);
    }

    // Riesgo aceptado (T-15 del informe): quien deposita justo antes de unas altas y retira justo
    // después se lleva su parte del bonus sin haber esperado. El test mide cuánto.
    function test_JustInTimeDepositSharesTheBonus() public {
        _register(alice, 1);
        _deposit(alice, 10 ether);
        _register(bob, 5);
        vm.startPrank(bob);
        loyalty.approve(address(vault), 50 ether);
        uint256 shares = vault.deposit(50 ether, bob);
        vm.stopPrank();

        _register(alice, 3);
        vm.prank(bob);
        uint256 received = vault.redeem(shares, bob, bob);
        assertGt(received, 52 ether);
        assertLt(received, 53 ether);
    }

    function testFuzz_RoundTripNeverProfits(uint256 assets) public {
        _register(alice, 1);
        assets = bound(assets, 1, 10 ether);
        uint256 shares = _deposit(alice, assets);
        vm.prank(alice);
        assertLe(vault.redeem(shares, alice, alice), assets);
    }

    function test_RevertWhen_StakingVaultNotByAdminOrTwice() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(LoyaltyToken.NotRegistryAdmin.selector, alice));
        loyalty.setStakingVault(alice);

        // Quien desplegó es el admin del registro, y aun así no puede cambiar el vault.
        assertTrue(registry.hasRole(0x00, DEFAULT_SENDER));
        vm.prank(DEFAULT_SENDER);
        vm.expectRevert(abi.encodeWithSelector(LoyaltyToken.VaultAlreadySet.selector, address(vault)));
        loyalty.setStakingVault(alice);
    }
}
