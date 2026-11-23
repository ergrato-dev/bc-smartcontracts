// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {DeployProtocol} from "../script/DeployProtocol.s.sol";
import {UpgradeToV2} from "../script/UpgradeToV2.s.sol";
import {UpgradeToV3} from "../script/UpgradeToV3.s.sol";
import {IRegistry} from "../src/IRegistry.sol";
import {Registry} from "../src/Registry.sol";
import {RegistryV3} from "../src/RegistryV3.sol";
import {RefundReentrant} from "./attackers/RefundReentrant.sol";

// Un contrato sin `receive`: no acepta que le devuelvan ETH.
contract NoReceive {
    function register(Registry registry, string calldata label) external payable returns (uint256) {
        return registry.register{value: msg.value}(label);
    }
}

// ¿Qué? Los ataques económicos de la semana 22 contra el protocolo actualizado a V3: el precio
//   que cambia entre que el usuario pide la tasa y su transacción entra en un bloque, quien
//   adelanta una orden firmada, la reentrancy por la devolución y el redondeo de la tasa.
// ¿Para qué? Que el orden de las transacciones y el redondeo dejen tests que fallen si un
//   cambio futuro los vuelve en contra de los usuarios o del registro.
contract EconomicAttacksTest is Test {
    DeployProtocol.Deployment d;
    RegistryV3 registry;
    MockV3Aggregator feed;
    address admin;
    address alice = makeAddr("alice");
    address mallory = makeAddr("mallory");
    address relayer = makeAddr("relayer");
    address member;
    uint256 memberKey;

    function setUp() public {
        vm.warp(1_750_000_000);
        d = new DeployProtocol().deploy(50);
        (, admin,) = vm.readCallers();
        feed = new MockV3Aggregator(8, 2500e8);
        registry = new UpgradeToV3()
            .upgrade(new UpgradeToV2().upgrade(d.registry, 3), AggregatorV3Interface(address(feed)), 25e18, 3 hours);
        (member, memberKey) = makeAddrAndKey("member");
        vm.deal(alice, 10 ether);
        vm.deal(mallory, 10 ether);
        vm.deal(relayer, 10 ether);
    }

    // La firma EIP-712 de `member` para dar de alta `label` con su nonce actual.
    function _signOrder(string memory label, uint256 deadline) internal view returns (bytes memory) {
        (, string memory name, string memory version,,,,) = registry.eip712Domain();
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(registry)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(registry.REGISTRATION_TYPEHASH(), member, keccak256(bytes(label)), registry.nonces(member), deadline)
        );
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(memberKey, keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash)));
        return abi.encodePacked(r, s, v);
    }

    function test_RevertWhen_ExactQuoteAfterPriceMove() public {
        uint256 quoted = registry.registrationFee();
        // El feed se actualiza antes de que entre el alta: ETH baja un 0,4 %.
        feed.updateAnswer(2490e8);
        uint256 fee = registry.registrationFee();
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.WrongFee.selector, fee, quoted));
        registry.register{value: quoted}("uno");
    }

    function test_PriceMoveWithinMarginKeepsRegister() public {
        uint256 quoted = registry.registrationFee();
        // Alice envía un 1 % de margen sobre lo que vio.
        uint256 sent = quoted * 101 / 100;
        feed.updateAnswer(2490e8);
        uint256 fee = registry.registrationFee();
        assertGt(fee, quoted);
        vm.prank(alice);
        registry.register{value: sent}("uno");
        // Paga la tasa nueva; el resto vuelve.
        assertEq(alice.balance, 10 ether - fee);
        assertEq(address(registry).balance, fee);
    }

    function test_RevertWhen_PriceMovesBeyondMargin() public {
        uint256 sent = registry.registrationFee() * 101 / 100;
        // ETH baja un 2 %: la tasa sube más que el margen.
        feed.updateAnswer(2450e8);
        uint256 fee = registry.registrationFee();
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IRegistry.WrongFee.selector, fee, sent));
        registry.register{value: sent}("uno");
    }

    function test_BatchRefundsExcess() public {
        string[] memory labels = new string[](3);
        labels[0] = "uno";
        labels[1] = "dos";
        labels[2] = "tres";
        uint256 fee = registry.registrationFee() * 3;
        vm.prank(alice);
        registry.registerBatch{value: 1 ether}(labels);
        assertEq(alice.balance, 10 ether - fee);
        assertEq(address(registry).balance, fee);
    }

    function test_BySigRefundsRelayer() public {
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory signature = _signOrder("firmado", deadline);
        uint256 fee = registry.registrationFee();
        vm.prank(relayer);
        uint256 id = registry.registerBySig{value: 1 ether}(member, "firmado", deadline, signature);
        // El recurso es de quien firmó; la devolución, de quien pagó.
        assertEq(registry.getItem(id).registrant, member);
        assertEq(relayer.balance, 10 ether - fee);
    }

    function test_FrontRunSignedOrderKeepsSigner() public {
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory signature = _signOrder("firmado", deadline);
        uint256 fee = registry.registrationFee();
        // Mallory ve la orden en la mempool y la envía antes que el relayer.
        vm.prank(mallory);
        uint256 id = registry.registerBySig{value: fee}(member, "firmado", deadline, signature);
        assertEq(registry.getItem(id).registrant, member);
        assertEq(d.certificate.ownerOf(id), member);
        // La del relayer llega después: el nonce ya se usó y la firma no cuadra.
        vm.prank(relayer);
        vm.expectPartialRevert(Registry.InvalidSigner.selector);
        registry.registerBySig{value: fee}(member, "firmado", deadline, signature);
    }

    function test_RefundReentrancyPaysEveryRegister() public {
        uint256 fee = registry.registrationFee();
        RefundReentrant attacker = new RefundReentrant(registry);
        vm.prank(mallory);
        uint256 firstId = attacker.attack{value: 2 * fee}();
        // La entrada anidada da el alta "dos" antes de que termine la de "uno".
        assertEq(attacker.secondId(), firstId + 1);
        assertEq(registry.count(), 2);
        assertEq(registry.idsOf(address(attacker)).length, 2);
        assertEq(address(registry).balance, 2 * fee);
        assertEq(address(attacker).balance, 0);
    }

    function test_RevertWhen_RefundRejected() public {
        uint256 fee = registry.registrationFee();
        NoReceive buyer = new NoReceive();
        vm.deal(address(buyer), 1 ether);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Registry.TransferFailed.selector, address(buyer), fee));
        buyer.register{value: 2 * fee}(registry, "uno");
        // Con la tasa exacta no hay nada que devolver: el alta funciona.
        vm.prank(alice);
        buyer.register{value: fee}(registry, "uno");
        assertEq(address(registry).balance, fee);
    }

    function testFuzz_FeeRoundsInFavorOfRegistry(uint256 price, uint256 usdFee) public {
        price = bound(price, 1e8, 1_000_000e8);
        usdFee = bound(usdFee, 1, 1_000_000e18);
        feed.updateAnswer(int256(price));
        vm.prank(admin);
        registry.setFeeConfig(AggregatorV3Interface(address(feed)), usdFee, 3 hours);
        uint256 fee = registry.registrationFee();
        // `fee` wei valen al menos `usdFee`, y un wei menos ya no llega.
        assertGe(fee * price, usdFee * 1e8);
        assertLt((fee - 1) * price, usdFee * 1e8);
    }
}
