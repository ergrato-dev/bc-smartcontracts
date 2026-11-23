// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Script} from "forge-std/Script.sol";
import {Box} from "../src/Box.sol";

// ¿Qué? Despliega una Box y guarda en ella su número inicial: dos transacciones.
// ¿Para qué? Escribir el despliegue en Solidity, probarlo con tests y lanzarlo igual en
//   anvil o en Sepolia.
// ¿Impacto? Solo lo que va entre `vm.startBroadcast()` y `vm.stopBroadcast()` se convierte
//   en transacciones firmadas.
// Uso: forge script script/DeployBox.s.sol --rpc-url <red> --account <keystore> --broadcast
contract DeployBox is Script {
    error ZeroInitialValue();

    /// @notice Despliega con el número de la variable de entorno INITIAL_VALUE.
    function run() external returns (Box) {
        return deploy(vm.envOr("INITIAL_VALUE", uint256(1)));
    }

    /// @notice Despliega una Box y guarda `initial` en ella.
    /// @param initial El número inicial; no puede ser 0.
    function deploy(uint256 initial) public returns (Box box) {
        if (initial == 0) revert ZeroInitialValue();

        vm.startBroadcast();
        (, address signer,) = vm.readCallers();
        box = new Box(signer);
        box.store(initial);
        vm.stopBroadcast();
    }
}
