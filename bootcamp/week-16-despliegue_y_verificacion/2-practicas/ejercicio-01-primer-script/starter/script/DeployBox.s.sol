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
        // PASO 4: leer el número inicial del entorno, con 1 si no existe.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 4");
        //> return deploy(vm.envOr("INITIAL_VALUE", uint256(1)));
    }

    /// @notice Despliega una Box y guarda `initial` en ella.
    /// @param initial El número inicial; no puede ser 0.
    function deploy(uint256 initial) public returns (Box box) {
        // PASO 3: rechazar un 0 antes de emitir nada. Descomenta la línea que empieza con `//> `.
        //> if (initial == 0) revert ZeroInitialValue();

        // PASO 1: desplegar la Box entre startBroadcast y stopBroadcast, con quien firma de dueño.
        // Borra la línea del revert y descomenta las cuatro líneas `//> ` del paso: las tres de
        // aquí y el `vm.stopBroadcast()` del final.
        revert("TODO: Paso 1");
        //> vm.startBroadcast();
        //> (, address signer,) = vm.readCallers();
        //> box = new Box(signer);

        // PASO 2: segunda transacción, firmada por la misma cuenta: guardar el número inicial.
        // Descomenta la línea que empieza con `//> `.
        //> box.store(initial);

        //> vm.stopBroadcast();
    }
}
