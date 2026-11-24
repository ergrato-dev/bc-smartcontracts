// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test, stdError} from "forge-std/Test.sol";
import {RewardPool} from "../src/RewardPool.sol";
import {MockToken} from "./MockToken.sol";

// ¿Qué? La auditoría de RewardPool en tests. Los dos primeros son los de su autora: el caso
//   normal funciona. Los demás son tus pruebas de concepto (PoC): cada una demuestra un hallazgo
//   con números, o descarta una sospecha.
// ¿Para qué? Un hallazgo sin PoC es una opinión. Con PoC, la autora lo ejecuta, ve el número y
//   después lo usa como test de regresión de su corrección.
contract AuditTest is Test {
    uint256 constant FUNDED = 1_000_000e18;
    uint256 constant RATE = 1e18;

    MockToken stakingToken;
    MockToken rewardToken;
    RewardPool pool;

    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address attacker = makeAddr("attacker");

    function setUp() public {
        stakingToken = new MockToken("STK");
        rewardToken = new MockToken("RWD");
        vm.prank(owner);
        pool = new RewardPool(stakingToken, rewardToken);
        rewardToken.mint(address(pool), FUNDED);
        vm.prank(owner);
        pool.setRewardRate(RATE);
        _fund(alice);
        _fund(bob);
        _fund(attacker);
    }

    function _fund(address who) internal {
        stakingToken.mint(who, 1000e18);
        vm.prank(who);
        stakingToken.approve(address(pool), type(uint256).max);
    }

    function _stake(address who, uint256 amount) internal {
        vm.prank(who);
        pool.stake(amount);
    }

    // ---------- Los tests de la autora ----------

    function test_AliceEarnsHerRewards() public {
        _stake(alice, 100e18);
        vm.warp(block.timestamp + 1 days);
        vm.prank(alice);
        pool.claim();
        assertEq(rewardToken.balanceOf(alice), 86_400e18, "un dia a 1 por segundo");
    }

    function test_AliceWithdrawsHerStake() public {
        _stake(alice, 100e18);
        vm.prank(alice);
        pool.withdraw(100e18);
        assertEq(stakingToken.balanceOf(alice), 1000e18);
    }

    // ---------- H-01: cualquiera fija el ritmo ----------

    function test_Paso1_PoC_AnyoneSetsTheRateAndDrainsThePool() public {
        _stake(alice, 100e18);
        _stake(attacker, 1e18);
        // PASO 1: el atacante fija un ritmo con el que su parte de un segundo es todo el pool.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 1");
        //> uint256 rate = FUNDED * pool.totalStaked() / 1e18;
        //> vm.prank(attacker);
        //> pool.setRewardRate(rate);
        //> vm.warp(block.timestamp + 1);
        //> vm.prank(attacker);
        //> pool.claim();
        //> assertEq(rewardToken.balanceOf(attacker), FUNDED, "H-01: el atacante se lleva todo el pool");
        //> vm.warp(block.timestamp + 1 days);
        //> vm.prank(alice);
        //> vm.expectRevert();
        //> pool.claim();
    }

    // ---------- H-02: quien llega tarde cobra lo de antes ----------

    function test_Paso2_PoC_LateStakerTakesHalfOfAlicesRewards() public {
        _stake(alice, 100e18);
        vm.warp(block.timestamp + 1 days);
        assertEq(pool.earned(alice), 86_400e18, "antes de bob, alice lleva un dia");
        // PASO 2: bob deposita lo mismo que alice y cobra en el mismo bloque.
        revert("TODO: Paso 2");
        //> _stake(bob, 100e18);
        //> vm.prank(bob);
        //> pool.claim();
        //> assertEq(rewardToken.balanceOf(bob), 43_200e18, "H-02: bob cobra medio dia que no estuvo");
        //> assertEq(pool.earned(alice), 43_200e18, "H-02: alice pierde la mitad");
    }

    // ---------- H-03: el redondeo borra las recompensas ----------

    function test_Paso3_PoC_PokingEveryBlockErasesTheRewards() public {
        _stake(alice, 100e18);
        // PASO 3: el atacante, sin depositar nada, llama a claim en cada bloque durante un día.
        revert("TODO: Paso 3");
        //> for (uint256 i = 0; i < 1 days / 12; i++) {
        //>     vm.warp(block.timestamp + 12);
        //>     vm.prank(attacker);
        //>     pool.claim();
        //> }
        //> assertEq(pool.earned(alice), 0, "H-03: un dia entero y alice no ha ganado nada");
    }

    // ---------- Una sospecha que no es un hallazgo ----------

    function test_Paso4_NoOneWithdrawsMoreThanTheirStake() public {
        _stake(alice, 100e18);
        _stake(attacker, 1e18);
        // PASO 4: withdraw no comprueba el saldo. ¿Se puede retirar lo de alice?
        revert("TODO: Paso 4");
        //> vm.prank(attacker);
        //> vm.expectRevert(stdError.arithmeticError);
        //> pool.withdraw(2e18);
        //> assertEq(stakingToken.balanceOf(address(pool)), 101e18, "el deposito de alice sigue en el pool");
    }
}
