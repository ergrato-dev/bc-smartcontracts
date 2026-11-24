// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Points} from "./Points.sol";

/// @title Una tienda que paga en puntos
/// @notice Cada compra cuesta `price` en ETH y da POINTS_PER_PURCHASE puntos. El dueño cambia el
///         precio y retira el ETH.
contract Shop is Ownable {
    uint256 public constant POINTS_PER_PURCHASE = 10e18;

    Points public immutable points;
    uint256 public price;

    event Purchased(address indexed buyer, uint256 paid);

    error WrongPayment(uint256 sent, uint256 price);
    error TransferFailed();

    constructor(Points points_, uint256 price_) Ownable(msg.sender) {
        points = points_;
        price = price_;
    }

    /// @notice Compra una vez: envía exactamente `price` y recibe los puntos.
    function buy() external payable {
        if (msg.value != price) revert WrongPayment(msg.value, price);
        emit Purchased(msg.sender, msg.value);
        points.mint(msg.sender, POINTS_PER_PURCHASE);
    }

    /// @notice Cambia el precio. Solo el dueño.
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    /// @notice Envía todo el ETH de la tienda a `to`. Solo el dueño.
    function withdraw(address payable to) external onlyOwner {
        (bool ok,) = to.call{value: address(this).balance}("");
        if (!ok) revert TransferFailed();
    }
}
