// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Script} from "forge-std/Script.sol";
import {Registry} from "../src/Registry.sol";
import {RegistryV2} from "../src/RegistryV2.sol";

// ¿Qué? Actualiza un registro ya desplegado a RegistryV2: despliega la implementación nueva y
//   llama a `upgradeToAndCall` con `initializeV2` en la misma transacción.
// ¿Para qué? Que la actualización sea tan repetible como el despliegue, y que la simulación
//   detecte un fallo (otra cuenta, otra versión) antes de gastar gas.
// ¿Impacto? Solo funciona firmado por el administrador del registro.
// Uso: REGISTRY=0x... forge script script/UpgradeToV2.s.sol --rpc-url <red> --account <keystore> --broadcast
contract UpgradeToV2 is Script {
    /// @notice Actualiza el registro de REGISTRY con el máximo de MAX_PER_ACCOUNT (3 si no existe).
    function run() external returns (RegistryV2) {
        return upgrade(Registry(vm.envAddress("REGISTRY")), vm.envOr("MAX_PER_ACCOUNT", uint256(3)));
    }

    /// @notice Despliega RegistryV2 y actualiza el proxy a ella.
    /// @param registry El proxy del registro.
    /// @param maxPerAccount Altas máximas por cuenta en V2.
    function upgrade(Registry registry, uint256 maxPerAccount) public returns (RegistryV2) {
        // TODO: entre `vm.startBroadcast()` y `vm.stopBroadcast()`, despliega `RegistryV2` y llama
        //   a `registry.upgradeToAndCall` con su dirección y `initializeV2(maxPerAccount)` codificada
        //   con `abi.encodeCall`. Devuelve el mismo proxy visto como `RegistryV2`.
        revert("TODO: upgrade");
    }
}
