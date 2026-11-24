// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Registry} from "./Registry.sol";

// ¿Qué? La versión 2 del registro: como mucho `maxPerAccount` altas por cuenta.
// ¿Para qué? Que una sola cuenta no ocupe toda la capacidad. Llega por actualización: el
//   proxy, los recursos, los puntos y los certificados siguen donde estaban.
// ¿Impacto? `maxPerAccount` va al final del storage, detrás de todo lo de V1. Las altas
//   anteriores cuentan: quien ya tenga `maxPerAccount` no registra más.
contract RegistryV2 is Registry {
    uint256 public maxPerAccount;

    error TooManyItems(address registrant, uint256 maxPerAccount);

    /// @notice Inicializa lo que trae V2. Se llama una vez, en `upgradeToAndCall`.
    /// @param newMaxPerAccount Cuántas altas admite cada cuenta. Mayor que 0.
    function initializeV2(uint256 newMaxPerAccount) external reinitializer(2) {
        require(newMaxPerAccount > 0, InvalidAmount(newMaxPerAccount));
        maxPerAccount = newMaxPerAccount;
    }

    /// @inheritdoc Registry
    function version() external pure virtual override returns (uint256) {
        return 2;
    }

    // Todas las altas (con ETH, en lote, con firma o con puntos) pasan por aquí.
    function _register(address registrant, string calldata label) internal override returns (uint256) {
        if (_idsOf[registrant].length >= maxPerAccount) revert TooManyItems(registrant, maxPerAccount);
        return super._register(registrant, label);
    }
}
