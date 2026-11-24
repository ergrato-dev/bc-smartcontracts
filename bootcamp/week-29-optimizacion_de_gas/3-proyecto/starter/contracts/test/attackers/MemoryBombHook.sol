// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC165} from "../../src/IERC165.sol";
import {IRegistrationHook} from "../../src/IRegistrationHook.sol";

// ¿Qué? La return bomb más grande que cabe en HOOK_GAS: revierte con SIZE bytes de ceros. No los
//   escribe: `revert(0, SIZE)` amplía su memoria hasta SIZE y devuelve lo que hay, ceros.
// ¿Para qué? Medir cuánto paga quien registra por la returndata de otro. Ampliar 192 000 bytes le
//   cuesta al hook unos 88 000 de gas, dentro de su tope de 100 000; copiarlos al registro le
//   costaría otro tanto, ya fuera del tope.
// Hecho: no tienes que tocarlo.
contract MemoryBombHook is IRegistrationHook, IERC165 {
    uint256 public constant SIZE = 192_000;

    /// @inheritdoc IRegistrationHook
    function onItemRegistered(uint256, address, string calldata) external pure {
        assembly {
            revert(0, SIZE)
        }
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IRegistrationHook).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
