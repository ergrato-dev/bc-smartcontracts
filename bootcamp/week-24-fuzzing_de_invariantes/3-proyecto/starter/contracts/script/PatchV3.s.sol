// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Script} from "forge-std/Script.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {RegistryV3} from "../src/RegistryV3.sol";

// ¿Qué? Despliega una implementación nueva de RegistryV3 con los hallazgos corregidos y apunta
//   el proxy a ella, sin inicializar nada: el storage no cambia.
// ¿Para qué? Llevar una corrección al registro ya desplegado. `UpgradeToV3` no sirve: llama a
//   `initializeV3`, que ya se usó y revertiría.
// ¿Impacto? Es una actualización como las demás: solo el administrador, y con el timelock de la
//   semana 13, tras su plazo.
// Uso: REGISTRY=0x... forge script script/PatchV3.s.sol --rpc-url <red> --account <keystore> --broadcast
contract PatchV3 is Script {
    /// @notice Corrige el registro de la variable de entorno REGISTRY.
    function run() external returns (address) {
        return patch(RegistryV3(vm.envAddress("REGISTRY")));
    }

    /// @notice Despliega la implementación corregida y actualiza el proxy a ella.
    /// @return implementation La dirección de la implementación nueva.
    function patch(RegistryV3 registry) public returns (address implementation) {
        vm.startBroadcast();
        implementation = address(new RegistryV3());
        registry.upgradeToAndCall(implementation, "");
        vm.stopBroadcast();
        // El slot de ERC-1967 dice a qué código apunta el proxy.
        bytes32 slot = vm.load(address(registry), ERC1967Utils.IMPLEMENTATION_SLOT);
        require(address(uint160(uint256(slot))) == implementation, "PatchV3: el proxy no apunta a la nueva");
    }
}
