// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {BasePaymaster} from "@account-abstraction/contracts/core/BasePaymaster.sol";
import {_packValidationData} from "@account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {SimpleWallet} from "./SimpleWallet.sol";

/// @title Un paymaster que patrocina llamadas a un solo contrato
/// @notice Paga el gas de las cuentas que llaman a `target`, con un tope por operación, un
///         presupuesto por cuenta y una fecha de fin. El gas sale de su depósito en el EntryPoint.
contract SponsorPaymaster is BasePaymaster {
    /// @notice El gas máximo que acepta pagar en una operación, en wei.
    uint256 public constant MAX_COST = 0.001 ether;

    address public immutable target;
    uint256 public immutable budget;
    uint48 public immutable validUntil;

    /// @notice Lo que cada cuenta ya ha gastado del presupuesto.
    mapping(address account => uint256) public spentBy;

    error NotSponsored();
    error TooExpensive(uint256 maxCost);
    error OverBudget(address account, uint256 spent, uint256 maxCost);

    constructor(IEntryPoint entryPoint_, address target_, uint256 budget_, uint48 validUntil_)
        BasePaymaster(entryPoint_)
    {
        target = target_;
        budget = budget_;
        validUntil = validUntil_;
    }

    // ¿Qué? El EntryPoint pregunta si el paymaster paga esta operación, que como mucho costará
    //   `maxCost`. Revertir es decir que no.
    // ¿Impacto? Lo que devuelve en `context` le llega de vuelta en `_postOp`.
    function _validatePaymasterUserOp(PackedUserOperation calldata userOp, bytes32, uint256 maxCost)
        internal
        view
        override
        returns (bytes memory context, uint256 validationData)
    {
        _checkCall(userOp.callData);
        // PASO 2: un tope por operación, para que nadie gaste el depósito con límites de gas enormes.
        //> if (maxCost > MAX_COST) revert TooExpensive(maxCost);
        // PASO 4: el presupuesto de la cuenta, contando lo que esta operación puede llegar a costar.
        //> uint256 spent = spentBy[userOp.sender];
        //> if (spent + maxCost > budget) revert OverBudget(userOp.sender, spent, maxCost);
        context = abi.encode(userOp.sender);
        // PASO 5: la fecha de fin va en validationData; el EntryPoint la comprueba, no el paymaster.
        validationData = 0; // <- Paso 5
        //> validationData = _packValidationData(false, validUntil, 0);
    }

    // PASO 3: después de ejecutar, apunta en el presupuesto de la cuenta lo que costó de verdad.
    // ¿Impacto? Si `_postOp` revierte, el EntryPoint deshace la llamada pero cobra el gas igual.
    function _postOp(PostOpMode, bytes calldata context, uint256 actualGasCost, uint256) internal override {
        (context, actualGasCost); // <- Paso 3
        //> address account = abi.decode(context, (address));
        //> spentBy[account] += actualGasCost;
    }

    // PASO 1: solo `SimpleWallet.execute(target, 0, ...)`. Cualquier otra cosa: NotSponsored.
    function _checkCall(bytes calldata callData) internal view {
        revert("TODO: Paso 1");
        //> if (callData.length < 4 || bytes4(callData[:4]) != SimpleWallet.execute.selector) revert NotSponsored();
        //> (address to, uint256 value,) = abi.decode(callData[4:], (address, uint256, bytes));
        //> if (to != target || value != 0) revert NotSponsored();
    }
}
