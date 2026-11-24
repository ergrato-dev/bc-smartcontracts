// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC165} from "../../src/IERC165.sol";
import {IRegistrationHook} from "../../src/IRegistrationHook.sol";

// ¿Qué? Un hook que, al recibir el aviso, gasta todo el gas que le den.
// ¿Para qué? Comprobar que el registro no depende de su hook para dar altas: el tope de gas
//   (HOOK_GAS) y el `try` hacen que el hook pierda el aviso, pero el alta siga.
contract GasBurnerHook is IRegistrationHook, IERC165 {
    /// @notice El contador del bucle: escribir en storage hace que cada vuelta gaste gas.
    uint256 public burned;

    /// @inheritdoc IRegistrationHook
    function onItemRegistered(uint256, address, string calldata) external {
        while (true) {
            burned++;
        }
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IRegistrationHook).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
