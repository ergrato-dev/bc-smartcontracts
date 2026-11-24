// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {EntryPoint} from "@account-abstraction/contracts/core/EntryPoint.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Account as OzAccount} from "@openzeppelin/contracts/account/Account.sol";
import {ERC7821} from "@openzeppelin/contracts/account/extensions/draft-ERC7821.sol";
import {Execution} from "@openzeppelin/contracts/account/utils/draft-ERC7579Utils.sol";
import {DeployProtocol} from "../../script/DeployProtocol.s.sol";
import {UpgradeToV2} from "../../script/UpgradeToV2.s.sol";
import {UpgradeToV3} from "../../script/UpgradeToV3.s.sol";
import {HandOverToDao} from "../../script/HandOverToDao.s.sol";
import {SponsorRegistrations} from "../../script/SponsorRegistrations.s.sol";
import {Registry} from "../../src/Registry.sol";
import {RegistryV3} from "../../src/RegistryV3.sol";
import {LoyaltyToken} from "../../src/LoyaltyToken.sol";
import {ProtocolAccount} from "../../src/ProtocolAccount.sol";
import {RegistrationPaymaster} from "../../src/RegistrationPaymaster.sol";
import {FakeRegistry} from "../attackers/FakeRegistry.sol";

// ¿Qué? Las altas sin ETH de la semana 32: una EOA con puntos y sin ETH delega en ProtocolAccount
//   (EIP-7702) y el paymaster paga el gas de su primera alta, por el EntryPoint de ERC-4337.
// ¿Para qué? Que el depósito del paymaster solo pague lo que debe pagar: un alta por cuenta, de
//   quien tiene los puntos, con un tope de gas, y que solo la DAO lo retire.
contract SponsoredTest is Test {
    bytes32 constant BATCH_MODE = bytes32(uint256(0x01) << 248);
    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    EntryPoint entryPoint;
    RegistryV3 registry;
    LoyaltyToken loyalty;
    ProtocolAccount account;
    RegistrationPaymaster paymaster;
    address timelock;

    address alice;
    uint256 aliceKey;
    address bob = makeAddr("bob");
    address bundler = makeAddr("bundler");
    address attacker = makeAddr("attacker");

    function setUp() public {
        vm.warp(1_750_000_000);
        DeployProtocol.Deployment memory d = new DeployProtocol().deploy(50);
        MockV3Aggregator feed = new MockV3Aggregator(8, 2500e8);
        registry = new UpgradeToV3()
            .upgrade(new UpgradeToV2().upgrade(d.registry, 10), AggregatorV3Interface(address(feed)), 25e18, 3 hours);
        loyalty = d.loyalty;
        timelock = address(new HandOverToDao().handOver(d.registry, d.vault, bob).timelock);

        entryPoint = new EntryPoint();
        vm.deal(DEFAULT_SENDER, 1 ether);
        SponsorRegistrations.Sponsorship memory s =
            new SponsorRegistrations().sponsor(entryPoint, d.registry, timelock);
        account = s.account;
        paymaster = s.paymaster;

        // bob se da de alta cinco veces con ETH (50 puntos) y le pasa a alice los 30 de un alta.
        (alice, aliceKey) = makeAddrAndKey("alice");
        uint256 fee = registry.registrationFee();
        vm.deal(bob, 1 ether);
        vm.startPrank(bob);
        for (uint256 i = 0; i < 5; i++) {
            registry.register{value: fee}("de bob");
        }
        loyalty.transfer(alice, registry.POINTS_PRICE());
        vm.stopPrank();
    }

    // ---------- Ayudantes ----------

    // La llamada de un alta: `registerWithPermit` con un permit de `key` para el registro.
    function _registerCall(uint256 key) internal view returns (Execution memory) {
        address owner = vm.addr(key);
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH, owner, address(registry), registry.POINTS_PRICE(), loyalty.nonces(owner), deadline
            )
        );
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(key, keccak256(abi.encodePacked("\x19\x01", loyalty.DOMAIN_SEPARATOR(), structHash)));
        return Execution(
            address(registry), 0, abi.encodeCall(Registry.registerWithPermit, ("sin eth", deadline, v, r, s))
        );
    }

    function _userOp(address sender, Execution memory call) internal view returns (PackedUserOperation memory op) {
        Execution[] memory calls = new Execution[](1);
        calls[0] = call;
        op.sender = sender;
        op.nonce = entryPoint.getNonce(sender, 0);
        op.callData = abi.encodeCall(ERC7821.execute, (BATCH_MODE, abi.encode(calls)));
        op.accountGasLimits = bytes32((uint256(150_000) << 128) | 600_000);
        op.preVerificationGas = 50_000;
        op.gasFees = bytes32((uint256(1 gwei) << 128) | 1 gwei);
        // Sin gas para postOp: el paymaster no devuelve contexto y el EntryPoint no lo llama.
        op.paymasterAndData = abi.encodePacked(address(paymaster), uint128(100_000), uint128(0));
    }

    function _sign(PackedUserOperation memory op, uint256 key) internal view returns (PackedUserOperation memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, entryPoint.getUserOpHash(op));
        op.signature = abi.encodePacked(r, s, v);
        return op;
    }

    // El bundler envía la operación; la autorización de EIP-7702 de `key` viaja en su transacción.
    function _handle(PackedUserOperation memory op, uint256 delegateKey) internal {
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;
        if (delegateKey != 0) vm.signAndAttachDelegation(address(account), delegateKey);
        vm.prank(bundler, bundler);
        entryPoint.handleOps(ops, payable(bundler));
    }

    function _rejected(bytes memory reason) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(IEntryPoint.FailedOpWithRevert.selector, 0, "AA33 reverted", reason);
    }

    // ---------- Tests ----------

    function test_AliceRegistersWithoutEth() public {
        uint256 deposit = entryPoint.balanceOf(address(paymaster));
        _handle(_sign(_userOp(alice, _registerCall(aliceKey)), aliceKey), aliceKey);
        assertEq(registry.idsOf(alice).length, 1, "alice tiene su alta");
        assertEq(alice.balance, 0, "alice no tenia ni gasto ETH");
        assertEq(deposit - entryPoint.balanceOf(address(paymaster)), bundler.balance, "el deposito pago al bundler");
        assertTrue(paymaster.sponsored(alice));
    }

    function test_RevertWhen_SponsoringAnotherFunction() public {
        Execution memory retire = Execution(address(registry), 0, abi.encodeCall(Registry.retire, (1)));
        PackedUserOperation memory op = _sign(_userOp(alice, retire), aliceKey);
        vm.expectRevert(_rejected(abi.encodeWithSelector(RegistrationPaymaster.NotSponsored.selector)));
        _handle(op, aliceKey);
    }

    function test_RevertWhen_TheTargetIsNotTheRegistry() public {
        Execution memory call = _registerCall(aliceKey);
        call.target = address(new FakeRegistry());
        PackedUserOperation memory op = _sign(_userOp(alice, call), aliceKey);
        vm.expectRevert(_rejected(abi.encodeWithSelector(RegistrationPaymaster.NotSponsored.selector)));
        _handle(op, aliceKey);
    }

    function test_RevertWhen_SecondSponsoredRegistration() public {
        _handle(_sign(_userOp(alice, _registerCall(aliceKey)), aliceKey), aliceKey);
        uint256 missing = registry.POINTS_PRICE() - 10 ether;
        vm.prank(bob);
        loyalty.transfer(alice, missing);
        // ¿Qué? alice ya tiene puntos otra vez (10 del alta y 20 de bob), pero no otra alta gratis.
        PackedUserOperation memory op = _sign(_userOp(alice, _registerCall(aliceKey)), aliceKey);
        vm.expectRevert(_rejected(abi.encodeWithSelector(RegistrationPaymaster.AlreadySponsored.selector, alice)));
        _handle(op, 0);
    }

    function test_RevertWhen_TheAccountHasNoPoints() public {
        (address carol, uint256 carolKey) = makeAddrAndKey("carol");
        PackedUserOperation memory op = _sign(_userOp(carol, _registerCall(carolKey)), carolKey);
        vm.expectRevert(_rejected(abi.encodeWithSelector(RegistrationPaymaster.NotEnoughPoints.selector, carol)));
        _handle(op, carolKey);
    }

    function test_RevertWhen_GasLimitsAreHuge() public {
        PackedUserOperation memory op = _userOp(alice, _registerCall(aliceKey));
        op.accountGasLimits = bytes32((uint256(150_000) << 128) | 10_000_000);
        uint256 maxCost = (150_000 + 10_000_000 + 50_000 + 100_000) * 1 gwei;
        op = _sign(op, aliceKey);
        vm.expectRevert(_rejected(abi.encodeWithSelector(RegistrationPaymaster.TooExpensive.selector, maxCost)));
        _handle(op, aliceKey);
    }

    function test_RevertWhen_StrangerSignsTheOperation() public {
        (, uint256 attackerKey) = makeAddrAndKey("attacker");
        PackedUserOperation memory op = _sign(_userOp(alice, _registerCall(aliceKey)), attackerKey);
        vm.expectRevert(abi.encodeWithSelector(IEntryPoint.FailedOp.selector, 0, "AA24 signature error"));
        _handle(op, aliceKey);
    }

    function test_RevertWhen_StrangerCallsTheDelegatedAccount() public {
        _handle(_sign(_userOp(alice, _registerCall(aliceKey)), aliceKey), aliceKey);
        Execution[] memory calls = new Execution[](1);
        calls[0] = Execution(address(loyalty), 0, abi.encodeCall(loyalty.transfer, (attacker, 1)));
        // ¿Qué? Sin el EntryPoint y sin ser alice, nadie mueve lo de alice.
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(OzAccount.AccountUnauthorized.selector, attacker));
        ERC7821(alice).execute(BATCH_MODE, abi.encode(calls));
    }

    function test_OnlyTheDaoWithdrawsTheDeposit() public {
        // ¿Qué? El paymaster es Ownable2Step: el script deja a la DAO como dueña pendiente, y la
        //   DAO acepta con una propuesta. Hasta entonces, quien desplegó sigue siendo el dueño.
        assertEq(paymaster.pendingOwner(), timelock);
        assertEq(paymaster.owner(), DEFAULT_SENDER);
        vm.prank(timelock); // lo que hace la propuesta que llama a acceptOwnership
        paymaster.acceptOwnership();
        vm.prank(DEFAULT_SENDER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, DEFAULT_SENDER));
        paymaster.withdrawTo(payable(DEFAULT_SENDER), 1);
        vm.prank(timelock);
        paymaster.withdrawTo(payable(timelock), 1);
        assertEq(timelock.balance, 1);
    }
}
