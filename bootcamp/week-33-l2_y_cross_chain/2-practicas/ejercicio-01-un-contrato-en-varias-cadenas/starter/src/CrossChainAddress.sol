// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

/// @title La misma dirección en todas las cadenas
/// @notice Despliega con la fábrica CREATE2 de Nick y calcula la dirección antes de desplegar.
/// @dev ¿Qué? La fábrica vive en la misma dirección en Ethereum, en casi todas las L2 y en anvil.
///   ¿Para qué? Con la misma sal y el mismo código de creación, el contrato queda en la misma
///   dirección en cada cadena, sin depender del nonce de quien despliega.
///   ¿Impacto? Una dirección igual en dos cadenas no es el mismo contrato: cada uno tiene su storage.
library CrossChainAddress {
    /// @notice La fábrica CREATE2 de Nick: recibe `sal ++ código de creación` y devuelve la dirección.
    address internal constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    error DeployFailed();

    // PASO 2: la dirección que dará CREATE2 desde la fábrica, sin desplegar nada.
    /// @notice La dirección en la que `deploy(salt, initCode)` deja el contrato, en cualquier cadena.
    function predict(bytes32 salt, bytes memory initCode) internal pure returns (address) {
        revert("TODO: Paso 2");
        //> bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), CREATE2_FACTORY, salt, keccak256(initCode)));
        //> return address(uint160(uint256(hash)));
    }

    /// @notice Despliega `initCode` (código de creación y argumentos del constructor) con `salt`.
    function deploy(bytes32 salt, bytes memory initCode) internal returns (address deployed) {
        (bool ok, bytes memory result) = CREATE2_FACTORY.call(abi.encodePacked(salt, initCode));
        if (!ok || result.length != 20) revert DeployFailed();
        deployed = address(bytes20(result));
    }
}
