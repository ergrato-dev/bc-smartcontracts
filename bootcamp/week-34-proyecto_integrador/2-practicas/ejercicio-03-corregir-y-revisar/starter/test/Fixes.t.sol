// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RewardPool} from "../src/RewardPool.sol";
import {MockToken} from "./MockToken.sol";

// ¿Qué? Las correcciones de RewardPool. Cada PoC del ejercicio 02 vuelve como test de regresión:
//   el mismo ataque, que ahora no funciona. El paso 4 es lo que encuentra la revisión de la
//   corrección: un fallo que ningún PoC había pedido.
// ¿Para qué? Que el hallazgo no vuelva con el próximo cambio, y que "corregido" lo diga un test
//   y no la autora.
contract FixesTest is Test {
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

    // ---------- Los tests de la autora: siguen en verde ----------

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

    // ---------- H-01 ----------

    function test_Paso1_RevertWhen_StrangerSetsTheRate() public {
        _stake(attacker, 1e18);
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, attacker));
        pool.setRewardRate(FUNDED * 101);
    }

    // ---------- H-02 ----------

    function test_Paso2_LateStakerEarnsOnlyFromJoining() public {
        _stake(alice, 100e18);
        vm.warp(block.timestamp + 1 days);
        _stake(bob, 100e18);
        assertEq(pool.earned(bob), 0, "Paso 2: bob acaba de llegar");
        assertEq(pool.earned(alice), 86_400e18, "Paso 2: el dia de alice sigue siendo suyo");
        vm.warp(block.timestamp + 1 days);
        assertEq(pool.earned(bob), 43_200e18, "Paso 2: bob, la mitad del segundo dia");
        assertEq(pool.earned(alice), 129_600e18, "Paso 2: alice, un dia y medio");
    }

    // ---------- H-03 ----------

    function test_Paso3_PokingEveryBlockKeepsTheRewards() public {
        _stake(alice, 100e18);
        for (uint256 i = 0; i < 1 days / 12; i++) {
            vm.warp(block.timestamp + 12);
            vm.prank(attacker);
            pool.claim();
        }
        assertEq(pool.earned(alice), 86_400e18, "Paso 3: el atacante ya no borra nada");
    }

    /// Con depósitos y tiempos cualesquiera, lo ganado es el ritmo por el tiempo, repartido por saldo.
    function testFuzz_Paso3_EarningsFollowStakeAndTime(uint96 aliceStake, uint96 bobStake, uint32 together)
        public
    {
        aliceStake = uint96(bound(aliceStake, 1e18, 1000e18));
        bobStake = uint96(bound(bobStake, 1e18, 1000e18));
        together = uint32(bound(together, 1, 30 days));
        _stake(alice, aliceStake);
        _stake(bob, bobStake);
        vm.warp(block.timestamp + together);
        uint256 total = uint256(aliceStake) + bobStake;
        // Lo que se pierde al redondear es menos de una unidad por cada 1e18 depositado.
        assertApproxEqAbs(pool.earned(alice), RATE * together * aliceStake / total, 1000, "Paso 3: alice");
        assertApproxEqAbs(pool.earned(bob), RATE * together * bobStake / total, 1000, "Paso 3: bob");
        assertLe(pool.earned(alice) + pool.earned(bob), RATE * together, "Paso 3: nunca mas de lo repartido");
    }

    // ---------- La revisión de la corrección ----------

    function test_Paso4_RateChangeIsNotRetroactive() public {
        _stake(alice, 100e18);
        vm.warp(block.timestamp + 1 days);
        vm.prank(owner);
        pool.setRewardRate(2 * RATE);
        assertEq(pool.earned(alice), 86_400e18, "Paso 4: el primer dia, al ritmo de antes");
        vm.warp(block.timestamp + 1 days);
        assertEq(pool.earned(alice), 259_200e18, "Paso 4: el segundo, al nuevo");
    }
}
