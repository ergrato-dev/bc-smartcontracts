// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {EntryPoint} from "@account-abstraction/contracts/core/EntryPoint.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {SimpleWallet} from "../src/SimpleWallet.sol";
import {WalletFactory} from "../src/WalletFactory.sol";

/// @notice Lo que la cuenta llama en los tests.
contract Counter {
    uint256 public count;

    function increment() external {
        count++;
    }
}

contract SimpleWalletTest is Test {
    EntryPoint internal entryPoint;
    WalletFactory internal factory;
    SimpleWallet internal wallet;
    Counter internal counter;

    address internal owner;
    uint256 internal ownerKey;
    address internal bundler = makeAddr("bundler");
    address internal attacker = makeAddr("attacker");

    function setUp() public {
        (owner, ownerKey) = makeAddrAndKey("owner");
        entryPoint = new EntryPoint();
        factory = new WalletFactory(entryPoint);
        wallet = new SimpleWallet(entryPoint, owner);
        counter = new Counter();
        vm.deal(address(wallet), 1 ether);
    }

    // ---------- Ayudantes ----------

    function _userOp(address sender, bytes memory callData) internal view returns (PackedUserOperation memory op) {
        op.sender = sender;
        op.nonce = entryPoint.getNonce(sender, 0);
        op.callData = callData;
        // ¿Qué? Dos límites de gas en una palabra: verificación (arriba) y llamada (abajo).
        op.accountGasLimits = bytes32((uint256(150_000) << 128) | 100_000);
        op.preVerificationGas = 50_000;
        // ¿Qué? Propina máxima (arriba) y precio máximo (abajo): 1 gwei los dos.
        op.gasFees = bytes32((uint256(1 gwei) << 128) | 1 gwei);
    }

    function _sign(PackedUserOperation memory op, uint256 key) internal view returns (PackedUserOperation memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, entryPoint.getUserOpHash(op));
        op.signature = abi.encodePacked(r, s, v);
        return op;
    }

    function _increment() internal view returns (bytes memory) {
        return abi.encodeCall(SimpleWallet.execute, (address(counter), 0, abi.encodeCall(Counter.increment, ())));
    }

    function _handle(PackedUserOperation memory op) internal {
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;
        vm.prank(bundler, bundler);
        entryPoint.handleOps(ops, payable(bundler));
    }

    // ---------- Paso 1: la firma ----------

    function test_Paso1_OwnerSignatureIsValid() public {
        PackedUserOperation memory op = _sign(_userOp(address(wallet), _increment()), ownerKey);
        bytes32 hash = entryPoint.getUserOpHash(op);
        vm.prank(address(entryPoint));
        assertEq(wallet.validateUserOp(op, hash, 0), 0);
    }

    function test_Paso1_StrangerSignatureFails() public {
        (, uint256 attackerKey) = makeAddrAndKey("attacker");
        PackedUserOperation memory op = _sign(_userOp(address(wallet), _increment()), attackerKey);
        bytes32 hash = entryPoint.getUserOpHash(op);
        vm.prank(address(entryPoint));
        assertEq(wallet.validateUserOp(op, hash, 0), 1);
    }

    function test_Paso1_GarbageSignatureFailsWithoutReverting() public {
        PackedUserOperation memory op = _userOp(address(wallet), _increment());
        op.signature = hex"c0ffee";
        bytes32 hash = entryPoint.getUserOpHash(op);
        vm.prank(address(entryPoint));
        assertEq(wallet.validateUserOp(op, hash, 0), 1);
    }

    // ---------- Paso 2: el prefund ----------

    function test_Paso2_HandleOpsRunsTheCall() public {
        _handle(_sign(_userOp(address(wallet), _increment()), ownerKey));
        assertEq(counter.count(), 1);
    }

    function test_Paso2_TheWalletPaysTheBundler() public {
        uint256 before = address(wallet).balance;
        _handle(_sign(_userOp(address(wallet), _increment()), ownerKey));
        uint256 paid = before - address(wallet).balance - entryPoint.balanceOf(address(wallet));
        assertGt(paid, 0);
        assertEq(bundler.balance, paid);
    }

    function test_Paso2_RevertWhen_TheSignatureIsBad() public {
        (, uint256 attackerKey) = makeAddrAndKey("attacker");
        PackedUserOperation memory op = _sign(_userOp(address(wallet), _increment()), attackerKey);
        vm.expectRevert(abi.encodeWithSelector(IEntryPoint.FailedOp.selector, 0, "AA24 signature error"));
        _handle(op);
    }

    function test_Paso2_RevertWhen_ReplayingAnOperation() public {
        PackedUserOperation memory op = _sign(_userOp(address(wallet), _increment()), ownerKey);
        _handle(op);
        vm.expectRevert(abi.encodeWithSelector(IEntryPoint.FailedOp.selector, 0, "AA25 invalid account nonce"));
        _handle(op);
    }

    // ---------- Paso 3: solo el EntryPoint valida ----------

    function test_Paso3_RevertWhen_StrangerCallsValidate() public {
        PackedUserOperation memory op = _userOp(address(wallet), _increment());
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(SimpleWallet.NotEntryPoint.selector, attacker));
        wallet.validateUserOp(op, bytes32(0), 1 ether);
    }

    // ---------- Paso 4: solo el EntryPoint o el dueño ejecutan ----------

    function test_Paso4_RevertWhen_StrangerExecutes() public {
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(SimpleWallet.NotAllowed.selector, attacker));
        wallet.execute(attacker, 1 ether, "");
    }

    function test_OwnerExecutesDirectly() public {
        vm.prank(owner);
        wallet.execute(address(counter), 0, abi.encodeCall(Counter.increment, ()));
        assertEq(counter.count(), 1);
    }

    // ---------- Paso 5: la fábrica ----------

    function test_Paso5_TheAddressIsKnownBeforeDeploying() public {
        address predicted = factory.getAddress(owner, 7);
        assertEq(predicted.code.length, 0);
        vm.prank(address(entryPoint.senderCreator()));
        assertEq(address(factory.createWallet(owner, 7)), predicted);
    }

    function test_Paso5_TheFirstOperationDeploysTheWallet() public {
        address predicted = factory.getAddress(owner, 7);
        vm.deal(predicted, 1 ether);
        PackedUserOperation memory op = _userOp(predicted, _increment());
        op.initCode = abi.encodePacked(address(factory), abi.encodeCall(WalletFactory.createWallet, (owner, 7)));
        op.accountGasLimits = bytes32((uint256(1_000_000) << 128) | 100_000);
        _handle(_sign(op, ownerKey));
        assertGt(predicted.code.length, 0);
        assertEq(counter.count(), 1);
    }
}
