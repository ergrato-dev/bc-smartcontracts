// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test, Vm} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Raffle} from "../src/Raffle.sol";

// ¿Qué? Tests del ejercicio 02 con el coordinador falso de Chainlink (VRFCoordinatorV2_5Mock).
// ¿Para qué? En el mock, la respuesta llega cuando el test llama a `fulfillRandomWordsWithOverride`
//   con el número que quiere: así cada test sabe quién gana.
contract RaffleTest is Test {
    bytes32 constant KEY_HASH = keccak256("carril de prueba");

    VRFCoordinatorV2_5Mock coordinator;
    Raffle raffle;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");

    function setUp() public {
        // Tasa base, precio del gas y precio del LINK en wei: lo que el mock cobra por respuesta.
        coordinator = new VRFCoordinatorV2_5Mock(0.002 ether, 1e9, 4e15);
        uint256 subId = coordinator.createSubscription();
        coordinator.fundSubscription(subId, 1000 ether);
        raffle = new Raffle(address(coordinator), subId, KEY_HASH);
        coordinator.addConsumer(subId, address(raffle));
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        vm.deal(carol, 1 ether);
    }

    function enterAll() internal {
        vm.prank(alice);
        raffle.enter{value: 0.01 ether}();
        vm.prank(bob);
        raffle.enter{value: 0.01 ether}();
        vm.prank(carol);
        raffle.enter{value: 0.01 ether}();
    }

    /// Responde `requestId` con `word` y devuelve si el callback del sorteo terminó sin revertir.
    function fulfill(uint256 requestId, uint256 word) internal returns (bool success) {
        uint256[] memory words = new uint256[](1);
        words[0] = word;
        vm.recordLogs();
        coordinator.fulfillRandomWordsWithOverride(requestId, address(raffle), words);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        // RandomWordsFulfilled(requestId, outputSeed, subId, payment, nativePayment, success, onlyPremium)
        (,,, success,) = abi.decode(logs[logs.length - 1].data, (uint256, uint96, bool, bool, bool));
    }

    function test_Paso1_Enter() public {
        vm.expectEmit(address(raffle));
        emit Raffle.Entered(alice);
        vm.prank(alice);
        raffle.enter{value: 0.01 ether}();
        assertEq(raffle.playerCount(), 1);
        assertEq(raffle.players(0), alice);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Raffle.WrongFee.selector, 0.02 ether));
        raffle.enter{value: 0.02 ether}();
    }

    function test_Paso1_RevertWhen_Full() public {
        for (uint256 i; i < raffle.MAX_PLAYERS(); i++) {
            raffle.enter{value: 0.01 ether}();
        }
        vm.expectRevert(Raffle.RaffleFull.selector);
        raffle.enter{value: 0.01 ether}();
    }

    function test_Paso2_Draw() public {
        vm.expectRevert(Raffle.NoPlayers.selector);
        raffle.draw();
        enterAll();
        vm.prank(alice);
        vm.expectRevert("Only callable by owner");
        raffle.draw();
        uint256 requestId = raffle.draw();
        assertEq(requestId, 1);
        assertEq(raffle.pendingRequestId(), 1);
        assertTrue(raffle.drawing());
        vm.prank(alice);
        vm.expectRevert(Raffle.DrawInProgress.selector);
        raffle.enter{value: 0.01 ether}();
    }

    function test_Paso3_Fulfill() public {
        enterAll();
        uint256 requestId = raffle.draw();
        // 7 % 3 = 1: gana el segundo jugador.
        assertTrue(fulfill(requestId, 7));
        assertEq(raffle.lastWinner(), bob);
        assertEq(raffle.prizes(bob), 0.03 ether);
        assertEq(raffle.playerCount(), 0);
        assertFalse(raffle.drawing());
        // Solo el coordinador puede responder.
        uint256[] memory words = new uint256[](1);
        vm.expectRevert(abi.encodeWithSignature("OnlyCoordinatorCanFulfill(address,address)", alice, coordinator));
        vm.prank(alice);
        raffle.rawFulfillRandomWords(requestId, words);
    }

    function test_Paso4_Withdraw() public {
        enterAll();
        uint256 requestId = raffle.draw();
        fulfill(requestId, 2);
        vm.prank(carol);
        raffle.withdraw();
        assertEq(carol.balance, 1 ether + 0.02 ether);
        assertEq(address(raffle).balance, 0);
        vm.prank(carol);
        vm.expectRevert(Raffle.NothingToWithdraw.selector);
        raffle.withdraw();
    }

    function test_Paso4_WinnerThatRejectsEth() public {
        // Un contrato sin `receive` gana: el sorteo termina igual; el que no puede cobrar es él.
        Rejecter rejecter = new Rejecter();
        rejecter.enter{value: 0.01 ether}(raffle);
        uint256 requestId = raffle.draw();
        assertTrue(fulfill(requestId, 0));
        assertEq(raffle.lastWinner(), address(rejecter));
        vm.expectRevert(Raffle.TransferFailed.selector);
        rejecter.withdraw(raffle);
    }

    function test_Paso5_CancelDraw() public {
        vm.expectRevert(Raffle.NoDrawPending.selector);
        raffle.cancelDraw();
        enterAll();
        uint256 oldRequest = raffle.draw();
        vm.expectRevert(abi.encodeWithSelector(Raffle.TooEarly.selector, block.timestamp + 1 hours));
        raffle.cancelDraw();
        vm.warp(block.timestamp + 1 hours);
        raffle.cancelDraw();
        assertFalse(raffle.drawing());
        assertEq(raffle.playerCount(), 3);
        // Se vuelve a pedir; la respuesta tardía de la petición vieja ya no vale.
        uint256 newRequest = raffle.draw();
        assertFalse(fulfill(oldRequest, 0));
        assertEq(raffle.lastWinner(), address(0));
        assertTrue(fulfill(newRequest, 1));
        assertEq(raffle.lastWinner(), bob);
    }
}

// Un jugador que no acepta ETH.
contract Rejecter {
    function enter(Raffle raffle) external payable {
        raffle.enter{value: msg.value}();
    }

    function withdraw(Raffle raffle) external {
        raffle.withdraw();
    }
}
