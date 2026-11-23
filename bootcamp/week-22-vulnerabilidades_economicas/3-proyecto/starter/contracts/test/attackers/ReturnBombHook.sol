// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC165} from "../../src/IERC165.sol";
import {IRegistrationHook} from "../../src/IRegistrationHook.sol";

// ¿Qué? Un hook que revierte con un motivo enorme: 64 000 bytes de ceros dentro de un custom
//   error. Hacerlo le cuesta menos que HOOK_GAS.
// ¿Para qué? Comprobar que el registro no copia al log todo lo que devuelve otro contrato. Cada
//   byte de un evento cuesta 8 de gas, y ese gas lo paga quien registra, no el hook.
// Hecho: no tienes que tocarlo.
contract ReturnBombHook is IRegistrationHook, IERC165 {
    uint256 public constant SIZE = 64_000;

    error Junk(bytes junk);

    /// @inheritdoc IRegistrationHook
    function onItemRegistered(uint256, address, string calldata) external pure {
        revert Junk(new bytes(SIZE));
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IRegistrationHook).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
