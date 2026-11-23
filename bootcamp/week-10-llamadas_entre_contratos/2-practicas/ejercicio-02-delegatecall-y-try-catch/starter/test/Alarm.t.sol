// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {IListener} from "../src/IListener.sol";
import {Alarm} from "../src/Alarm.sol";

// ¿Qué? Oyentes de prueba: uno que funciona y tres que fallan de formas distintas.
contract GoodListener is IListener {
    uint256 public lastRound;

    function onAlarm(uint256 round) external {
        lastRound = round;
    }
}

contract BrokenListener is IListener {
    function onAlarm(uint256) external pure {
        revert("roto");
    }
}

contract SnoozingListener is IListener {
    function onAlarm(uint256 round) external pure {
        revert Snoozed(round);
    }
}

contract GasBurner is IListener {
    function onAlarm(uint256) external pure {
        while (true) {}
    }
}

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
contract AlarmTest is Test {
    Alarm alarm;
    GoodListener good;
    address bob = makeAddr("bob");

    function setUp() public {
        alarm = new Alarm();
        good = new GoodListener();
    }

    function test_Step1_AddListener() public {
        alarm.addListener(address(good));
        assertEq(alarm.listenerCount(), 1);
    }

    function test_Step1_RevertWhen_ListenerHasNoCode() public {
        vm.expectRevert(abi.encodeWithSelector(Alarm.NoCode.selector, bob));
        alarm.addListener(bob);
    }

    function test_Step2_IsSnoozed() public view {
        assertTrue(alarm.isSnoozed(abi.encodeWithSelector(IListener.Snoozed.selector, 7)));
        assertFalse(alarm.isSnoozed(abi.encodeWithSignature("Error(string)", "roto")));
        assertFalse(alarm.isSnoozed(""));
    }

    function test_Step3_NotifiesEveryone() public {
        BrokenListener broken = new BrokenListener();
        SnoozingListener snoozing = new SnoozingListener();
        alarm.addListener(address(broken));
        alarm.addListener(address(snoozing));
        alarm.addListener(address(good));

        vm.expectEmit(address(alarm));
        emit Alarm.NotifyFailed(address(broken), 1, abi.encodeWithSignature("Error(string)", "roto"));
        vm.expectEmit(address(alarm));
        emit Alarm.ListenerSnoozed(address(snoozing), 1);
        vm.expectEmit(address(alarm));
        emit Alarm.Notified(address(good), 1);
        alarm.ring();

        assertEq(good.lastRound(), 1);
    }

    function test_Step3_GasBurnerIsBounded() public {
        GasBurner burner = new GasBurner();
        alarm.addListener(address(burner));
        alarm.addListener(address(good));

        vm.expectEmit(address(alarm));
        emit Alarm.NotifyFailed(address(burner), 1, "");
        uint256 before = gasleft();
        alarm.ring();
        assertLt(before - gasleft(), 150_000);
        assertEq(good.lastRound(), 1);
    }

    function test_Step4_MulticallAddsListeners() public {
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(Alarm.addListener, (address(good)));
        calls[1] = abi.encodeCall(Alarm.addListener, (address(new GoodListener())));
        alarm.multicall(calls);
        assertEq(alarm.listenerCount(), 2);
    }

    function test_Step4_MulticallKeepsTheSender() public {
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeCall(Alarm.addListener, (address(good)));
        bytes memory reason = abi.encodeWithSelector(Alarm.NotOwner.selector, bob);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Alarm.CallFailed.selector, 0, reason));
        alarm.multicall(calls);
    }

    function test_Step4_MulticallRejectsEther() public {
        bytes[] memory calls = new bytes[](0);
        (bool ok,) = address(alarm).call{value: 1 ether}(abi.encodeCall(Alarm.multicall, (calls)));
        assertFalse(ok);
    }
}
