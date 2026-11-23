// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {Token} from "../src/Token.sol";
import {Pool} from "../src/Pool.sol";
import {Lender} from "../src/Lender.sol";
import {SpotLender} from "../src/SpotLender.sol";
import {FeedLender} from "../src/FeedLender.sol";
import {FlashAttacker} from "../src/FlashAttacker.sol";

contract OracleFlashLoanTest is Test {
    Token usd;
    Token gov;
    Pool pool;
    SpotLender spotLender;
    FeedLender feedLender;
    MockV3Aggregator feed;
    address mallory = makeAddr("mallory");
    address stranger = makeAddr("stranger");

    function setUp() public {
        usd = new Token("Dollar", "USD");
        gov = new Token("Governance", "GOV");
        // El pool empieza con 1 000 000 USD y 1000 GOV: 1 GOV vale 1000 USD.
        pool = new Pool(usd, gov);
        usd.mint(address(this), 1_000_000e18);
        gov.mint(address(this), 1000e18);
        usd.approve(address(pool), 1_000_000e18);
        gov.approve(address(pool), 1000e18);
        pool.addLiquidity(1_000_000e18, 1000e18);
        // Cada prestamista tiene 2 000 000 USD para prestar. El feed dice lo mismo que el pool.
        spotLender = new SpotLender(usd, gov, pool);
        feed = new MockV3Aggregator(8, 1000e8);
        feedLender = new FeedLender(usd, gov, feed);
        usd.mint(address(spotLender), 2_000_000e18);
        usd.mint(address(feedLender), 2_000_000e18);
    }

    function test_Paso1_SpotPrice() public {
        assertEq(pool.spotPrice(), 1000e18);
        // Un swap de 1 000 000 USD saca 500 GOV y deja el pool en 2 000 000 / 500.
        usd.mint(address(this), 1_000_000e18);
        usd.approve(address(pool), 1_000_000e18);
        assertEq(pool.swap(usd, 1_000_000e18), 500e18);
        assertEq(pool.spotPrice(), 4000e18);
    }

    function test_Paso2_FlashLoanDrainsSpotLender() public {
        vm.prank(mallory);
        FlashAttacker attacker = new FlashAttacker(usd, gov, pool, spotLender);
        assertEq(usd.balanceOf(mallory), 0);

        attacker.attack(1_000_000e18);

        // Pidió 1 600 000 USD contra 500 GOV a 4000 y devolvió 1 000 000 más 1000 de comisión.
        assertEq(usd.balanceOf(mallory), 599_000e18);
        assertEq(usd.balanceOf(address(spotLender)), 400_000e18);
        assertEq(spotLender.debtOf(address(attacker)), 1_600_000e18);
        // Al precio del feed, ese colateral vale 500 000 USD: la deuda nunca se va a pagar.
        assertEq(spotLender.collateralOf(address(attacker)), 500e18);
        // El flash loan se creó y se quemó en la misma transacción; solo falta la comisión.
        assertEq(usd.totalSupply(), 5_000_000e18 - 1000e18);
    }

    function test_Paso3_RevertWhen_UntrustedInitiator() public {
        FlashAttacker attacker = new FlashAttacker(usd, gov, pool, spotLender);
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(FlashAttacker.UntrustedInitiator.selector, stranger));
        usd.flashLoan(attacker, address(usd), 1000e18, "");
    }

    function test_Paso3_RevertWhen_CallerIsNotLender() public {
        FlashAttacker attacker = new FlashAttacker(usd, gov, pool, spotLender);
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(FlashAttacker.UntrustedLender.selector, stranger));
        attacker.onFlashLoan(stranger, address(usd), 1e18, 0, "");
    }

    function test_Paso4_FeedPrice() public {
        assertEq(feedLender.price(), 1000e18);
        feed.updateAnswer(-1);
        vm.expectRevert(abi.encodeWithSelector(FeedLender.InvalidPrice.selector, int256(-1)));
        feedLender.price();
        feed.updateAnswer(1000e8);
        uint256 updatedAt = block.timestamp;
        vm.warp(updatedAt + 1 hours + 1);
        vm.expectRevert(abi.encodeWithSelector(FeedLender.StalePrice.selector, updatedAt));
        feedLender.price();
    }

    function test_Paso4_RevertWhen_AttackingFeedLender() public {
        FlashAttacker attacker = new FlashAttacker(usd, gov, pool, feedLender);
        // El feed vale 500 GOV en 400 000 USD prestados: no llega para devolver 1 001 000.
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector, address(attacker), 400_000e18, 1_001_000e18
            )
        );
        attacker.attack(1_000_000e18);
    }

    function test_Paso4_HonestBorrow() public {
        address alice = makeAddr("alice");
        gov.mint(alice, 10e18);
        vm.startPrank(alice);
        gov.approve(address(feedLender), 10e18);
        vm.expectRevert(abi.encodeWithSelector(Lender.TooMuchDebt.selector, 8001e18, 8000e18));
        feedLender.borrow(10e18, 8001e18);
        feedLender.borrow(10e18, 8000e18);
        vm.stopPrank();
        assertEq(usd.balanceOf(alice), 8000e18);
    }
}
