// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {GovToken} from "../src/GovToken.sol";
import {DaoGovernor} from "../src/DaoGovernor.sol";
import {Treasury} from "../src/Treasury.sol";
import {DaoDeployer} from "../src/DaoDeployer.sol";

// Pide prestado un millón de tokens, delega en sí mismo y vota en la misma transacción.
contract FlashVoter is IERC3156FlashBorrower {
    GovToken immutable TOKEN;
    DaoGovernor immutable GOVERNOR;
    uint256 public votesDuringLoan;
    uint256 public countedVotes;

    constructor(GovToken token, DaoGovernor governor) {
        TOKEN = token;
        GOVERNOR = governor;
    }

    function attack(uint256 proposalId) external {
        TOKEN.flashLoan(this, address(TOKEN), 1_000_000 ether, abi.encode(proposalId));
    }

    function onFlashLoan(address, address, uint256 amount, uint256 fee, bytes calldata data)
        external
        returns (bytes32)
    {
        TOKEN.delegate(address(this));
        votesDuringLoan = TOKEN.getVotes(address(this));
        countedVotes = GOVERNOR.castVote(abi.decode(data, (uint256)), 1);
        // ERC20FlashMint quema lo prestado con un allowance del prestatario.
        TOKEN.approve(address(TOKEN), amount + fee);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}

contract DaoTest is Test {
    GovToken token;
    DaoDeployer deployer;
    TimelockController timelock;
    DaoGovernor governor;
    Treasury treasury;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address dave = makeAddr("dave");
    address guardian = makeAddr("guardian");
    string constant DESCRIPTION = "Pagar 1 ETH a dave";

    function setUp() public {
        vm.roll(1000);
        vm.warp(1_750_000_000);
        token = new GovToken();
        deployer = new DaoDeployer(token, guardian);
        timelock = deployer.timelock();
        governor = deployer.governor();
        treasury = deployer.treasury();
        vm.deal(address(treasury), 10 ether);

        // alice 400 000 (40 %) y bob 300 000 (30 %), los dos con sus votos delegados.
        token.transfer(alice, 400_000 ether);
        token.transfer(bob, 300_000 ether);
        vm.prank(alice);
        token.delegate(alice);
        vm.prank(bob);
        token.delegate(bob);
        vm.roll(vm.getBlockNumber() + 1);
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

    function _proposeAndOpen() internal returns (uint256 id) {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _proposal();
        vm.prank(alice);
        id = governor.propose(targets, values, calldatas, DESCRIPTION);
        vm.roll(vm.getBlockNumber() + governor.votingDelay() + 1);
    }

    // alice propone, vota a favor y la votación se cierra: aprobada.
    function _approve() internal returns (uint256 id) {
        id = _proposeAndOpen();
        vm.prank(alice);
        governor.castVote(id, 1);
        vm.roll(governor.proposalDeadline(id) + 1);
    }

    function _queue() internal {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _proposal();
        governor.queue(targets, values, calldatas, keccak256(bytes(DESCRIPTION)));
    }

    function _execute() internal {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _proposal();
        vm.prank(dave);
        governor.execute(targets, values, calldatas, keccak256(bytes(DESCRIPTION)));
    }

    // El id de la operación en el timelock: GovernorTimelockControl usa como salt la dirección del
    // Governor mezclada con el hash de la descripción.
    function _operationId() internal view returns (bytes32) {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _proposal();
        bytes32 salt = bytes20(address(governor)) ^ keccak256(bytes(DESCRIPTION));
        return timelock.hashOperationBatch(targets, values, calldatas, 0, salt);
    }

    function test_FlashLoanVotesCountZero() public {
        uint256 id = _proposeAndOpen();
        FlashVoter attacker = new FlashVoter(token, governor);
        attacker.attack(id);
        assertEq(attacker.votesDuringLoan(), 1_000_000 ether, "durante el prestamo tiene un millon de votos");
        assertEq(attacker.countedVotes(), 0, "en la foto no tenia ninguno");
        assertEq(token.balanceOf(address(attacker)), 0, "y lo devolvio todo");
    }

    function test_Paso1_TimelockWaitsTwoDays() public view {
        assertEq(timelock.getMinDelay(), 2 days);
        assertTrue(timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0)), "cualquiera ejecuta");
    }

    function test_Paso2_ApprovedProposalsGoToTheQueue() public {
        uint256 id = _approve();
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Succeeded));
        _queue();
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Queued));
        assertTrue(timelock.isOperationPending(_operationId()));
        assertEq(governor.proposalEta(id), vm.getBlockTimestamp() + 2 days);
    }

    function test_RevertWhen_SchedulingWithoutTheGovernor() public {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _proposal();
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, alice, timelock.PROPOSER_ROLE()
            )
        );
        vm.prank(alice);
        timelock.scheduleBatch(targets, values, calldatas, 0, 0, 2 days);
    }

    function test_Paso3_GuardianCancelsAQueuedProposal() public {
        uint256 id = _approve();
        _queue();
        bytes32 operation = _operationId();
        vm.prank(guardian);
        timelock.cancel(operation);
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Canceled));
    }

    function test_Paso4_ExecutionPaysAfterTheDelay() public {
        _approve();
        _queue();
        vm.warp(vm.getBlockTimestamp() + 2 days - 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockController.TimelockUnexpectedOperationState.selector,
                _operationId(),
                bytes32(1 << uint8(TimelockController.OperationState.Ready))
            )
        );
        _execute();

        vm.warp(vm.getBlockTimestamp() + 1);
        _execute();
        assertEq(dave.balance, 1 ether, "dave ejecuta y cobra");
        assertEq(treasury.owner(), address(timelock));
    }

    function test_Paso5_NobodyAdministersTheTimelock() public view {
        bytes32 admin = timelock.DEFAULT_ADMIN_ROLE();
        assertFalse(timelock.hasRole(admin, address(deployer)), "el desplegador renuncio");
        assertTrue(timelock.hasRole(admin, address(timelock)), "solo el timelock");
    }

    function test_Paso5_RolesOnlyChangeByProposal() public {
        bytes32 canceller = timelock.CANCELLER_ROLE();
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, address(deployer), timelock.DEFAULT_ADMIN_ROLE()
            )
        );
        vm.prank(address(deployer));
        timelock.grantRole(canceller, bob);

        // La DAO le quita el rol al guardián: una propuesta al propio timelock.
        address[] memory targets = new address[](1);
        targets[0] = address(timelock);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeCall(timelock.revokeRole, (canceller, guardian));
        vm.prank(alice);
        uint256 id = governor.propose(targets, values, calldatas, "Quitar al guardian");
        vm.roll(vm.getBlockNumber() + governor.votingDelay() + 1);
        vm.prank(alice);
        governor.castVote(id, 1);
        vm.roll(governor.proposalDeadline(id) + 1);
        governor.queue(targets, values, calldatas, keccak256("Quitar al guardian"));
        vm.warp(vm.getBlockTimestamp() + 2 days);
        governor.execute(targets, values, calldatas, keccak256("Quitar al guardian"));
        assertFalse(timelock.hasRole(canceller, guardian));
    }
}
