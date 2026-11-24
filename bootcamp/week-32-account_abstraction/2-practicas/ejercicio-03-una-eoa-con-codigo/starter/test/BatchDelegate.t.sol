// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {BatchDelegate} from "../src/BatchDelegate.sol";
import {OldDelegate} from "../src/OldDelegate.sol";

contract Counter {
    uint256 public count;

    error Nope();

    function fail() external pure {
        revert Nope();
    }

    function increment() external {
        count++;
    }
}

contract BatchDelegateTest is Test {
    BatchDelegate internal implementation;
    Counter internal counter;

    address internal alice;
    uint256 internal aliceKey;
    address internal bob = makeAddr("bob");
    address internal relayer = makeAddr("relayer");

    function setUp() public {
        (alice, aliceKey) = makeAddrAndKey("alice");
        implementation = new BatchDelegate();
        counter = new Counter();
        vm.deal(alice, 10 ether);
    }

    // ---------- Ayudantes ----------

    // ¿Qué? Alice firma una autorización de EIP-7702 y la adjunta a la siguiente llamada: desde
    //   ese momento, su dirección tiene el código de `implementation`.
    function _delegate() internal {
        vm.signAndAttachDelegation(address(implementation), aliceKey);
        // La autorización viaja en una transacción; esta, vacía, la de cualquiera.
        vm.prank(relayer);
        (bool ok,) = alice.call("");
        assertTrue(ok);
    }

    function _calls() internal view returns (BatchDelegate.Call[] memory calls) {
        calls = new BatchDelegate.Call[](3);
        calls[0] = BatchDelegate.Call(address(counter), 0, abi.encodeCall(Counter.increment, ()));
        calls[1] = BatchDelegate.Call(address(counter), 0, abi.encodeCall(Counter.increment, ()));
        calls[2] = BatchDelegate.Call(bob, 1 ether, "");
    }

    function _signCalls(BatchDelegate.Call[] memory calls, uint256 deadline, uint256 key)
        internal
        view
        returns (bytes memory)
    {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(
            keccak256(abi.encode(block.chainid, alice, BatchDelegate(payable(alice)).nonce(), deadline, calls))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, digest);
        return abi.encodePacked(r, s, v);
    }

    // ---------- La delegación ----------

    function test_DelegationWritesTheDesignator() public {
        assertEq(alice.code.length, 0);
        _delegate();
        assertEq(alice.code, abi.encodePacked(hex"ef0100", address(implementation)));
    }

    function test_DelegatingToZeroClearsTheCode() public {
        _delegate();
        vm.signAndAttachDelegation(address(0), aliceKey);
        vm.prank(relayer);
        (bool ok,) = alice.call("");
        assertTrue(ok);
        assertEq(alice.code.length, 0);
    }

    // ---------- Paso 1: varias llamadas en una ----------

    function test_Paso1_AliceBatchesThreeCalls() public {
        _delegate();
        vm.prank(alice);
        BatchDelegate(payable(alice)).execute(_calls());
        assertEq(counter.count(), 2);
        assertEq(bob.balance, 1 ether);
    }

    function test_Paso1_OneFailingCallRevertsAll() public {
        _delegate();
        BatchDelegate.Call[] memory calls = _calls();
        calls[2] = BatchDelegate.Call(address(counter), 0, abi.encodeCall(Counter.fail, ()));
        vm.prank(alice);
        vm.expectRevert(Counter.Nope.selector);
        BatchDelegate(payable(alice)).execute(calls);
        assertEq(counter.count(), 0);
    }

    // ---------- Paso 2: solo la EOA ----------

    function test_Paso2_RevertWhen_StrangerExecutes() public {
        _delegate();
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(BatchDelegate.Unauthorized.selector, bob));
        BatchDelegate(payable(alice)).execute(_calls());
    }

    // ---------- Paso 3: firmada por alice, pagada por otro ----------

    function test_Paso3_RelayerSendsWhatAliceSigned() public {
        _delegate();
        BatchDelegate.Call[] memory calls = _calls();
        bytes memory signature = _signCalls(calls, block.timestamp + 1 hours, aliceKey);
        vm.prank(relayer);
        BatchDelegate(payable(alice)).executeWithSignature(calls, block.timestamp + 1 hours, signature);
        assertEq(counter.count(), 2);
        assertEq(alice.balance, 9 ether);
        assertEq(BatchDelegate(payable(alice)).nonce(), 1);
    }

    function test_Paso3_RevertWhen_ReplayingASignature() public {
        _delegate();
        BatchDelegate.Call[] memory calls = _calls();
        bytes memory signature = _signCalls(calls, block.timestamp + 1 hours, aliceKey);
        BatchDelegate(payable(alice)).executeWithSignature(calls, block.timestamp + 1 hours, signature);
        vm.expectRevert(BatchDelegate.BadSignature.selector);
        BatchDelegate(payable(alice)).executeWithSignature(calls, block.timestamp + 1 hours, signature);
    }

    function test_Paso3_RevertWhen_SignedForAnotherChain() public {
        _delegate();
        BatchDelegate.Call[] memory calls = _calls();
        bytes memory signature = _signCalls(calls, block.timestamp + 1 hours, aliceKey);
        vm.chainId(10);
        vm.expectRevert(BatchDelegate.BadSignature.selector);
        BatchDelegate(payable(alice)).executeWithSignature(calls, block.timestamp + 1 hours, signature);
    }

    function test_Paso3_RevertWhen_TheDeadlinePassed() public {
        _delegate();
        BatchDelegate.Call[] memory calls = _calls();
        uint256 deadline = block.timestamp + 1 hours;
        bytes memory signature = _signCalls(calls, deadline, aliceKey);
        vm.warp(deadline + 1);
        vm.expectRevert(abi.encodeWithSelector(BatchDelegate.Expired.selector, deadline));
        BatchDelegate(payable(alice)).executeWithSignature(calls, deadline, signature);
    }

    // ---------- Paso 4: el storage de la EOA ----------

    function test_Paso4_TheNonceLivesInItsOwnSlot() public {
        _delegate();
        BatchDelegate.Call[] memory calls = _calls();
        bytes memory signature = _signCalls(calls, block.timestamp + 1 hours, aliceKey);
        BatchDelegate(payable(alice)).executeWithSignature(calls, block.timestamp + 1 hours, signature);
        bytes32 slot = keccak256(abi.encode(uint256(keccak256("bootcamp.BatchDelegate")) - 1)) & ~bytes32(uint256(0xff));
        assertEq(uint256(vm.load(alice, slot)), 1);
        assertEq(uint256(vm.load(alice, bytes32(0))), 0);
    }

    function test_Paso4_OldStorageDoesNotBreakTheNonce() public {
        // ¿Qué? Antes, alice delegó en otro código, que escribió en el slot 0 de su storage.
        OldDelegate old = new OldDelegate();
        vm.signAndAttachDelegation(address(old), aliceKey);
        vm.prank(alice);
        OldDelegate(alice).save(42);
        // Ahora delega en BatchDelegate: el código cambia, el storage no.
        _delegate();
        assertEq(uint256(vm.load(alice, bytes32(0))), 42);
        assertEq(BatchDelegate(payable(alice)).nonce(), 0);
    }
}
