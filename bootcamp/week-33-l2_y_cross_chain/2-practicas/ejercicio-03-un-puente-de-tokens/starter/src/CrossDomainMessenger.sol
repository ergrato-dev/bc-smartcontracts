// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ICrossDomainMessenger} from "./ICrossDomainMessenger.sol";

/// @title Un mensajero entre dos cadenas
/// @notice Hay uno en cada cadena. `sendMessage` deja el mensaje en un evento; el sistema del rollup
///         lo lleva a la otra cadena y llama a `relayMessage` del otro mensajero, que lo entrega.
/// @dev ¿Qué? Una versión reducida del `CrossDomainMessenger` del OP Stack: sin ETH, sin versiones
///   y sin la prueba de inclusión, que aquí sustituye `relayer`.
///   ¿Para qué? Que un contrato de una cadena llame a uno de la otra y que el destino sepa quién
///   llamó al otro lado.
///   ¿Impacto? El destino solo puede fiarse de `xDomainMessageSender()` si el mensaje llegó por aquí.
contract CrossDomainMessenger is ICrossDomainMessenger {
    /// @notice El valor de `xDomainMessageSender` cuando no se entrega nada.
    address internal constant DEFAULT_SENDER = 0x000000000000000000000000000000000000dEaD;

    /// @notice Quien entrega en esta cadena los mensajes de la otra: el sistema del rollup.
    address public immutable relayer;
    /// @notice El número del próximo mensaje enviado desde esta cadena.
    uint256 public messageNonce;
    /// @notice Los mensajes entregados con éxito y los que fallaron, por su hash.
    mapping(bytes32 msgHash => bool) public successfulMessages;
    mapping(bytes32 msgHash => bool) public failedMessages;

    address private xSender = DEFAULT_SENDER;

    event SentMessage(address indexed target, address sender, bytes message, uint256 messageNonce, uint32 gasLimit);
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    error NotRelayer();
    error AlreadyRelayed(bytes32 msgHash);
    error ReentrantRelay();
    error NoMessageBeingRelayed();

    constructor(address relayer_) {
        relayer = relayer_;
    }

    /// @inheritdoc ICrossDomainMessenger
    function sendMessage(address target, bytes calldata message, uint32 minGasLimit) external {
        emit SentMessage(target, msg.sender, message, messageNonce, minGasLimit);
        messageNonce++;
    }

    /// @notice El identificador de un mensaje: lo que lo distingue de todos los demás.
    function hashMessage(uint256 nonce, address sender, address target, bytes calldata message, uint32 minGasLimit)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(nonce, sender, target, message, minGasLimit));
    }

    /// @notice Entrega un mensaje de la otra cadena: llama a `target` con `message`.
    /// @dev Si la llamada falla no revierte: apunta el fallo, y el mensaje se puede reintentar.
    function relayMessage(uint256 nonce, address sender, address target, bytes calldata message, uint32 minGasLimit)
        external
    {
        if (xSender != DEFAULT_SENDER) revert ReentrantRelay();
        bytes32 msgHash = hashMessage(nonce, sender, target, message, minGasLimit);
        if (msg.sender != relayer && !failedMessages[msgHash]) revert NotRelayer();
        if (successfulMessages[msgHash]) revert AlreadyRelayed(msgHash);

        xSender = sender;
        (bool ok,) = target.call{gas: minGasLimit}(message);
        xSender = DEFAULT_SENDER;
        if (ok) {
            successfulMessages[msgHash] = true;
            emit RelayedMessage(msgHash);
        } else {
            failedMessages[msgHash] = true;
            emit FailedRelayedMessage(msgHash);
        }
    }

    /// @inheritdoc ICrossDomainMessenger
    function xDomainMessageSender() external view returns (address) {
        if (xSender == DEFAULT_SENDER) revert NoMessageBeingRelayed();
        return xSender;
    }
}
