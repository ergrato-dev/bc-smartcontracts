// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ICrossDomainMessenger} from "./ICrossDomainMessenger.sol";

/// @title Las manos de la DAO de L1 en la L2
/// @notice Administra el registro de la L2 y solo obedece mensajes que el timelock de la DAO
///         envió desde L1 por el mensajero del rollup.
/// @dev ¿Qué? En la L2 no hay Governor: los votos están en L1. Una propuesta aprobada llama, desde
///   el timelock, a `sendMessage` del mensajero de L1, y el rollup entrega aquí la llamada.
///   ¿Para qué? Que la L2 tenga el mismo dueño que L1, con sus mismos plazos.
///   ¿Impacto? Quien engañe a estas dos comprobaciones administra el registro de la L2.
contract L2Executor {
    /// @notice El mensajero de esta L2 (en el OP Stack, el predeploy 0x4200…0007).
    ICrossDomainMessenger public immutable messenger;
    /// @notice El timelock de la DAO, en L1.
    address public immutable l1Dao;

    event Executed(address indexed target, bytes data);

    error NotMessenger(address caller);
    error NotL1Dao(address remoteSender);
    error ZeroAddress();

    constructor(ICrossDomainMessenger messenger_, address l1Dao_) {
        // Con l1Dao a cero nadie podría volver a administrar el registro de la L2.
        if (l1Dao_ == address(0)) revert ZeroAddress();
        messenger = messenger_;
        l1Dao = l1Dao_;
    }

    /// @notice Ejecuta en la L2 una llamada que aprobó la DAO de L1.
    /// @param target El contrato al que llamar.
    /// @param data La llamada codificada.
    function execute(address target, bytes calldata data) external returns (bytes memory) {
        // TODO (semana 33): las dos comprobaciones del ejercicio 02, paso 5. Quien llama es
        //   `messenger` (si no, NotMessenger(quien llama)) y el remitente en L1 es `l1Dao` (si no,
        //   NotL1Dao(remitente)).
        emit Executed(target, data);
        return Address.functionCall(target, data);
    }
}
