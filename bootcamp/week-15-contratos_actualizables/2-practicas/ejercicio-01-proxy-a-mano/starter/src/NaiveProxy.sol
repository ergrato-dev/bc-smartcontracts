// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// ¿Qué? Un proxy ingenuo: guarda la dirección de la implementación en su slot 0.
// ¿Para qué? Ver la colisión de storage. Ya está completo: no lo cambies.
// ¿Impacto? La implementación escribe `count` en el slot 0 del proxy, que es este
//   `implementation`: el primer `increment` cambia la dirección y rompe el proxy.
contract NaiveProxy {
    address public implementation;

    // Ingenuo a propósito: ni comprueba la dirección.
    // forge-lint: disable-next-line(missing-zero-check)
    constructor(address impl) {
        implementation = impl;
    }

    fallback(bytes calldata) external returns (bytes memory) {
        return Address.functionDelegateCall(implementation, msg.data);
    }
}
