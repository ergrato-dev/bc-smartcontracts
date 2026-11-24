// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ICrossDomainMessenger} from "./ICrossDomainMessenger.sol";

/// @title Lo común a las dos mitades del puente
/// @notice Cada mitad conoce el mensajero de su cadena y la dirección de la otra mitad.
abstract contract BridgeBase {
    /// @notice El gas con el que se ejecuta, al otro lado, la llamada de cada mensaje.
    uint32 public constant FINALIZE_GAS = 200_000;

    ICrossDomainMessenger public immutable messenger;
    /// @notice La otra mitad del puente, en la otra cadena.
    address public immutable otherBridge;

    error NotOtherBridge();

    constructor(ICrossDomainMessenger messenger_, address otherBridge_) {
        messenger = messenger_;
        otherBridge = otherBridge_;
    }

    // PASO 3: solo un mensaje que envió la otra mitad del puente.
    // ¿Impacto? Sin esta comprobación, cualquiera acuña tokens en L2 o saca los bloqueados en L1.
    modifier onlyOtherBridge() {
        revert("TODO: Paso 3");
        //> if (msg.sender != address(messenger) || messenger.xDomainMessageSender() != otherBridge) {
        //>     revert NotOtherBridge();
        //> }
        _;
    }
}
