// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {GovToken} from "../src/GovToken.sol";
import {Treasury} from "../src/Treasury.sol";
import {MyGovernor} from "../src/MyGovernor.sol";

contract MyGovernorTest is Test {
    GovToken token;
    MyGovernor governor;
    Treasury treasury;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");
    address dave = makeAddr("dave");
    string constant DESCRIPTION = "Pagar 1 ETH a dave";

    function setUp() public {
        vm.roll(1000);
        token = new GovToken();
        governor = new MyGovernor(token);
        treasury = new Treasury(address(governor));
        vm.deal(address(treasury), 10 ether);

        // alice 400 000 (40 %), bob 300 000 (30 %), carol 20 000 (2 %). El quórum es el 4 %.
        _give(alice, 400_000 ether);
        _give(bob, 300_000 ether);
        _give(carol, 20_000 ether);
        vm.roll(vm.getBlockNumber() + 1);
    }

    function _give(address who, uint256 amount) internal {
        token.transfer(who, amount);
        vm.prank(who);
        token.delegate(who);
    }

    function _proposal()
        internal
        view
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        targets = new address[](1);
        targets[0] = address(treasury);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeCall(Treasury.pay, (payable(dave), 1 ether));
    }

    // alice propone y pasa la foto: la votación queda abierta.
    function _proposeAndOpen() internal returns (uint256 id) {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _proposal();
        vm.prank(alice);
        id = governor.propose(targets, values, calldatas, DESCRIPTION);
        vm.roll(vm.getBlockNumber() + governor.votingDelay() + 1);
    }

    function _vote(address who, uint256 id, uint8 support) internal returns (uint256) {
        vm.prank(who);
        return governor.castVote(id, support);
    }

    function _close() internal {
        vm.roll(vm.getBlockNumber() + governor.votingPeriod());
    }

    function _state(uint256 id) internal view returns (IGovernor.ProposalState) {
        return governor.state(id);
    }

    function test_ProposalIdIsTheHashOfItsContent() public {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _proposal();
        uint256 expected = uint256(keccak256(abi.encode(targets, values, calldatas, keccak256(bytes(DESCRIPTION)))));
        assertEq(governor.hashProposal(targets, values, calldatas, keccak256(bytes(DESCRIPTION))), expected);
        vm.prank(alice);
        assertEq(governor.propose(targets, values, calldatas, DESCRIPTION), expected);
        assertEq(uint8(_state(expected)), uint8(IGovernor.ProposalState.Pending));
        assertEq(governor.proposalSnapshot(expected), vm.getBlockNumber() + governor.votingDelay());
    }

    function test_Paso1_CountsEachOption() public {
        uint256 id = _proposeAndOpen();
        assertEq(_vote(alice, id, 1), 400_000 ether, "los votos de la foto");
        _vote(bob, id, 0);
        _vote(carol, id, 2);
        (uint256 against, uint256 forVotes, uint256 abstain) = governor.proposalVotes(id);
        assertEq(against, 300_000 ether);
        assertEq(forVotes, 400_000 ether);
        assertEq(abstain, 20_000 ether);
        assertTrue(governor.hasVoted(id, alice));
        assertFalse(governor.hasVoted(id, dave));
    }

    function test_Paso1_RevertWhen_VotingTwiceOrWithAnInvalidOption() public {
        uint256 id = _proposeAndOpen();
        _vote(alice, id, 1);
        vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorAlreadyCastVote.selector, alice));
        _vote(alice, id, 0);
        vm.expectRevert(IGovernor.GovernorInvalidVoteType.selector);
        _vote(bob, id, 3);
    }

    function test_Paso2_DefeatedWithoutQuorum() public {
        uint256 id = _proposeAndOpen();
        _vote(carol, id, 1);
        _close();
        assertEq(governor.quorum(governor.proposalSnapshot(id)), 40_000 ether, "el 4 % de un millon");
        assertEq(uint8(_state(id)), uint8(IGovernor.ProposalState.Defeated), "2 % a favor no llega");
    }

    function test_Paso2_AbstentionCountsForQuorum() public {
        uint256 id = _proposeAndOpen();
        _vote(carol, id, 1);
        _vote(bob, id, 2);
        _close();
        assertEq(uint8(_state(id)), uint8(IGovernor.ProposalState.Succeeded), "bob se abstiene y hay quorum");
    }

    function test_Paso3_DefeatedWhenAgainstWins() public {
        uint256 id = _proposeAndOpen();
        _vote(bob, id, 1);
        _vote(alice, id, 0);
        _close();
        assertEq(uint8(_state(id)), uint8(IGovernor.ProposalState.Defeated));
    }

    function test_Paso3_TieIsDefeated() public {
        _give(dave, 280_000 ether);
        vm.roll(vm.getBlockNumber() + 1);
        uint256 id = _proposeAndOpen();
        _vote(bob, id, 1);
        _vote(carol, id, 0);
        _vote(dave, id, 0);
        _close();
        assertEq(uint8(_state(id)), uint8(IGovernor.ProposalState.Defeated), "300 000 contra 20 000 + 280 000");
    }

    function test_Paso4_SettingsInBlocks() public view {
        assertEq(governor.votingDelay(), 7200, "un dia de bloques de 12 s");
        assertEq(governor.votingPeriod(), 50_400, "una semana");
        assertEq(governor.proposalThreshold(), 10_000 ether, "el 1 %");
        assertEq(governor.clock(), vm.getBlockNumber(), "el reloj del token: bloques");
    }

    function test_Paso4_RevertWhen_ProposerBelowThreshold() public {
        _give(dave, 9_999 ether);
        vm.roll(vm.getBlockNumber() + 1);
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _proposal();
        vm.expectRevert(
            abi.encodeWithSelector(IGovernor.GovernorInsufficientProposerVotes.selector, dave, 9_999 ether, 10_000 ether)
        );
        vm.prank(dave);
        governor.propose(targets, values, calldatas, DESCRIPTION);
    }

    function test_Paso4_TheWholeLifecycle() public {
        uint256 id = _proposeAndOpen();
        assertEq(uint8(_state(id)), uint8(IGovernor.ProposalState.Active));
        _vote(alice, id, 1);
        _vote(bob, id, 0);
        vm.roll(governor.proposalDeadline(id));
        assertEq(uint8(_state(id)), uint8(IGovernor.ProposalState.Active), "el ultimo bloque aun vota");
        vm.roll(governor.proposalDeadline(id) + 1);
        assertEq(uint8(_state(id)), uint8(IGovernor.ProposalState.Succeeded));

        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _proposal();
        governor.execute(targets, values, calldatas, keccak256(bytes(DESCRIPTION)));
        assertEq(uint8(_state(id)), uint8(IGovernor.ProposalState.Executed));
        assertEq(dave.balance, 1 ether, "la tesoreria pago lo aprobado");
    }
}
