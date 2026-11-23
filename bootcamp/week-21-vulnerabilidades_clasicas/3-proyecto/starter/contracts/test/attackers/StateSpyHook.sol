// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC165} from "../../src/IERC165.sol";
import {IRegistrationHook} from "../../src/IRegistrationHook.sol";
import {Registry} from "../../src/Registry.sol";

// ¿Qué? Un hook espía: cuando el registro lo avisa de un alta, lee el estado del registro y del
//   certificado desde dentro de esa misma llamada.
// ¿Para qué? Comprobar que el registro llama a otros contratos solo con el estado ya escrito:
//   quien lea a mitad de un alta (reentrancy de solo lectura) ve el estado final, no uno a medias.
contract StateSpyHook is IRegistrationHook, IERC165 {
    Registry public immutable REGISTRY;
    /// @notice `count()` del registro durante el aviso.
    uint256 public seenCount;
    /// @notice `activeCount()` del registro durante el aviso.
    uint256 public seenActive;
    /// @notice El `registrant` del recurso avisado, leído con `getItem`.
    address public seenRegistrant;
    /// @notice El dueño del certificado del recurso avisado.
    address public seenCertificateOwner;

    constructor(Registry registry) {
        REGISTRY = registry;
    }

    /// @inheritdoc IRegistrationHook
    function onItemRegistered(uint256 id, address, string calldata) external {
        // TODO: guarda `REGISTRY.count()`, `REGISTRY.activeCount()`,
        //   `REGISTRY.getItem(id).registrant` y `REGISTRY.certificate().ownerOf(id)` en las cuatro
        //   variables `seen*`. Si el registro avisara antes de escribir el alta, `getItem`
        //   revertiría con ItemNotFound y `ownerOf` con ERC721NonexistentToken.
        revert("TODO: StateSpyHook");
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IRegistrationHook).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
