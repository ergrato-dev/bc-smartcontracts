// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? La subasta corregida con el patrón pull: cada puja superada se apunta, y su dueño la
//   retira cuando quiere con `withdraw`.
// ¿Para qué? Que un pujador que rechaza ETH solo se perjudique a sí mismo.
// ¿Impacto? Un paso más para quien pierde la puja, a cambio de que nadie bloquee la subasta.
contract Auction {
    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public pendingReturns;

    error BidTooLow(uint256 bid, uint256 highestBid);
    error NothingToWithdraw();
    error TransferFailed();

    /// @notice Puja con el ETH que envías. Tiene que superar la puja más alta.
    function bid() external payable {
        if (msg.value <= highestBid) revert BidTooLow(msg.value, highestBid);
        // PASO 2: apuntar la puja superada en vez de enviarla.
        revert("TODO: Paso 2");
        //> pendingReturns[highestBidder] += highestBid;
        highestBidder = msg.sender;
        highestBid = msg.value;
    }

    /// @notice Retira tus pujas superadas.
    function withdraw() external {
        // PASO 3: retirar lo apuntado, con checks-effects-interactions.
        revert("TODO: Paso 3");
        //> uint256 amount = pendingReturns[msg.sender];
        //> if (amount == 0) revert NothingToWithdraw();
        //> pendingReturns[msg.sender] = 0;
        //> (bool ok,) = msg.sender.call{value: amount}("");
        //> if (!ok) revert TransferFailed();
    }
}
