// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC165} from "../../src/IERC165.sol";
import {IRegistrationHook} from "../../src/IRegistrationHook.sol";

// ¿Qué? Un hook que revierte con los bytes exactos que le das, sin selector ni codificación ABI:
//   vacíos, 1 byte, 3, 4, 64 000...
// ¿Para qué? Probar `_notifyHook` con cualquier returndata, también con las que ningún `revert`
//   de Solidity produce (un motivo de 3 bytes no es ningún error válido).
// Hecho: no tienes que tocarlo.
contract RevertDataHook is IRegistrationHook, IERC165 {
    bytes public data;

    constructor(bytes memory revertData) {
        data = revertData;
    }

    /// @inheritdoc IRegistrationHook
    function onItemRegistered(uint256, address, string calldata) external view {
        bytes memory revertData = data;
        // `revert` de Solidity siempre codifica un error; en assembly, `revert(p, n)` devuelve los
        //   `n` bytes que empiezan en `p`, tal cual. Los datos de un `bytes` en memoria empiezan
        //   32 bytes después de su longitud.
        assembly ("memory-safe") {
            revert(add(revertData, 0x20), mload(revertData))
        }
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IRegistrationHook).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
