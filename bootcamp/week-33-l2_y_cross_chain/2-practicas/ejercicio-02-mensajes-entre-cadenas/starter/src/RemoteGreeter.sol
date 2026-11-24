// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ICrossDomainMessenger} from "./ICrossDomainMessenger.sol";

/// @title Un saludo en la L2 que solo cambia una cuenta de L1
/// @notice `setGreeting` solo acepta mensajes que `l1Owner` envió desde L1 por el mensajero.
contract RemoteGreeter {
    ICrossDomainMessenger public immutable messenger;
    /// @notice La cuenta de L1 que manda aquí. En L2 no tiene código ni clave: solo es un remitente.
    address public immutable l1Owner;

    string public greeting = "hola";

    error NotMessenger(address caller);
    error NotL1Owner(address remoteSender);

    constructor(ICrossDomainMessenger messenger_, address l1Owner_) {
        messenger = messenger_;
        l1Owner = l1Owner_;
    }

    // PASO 5: dos comprobaciones. Quien llama es el mensajero, y el mensaje lo envió `l1Owner`.
    modifier onlyFromL1Owner() {
        revert("TODO: Paso 5");
        //> if (msg.sender != address(messenger)) revert NotMessenger(msg.sender);
        //> address remoteSender = messenger.xDomainMessageSender();
        //> if (remoteSender != l1Owner) revert NotL1Owner(remoteSender);
        _;
    }

    /// @notice Cambia el saludo. Solo por mensaje de `l1Owner`.
    function setGreeting(string calldata newGreeting) external onlyFromL1Owner {
        greeting = newGreeting;
    }
}
