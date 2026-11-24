// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test, Vm} from "forge-std/Test.sol";
import {CrossDomainMessenger} from "../src/CrossDomainMessenger.sol";
import {RemoteGreeter} from "../src/RemoteGreeter.sol";

// Un destino que apunta quién lo llamó y quién envió el mensaje en la otra cadena.
contract Recorder {
    address public caller;
    address public remoteSender;
    bool public broken;

    function record() external {
        require(!broken, "roto");
        caller = msg.sender;
        remoteSender = CrossDomainMessenger(msg.sender).xDomainMessageSender();
    }

    function setBroken(bool value) external {
        broken = value;
    }
}

// ¿Qué? L1 y L2 en un solo EVM: un mensajero para cada cadena. `rollup` hace de sistema del rollup:
//   lee el evento SentMessage de un mensajero y llama a `relayMessage` del otro.
contract MessengerTest is Test {
    struct Message {
        uint256 nonce;
        address sender;
        address target;
        bytes message;
        uint32 gasLimit;
    }

    uint32 constant GAS = 200_000;

    address rollup = makeAddr("rollup");
    address l1Owner = makeAddr("l1Owner");
    address attacker = makeAddr("attacker");

    CrossDomainMessenger l1Messenger;
    CrossDomainMessenger l2Messenger;
    Recorder recorder;
    RemoteGreeter greeter;

    function setUp() public {
        l1Messenger = new CrossDomainMessenger(rollup);
        l2Messenger = new CrossDomainMessenger(rollup);
        recorder = new Recorder();
        greeter = new RemoteGreeter(l2Messenger, l1Owner);
    }

    // `from` envía por el mensajero de L1; devuelve el mensaje tal como salió en el evento.
    function _send(address from, address target, bytes memory data) internal returns (Message memory m) {
        vm.recordLogs();
        vm.prank(from);
        l1Messenger.sendMessage(target, data, GAS);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1, "un evento por mensaje");
        assertEq(logs[0].topics[0], CrossDomainMessenger.SentMessage.selector);
        m.target = address(uint160(uint256(logs[0].topics[1])));
        (m.sender, m.message, m.nonce, m.gasLimit) = abi.decode(logs[0].data, (address, bytes, uint256, uint32));
    }

    function _relay(address as_, Message memory m) internal {
        vm.prank(as_);
        l2Messenger.relayMessage(m.nonce, m.sender, m.target, m.message, m.gasLimit);
    }

    function _hash(Message memory m) internal view returns (bytes32) {
        return l2Messenger.hashMessage(m.nonce, m.sender, m.target, m.message, m.gasLimit);
    }

    function test_Paso1_SendEmitsTheMessage() public {
        bytes memory data = abi.encodeCall(Recorder.record, ());
        vm.expectEmit(address(l1Messenger));
        emit CrossDomainMessenger.SentMessage(address(recorder), l1Owner, data, 0, GAS);
        vm.prank(l1Owner);
        l1Messenger.sendMessage(address(recorder), data, GAS);
    }

    function test_Paso1_EachMessageHasItsNonce() public {
        Message memory first = _send(l1Owner, address(recorder), "");
        Message memory second = _send(l1Owner, address(recorder), "");
        assertEq(first.nonce, 0);
        assertEq(second.nonce, 1, "Paso 1: el nonce avanza");
        assertEq(l1Messenger.messageNonce(), 2);
    }

    function test_Paso2_DeliversWithTheRemoteSender() public {
        Message memory m = _send(l1Owner, address(recorder), abi.encodeCall(Recorder.record, ()));
        _relay(rollup, m);
        assertEq(recorder.caller(), address(l2Messenger), "Paso 2: en L2 llama el mensajero");
        assertEq(recorder.remoteSender(), l1Owner, "Paso 2: y dice quien envio en L1");
        assertTrue(l2Messenger.successfulMessages(_hash(m)));
    }

    function test_Paso2_RevertWhen_NothingIsBeingRelayed() public {
        vm.expectRevert(CrossDomainMessenger.NoMessageBeingRelayed.selector);
        l2Messenger.xDomainMessageSender();
    }

    function test_Paso2_AFailedCallIsRecorded() public {
        recorder.setBroken(true);
        Message memory m = _send(l1Owner, address(recorder), abi.encodeCall(Recorder.record, ()));
        vm.expectEmit(address(l2Messenger));
        emit CrossDomainMessenger.FailedRelayedMessage(_hash(m));
        _relay(rollup, m);
        assertTrue(l2Messenger.failedMessages(_hash(m)), "Paso 2: el fallo queda apuntado");
        assertFalse(l2Messenger.successfulMessages(_hash(m)));
    }

    function test_Paso3_RevertWhen_RelayedTwice() public {
        Message memory m = _send(l1Owner, address(recorder), abi.encodeCall(Recorder.record, ()));
        _relay(rollup, m);
        vm.expectRevert(abi.encodeWithSelector(CrossDomainMessenger.AlreadyRelayed.selector, _hash(m)));
        _relay(rollup, m);
    }

    function test_Paso4_AnyoneRetriesAFailedMessage() public {
        recorder.setBroken(true);
        Message memory m = _send(l1Owner, address(recorder), abi.encodeCall(Recorder.record, ()));
        _relay(rollup, m);
        recorder.setBroken(false);
        _relay(attacker, m);
        assertEq(recorder.remoteSender(), l1Owner, "Paso 4: el reintento lleva el remitente original");
        assertTrue(l2Messenger.successfulMessages(_hash(m)));
    }

    function test_Paso4_RevertWhen_StrangerRelaysANewMessage() public {
        Message memory m = _send(l1Owner, address(recorder), abi.encodeCall(Recorder.record, ()));
        vm.expectRevert(CrossDomainMessenger.NotRelayer.selector);
        _relay(attacker, m);
    }

    function test_Paso4_RevertWhen_StrangerForgesTheSender() public {
        // El atacante inventa un mensaje "de l1Owner" que nunca salió de L1.
        Message memory forged =
            Message(7, l1Owner, address(greeter), abi.encodeCall(RemoteGreeter.setGreeting, ("hackeado")), GAS);
        vm.expectRevert(CrossDomainMessenger.NotRelayer.selector);
        _relay(attacker, forged);
    }

    function test_Paso5_L1OwnerSetsTheGreeting() public {
        Message memory m = _send(l1Owner, address(greeter), abi.encodeCall(RemoteGreeter.setGreeting, ("buenas")));
        _relay(rollup, m);
        assertEq(greeter.greeting(), "buenas", "Paso 5: el mensaje de l1Owner cambia el saludo");
    }

    function test_Paso5_RevertWhen_CalledDirectly() public {
        vm.prank(l1Owner);
        vm.expectRevert(abi.encodeWithSelector(RemoteGreeter.NotMessenger.selector, l1Owner));
        greeter.setGreeting("directo");
    }

    function test_Paso5_AnotherL1SenderChangesNothing() public {
        Message memory m = _send(attacker, address(greeter), abi.encodeCall(RemoteGreeter.setGreeting, ("hackeado")));
        _relay(rollup, m);
        assertEq(greeter.greeting(), "hola", "Paso 5: un mensaje de otra cuenta de L1 no cambia nada");
        assertTrue(l2Messenger.failedMessages(_hash(m)), "Paso 5: el mensajero lo apunta como fallido");
    }
}
