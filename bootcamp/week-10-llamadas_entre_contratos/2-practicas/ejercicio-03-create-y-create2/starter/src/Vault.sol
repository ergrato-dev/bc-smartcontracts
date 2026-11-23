// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Una caja fuerte de ETH con un dueño fijo desde el despliegue.
// ¿Para qué? Ser el contrato que despliega VaultFactory, uno por cliente.
// ¿Impacto? Terminado: no lo cambies. El dueño forma parte del código de creación: con
//   otro dueño, la dirección de CREATE2 es otra.
contract Vault {
    address public immutable OWNER;

    error NotOwner(address caller);
    error TransferFailed();

    constructor(address owner) {
        OWNER = owner;
    }

    receive() external payable {}

    /// @notice Envía todo el ETH de la caja a su dueño. Solo el dueño.
    function withdraw() external {
        if (msg.sender != OWNER) revert NotOwner(msg.sender);
        (bool ok,) = OWNER.call{value: address(this).balance}("");
        if (!ok) revert TransferFailed();
    }
}
