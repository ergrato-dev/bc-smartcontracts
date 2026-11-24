// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {DeployProtocol} from "../../script/DeployProtocol.s.sol";
import {UpgradeToV2} from "../../script/UpgradeToV2.s.sol";
import {UpgradeToV3} from "../../script/UpgradeToV3.s.sol";
import {HandOverToDao} from "../../script/HandOverToDao.s.sol";
import {RegistryV3} from "../../src/RegistryV3.sol";
import {LoyaltyToken} from "../../src/LoyaltyToken.sol";
import {PointsVault} from "../../src/PointsVault.sol";
import {ProtocolGovernor} from "../../src/ProtocolGovernor.sol";

// ¿Qué? La gobernanza de la semana 31: que el traspaso no deja ninguna clave con el rol de
//   administrador, que una propuesta aprobada pasa por el timelock con su plazo, y que los votos
//   son los de la foto de cada propuesta, con quórum.
// ¿Para qué? Que el hallazgo de centralización de la semana 26 quede corregido con pruebas, con el
//   registro, el vault y los scripts de verdad.
contract GovernanceTest is Test {
    RegistryV3 registry;
    LoyaltyToken loyalty;
    PointsVault vault;
    TimelockController timelock;
    ProtocolGovernor governor;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");
    address guardian = makeAddr("guardian");
    uint256 fee;

    function setUp() public {
        vm.warp(1_750_000_000);
        DeployProtocol.Deployment memory d = new DeployProtocol().deploy(50);
        MockV3Aggregator feed = new MockV3Aggregator(8, 2500e8);
        registry = new UpgradeToV3()
            .upgrade(new UpgradeToV2().upgrade(d.registry, 10), AggregatorV3Interface(address(feed)), 25e18, 3 hours);
        loyalty = d.loyalty;
        vault = d.vault;
        fee = registry.registrationFee();
        HandOverToDao.Dao memory dao = new HandOverToDao().handOver(d.registry, vault, guardian);
        timelock = dao.timelock;
        governor = dao.governor;

        // alice guarda 100 puntos y bob 30, y los dos se delegan sus votos.
        _stake(alice, 10);
        _stake(bob, 3);
        vm.prank(alice);
        vault.delegate(alice);
        vm.prank(bob);
        vault.delegate(bob);
        vm.roll(vm.getBlockNumber() + 1);
    }

    // `who` da de alta `amount` recursos y deposita en el vault los 10 puntos de cada uno.
    function _stake(address who, uint256 amount) internal {
        vm.deal(who, 1 ether);
        vm.startPrank(who);
        for (uint256 i = 0; i < amount; i++) {
            registry.register{value: fee}("recurso");
        }
        loyalty.approve(address(vault), type(uint256).max);
        vault.deposit(loyalty.balanceOf(who), who);
        vm.stopPrank();
    }

    // La propuesta de todos los tests: quitar la pausa del registro.
    function _unpauseProposal()
        internal
        view
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        targets = new address[](1);
        targets[0] = address(registry);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeCall(registry.unpause, ());
    }

    function _propose() internal returns (uint256 id) {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _unpauseProposal();
        vm.prank(alice);
        id = governor.propose(targets, values, calldatas, "Reanudar las altas");
    }

    // Vota `support` (0 en contra, 1 a favor, 2 abstención) y devuelve los votos que contaron.
    function _vote(address who, uint256 id, uint8 support) internal returns (uint256) {
        vm.prank(who);
        return governor.castVote(id, support);
    }

    function _queue() internal {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _unpauseProposal();
        governor.queue(targets, values, calldatas, keccak256("Reanudar las altas"));
    }

    function _execute() internal {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _unpauseProposal();
        governor.execute(targets, values, calldatas, keccak256("Reanudar las altas"));
    }

    function test_HandOverLeavesNoAdmin() public view {
        bytes32 admin = registry.DEFAULT_ADMIN_ROLE();
        assertTrue(registry.hasRole(admin, address(timelock)), "el timelock administra el registro");
        assertFalse(registry.hasRole(admin, DEFAULT_SENDER), "quien desplego ya no es admin");
        assertTrue(registry.hasRole(registry.PAUSER_ROLE(), guardian), "el guardian solo pausa");
        assertFalse(registry.hasRole(admin, guardian));
        assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), address(governor)), "solo el Governor propone");
        assertTrue(timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0)), "cualquiera ejecuta");
        assertFalse(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), DEFAULT_SENDER), "el timelock no tiene admin");
        assertEq(timelock.getMinDelay(), 2 days);
        assertEq(address(governor.token()), address(vault));
    }

    function test_RevertWhen_DeployerActsAfterHandOver() public {
        bytes32 admin = registry.DEFAULT_ADMIN_ROLE();
        vm.startPrank(DEFAULT_SENDER);
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, DEFAULT_SENDER, admin)
        );
        registry.removeHook();
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, DEFAULT_SENDER, admin)
        );
        registry.upgradeToAndCall(address(1), "");
        vm.stopPrank();
    }

    function test_SharesVoteOnlyWhenDelegated() public {
        _stake(carol, 2);
        assertGt(vault.balanceOf(carol), 0);
        assertEq(vault.getVotes(carol), 0, "sin delegar, las shares no votan");
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _unpauseProposal();
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorInsufficientProposerVotes.selector, carol, 0, 1));
        governor.propose(targets, values, calldatas, "Reanudar las altas");

        vm.prank(carol);
        vault.delegate(carol);
        assertEq(vault.getVotes(carol), vault.balanceOf(carol));
        vm.roll(vm.getBlockNumber() + 1);
        vm.prank(carol);
        governor.propose(targets, values, calldatas, "Reanudar las altas");
    }

    function test_DaoUnpausesAfterTheGuardian() public {
        vm.prank(guardian);
        registry.pause();
        assertTrue(registry.paused());

        uint256 id = _propose();
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Pending));
        vm.roll(vm.getBlockNumber() + governor.votingDelay() + 1);
        assertEq(_vote(alice, id, 1), vault.balanceOf(alice));
        vm.roll(vm.getBlockNumber() + governor.votingPeriod());
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Succeeded));

        _queue();
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Queued));
        vm.warp(vm.getBlockTimestamp() + 2 days);
        _execute();
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Executed));
        assertFalse(registry.paused(), "la DAO reanuda las altas");
    }

    function test_RevertWhen_ExecuteBeforeTheDelay() public {
        vm.prank(guardian);
        registry.pause();
        uint256 id = _propose();
        vm.roll(vm.getBlockNumber() + governor.votingDelay() + 1);
        _vote(alice, id, 1);
        vm.roll(vm.getBlockNumber() + governor.votingPeriod());
        _queue();

        vm.warp(vm.getBlockTimestamp() + 2 days - 1);
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _unpauseProposal();
        bytes32 operation = timelock.hashOperationBatch(
            targets, values, calldatas, 0, bytes20(address(governor)) ^ keccak256("Reanudar las altas")
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockController.TimelockUnexpectedOperationState.selector,
                operation,
                bytes32(1 << uint8(TimelockController.OperationState.Ready))
            )
        );
        _execute();
        assertTrue(registry.paused());
    }

    function test_FlashDepositCannotVote() public {
        uint256 id = _propose();
        vm.roll(vm.getBlockNumber() + governor.votingDelay() + 1);
        _vote(bob, id, 0);

        // carol llega con la votación abierta: en un mismo bloque consigue 100 puntos, los
        // deposita, se delega y vota. Sus votos son los de la foto de la propuesta: cero.
        _stake(carol, 10);
        vm.prank(carol);
        vault.delegate(carol);
        assertEq(vault.getVotes(carol), vault.balanceOf(carol), "hoy si tiene votos");
        assertEq(_vote(carol, id, 0), 0, "en la propuesta no cuentan");

        _vote(alice, id, 1);
        vm.roll(vm.getBlockNumber() + governor.votingPeriod());
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Succeeded));
    }

    function test_VotingDelayLetsHoldersDelegate() public {
        _stake(carol, 2);
        uint256 id = _propose();
        // carol se entera de la propuesta y delega en el bloque siguiente, antes de la foto.
        vm.roll(vm.getBlockNumber() + 1);
        vm.prank(carol);
        vault.delegate(carol);
        vm.roll(vm.getBlockNumber() + governor.votingDelay());
        assertEq(_vote(carol, id, 1), vault.balanceOf(carol), "delego a tiempo");
    }

    function test_DefeatedWithoutQuorum() public {
        // carol solo guarda 1 punto: sus votos no llegan al 4 % de las shares.
        vm.deal(carol, 1 ether);
        vm.startPrank(carol);
        registry.register{value: fee}("recurso");
        loyalty.approve(address(vault), 1 ether);
        vault.deposit(1 ether, carol);
        vault.delegate(carol);
        vm.stopPrank();
        vm.roll(vm.getBlockNumber() + 1);

        uint256 id = _propose();
        vm.roll(vm.getBlockNumber() + governor.votingDelay() + 1);
        uint256 snapshot = governor.proposalSnapshot(id);
        assertLt(vault.getPastVotes(carol, snapshot), governor.quorum(snapshot));
        _vote(carol, id, 1);
        vm.roll(vm.getBlockNumber() + governor.votingPeriod());
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Defeated), "a favor, pero sin quorum");
    }
}
