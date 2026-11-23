// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Una cartera que autoriza con `tx.origin`: la cuenta que firmó la transacción.
// ¿Para qué? Ser el blanco de tu phisher. **No la arregles**: los tests la necesitan rota.
// ¿Impacto? Cualquier contrato al que llame el dueño puede gastar su ETH en su nombre.
contract OriginWallet {
    address public immutable OWNER;

    error NotOwner(address caller);
    error TransferFailed();

    constructor() payable {
        OWNER = msg.sender;
    }

    /// @notice Envía `amount` wei a `to`. Solo el dueño... o eso parece.
    function withdraw(address to, uint256 amount) external {
        // ❌ tx.origin es quien firmó, no quien llama: un contrato intermedio pasa el control.
        // forge-lint: disable-next-line(tx-origin)
        if (tx.origin != OWNER) revert NotOwner(tx.origin);
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }
}
