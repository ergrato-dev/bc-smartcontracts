// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Una subasta que, en cada puja, devuelve el ETH al pujador anterior en la misma llamada
//   (patrón push).
// ¿Para qué? Ser el blanco de tu bloqueador. **No la arregles**: los tests la necesitan rota.
// ¿Impacto? Si el pujador anterior no acepta ETH, nadie más puede pujar.
contract PushAuction {
    address public highestBidder;
    uint256 public highestBid;

    error BidTooLow(uint256 bid, uint256 highestBid);
    error RefundFailed(address bidder);

    /// @notice Puja con el ETH que envías. Tiene que superar la puja más alta.
    function bid() external payable {
        if (msg.value <= highestBid) revert BidTooLow(msg.value, highestBid);
        address previous = highestBidder;
        uint256 refund = highestBid;
        highestBidder = msg.sender;
        highestBid = msg.value;
        if (previous != address(0)) {
            // ❌ Si `previous` revierte al recibir, esta puja revierte también, y la siguiente.
            (bool ok,) = previous.call{value: refund}("");
            if (!ok) revert RefundFailed(previous);
        }
    }
}
