// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? La misma cartera, autorizando con `msg.sender`: quien hace esta llamada.
// ¿Para qué? Que un contrato intermedio no herede los permisos de quien lo llamó.
contract Wallet {
    address public immutable OWNER;

    error NotOwner(address caller);
    error TransferFailed();

    constructor() payable {
        OWNER = msg.sender;
    }

    /// @notice Envía `amount` wei a `to`. Solo el dueño, directamente.
    // PASO 2: comprobar quién llama, no quién firmó.
    function withdraw(address to, uint256 amount) external {
        revert("TODO: Paso 2");
        //> if (msg.sender != OWNER) revert NotOwner(msg.sender);
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }
}
