// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// ¿Qué? Una tesorería con ETH que solo paga su dueño.
// ¿Para qué? Ser lo que gobierna la DAO: su dueño es el Governor (o el timelock, en el ejercicio
//   03), así que cada pago es una propuesta votada.
contract Treasury is Ownable {
    event Paid(address indexed to, uint256 amount);

    error PaymentFailed(address to, uint256 amount);

    constructor(address owner_) Ownable(owner_) {}

    receive() external payable {}

    /// @notice Envía `amount` wei a `to`. Solo el dueño.
    function pay(address payable to, uint256 amount) external onlyOwner {
        emit Paid(to, amount);
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert PaymentFailed(to, amount);
    }
}
