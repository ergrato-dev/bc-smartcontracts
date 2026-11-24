// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BridgeBase} from "./BridgeBase.sol";
import {ICrossDomainMessenger} from "./ICrossDomainMessenger.sol";
import {L2Bridge} from "./L2Bridge.sol";

/// @title La mitad de L1 de un puente de bloquear y acuñar
/// @notice Bloquea el token al depositar y lo devuelve al llegar una retirada de L2.
/// @dev ¿Impacto? Todo lo acuñado en L2 está respaldado por lo que hay aquí: es el bote que se ataca.
contract L1Bridge is BridgeBase {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;

    event DepositInitiated(address indexed from, address indexed to, uint256 amount);
    event WithdrawalFinalized(address indexed from, address indexed to, uint256 amount);

    constructor(IERC20 token_, ICrossDomainMessenger messenger_, address l2Bridge) BridgeBase(messenger_, l2Bridge) {
        token = token_;
    }

    // PASO 2: bloquear aquí y pedir a la otra mitad que acuñe lo mismo para `to`.
    /// @notice Deposita `amount` en el puente; `to` los recibe en L2.
    function deposit(address to, uint256 amount) external {
        revert("TODO: Paso 2");
        //> token.safeTransferFrom(msg.sender, address(this), amount);
        //> messenger.sendMessage(
        //>     otherBridge, abi.encodeCall(L2Bridge.finalizeDeposit, (msg.sender, to, amount)), FINALIZE_GAS
        //> );
        //> emit DepositInitiated(msg.sender, to, amount);
    }

    // PASO 5: devolver lo que se quemó en L2. Solo por mensaje de la otra mitad.
    /// @notice Termina una retirada que empezó en L2.
    function finalizeWithdrawal(address from, address to, uint256 amount) external onlyOtherBridge {
        revert("TODO: Paso 5");
        //> token.safeTransfer(to, amount);
        //> emit WithdrawalFinalized(from, to, amount);
    }
}
