// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

// ¿Qué? Un proxy escrito a mano: reenvía toda llamada a la implementación con
//   `delegatecall` y guarda la implementación y el administrador en los slots de EIP-1967.
// ¿Para qué? Ver todas las piezas de un proxy antes de usar los de OpenZeppelin.
// ¿Impacto? El estado vive aquí y el código en la implementación: cambiar la implementación
//   cambia el código sin perder el estado ni la dirección.
contract Proxy {
    // keccak256("eip1967.proxy.implementation") - 1
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    // keccak256("eip1967.proxy.admin") - 1
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event Upgraded(address indexed implementation);

    error NotAdmin(address caller);
    error NotAContract(address implementation);

    constructor(address impl) {
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = msg.sender;
        _setImplementation(impl);
    }

    /// @notice Cambia la implementación. Solo el administrador.
    /// @param newImplementation Un contrato con código.
    function upgradeTo(address newImplementation) external {
        // PASO 3: solo el administrador cambia la implementación.
        revert("TODO: Paso 3");
        //> if (msg.sender != StorageSlot.getAddressSlot(ADMIN_SLOT).value) revert NotAdmin(msg.sender);
        //> _setImplementation(newImplementation);
    }

    // Toda llamada a una función que el proxy no tiene llega aquí y se reenvía.
    fallback(bytes calldata) external returns (bytes memory) {
        // PASO 2: ejecutar el código de la implementación sobre el storage de este proxy.
        revert("TODO: Paso 2");
        //> return Address.functionDelegateCall(_implementation(), msg.data);
    }

    function _implementation() internal view returns (address) {
        // PASO 1: leer la implementación de su slot de EIP-1967.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 1");
        //> return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    function _setImplementation(address newImplementation) internal {
        if (newImplementation.code.length == 0) revert NotAContract(newImplementation);
        // PASO 1: escribir la implementación en su slot de EIP-1967.
        //> StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
        // `code.length` lee el código de la dirección, no la llama: no hay reentrada.
        // forge-lint: disable-next-line(reentrancy-events)
        emit Upgraded(newImplementation);
    }
}
