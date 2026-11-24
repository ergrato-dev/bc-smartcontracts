// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {EntryPoint} from "@account-abstraction/contracts/core/EntryPoint.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {IPaymaster} from "@account-abstraction/contracts/interfaces/IPaymaster.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Counter} from "../src/Counter.sol";
import {SimpleWallet} from "../src/SimpleWallet.sol";
import {SponsorPaymaster} from "../src/SponsorPaymaster.sol";

contract SponsorPaymasterTest is Test {
    uint256 internal constant BUDGET = 0.001 ether;
    uint48 internal constant VALID_UNTIL = 2_000_000_000;

    EntryPoint internal entryPoint;
    SponsorPaymaster internal paymaster;
    SimpleWallet internal wallet;
    Counter internal counter;

    address internal owner;
    uint256 internal ownerKey;
    address internal bundler = makeAddr("bundler");
    address internal attacker = makeAddr("attacker");

    function setUp() public {
        (owner, ownerKey) = makeAddrAndKey("owner");
        entryPoint = new EntryPoint();
        counter = new Counter();
        paymaster = new SponsorPaymaster(entryPoint, address(counter), BUDGET, VALID_UNTIL);
        paymaster.deposit{value: 1 ether}();
        // ¿Qué? La cuenta no tiene ni un wei: todo el gas lo paga el paymaster.
        wallet = new SimpleWallet(entryPoint, owner);
    }

    // ---------- Ayudantes ----------

    function _userOp(bytes memory callData) internal view returns (PackedUserOperation memory op) {
        op.sender = address(wallet);
        op.nonce = entryPoint.getNonce(address(wallet), 0);
        op.callData = callData;
        op.accountGasLimits = bytes32((uint256(100_000) << 128) | 100_000);
        op.preVerificationGas = 50_000;
        op.gasFees = bytes32((uint256(1 gwei) << 128) | 1 gwei);
        // ¿Qué? Dirección del paymaster, gas de su validación y gas de su postOp.
        op.paymasterAndData = abi.encodePacked(address(paymaster), uint128(100_000), uint128(50_000));
    }

    function _maxCost(PackedUserOperation memory op) internal pure returns (uint256) {
        uint256 gas = uint128(uint256(op.accountGasLimits) >> 128) + uint128(uint256(op.accountGasLimits))
            + op.preVerificationGas + 100_000 + 50_000;
        return gas * uint128(uint256(op.gasFees));
    }

    function _call(address to, uint256 value) internal pure returns (bytes memory) {
        return abi.encodeCall(SimpleWallet.execute, (to, value, abi.encodeCall(Counter.increment, ())));
    }

    // ¿Qué? Firma antes de `vm.expectRevert`: `getUserOpHash` es una llamada externa y se la
    //   comería el expectRevert.
    function _sign(PackedUserOperation memory op) internal view returns (PackedUserOperation memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, entryPoint.getUserOpHash(op));
        op.signature = abi.encodePacked(r, s, v);
        return op;
    }

    function _handle(PackedUserOperation memory op) internal {
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;
        vm.prank(bundler, bundler);
        entryPoint.handleOps(ops, payable(bundler));
    }

    function _rejected(bytes memory reason) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(IEntryPoint.FailedOpWithRevert.selector, 0, "AA33 reverted", reason);
    }

    // ---------- Paso 1: qué se patrocina ----------

    function test_Paso1_TheWalletPaysNothing() public {
        _handle(_sign(_userOp(_call(address(counter), 0))));
        assertEq(counter.count(), 1);
        assertEq(address(wallet).balance, 0);
    }

    function test_Paso1_TheDepositPaysTheBundler() public {
        _handle(_sign(_userOp(_call(address(counter), 0))));
        assertEq(1 ether - entryPoint.balanceOf(address(paymaster)), bundler.balance);
    }

    function test_Paso1_RevertWhen_CallingAnotherTarget() public {
        PackedUserOperation memory op = _sign(_userOp(_call(attacker, 0)));
        vm.expectRevert(_rejected(abi.encodeWithSelector(SponsorPaymaster.NotSponsored.selector)));
        _handle(op);
    }

    function test_Paso1_RevertWhen_SendingValue() public {
        PackedUserOperation memory op = _sign(_userOp(_call(address(counter), 1)));
        vm.expectRevert(_rejected(abi.encodeWithSelector(SponsorPaymaster.NotSponsored.selector)));
        _handle(op);
    }

    function test_RevertWhen_StrangerCallsValidate() public {
        PackedUserOperation memory op = _userOp(_call(address(counter), 0));
        vm.prank(attacker);
        vm.expectRevert("Sender not EntryPoint");
        paymaster.validatePaymasterUserOp(op, bytes32(0), 0);
    }

    // ---------- Paso 2: el tope por operación ----------

    function test_Paso2_RevertWhen_GasLimitsAreHuge() public {
        PackedUserOperation memory op = _userOp(_call(address(counter), 0));
        op.accountGasLimits = bytes32((uint256(100_000) << 128) | 10_000_000);
        uint256 maxCost = _maxCost(op);
        op = _sign(op);
        vm.expectRevert(_rejected(abi.encodeWithSelector(SponsorPaymaster.TooExpensive.selector, maxCost)));
        _handle(op);
    }

    // ---------- Paso 3: lo que costó ----------

    function test_Paso3_PostOpRecordsTheRealCost() public {
        _handle(_sign(_userOp(_call(address(counter), 0))));
        // ¿Qué? `_postOp` ve el coste hasta antes de sí mismo: el bundler cobra algo más (el gas
        //   del propio postOp).
        assertGt(paymaster.spentBy(address(wallet)), 0);
        assertLt(paymaster.spentBy(address(wallet)), bundler.balance);
    }

    // ---------- Paso 4: el presupuesto ----------

    function test_Paso4_RevertWhen_TheBudgetIsUsedUp() public {
        for (uint256 i; i < 20; i++) {
            PackedUserOperation memory op = _sign(_userOp(_call(address(counter), 0)));
            uint256 spent = paymaster.spentBy(address(wallet));
            uint256 maxCost = _maxCost(op);
            if (spent + maxCost > BUDGET) {
                vm.expectRevert(
                    _rejected(
                        abi.encodeWithSelector(SponsorPaymaster.OverBudget.selector, address(wallet), spent, maxCost)
                    )
                );
                _handle(op);
                return;
            }
            _handle(op);
        }
        fail();
    }

    // ---------- Paso 5: la fecha de fin ----------

    function test_Paso5_ValidUntilGoesInTheValidationData() public {
        PackedUserOperation memory op = _userOp(_call(address(counter), 0));
        vm.prank(address(entryPoint));
        (, uint256 validationData) = paymaster.validatePaymasterUserOp(op, bytes32(0), 0);
        assertEq(uint48(validationData >> 160), VALID_UNTIL);
    }

    function test_Paso5_RevertWhen_TheSponsorshipExpired() public {
        vm.warp(uint256(VALID_UNTIL) + 1);
        PackedUserOperation memory op = _sign(_userOp(_call(address(counter), 0)));
        vm.expectRevert(abi.encodeWithSelector(IEntryPoint.FailedOp.selector, 0, "AA32 paymaster expired or not due"));
        _handle(op);
    }
}
