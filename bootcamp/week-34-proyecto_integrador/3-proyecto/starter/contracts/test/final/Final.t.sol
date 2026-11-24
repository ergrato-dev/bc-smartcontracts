// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {DeployProtocol} from "../../script/DeployProtocol.s.sol";
import {UpgradeToV2} from "../../script/UpgradeToV2.s.sol";
import {RegistryV2} from "../../src/RegistryV2.sol";
import {UpgradeToV3} from "../../script/UpgradeToV3.s.sol";
import {HandOverToDao} from "../../script/HandOverToDao.s.sol";
import {DeployToL2} from "../../script/DeployToL2.s.sol";
import {RegistryV3} from "../../src/RegistryV3.sol";
import {LoyaltyToken} from "../../src/LoyaltyToken.sol";
import {PointsVault} from "../../src/PointsVault.sol";
import {ProtocolGovernor} from "../../src/ProtocolGovernor.sol";
import {SequencerAwareFeed} from "../../src/SequencerAwareFeed.sol";
import {L2Executor} from "../../src/L2Executor.sol";
import {MockMessenger} from "../l2/MockMessenger.sol";
import {CheckDeployment} from "../../script/CheckDeployment.s.sol";

// ¿Qué? La entrega (semana 34): el protocolo entero, en L1 y en la L2, desplegado con los scripts
//   de siempre y comprobado con CheckDeployment. Cada test negativo estropea una sola cosa del
//   despliegue y espera el error que la nombra. El último recorre el protocolo de punta a punta.
// ¿Para qué? Que la comprobación de un despliegue esté probada como cualquier otro contrato: si
//   no detecta un despliegue malo, no sirve de nada que pase con uno bueno.
contract FinalTest is Test {
    uint32 constant MESSAGE_GAS = 300_000;

    MockMessenger messenger;
    TimelockController timelock;
    ProtocolGovernor governor;
    RegistryV3 l2Registry;
    LoyaltyToken l2Loyalty;
    MockV3Aggregator sequencerFeed;
    MockV3Aggregator l2PriceFeed;
    DeployToL2.L2 l2;
    CheckDeployment checker;
    CheckDeployment.L1 l1;
    CheckDeployment.L2 l2Check;
    LoyaltyToken l1Loyalty;
    PointsVault l1Vault;

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
        l1 = CheckDeployment.L1(l1Registry, d1.vault, timelock, governor, DEFAULT_SENDER, guardian);
        l1Loyalty = d1.loyalty;
        l1Vault = d1.vault;

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

        l2Check = CheckDeployment.L2(
            l2Registry, l2.executor, l2.feed, messenger, address(timelock), DEFAULT_SENDER, guardian
        );
        checker = new CheckDeployment();

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

    function _expectWiring(string memory what, address actual) internal {
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.WrongWiring.selector, what, actual));
    }

    // ---------- Los despliegues buenos ----------

    function test_ChecksTheL1Deployment() public view {
        checker.checkL1(l1);
    }

    function test_ChecksTheL2Deployment() public view {
        checker.checkL2(l2Check);
    }

    // ---------- L1 mal desplegado ----------

    function test_RevertWhen_TheL1RegistryIsNotV3() public {
        DeployProtocol.Deployment memory fresh = new DeployProtocol().deploy(50);
        RegistryV2 v2 = new UpgradeToV2().upgrade(fresh.registry, 10);
        l1.registry = RegistryV3(address(v2));
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.WrongVersion.selector, 2));
        checker.checkL1(l1);
    }

    function test_RevertWhen_TheDeployerIsStillAdminOnL1() public {
        bytes32 admin = l1.registry.DEFAULT_ADMIN_ROLE();
        vm.prank(address(timelock));
        l1.registry.grantRole(admin, DEFAULT_SENDER);
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.DeployerStillAdmin.selector, address(l1.registry)));
        checker.checkL1(l1);
    }

    function test_RevertWhen_TheGuardianCannotPause() public {
        bytes32 pauser = l1.registry.PAUSER_ROLE();
        vm.prank(address(timelock));
        l1.registry.revokeRole(pauser, guardian);
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.NotPauser.selector, guardian));
        checker.checkL1(l1);
    }

    function test_RevertWhen_TheDeployerAdministersTheTimelock() public {
        bytes32 admin = timelock.DEFAULT_ADMIN_ROLE();
        vm.prank(address(timelock));
        timelock.grantRole(admin, DEFAULT_SENDER);
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.DeployerStillAdmin.selector, address(timelock)));
        checker.checkL1(l1);
    }

    function test_RevertWhen_TheGovernorCannotPropose() public {
        bytes32 proposer = timelock.PROPOSER_ROLE();
        vm.prank(address(timelock));
        timelock.revokeRole(proposer, address(governor));
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.NotProposer.selector, address(governor)));
        checker.checkL1(l1);
    }

    function test_RevertWhen_TheDeployerCanPropose() public {
        bytes32 proposer = timelock.PROPOSER_ROLE();
        vm.prank(address(timelock));
        timelock.grantRole(proposer, DEFAULT_SENDER);
        vm.expectRevert(CheckDeployment.DeployerStillProposer.selector);
        checker.checkL1(l1);
    }

    function test_RevertWhen_TheGovernorVotesWithAnotherVault() public {
        l1.vault = new PointsVault(l1Loyalty);
        _expectWiring("governor.token", address(l1Vault));
        checker.checkL1(l1);
    }

    // ---------- L2 mal desplegada ----------

    function test_RevertWhen_TheDeployerIsStillAdminOnL2() public {
        bytes32 admin = l2Registry.DEFAULT_ADMIN_ROLE();
        vm.prank(address(l2.executor));
        l2Registry.grantRole(admin, DEFAULT_SENDER);
        vm.expectRevert(abi.encodeWithSelector(CheckDeployment.DeployerStillAdmin.selector, address(l2Registry)));
        checker.checkL2(l2Check);
    }

    function test_RevertWhen_TheL2ReadsTheRawFeed() public {
        vm.prank(address(l2.executor));
        l2Registry.setFeeConfig(AggregatorV3Interface(address(l2PriceFeed)), 25e18, 3 hours);
        _expectWiring("registry.priceFeed", address(l2PriceFeed));
        checker.checkL2(l2Check);
    }

    function test_RevertWhen_TheExecutorObeysAnotherDao() public {
        l2Check.l1Dao = attacker;
        _expectWiring("executor.l1Dao", address(timelock));
        checker.checkL2(l2Check);
    }

    // ---------- Hallazgos de la auditoría cruzada ----------

    // H-07 (reconocido): tras el despliegue nadie cobra las tasas; al tesorero lo nombra el timelock.
    function test_NoOneCollectsTheFeesUntilTheTimelockNamesATreasurer() public {
        bytes32 treasurer = l1.registry.TREASURER_ROLE();
        assertFalse(l1.registry.hasRole(treasurer, DEFAULT_SENDER), "quien despliega no cobra");
        assertFalse(l1.registry.hasRole(treasurer, address(timelock)), "el timelock no cobra");
        assertFalse(l1.registry.hasRole(treasurer, guardian), "el guardian no cobra");
        vm.prank(address(timelock));
        l1.registry.grantRole(treasurer, carol);
        uint256 fees = address(l1.registry).balance;
        vm.prank(carol);
        l1.registry.withdrawFees(payable(carol));
        assertEq(carol.balance, fees, "la tesorera que nombra el timelock cobra las tasas");
    }

    // ---------- De punta a punta ----------

    function test_FromAnL1RegistrationToANewL2Fee() public {
        // carol da de alta en L1: paga en ETH, recibe el certificado y los puntos.
        uint256 fee = l1.registry.registrationFee();
        vm.deal(carol, fee);
        vm.prank(carol);
        uint256 id = l1.registry.register{value: fee}("de punta a punta");
        assertEq(l1.registry.certificate().ownerOf(id), carol, "el certificado es de carol");
        assertGt(l1Loyalty.balanceOf(carol), 0, "carol tiene puntos");

        // La DAO de L1 sube la tasa de la L2 y el rollup entrega el mensaje.
        _passOnL1(abi.encodeCall(RegistryV3.setFeeConfig, (l2.feed, 30e18, 3 hours)));
        (bool ok,) = messenger.relay(0);
        assertTrue(ok, "el ejecutor acepta la propuesta");

        // En la L2, carol paga la tasa nueva: 30 dólares a 2500 dólares el ETH.
        l2PriceFeed.updateAnswer(2500e8);
        assertEq(l2Registry.registrationFee(), 0.012 ether, "la tasa nueva en ETH");
        _registerOnL2(carol);

        // Y después de todo, los dos despliegues siguen siendo los que deben.
        checker.checkL1(l1);
        checker.checkL2(l2Check);
    }
}
