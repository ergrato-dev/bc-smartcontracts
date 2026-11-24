// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {VotesToken} from "../src/VotesToken.sol";

// El token del ejercicio con `mint` y `burn` abiertos, solo para los tests.
contract VotesHarness is VotesToken {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

// El ERC20Votes de OpenZeppelin, con lo mismo: la referencia del último test.
contract OzVotes is ERC20, ERC20Votes {
    constructor() ERC20("OZ Votes", "OZV") EIP712("OZ Votes", "1") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }
}

contract VotesTokenTest is Test {
    VotesHarness token;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");

    function setUp() public {
        vm.roll(100);
        token = new VotesHarness();
        token.mint(alice, 100 ether);
        token.mint(bob, 50 ether);
    }

    function test_HoldingIsNotVoting() public view {
        assertEq(token.balanceOf(alice), 100 ether);
        assertEq(token.getVotes(alice), 0, "sin delegar no hay votos");
    }

    function test_Paso1_DelegateToSelfGivesVotes() public {
        vm.expectEmit(address(token));
        emit VotesToken.DelegateChanged(alice, address(0), alice);
        vm.expectEmit(address(token));
        emit VotesToken.DelegateVotesChanged(alice, 0, 100 ether);
        vm.prank(alice);
        token.delegate(alice);
        assertEq(token.delegates(alice), alice);
        assertEq(token.getVotes(alice), 100 ether);
    }

    function test_Paso1_RedelegateMovesEveryVote() public {
        vm.prank(alice);
        token.delegate(alice);
        vm.roll(101);
        vm.prank(alice);
        token.delegate(carol);
        assertEq(token.getVotes(alice), 0);
        assertEq(token.getVotes(carol), 100 ether, "carol vota con los tokens de alice");
        assertEq(token.balanceOf(carol), 0, "sin tener ninguno");
    }

    function test_Paso2_OneCheckpointPerBlock() public {
        vm.startPrank(alice);
        token.delegate(alice);
        token.delegate(carol);
        token.delegate(alice);
        vm.stopPrank();
        assertEq(token.numCheckpoints(alice), 1, "tres cambios en el bloque 100, un checkpoint");
        VotesToken.Checkpoint memory last = token.checkpoints(alice, 0);
        assertEq(last.fromBlock, 100);
        assertEq(last.votes, 100 ether);

        vm.roll(101);
        vm.prank(alice);
        token.delegate(carol);
        assertEq(token.numCheckpoints(alice), 2);
    }

    function test_Paso3_TransferMovesVotes() public {
        vm.prank(alice);
        token.delegate(alice);
        vm.prank(bob);
        token.delegate(carol);
        vm.prank(alice);
        token.transfer(bob, 30 ether);
        assertEq(token.getVotes(alice), 70 ether);
        assertEq(token.getVotes(carol), 80 ether, "los 30 llegan al delegado de bob");
        assertEq(token.getVotes(bob), 0);
    }

    function test_Paso3_TokensToSomeoneWithoutDelegateLoseTheirVotes() public {
        vm.prank(alice);
        token.delegate(alice);
        vm.prank(alice);
        token.transfer(carol, 40 ether);
        assertEq(token.getVotes(alice), 60 ether);
        assertEq(token.getVotes(carol), 0, "carol no delego: sus tokens no votan");
    }

    function test_Paso4_PastVotesAreFrozen() public {
        vm.prank(alice);
        token.delegate(alice);
        vm.roll(110);
        vm.prank(alice);
        token.transfer(bob, 60 ether);
        vm.roll(120);
        vm.prank(alice);
        token.delegate(carol);
        vm.roll(130);

        assertEq(token.getPastVotes(alice, 99), 0, "antes de delegar");
        assertEq(token.getPastVotes(alice, 100), 100 ether);
        assertEq(token.getPastVotes(alice, 109), 100 ether);
        assertEq(token.getPastVotes(alice, 110), 40 ether);
        assertEq(token.getPastVotes(alice, 119), 40 ether);
        assertEq(token.getPastVotes(alice, 120), 0);
        assertEq(token.getPastVotes(carol, 129), 40 ether);
    }

    function test_RevertWhen_LookingAtTheCurrentBlock() public {
        vm.expectRevert(abi.encodeWithSelector(VotesToken.FutureLookup.selector, 100, 100));
        token.getPastVotes(alice, 100);
    }

    function test_Paso4_FlashLoanGivesNoPastVotes() public {
        vm.prank(alice);
        token.delegate(alice);
        vm.roll(200);
        // carol "pide prestado" un millón de tokens, delega y los devuelve, todo en el bloque 200.
        token.mint(carol, 1_000_000 ether);
        vm.prank(carol);
        token.delegate(carol);
        assertEq(token.getVotes(carol), 1_000_000 ether, "durante el prestamo, si");
        token.burn(carol, 1_000_000 ether);

        vm.roll(201);
        assertEq(token.getPastVotes(carol, 199), 0, "en cualquier bloque anterior, no");
        assertEq(token.getPastVotes(carol, 200), 0, "y al acabar el suyo, tampoco");
        assertEq(token.getPastVotes(alice, 200), 100 ether);
    }

    function test_Paso5_PastTotalSupply() public {
        vm.roll(101);
        token.mint(carol, 50 ether);
        vm.roll(102);
        token.burn(bob, 50 ether);
        vm.prank(alice);
        token.transfer(carol, 10 ether);
        vm.roll(103);
        assertEq(token.getPastTotalSupply(100), 150 ether);
        assertEq(token.getPastTotalSupply(101), 200 ether);
        assertEq(token.getPastTotalSupply(102), 150 ether, "una transferencia no cambia el total");
    }

    // Diferencial: las mismas operaciones en tu token y en el de OpenZeppelin dan los mismos
    // votos, ahora y en cada bloque pasado.
    function testFuzz_Paso5_MatchesOpenZeppelin(uint256 seed) public {
        OzVotes oz = new OzVotes();
        oz.mint(alice, 100 ether);
        oz.mint(bob, 50 ether);
        address[3] memory users = [alice, bob, carol];
        uint256 start = block.number;

        for (uint256 i = 0; i < 12; i++) {
            uint256 r = uint256(keccak256(abi.encode(seed, i)));
            address who = users[r % 3];
            address other = users[(r >> 8) % 3];
            uint256 op = (r >> 16) % 4;
            if (op == 0) {
                vm.prank(who);
                token.delegate(other);
                vm.prank(who);
                oz.delegate(other);
            } else if (op == 1) {
                uint256 amount = (r >> 24) % (token.balanceOf(who) + 1);
                vm.prank(who);
                token.transfer(other, amount);
                vm.prank(who);
                oz.transfer(other, amount);
            } else if (op == 2) {
                uint256 amount = (r >> 24) % 100 ether;
                token.mint(who, amount);
                oz.mint(who, amount);
            } else {
                uint256 amount = (r >> 24) % (token.balanceOf(who) + 1);
                token.burn(who, amount);
                oz.burn(who, amount);
            }
            vm.roll(block.number + (r >> 128) % 3);
        }
        vm.roll(block.number + 1);

        for (uint256 b = start; b < block.number; b++) {
            assertEq(token.getPastTotalSupply(b), oz.getPastTotalSupply(b), "total");
            for (uint256 u = 0; u < 3; u++) {
                assertEq(token.getPastVotes(users[u], b), oz.getPastVotes(users[u], b), "votos");
            }
        }
    }
}
