// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {DeployProtocol} from "../script/DeployProtocol.s.sol";
import {UpgradeToV2} from "../script/UpgradeToV2.s.sol";
import {UpgradeToV3} from "../script/UpgradeToV3.s.sol";
import {IRegistry} from "../src/IRegistry.sol";
import {Registry} from "../src/Registry.sol";
import {RegistryV2} from "../src/RegistryV2.sol";
import {RegistryV3} from "../src/RegistryV3.sol";

// ¿Qué? Tests del proyecto: despliega el protocolo con los scripts, da un alta en V1, actualiza a
//   V2 y a V3 con un feed falso de 8 decimales a 2500 dólares, y comprueba la tasa en dólares.
// ¿Para qué? Que los scripts que usarás en Sepolia sean los mismos que se prueban.
contract RegistryV3Test is Test {
    MockV3Aggregator feed;
    RegistryV3 registry;
    address admin;
    address alice = makeAddr("alice");

    function setUp() public {
        vm.warp(1_750_000_000);
        DeployProtocol.Deployment memory d = new DeployProtocol().deploy(50);
        (, admin,) = vm.readCallers();
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        d.registry.register{value: 0.01 ether}("antes de V3");
        RegistryV2 v2 = new UpgradeToV2().upgrade(d.registry, 3);
        feed = new MockV3Aggregator(8, 2500e8);
        registry = new UpgradeToV3().upgrade(v2, AggregatorV3Interface(address(feed)), 25e18, 3 hours);
    }

    function test_Upgrade() public view {
        assertEq(registry.version(), 3);
        assertEq(address(registry.priceFeed()), address(feed));
        assertEq(registry.usdFee(), 25e18);
        assertEq(registry.maxPriceAge(), 3 hours);
        // Lo de V1 y V2 sigue en su sitio.
        assertEq(registry.getItem(1).label, "antes de V3");
        assertEq(registry.maxPerAccount(), 3);
        assertTrue(registry.hasRole(registry.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_EthUsdPrice() public {
        (uint256 price, uint8 decimals) = registry.ethUsdPrice();
        assertEq(price, 2500e8);
        assertEq(decimals, 8);
        // Justo en el límite todavía vale.
        vm.warp(block.timestamp + 3 hours);
        (price,) = registry.ethUsdPrice();
        assertEq(price, 2500e8);
    }

    function test_RevertWhen_PriceInvalidOrStale() public {
        feed.updateAnswer(0);
        vm.expectRevert(abi.encodeWithSelector(RegistryV3.InvalidPrice.selector, int256(0)));
        registry.ethUsdPrice();
        feed.updateAnswer(-1);
        vm.expectRevert(abi.encodeWithSelector(RegistryV3.InvalidPrice.selector, int256(-1)));
        registry.registrationFee();
        feed.updateAnswer(2500e8);
        uint256 updatedAt = block.timestamp;
        vm.warp(block.timestamp + 3 hours + 1);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(RegistryV3.StalePrice.selector, updatedAt, 3 hours));
        registry.register{value: 0.01 ether}("tarde");
    }

    function test_RegistrationFee() public {
        assertEq(registry.registrationFee(), 0.01 ether);
        feed.updateAnswer(2000e8);
        assertEq(registry.registrationFee(), 0.0125 ether);
        // 25 / 3000 = 0,008333... ETH: el último wei se redondea hacia arriba.
        feed.updateAnswer(3000e8);
        assertEq(registry.registrationFee(), 8333333333333334);
    }

    function test_RegisterPaysFeedFee() public {
        feed.updateAnswer(3000e8);
        uint256 fee = registry.registrationFee();
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.WrongFee.selector, fee, 0.01 ether));
        registry.register{value: 0.01 ether}("tasa vieja");
        uint256 id = registry.register{value: fee}("tasa del feed");
        assertEq(registry.getItem(id).label, "tasa del feed");
        string[] memory labels = new string[](2);
        labels[0] = "lote 1";
        labels[1] = "lote 2";
        // La tasa del lote es la de un alta por cada etiqueta.
        vm.expectRevert(abi.encodeWithSelector(IRegistry.WrongFee.selector, fee * 2, fee));
        registry.registerBatch{value: fee}(labels);
        vm.stopPrank();
    }

    function test_SetFeeConfig() public {
        MockV3Aggregator other = new MockV3Aggregator(18, 2000e18);
        bytes32 adminRole = registry.DEFAULT_ADMIN_ROLE();
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, adminRole)
        );
        registry.setFeeConfig(other, 30e18, 1 hours);
        vm.startPrank(admin);
        vm.expectRevert(Registry.ZeroAddress.selector);
        registry.setFeeConfig(AggregatorV3Interface(address(0)), 30e18, 1 hours);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidAmount.selector, 0));
        registry.setFeeConfig(other, 0, 1 hours);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidAmount.selector, 0));
        registry.setFeeConfig(other, 30e18, 0);
        vm.expectEmit(address(registry));
        emit RegistryV3.FeeConfigChanged(address(other), 30e18, 1 hours);
        registry.setFeeConfig(other, 30e18, 1 hours);
        vm.stopPrank();
        // Otro feed con 18 decimales: la tasa lee los decimales, no los supone.
        assertEq(registry.registrationFee(), 0.015 ether);
    }

    function test_RevertWhen_InitializeV3Twice() public {
        vm.prank(admin);
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        registry.initializeV3(feed, 1e18, 1 hours);
    }

    function test_RevertWhen_UpgradeWithBrokenFeed() public {
        // Un feed parado hace fallar el script antes de enviar nada.
        RegistryV2 fresh = new UpgradeToV2().upgrade(new DeployProtocol().deploy(50).registry, 3);
        MockV3Aggregator stale = new MockV3Aggregator(8, 2500e8);
        vm.warp(block.timestamp + 1 days);
        UpgradeToV3 script = new UpgradeToV3();
        vm.expectRevert(abi.encodeWithSelector(RegistryV3.StalePrice.selector, block.timestamp - 1 days, 3 hours));
        script.upgrade(fresh, AggregatorV3Interface(address(stale)), 25e18, 3 hours);
    }
}
