// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

/// @title La parte del mensajero entre cadenas que usan los contratos
/// @notice Las mismas dos funciones que el `CrossDomainMessenger` del OP Stack.
interface ICrossDomainMessenger {
    /// @notice Envía `message` (una llamada codificada) a `target` en la otra cadena.
    /// @param minGasLimit El gas con el que se ejecutará la llamada al otro lado.
    function sendMessage(address target, bytes calldata message, uint32 minGasLimit) external;

    /// @notice Quién envió, en la otra cadena, el mensaje que se está entregando ahora.
    function xDomainMessageSender() external view returns (address);
}
