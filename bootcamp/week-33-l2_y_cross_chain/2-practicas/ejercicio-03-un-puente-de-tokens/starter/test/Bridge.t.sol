// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test, Vm} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {CrossDomainMessenger} from "../src/CrossDomainMessenger.sol";
import {BridgeBase} from "../src/BridgeBase.sol";
import {BridgedToken} from "../src/BridgedToken.sol";
import {L1Bridge} from "../src/L1Bridge.sol";
import {L2Bridge} from "../src/L2Bridge.sol";

contract Points is ERC20 {
    constructor() ERC20("Puntos", "PTS") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// ¿Qué? L1 y L2 en un solo EVM, como en el ejercicio 02: `rollup` lleva cada mensaje de un
//   mensajero al otro. Las retiradas se entregan pasados siete días, como en un rollup optimista.
contract BridgeTest is Test {
    uint256 constant CHALLENGE_PERIOD = 7 days;

    address rollup = makeAddr("rollup");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address attacker = makeAddr("attacker");

    Points points;
    CrossDomainMessenger l1Messenger;
    CrossDomainMessenger l2Messenger;
    L1Bridge l1Bridge;
    BridgedToken l2Token;
    L2Bridge l2Bridge;

    function setUp() public {
        points = new Points();
        l1Messenger = new CrossDomainMessenger(rollup);
        l2Messenger = new CrossDomainMessenger(rollup);
        // Cada mitad necesita la dirección de la otra: se calculan antes de desplegar.
        uint256 nonce = vm.getNonce(address(this));
        address l2BridgeAddress = vm.computeCreateAddress(address(this), nonce + 2);
        l1Bridge = new L1Bridge(points, l1Messenger, l2BridgeAddress);
        l2Token = new BridgedToken(l2BridgeAddress);
        l2Bridge = new L2Bridge(l2Token, l2Messenger, address(l1Bridge));
        assertEq(address(l2Bridge), l2BridgeAddress);

        points.mint(alice, 100);
        vm.prank(alice);
        points.approve(address(l1Bridge), type(uint256).max);
    }

    // Entrega en `to` el último mensaje que salió de `from` (el único evento SentMessage grabado).
    function _deliver(CrossDomainMessenger from, CrossDomainMessenger to) internal {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].emitter != address(from) || logs[i].topics[0] != CrossDomainMessenger.SentMessage.selector) {
                continue;
            }
            address target = address(uint160(uint256(logs[i].topics[1])));
            (address sender, bytes memory message, uint256 nonce, uint32 gasLimit) =
                abi.decode(logs[i].data, (address, bytes, uint256, uint32));
            vm.prank(rollup);
            to.relayMessage(nonce, sender, target, message, gasLimit);
            return;
        }
        revert("sin mensaje que entregar");
    }

    function _deposit(address from, address to, uint256 amount) internal {
        vm.recordLogs();
        vm.prank(from);
        l1Bridge.deposit(to, amount);
        _deliver(l1Messenger, l2Messenger);
    }

    function _withdraw(address from, address to, uint256 amount) internal {
        vm.recordLogs();
        vm.prank(from);
        l2Bridge.withdraw(to, amount);
        vm.warp(block.timestamp + CHALLENGE_PERIOD);
        _deliver(l2Messenger, l1Messenger);
    }

    function test_Paso1_RevertWhen_StrangerMints() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(BridgedToken.NotBridge.selector, attacker));
        l2Token.mint(attacker, 1);
    }

    function test_Paso1_RevertWhen_StrangerBurns() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(BridgedToken.NotBridge.selector, attacker));
        l2Token.burn(alice, 0);
    }

    function test_Paso2_DepositLocksAndSends() public {
        vm.expectEmit(address(l1Messenger));
        emit CrossDomainMessenger.SentMessage(
            address(l2Bridge),
            address(l1Bridge),
            abi.encodeCall(L2Bridge.finalizeDeposit, (alice, bob, 40)),
            0,
            l1Bridge.FINALIZE_GAS()
        );
        vm.prank(alice);
        l1Bridge.deposit(bob, 40);
        assertEq(points.balanceOf(address(l1Bridge)), 40, "Paso 2: los puntos quedan bloqueados en L1");
        assertEq(points.balanceOf(alice), 60);
    }

    function test_Paso3_DepositMintsOnL2() public {
        _deposit(alice, bob, 40);
        assertEq(l2Token.balanceOf(bob), 40, "Paso 3: bob recibe en L2 lo que alice bloqueo en L1");
        assertEq(l2Token.totalSupply(), 40);
    }

    function test_Paso3_RevertWhen_StrangerFinalizesADeposit() public {
        vm.prank(attacker);
        vm.expectRevert(BridgeBase.NotOtherBridge.selector);
        l2Bridge.finalizeDeposit(attacker, attacker, 1000);
    }

    function test_Paso3_AFakeL1BridgeMintsNothing() public {
        // El atacante envía desde L1 el mismo mensaje que enviaría el puente, sin bloquear nada.
        vm.recordLogs();
        vm.prank(attacker);
        l1Messenger.sendMessage(
            address(l2Bridge), abi.encodeCall(L2Bridge.finalizeDeposit, (attacker, attacker, 1000)), 200_000
        );
        _deliver(l1Messenger, l2Messenger);
        assertEq(l2Token.balanceOf(attacker), 0, "Paso 3: el mensaje llega, pero no lo envio el puente");
    }

    function test_Paso4_WithdrawBurnsAndSends() public {
        _deposit(alice, bob, 40);
        vm.expectEmit(address(l2Messenger));
        emit CrossDomainMessenger.SentMessage(
            address(l1Bridge),
            address(l2Bridge),
            abi.encodeCall(L1Bridge.finalizeWithdrawal, (bob, bob, 15)),
            0,
            l2Bridge.FINALIZE_GAS()
        );
        vm.prank(bob);
        l2Bridge.withdraw(bob, 15);
        assertEq(l2Token.balanceOf(bob), 25, "Paso 4: lo que sale de L2 se quema");
    }

    function test_Paso5_WithdrawalReleasesOnL1() public {
        _deposit(alice, bob, 40);
        _withdraw(bob, bob, 15);
        assertEq(points.balanceOf(bob), 15, "Paso 5: bob recibe en L1 lo que quemo en L2");
        assertEq(points.balanceOf(address(l1Bridge)), 25);
    }

    function test_Paso5_RevertWhen_StrangerFinalizesAWithdrawal() public {
        _deposit(alice, bob, 40);
        vm.prank(attacker);
        vm.expectRevert(BridgeBase.NotOtherBridge.selector);
        l1Bridge.finalizeWithdrawal(attacker, attacker, 40);
    }

    /// Lo bloqueado en L1 respalda exactamente lo que circula en L2.
    function testFuzz_Paso5_LockedBacksTheL2Supply(uint256 deposited, uint256 withdrawn) public {
        deposited = bound(deposited, 1, 100);
        withdrawn = bound(withdrawn, 0, deposited);
        _deposit(alice, alice, deposited);
        _withdraw(alice, alice, withdrawn);
        assertEq(points.balanceOf(address(l1Bridge)), l2Token.totalSupply(), "Paso 5: respaldo uno a uno");
        assertEq(points.balanceOf(alice), 100 - deposited + withdrawn);
    }
}
