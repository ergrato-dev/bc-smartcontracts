// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Poll} from "../src/Poll.sol";

contract PollTest is Test {
    Poll poll;
    address voter;
    uint256 voterKey;
    address mallory;
    uint256 malloryKey;
    address relayer = makeAddr("relayer");
    uint256 deadline;

    function setUp() public {
        (voter, voterKey) = makeAddrAndKey("voter");
        (mallory, malloryKey) = makeAddrAndKey("mallory");
        poll = new Poll();
        deadline = block.timestamp + 1 hours;
    }

    // El dominio y el mensaje, montados a mano según EIP-712, sin la librería del contrato.
    function _expectedDigest(address v, uint256 option, string memory comment, uint256 nonce, uint256 dl)
        internal
        view
        returns (bytes32)
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Poll"),
                keccak256("1"),
                block.chainid,
                address(poll)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Vote(address voter,uint256 option,string comment,uint256 nonce,uint256 deadline)"),
                v,
                option,
                keccak256(bytes(comment)),
                nonce,
                dl
            )
        );
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    function _sign(uint256 key, uint256 option, string memory comment) internal view returns (bytes memory) {
        bytes32 digest = poll.voteDigest(voter, option, comment, poll.nonces(voter), deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, digest);
        return abi.encodePacked(r, s, v);
    }

    function test_Inherited_DomainIsReadable() public view {
        (, string memory name, string memory version, uint256 chainId, address verifyingContract,,) =
            poll.eip712Domain();
        assertEq(name, "Poll");
        assertEq(version, "1");
        assertEq(chainId, block.chainid);
        assertEq(verifyingContract, address(poll));
    }

    function test_Step1_DigestFollowsEip712() public view {
        assertEq(poll.voteDigest(voter, 2, "yes", 0, deadline), _expectedDigest(voter, 2, "yes", 0, deadline));
    }

    function test_Step1_DigestDependsOnEveryField() public view {
        bytes32 base = poll.voteDigest(voter, 2, "yes", 0, deadline);
        assertNotEq(poll.voteDigest(mallory, 2, "yes", 0, deadline), base);
        assertNotEq(poll.voteDigest(voter, 1, "yes", 0, deadline), base);
        assertNotEq(poll.voteDigest(voter, 2, "no", 0, deadline), base);
        assertNotEq(poll.voteDigest(voter, 2, "yes", 1, deadline), base);
        assertNotEq(poll.voteDigest(voter, 2, "yes", 0, deadline + 1), base);
    }

    function test_Step2_RelayerSendsTheVote() public {
        bytes memory sig = _sign(voterKey, 2, "yes");
        vm.expectEmit(address(poll));
        emit Poll.Voted(voter, 2, "yes");
        vm.prank(relayer);
        poll.voteBySig(voter, 2, "yes", deadline, sig);
        assertEq(poll.votesFor(2), 1);
        assertTrue(poll.hasVoted(voter));
        assertFalse(poll.hasVoted(relayer));
        assertEq(poll.nonces(voter), 1);
    }

    function test_Step2_RevertWhen_SignedByOtherKey() public {
        bytes memory sig = _sign(malloryKey, 2, "yes");
        vm.expectRevert(abi.encodeWithSelector(Poll.InvalidSigner.selector, mallory, voter));
        poll.voteBySig(voter, 2, "yes", deadline, sig);
    }

    // El relayer no puede cambiar el voto: otro campo da otro hash y otro firmante.
    function test_Step2_RevertWhen_RelayerChangesTheOption() public {
        bytes memory sig = _sign(voterKey, 2, "yes");
        vm.expectPartialRevert(Poll.InvalidSigner.selector);
        poll.voteBySig(voter, 0, "yes", deadline, sig);
    }

    function test_Step2_RevertWhen_Expired() public {
        bytes memory sig = _sign(voterKey, 2, "yes");
        vm.warp(deadline + 1);
        vm.expectRevert(abi.encodeWithSelector(Poll.ExpiredSignature.selector, deadline));
        poll.voteBySig(voter, 2, "yes", deadline, sig);
    }

    function test_Step2_RevertWhen_SignatureIsReplayed() public {
        bytes memory sig = _sign(voterKey, 2, "yes");
        poll.voteBySig(voter, 2, "yes", deadline, sig);
        vm.expectPartialRevert(Poll.InvalidSigner.selector);
        poll.voteBySig(voter, 2, "yes", deadline, sig);
    }

    function test_Step2_RevertWhen_SentToOtherPoll() public {
        bytes memory sig = _sign(voterKey, 2, "yes");
        Poll other = new Poll();
        vm.expectPartialRevert(Poll.InvalidSigner.selector);
        other.voteBySig(voter, 2, "yes", deadline, sig);
    }

    function test_Step2_RevertWhen_OptionDoesNotExist() public {
        bytes memory sig = _sign(voterKey, 3, "yes");
        vm.expectRevert(abi.encodeWithSelector(Poll.InvalidOption.selector, 3));
        poll.voteBySig(voter, 3, "yes", deadline, sig);
    }

    function test_Step3_CancelInvalidatesPendingSignature() public {
        bytes memory sig = _sign(voterKey, 2, "yes");
        vm.prank(voter);
        poll.cancelNonce();
        assertEq(poll.nonces(voter), 1);
        vm.expectPartialRevert(Poll.InvalidSigner.selector);
        poll.voteBySig(voter, 2, "yes", deadline, sig);
    }

    function test_Step3_NewSignatureWorksAfterCancel() public {
        vm.prank(voter);
        poll.cancelNonce();
        poll.voteBySig(voter, 1, "maybe", deadline, _sign(voterKey, 1, "maybe"));
        assertEq(poll.votesFor(1), 1);
        assertEq(poll.nonces(voter), 2);
    }

    function test_Step3_CancelOnlyTouchesTheCaller() public {
        vm.prank(mallory);
        poll.cancelNonce();
        assertEq(poll.nonces(voter), 0);
        assertEq(poll.nonces(mallory), 1);
    }
}
