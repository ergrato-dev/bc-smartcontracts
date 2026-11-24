// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {BridgeBase} from "./BridgeBase.sol";
import {BridgedToken} from "./BridgedToken.sol";
import {ICrossDomainMessenger} from "./ICrossDomainMessenger.sol";
import {L1Bridge} from "./L1Bridge.sol";

/// @title La mitad de L2 del puente
/// @notice Acuña al llegar un depósito de L1 y quema al empezar una retirada.
contract L2Bridge is BridgeBase {
    BridgedToken public immutable token;

    event DepositFinalized(address indexed from, address indexed to, uint256 amount);
    event WithdrawalInitiated(address indexed from, address indexed to, uint256 amount);

    constructor(BridgedToken token_, ICrossDomainMessenger messenger_, address l1Bridge)
        BridgeBase(messenger_, l1Bridge)
    {
        token = token_;
    }

    // PASO 3: acuñar lo que se bloqueó en L1. Solo por mensaje de la otra mitad.
    /// @notice Termina un depósito que empezó en L1.
    function finalizeDeposit(address from, address to, uint256 amount) external onlyOtherBridge {
        revert("TODO: Paso 3");
        //> token.mint(to, amount);
        //> emit DepositFinalized(from, to, amount);
    }

    // PASO 4: quemar aquí y pedir a la otra mitad que devuelva lo mismo a `to`.
    /// @notice Saca `amount` de L2; `to` los recibe en L1 cuando la retirada termina.
    function withdraw(address to, uint256 amount) external {
        revert("TODO: Paso 4");
        //> token.burn(msg.sender, amount);
        //> messenger.sendMessage(
        //>     otherBridge, abi.encodeCall(L1Bridge.finalizeWithdrawal, (msg.sender, to, amount)), FINALIZE_GAS
        //> );
        //> emit WithdrawalInitiated(msg.sender, to, amount);
    }
}
