// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PointsToken} from "./PointsToken.sol";

// ¿Qué? Una tienda que cobra en puntos: con `approve` y `buy` (dos transacciones) o con un
//   `permit` firmado y `buyWithPermit` (una).
// ¿Para qué? Practicar ERC-2612 desde el lado del contrato que gasta: usar la firma y
//   defenderse de quien la envía antes.
// ¿Impacto? La tienda solo cobra lo que la allowance permite: si el permit falla, el cobro
//   revierte igual, así que ignorar el fallo del permit no regala nada.
contract Shop {
    using SafeERC20 for PointsToken;

    uint256 public constant PRICE = 50 ether;
    PointsToken public immutable TOKEN;

    mapping(address => uint256) public purchases;

    event Purchased(address indexed buyer, uint256 price);

    constructor(PointsToken token) {
        TOKEN = token;
    }

    /// @notice Compra con una allowance dada antes con `approve`.
    function buy() external {
        _buy(msg.sender);
    }

    /// @notice Compra en una sola transacción con un permit firmado por quien llama.
    /// @param deadline Hasta cuándo vale el permit (timestamp).
    function buyWithPermit(uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        // PASO 2: usar el permit y cobrar. Si alguien ya envió esta firma al token, el permit
        //   revierte, pero la allowance ya está dada: se ignora el fallo y se cobra igual.
        revert("TODO: Paso 2");
        //> try TOKEN.permit(msg.sender, address(this), PRICE, deadline, v, r, s) {} catch {}
        //> _buy(msg.sender);
    }

    // Cobra PRICE a `buyer` con la allowance que dio a la tienda y anota la compra.
    function _buy(address buyer) internal {
        // PASO 1: anotar y cobrar. `safeTransferFrom` revierte si la allowance no llega.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 1");
        //> purchases[buyer]++;
        //> emit Purchased(buyer, PRICE);
        //> TOKEN.safeTransferFrom(buyer, address(this), PRICE);
    }
}
