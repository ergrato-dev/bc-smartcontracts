// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Script} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Registry} from "../src/Registry.sol";
import {IRegistry} from "../src/IRegistry.sol";
import {LoyaltyToken} from "../src/LoyaltyToken.sol";
import {Certificate} from "../src/Certificate.sol";

// ¿Qué? Despliega el protocolo entero: implementación, token, certificado y proxy, y conecta
//   el token como hook. Cinco transacciones, firmadas por la cuenta que recibe `forge script`.
// ¿Para qué? Que desplegar en anvil o en Sepolia sea un solo comando repetible, con el mismo
//   orden siempre, en vez de una serie de `forge create` y `cast send` a mano.
// ¿Impacto? Quien firma queda como administrador del registro y puede actualizarlo.
// Uso: forge script script/DeployProtocol.s.sol --rpc-url <red> --account <keystore> --broadcast
contract DeployProtocol is Script {
    /// @notice Las direcciones que deja el despliegue.
    struct Deployment {
        address implementation;
        LoyaltyToken loyalty;
        Certificate certificate;
        Registry registry;
    }

    /// @notice Despliega con la capacidad de la variable de entorno CAPACITY (50 si no existe).
    function run() external returns (Deployment memory) {
        // TODO: devuelve `deploy` con la capacidad de CAPACITY. Pista: `vm.envOr`, con
        //   `uint256(50)` como valor por defecto (ejercicio 01).
        revert("TODO: run");
    }

    /// @notice Despliega los cuatro contratos y pone el token como hook.
    /// @param capacity Capacidad inicial del registro.
    function deploy(uint256 capacity) public returns (Deployment memory d) {
        // TODO: entre `vm.startBroadcast()` y `vm.stopBroadcast()`, y en este orden:
        //   1. quien firma, con `vm.readCallers()` (ejercicio 01);
        //   2. `new Registry()`, la implementación, en `d.implementation`;
        //   3. la dirección del proxy, que es la tercera creación a partir de aquí (token,
        //      certificado, proxy): `vm.computeCreateAddress(firmante, vm.getNonce(firmante) + 2)`;
        //   4. el token y el certificado, con esa dirección en su constructor;
        //   5. el `ERC1967Proxy` con la implementación y la llamada a `initialize`
        //      (`abi.encodeCall`), guardado en `d.registry` como `Registry`;
        //   6. `setHook` con el token.
        //   Pista: es lo mismo que hace `test/DeployRegistry.sol` con `startPrank`.
        revert("TODO: deploy");
    }
}
