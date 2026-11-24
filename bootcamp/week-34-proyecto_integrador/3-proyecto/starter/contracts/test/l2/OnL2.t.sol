// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {DeployProtocol} from "../../script/DeployProtocol.s.sol";
import {UpgradeToV2} from "../../script/UpgradeToV2.s.sol";
import {UpgradeToV3} from "../../script/UpgradeToV3.s.sol";
import {HandOverToDao} from "../../script/HandOverToDao.s.sol";
import {DeployToL2} from "../../script/DeployToL2.s.sol";
import {RegistryV3} from "../../src/RegistryV3.sol";
import {LoyaltyToken} from "../../src/LoyaltyToken.sol";
import {PointsVault} from "../../src/PointsVault.sol";
import {ProtocolGovernor} from "../../src/ProtocolGovernor.sol";
import {SequencerAwareFeed} from "../../src/SequencerAwareFeed.sol";
import {L2Executor} from "../../src/L2Executor.sol";
import {MockMessenger} from "./MockMessenger.sol";

// ¿Qué? El protocolo en una L2 (semana 33): en L1, el de siempre con su DAO; en la L2, otro
//   despliegue con los mismos scripts, un feed que mira el secuenciador y un ejecutor que solo
//   obedece al timelock de L1. Las dos cadenas viven en un solo EVM y MockMessenger hace de rollup.
// ¿Para qué? Que en la L2 no se cobre con precios viejos y que nadie más que la DAO de L1 la
//   administre, ni siquiera quien la desplegó.
contract OnL2Test is Test {
    uint32 constant MESSAGE_GAS = 300_000;

    MockMessenger messenger;
    TimelockController timelock;
    ProtocolGovernor governor;
    RegistryV3 l2Registry;
    LoyaltyToken l2Loyalty;
    MockV3Aggregator sequencerFeed;
    MockV3Aggregator l2PriceFeed;
    DeployToL2.L2 l2;

    address alice = makeAddr("alice");
    address carol = makeAddr("carol");
    address guardian = makeAddr("guardian");
    address attacker = makeAddr("attacker");

    function setUp() public {
        vm.warp(1_750_000_000);
        messenger = new MockMessenger();

        // L1: el protocolo de la semana 32, con su DAO. alice tiene los votos.
        DeployProtocol.Deployment memory d1 = new DeployProtocol().deploy(50);
        MockV3Aggregator l1PriceFeed = new MockV3Aggregator(8, 2500e8);
        RegistryV3 l1Registry = new UpgradeToV3()
            .upgrade(
                new UpgradeToV2().upgrade(d1.registry, 10), AggregatorV3Interface(address(l1PriceFeed)), 25e18, 3 hours
            );
        HandOverToDao.Dao memory dao = new HandOverToDao().handOver(d1.registry, d1.vault, guardian);
        timelock = dao.timelock;
        governor = dao.governor;
        _stake(l1Registry, d1.loyalty, d1.vault, alice, 10);

        // L2: los mismos scripts, otro feed de precios y, al final, DeployToL2.
        sequencerFeed = new MockV3Aggregator(0, 0);
        DeployProtocol.Deployment memory d2 = new DeployProtocol().deploy(50);
        l2PriceFeed = new MockV3Aggregator(8, 2500e8);
        l2Registry = new UpgradeToV3()
            .upgrade(
                new UpgradeToV2().upgrade(d2.registry, 10), AggregatorV3Interface(address(l2PriceFeed)), 25e18, 3 hours
            );
        l2Loyalty = d2.loyalty;
        l2 = new DeployToL2()
            .goL2(l2Registry, messenger, address(timelock), AggregatorV3Interface(address(sequencerFeed)), guardian);

        // El secuenciador lleva dos horas en marcha y el precio es reciente.
        vm.warp(block.timestamp + 2 hours);
        l2PriceFeed.updateAnswer(2500e8);
        vm.roll(vm.getBlockNumber() + 1);
    }

    // ---------- Ayudantes ----------

    // `who` da de alta `amount` recursos en L1, deposita los puntos en el vault y se delega los votos.
    function _stake(RegistryV3 registry, LoyaltyToken loyalty, PointsVault vault, address who, uint256 amount)
        internal
    {
        uint256 fee = registry.registrationFee();
        vm.deal(who, 1 ether);
        vm.startPrank(who);
        for (uint256 i = 0; i < amount; i++) {
            registry.register{value: fee}("recurso");
        }
        loyalty.approve(address(vault), type(uint256).max);
        vault.deposit(loyalty.balanceOf(who), who);
        vault.delegate(who);
        vm.stopPrank();
    }

    // La propuesta de L1: el timelock envía por el mensajero una llamada al ejecutor de L2.
    function _proposal(bytes memory l2Call)
        internal
        view
        returns (address[] memory targets, uint256[] memory values, bytes[] memory calldatas)
    {
        targets = new address[](1);
        targets[0] = address(messenger);
        values = new uint256[](1);
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeCall(
            messenger.sendMessage,
            (address(l2.executor), abi.encodeCall(L2Executor.execute, (address(l2Registry), l2Call)), MESSAGE_GAS)
        );
    }

    // La DAO de L1 aprueba y ejecuta la propuesta: votación, cola y plazo del timelock.
    function _passOnL1(bytes memory l2Call) internal {
        (address[] memory targets, uint256[] memory values, bytes[] memory calldatas) = _proposal(l2Call);
        vm.prank(alice);
        uint256 id = governor.propose(targets, values, calldatas, "Cambiar la L2");
        vm.roll(vm.getBlockNumber() + governor.votingDelay() + 1);
        vm.prank(alice);
        governor.castVote(id, 1);
        vm.roll(vm.getBlockNumber() + governor.votingPeriod());
        governor.queue(targets, values, calldatas, keccak256("Cambiar la L2"));
        vm.warp(vm.getBlockTimestamp() + 2 days);
        governor.execute(targets, values, calldatas, keccak256("Cambiar la L2"));
    }

    function _registerOnL2(address who) internal returns (uint256) {
        uint256 fee = l2Registry.registrationFee();
        vm.deal(who, fee);
        vm.prank(who);
        return l2Registry.register{value: fee}("en L2");
    }

    // ---------- El feed del secuenciador ----------

    function test_RegistersOnL2WhileTheSequencerIsUp() public {
        uint256 id = _registerOnL2(carol);
        assertEq(l2Registry.getItem(id).registrant, carol);
        assertEq(address(l2Registry.priceFeed()), address(l2.feed), "el registro lee el feed del secuenciador");
    }

    function test_RevertWhen_TheSequencerIsDown() public {
        sequencerFeed.updateAnswer(1);
        vm.expectRevert(SequencerAwareFeed.SequencerDown.selector);
        l2Registry.registrationFee();
    }

    function test_RevertWhen_TheSequencerJustCameBack() public {
        sequencerFeed.updateAnswer(1);
        vm.warp(block.timestamp + 20 minutes);
        sequencerFeed.updateAnswer(0);
        uint256 upSince = block.timestamp;
        vm.warp(block.timestamp + 30 minutes);
        l2PriceFeed.updateAnswer(2600e8);
        vm.expectRevert(abi.encodeWithSelector(SequencerAwareFeed.GracePeriodNotOver.selector, upSince));
        l2Registry.registrationFee();
    }

    function test_PointsRegistrationsGoOnWhileDown() public {
        for (uint256 i = 0; i < 3; i++) {
            _registerOnL2(carol);
        }
        sequencerFeed.updateAnswer(1);
        vm.startPrank(carol);
        l2Loyalty.approve(address(l2Registry), l2Registry.POINTS_PRICE());
        uint256 id = l2Registry.registerWithPoints("con puntos");
        vm.stopPrank();
        assertEq(l2Registry.getItem(id).registrant, carol, "las altas con puntos no leen el precio");
    }

    // ---------- La DAO de L1 en la L2 ----------

    function test_HandOverLeavesOnlyTheExecutor() public view {
        bytes32 admin = l2Registry.DEFAULT_ADMIN_ROLE();
        assertTrue(l2Registry.hasRole(admin, address(l2.executor)));
        assertFalse(l2Registry.hasRole(admin, DEFAULT_SENDER), "quien despliega ya no es admin");
        assertTrue(l2Registry.hasRole(l2Registry.PAUSER_ROLE(), guardian));
        assertEq(l2.executor.l1Dao(), address(timelock));
    }

    function test_DaoChangesTheL2FeeFromL1() public {
        _passOnL1(abi.encodeCall(RegistryV3.setFeeConfig, (l2.feed, 30e18, 3 hours)));
        assertEq(messenger.sentCount(), 1, "el timelock envio el mensaje");
        (bool ok,) = messenger.relay(0);
        assertTrue(ok, "el ejecutor acepta el mensaje del timelock");
        assertEq(l2Registry.usdFee(), 30e18);
    }

    function test_RevertWhen_StrangerCallsTheExecutor() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(L2Executor.NotMessenger.selector, attacker));
        l2.executor.execute(address(l2Registry), abi.encodeCall(RegistryV3.setFeeConfig, (l2.feed, 1, 3 hours)));
    }

    function test_RevertWhen_AnotherL1SenderMessagesTheExecutor() public {
        bytes memory l2Call = abi.encodeCall(RegistryV3.setFeeConfig, (l2.feed, 1, 3 hours));
        vm.prank(attacker);
        messenger.sendMessage(
            address(l2.executor), abi.encodeCall(L2Executor.execute, (address(l2Registry), l2Call)), MESSAGE_GAS
        );
        (bool ok, bytes memory result) = messenger.relay(0);
        assertFalse(ok);
        assertEq(result, abi.encodeWithSelector(L2Executor.NotL1Dao.selector, attacker));
        assertEq(l2Registry.usdFee(), 25e18);
    }

    function test_GuardianPausesTheL2WithoutWaiting() public {
        vm.prank(guardian);
        l2Registry.pause();
        assertTrue(l2Registry.paused());
    }
}
