// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Pair} from "../src/Pair.sol";
import {Token} from "../src/Token.sol";

// ¿Qué? Los tests del ejercicio 01: dos por paso (uno en el paso 1, tres en el 4), con los números
//   exactos que tiene que dar cada cuenta.
// ¿Para qué? Que cada paso se compruebe solo y que el fuzz del paso 4 pruebe que ningún swap
//   baja el producto de las reservas.
contract PairTest is Test {
    Token a;
    Token b;
    Pair pair;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        a = new Token("Token A", "A");
        b = new Token("Token B", "B");
        pair = new Pair(a, b);
        address[2] memory users = [alice, bob];
        for (uint256 i = 0; i < users.length; i++) {
            a.mint(users[i], 1000 ether);
            b.mint(users[i], 1000 ether);
            vm.startPrank(users[i]);
            a.approve(address(pair), type(uint256).max);
            b.approve(address(pair), type(uint256).max);
            vm.stopPrank();
        }
    }

    // `alice` abre el pool con 100 A y 400 B: 1 A vale 4 B.
    function _seed() internal returns (uint256) {
        vm.prank(alice);
        return pair.addLiquidity(100 ether, 400 ether);
    }

    function test_Paso1_AmountOutChargesFee() public view {
        uint256 out = pair.getAmountOut(10 ether, 100 ether, 100 ether);
        assertEq(out, 9066108938801491315);
        // Sin comisión saldría 100 * 10 / 110.
        assertLt(out, uint256(100 ether) * 10 ether / 110 ether);
    }

    function test_Paso2_FirstLiquidityIsGeometricMean() public {
        uint256 liquidity = _seed();
        // sqrt(100 * 400) = 200, menos las 1000 shares bloqueadas.
        assertEq(liquidity, 200 ether - 1000);
        assertEq(pair.balanceOf(pair.DEAD()), 1000);
        assertEq(pair.totalSupply(), 200 ether);
        assertEq(pair.reserve0(), 100 ether);
        assertEq(pair.reserve1(), 400 ether);
    }

    function test_Paso2_RevertWhen_FirstLiquidityTooSmall() public {
        vm.prank(alice);
        vm.expectRevert(Pair.InsufficientLiquidity.selector);
        pair.addLiquidity(1000, 1000);
    }

    function test_Paso3_ProportionalLiquidity() public {
        _seed();
        vm.prank(bob);
        uint256 liquidity = pair.addLiquidity(50 ether, 200 ether);
        // La mitad de cada reserva: la mitad de las shares que había.
        assertEq(liquidity, 100 ether);
    }

    function test_Paso3_UnbalancedLiquidityTakesTheMin() public {
        _seed();
        vm.prank(bob);
        uint256 liquidity = pair.addLiquidity(50 ether, 100 ether);
        // 100 B es una cuarta parte de la reserva: cuenta eso, y los 25 A de más se quedan en el pool.
        assertEq(liquidity, 50 ether);
        assertEq(pair.reserve0(), 150 ether);
    }

    function test_Paso4_SwapPaysQuoteAndMovesReserves() public {
        _seed();
        uint256 expected = pair.getAmountOut(10 ether, 100 ether, 400 ether);
        vm.prank(bob);
        uint256 out = pair.swap(a, 10 ether, expected);
        assertEq(out, expected);
        assertEq(b.balanceOf(bob), 1000 ether + out);
        assertEq(pair.reserve0(), 110 ether);
        assertEq(pair.reserve1(), 400 ether - out);
    }

    function test_Paso4_RevertWhen_OutputBelowMin() public {
        _seed();
        uint256 out = pair.getAmountOut(10 ether, 100 ether, 400 ether);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Pair.InsufficientOutput.selector, out, out + 1));
        pair.swap(a, 10 ether, out + 1);
    }

    function testFuzz_Paso4_SwapNeverLowersK(uint256 amountIn, bool zeroForOne) public {
        _seed();
        amountIn = bound(amountIn, 1, 900 ether);
        uint256 kBefore = pair.reserve0() * pair.reserve1();
        vm.prank(bob);
        pair.swap(zeroForOne ? a : b, amountIn, 0);
        assertGe(pair.reserve0() * pair.reserve1(), kBefore);
    }

    function test_Paso5_RemoveReturnsProportionalShare() public {
        _seed();
        vm.startPrank(bob);
        uint256 liquidity = pair.addLiquidity(50 ether, 200 ether);
        (uint256 amount0, uint256 amount1) = pair.removeLiquidity(liquidity);
        vm.stopPrank();
        assertEq(amount0, 50 ether);
        assertEq(amount1, 200 ether);
        assertEq(pair.balanceOf(bob), 0);
    }

    function test_Paso5_FeesGrowEachShare() public {
        uint256 liquidity = _seed();
        // `bob` cambia 10 A por B y todos esos B otra vez por A: paga la comisión dos veces.
        vm.startPrank(bob);
        uint256 outB = pair.swap(a, 10 ether, 0);
        pair.swap(b, outB, 0);
        vm.stopPrank();

        vm.prank(alice);
        (uint256 amount0, uint256 amount1) = pair.removeLiquidity(liquidity);
        // Sin swaps, `alice` sacaría 100 A menos su parte de las shares bloqueadas.
        assertGt(amount0, 100 ether);
        assertEq(amount1, 400 ether - 2000);
    }
}
