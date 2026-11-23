// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// ¿Qué? Una tesorería pensada para vivir detrás de un proxy (semana 15): el dueño se fija en
//   `initialize`, no en el constructor, y puede barrer el ETH a donde quiera.
// ¿Para qué? Corregir los tres fallos de control de acceso más comunes de un contrato así.
// ¿Impacto? Quien sea `owner` decide a dónde va todo el ETH.
contract Treasury is Initializable {
    address public owner;

    event Swept(address indexed to, uint256 amount);

    error NotOwner(address caller);
    error TransferFailed();

    // PASO 4: cerrar la implementación.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        //> _disableInitializers();
    }

    /// @notice Fija el dueño. Una sola vez, al desplegar el proxy.
    // PASO 3: una sola vez. Descomenta la línea `//> initializer`.
    function initialize(address newOwner)
        external
        //> initializer
    {
        owner = newOwner;
    }

    /// @notice Acepta ETH.
    receive() external payable {}

    /// @notice Envía todo el ETH a `to`. Solo el dueño.
    function sweep(address to) external {
        // PASO 5: la comprobación que falta.
        //> if (msg.sender != owner) revert NotOwner(msg.sender);
        uint256 amount = address(this).balance;
        emit Swept(to, amount);
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }
}
