// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {LendingPool} from "../src/LendingPool.sol";
import {Token} from "../src/Token.sol";

// ¿Qué? Los tests del ejercicio 03, con un feed falso de 8 decimales que empieza en 2000 USD.
// ¿Para qué? Comprobar cada cuenta del préstamo con números que puedes hacer a mano: 2 de garantía
//   valen 4000, se puede pedir 3000, y a 1800 la posición ya se puede liquidar.
contract LendingPoolTest is Test {
    Token collateral;
    Token usd;
    MockV3Aggregator feed;
    LendingPool pool;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        collateral = new Token("Wrapped Ether", "WETH");
        usd = new Token("Test Dollar", "TUSD");
        feed = new MockV3Aggregator(8, 2000e8);
        pool = new LendingPool(collateral, usd, feed);
        // La liquidez que presta el pool: en un protocolo real, la de sus depositantes.
        usd.mint(address(pool), 1_000_000 ether);

        collateral.mint(alice, 10 ether);
        vm.prank(alice);
        collateral.approve(address(pool), type(uint256).max);
        usd.mint(bob, 100_000 ether);
        vm.prank(bob);
        usd.approve(address(pool), type(uint256).max);
    }

    function _open(uint256 deposit, uint256 debt) internal {
        vm.startPrank(alice);
        pool.depositCollateral(deposit);
        pool.borrow(debt);
        vm.stopPrank();
    }

    function test_Paso1_CollateralValueUsesTheFeed() public {
        vm.prank(alice);
        pool.depositCollateral(2 ether);
        assertEq(pool.collateralValue(alice), 4000 ether);
        feed.updateAnswer(1800e8);
        assertEq(pool.collateralValue(alice), 3600 ether);
    }

    function test_Paso2_BorrowUpToLtv() public {
        _open(2 ether, 3000 ether);
        assertEq(usd.balanceOf(alice), 3000 ether);
        assertEq(pool.debtOf(alice), 3000 ether);
    }

    function test_Paso2_RevertWhen_BorrowAboveLtv() public {
        vm.startPrank(alice);
        pool.depositCollateral(2 ether);
        vm.expectRevert(abi.encodeWithSelector(LendingPool.ExceedsLtv.selector, 3000 ether + 1, 3000 ether));
        pool.borrow(3000 ether + 1);
        vm.stopPrank();
    }

    function test_Paso3_HealthFactorFallsWithPrice() public {
        _open(2 ether, 3000 ether);
        // 4000 por 0,8 entre 3000.
        assertEq(pool.healthFactor(alice), 1066666666666666666);
        feed.updateAnswer(1800e8);
        assertEq(pool.healthFactor(alice), 0.96e18);
    }

    function test_Paso3_RevertWhen_WithdrawLeavesUnhealthy() public {
        _open(2 ether, 3000 ether);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(LendingPool.Unhealthy.selector, 0.96e18));
        pool.withdrawCollateral(0.2 ether);
    }

    function test_Paso4_LiquidationPaysBonus() public {
        _open(2 ether, 3000 ether);
        feed.updateAnswer(1800e8);
        vm.prank(bob);
        uint256 seized = pool.liquidate(alice, 1500 ether);
        // 1500 más un 5 %, en garantía a 1800 cada una.
        assertEq(seized, 0.875 ether);
        assertEq(collateral.balanceOf(bob), 0.875 ether);
        assertEq(pool.debtOf(alice), 1500 ether);
        assertGt(pool.healthFactor(alice), 1e18);
    }

    function test_Paso4_RevertWhen_HealthyOrAboveCloseFactor() public {
        _open(2 ether, 3000 ether);
        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(LendingPool.Healthy.selector, 1066666666666666666));
        pool.liquidate(alice, 1000 ether);

        feed.updateAnswer(1800e8);
        vm.expectRevert(abi.encodeWithSelector(LendingPool.ExceedsCloseFactor.selector, 1501 ether, 1500 ether));
        pool.liquidate(alice, 1501 ether);
        vm.stopPrank();
    }

    function test_Paso5_DebtGrowsWithTime() public {
        _open(2 ether, 1000 ether);
        vm.warp(block.timestamp + 365 days);
        assertEq(pool.debtOf(alice), 1049999999994064000000);
    }

    function test_Paso5_RepayClearsAccruedDebt() public {
        _open(2 ether, 1000 ether);
        vm.warp(block.timestamp + 365 days);
        uint256 debt = pool.debtOf(alice);
        assertGt(debt, 1000 ether);
        usd.mint(alice, debt - 1000 ether);
        vm.startPrank(alice);
        usd.approve(address(pool), debt);
        assertEq(pool.repay(type(uint256).max), debt);
        vm.stopPrank();
        assertEq(pool.debtOf(alice), 0);
        assertEq(usd.balanceOf(alice), 0);
    }
}
