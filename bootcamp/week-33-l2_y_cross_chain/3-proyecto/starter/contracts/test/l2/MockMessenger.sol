// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ICrossDomainMessenger} from "../../src/ICrossDomainMessenger.sol";

// ¿Qué? Los dos mensajeros del rollup (el de L1 y el de L2) en uno: `sendMessage` guarda el
//   mensaje y `relay` lo entrega, con su remitente a la vista, como haría el rollup.
// ¿Para qué? Probar en un solo EVM el camino timelock de L1 → mensajero → ejecutor de L2.
// ¿Impacto? Como el mensajero del ejercicio 02, `relay` no revierte si la llamada falla:
//   devuelve `ok` y lo que respondió el destino.
contract MockMessenger is ICrossDomainMessenger {
    struct Message {
        address sender;
        address target;
        bytes message;
        uint32 gasLimit;
    }

    Message[] public sent;
    address private xSender;

    function sendMessage(address target, bytes calldata message, uint32 minGasLimit) external {
        sent.push(Message(msg.sender, target, message, minGasLimit));
    }

    function relay(uint256 index) external returns (bool ok, bytes memory result) {
        Message memory m = sent[index];
        xSender = m.sender;
        (ok, result) = m.target.call{gas: m.gasLimit}(m.message);
        xSender = address(0);
    }

    function xDomainMessageSender() external view returns (address) {
        require(xSender != address(0), "sin mensaje en curso");
        return xSender;
    }

    function sentCount() external view returns (uint256) {
        return sent.length;
    }
}
