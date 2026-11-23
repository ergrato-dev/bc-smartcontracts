// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {Pool} from "../src/Pool.sol";
import {Sandwicher} from "../src/Sandwicher.sol";
import {VulnerablePuzzle} from "../src/VulnerablePuzzle.sol";
import {CommitRevealPuzzle} from "../src/CommitRevealPuzzle.sol";

// Los tests no tienen mempool: el orden de las llamadas es el orden en que el constructor del
// bloque metió las transacciones. Un front-runner es quien consigue ir antes.
contract FrontRunningTest is Test {
    Token usd;
    Token gov;
    Pool pool;
    Sandwicher sandwicher;
    address alice = makeAddr("alice");
    address mallory = makeAddr("mallory");
    bytes32 salt = keccak256("secreto de alice");

    function setUp() public {
        usd = new Token("Dollar", "USD");
        gov = new Token("Governance", "GOV");
        pool = new Pool(usd, gov);
        usd.mint(address(this), 1_000_000e18);
        gov.mint(address(this), 1000e18);
        usd.approve(address(pool), 1_000_000e18);
        gov.approve(address(pool), 1000e18);
        pool.addLiquidity(1_000_000e18, 1000e18);
        // Alice quiere comprar GOV con 100 000 USD; el atacante tiene 500 000.
        usd.mint(alice, 100_000e18);
        vm.prank(alice);
        usd.approve(address(pool), type(uint256).max);
        sandwicher = new Sandwicher(pool);
        usd.mint(address(sandwicher), 500_000e18);
    }

    function _aliceSwap(uint256 minAmountOut) internal returns (uint256) {
        vm.prank(alice);
        return pool.swap(usd, 100_000e18, minAmountOut, block.timestamp + 5 minutes);
    }

    function test_Paso1_SandwichProfits() public {
        uint256 fair = pool.quote(usd, 100_000e18);
        sandwicher.frontRun();
        uint256 got = _aliceSwap(0);
        sandwicher.backRun();
        // Sola, Alice habría recibido 90,9 GOV; con el sándwich, 41,6.
        assertEq(fair, 90_909090909090909090);
        assertEq(got, 41_666666666666666666);
        assertEq(gov.balanceOf(address(sandwicher)), 0);
        assertEq(usd.balanceOf(address(sandwicher)), 556_521_739130434782607751);
    }

    function test_Paso2_SwapWithinSlippage() public {
        uint256 minOut = pool.quote(usd, 100_000e18) * 99 / 100;
        assertEq(_aliceSwap(minOut), 90_909090909090909090);
    }

    function test_Paso2_RevertWhen_Sandwiched() public {
        // Alice acepta hasta un 1 % menos de lo que ve al firmar.
        uint256 minOut = pool.quote(usd, 100_000e18) * 99 / 100;
        sandwicher.frontRun();
        vm.expectRevert(abi.encodeWithSelector(Pool.InsufficientOutput.selector, 41_666666666666666666, minOut));
        _aliceSwap(minOut);
        sandwicher.backRun();
        // Sin la víctima en medio, el atacante recupera lo suyo menos 500 wei de redondeo.
        assertEq(usd.balanceOf(address(sandwicher)), 499_999_999999999999999500);
    }

    function test_Paso3_RevertWhen_Expired() public {
        uint256 deadline = block.timestamp + 5 minutes;
        // La transacción espera en la mempool diez minutos.
        vm.warp(block.timestamp + 10 minutes);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Pool.Expired.selector, deadline));
        pool.swap(usd, 100_000e18, 0, deadline);
    }

    function test_FrontRunnerStealsVulnerablePuzzle() public {
        VulnerablePuzzle puzzle = new VulnerablePuzzle{value: 1 ether}();
        // Mallory ve en la mempool `solve("rollup")` de Alice y envía la misma llamada antes.
        vm.prank(mallory);
        puzzle.solve("rollup");
        vm.prank(alice);
        vm.expectRevert(VulnerablePuzzle.AlreadySolved.selector);
        puzzle.solve("rollup");
        assertEq(mallory.balance, 1 ether);
    }

    function test_Paso4_Commit() public {
        CommitRevealPuzzle puzzle = new CommitRevealPuzzle{value: 1 ether}();
        bytes32 commitment = puzzle.hashCommitment(alice, "rollup", salt);
        vm.prank(alice);
        puzzle.commit(commitment);
        assertEq(puzzle.commitmentOf(alice), commitment);
        assertEq(puzzle.committedAt(alice), block.number);
    }

    function test_Paso5_RevealPays() public {
        CommitRevealPuzzle puzzle = new CommitRevealPuzzle{value: 1 ether}();
        bytes32 commitment = puzzle.hashCommitment(alice, "rollup", salt);
        vm.prank(alice);
        puzzle.commit(commitment);
        vm.prank(alice);
        vm.expectRevert(CommitRevealPuzzle.RevealTooEarly.selector);
        puzzle.reveal("rollup", salt);
        vm.roll(block.number + 1);
        vm.prank(alice);
        puzzle.reveal("rollup", salt);
        assertEq(alice.balance, 1 ether);
    }

    function test_Paso5_RevertWhen_FrontRunnerCopiesCommit() public {
        CommitRevealPuzzle puzzle = new CommitRevealPuzzle{value: 1 ether}();
        bytes32 commitment = puzzle.hashCommitment(alice, "rollup", salt);
        // Mallory copia el compromiso de Alice y, cuando ella revela, copia también la revelación.
        vm.prank(mallory);
        puzzle.commit(commitment);
        vm.roll(block.number + 1);
        vm.prank(mallory);
        vm.expectRevert(CommitRevealPuzzle.WrongCommitment.selector);
        puzzle.reveal("rollup", salt);
    }

    function test_Paso5_RevertWhen_FrontRunnerCopiesReveal() public {
        CommitRevealPuzzle puzzle = new CommitRevealPuzzle{value: 1 ether}();
        bytes32 commitment = puzzle.hashCommitment(alice, "rollup", salt);
        vm.prank(alice);
        puzzle.commit(commitment);
        vm.roll(block.number + 1);
        // Mallory ve la revelación en la mempool: se compromete y revela en el mismo bloque.
        bytes32 malloryCommitment = puzzle.hashCommitment(mallory, "rollup", salt);
        vm.startPrank(mallory);
        puzzle.commit(malloryCommitment);
        vm.expectRevert(CommitRevealPuzzle.RevealTooEarly.selector);
        puzzle.reveal("rollup", salt);
        vm.stopPrank();
        vm.prank(alice);
        puzzle.reveal("rollup", salt);
        assertEq(alice.balance, 1 ether);
    }
}
