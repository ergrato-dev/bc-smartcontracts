// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Script} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Registry} from "../src/Registry.sol";
import {IRegistry} from "../src/IRegistry.sol";
import {LoyaltyToken} from "../src/LoyaltyToken.sol";
import {Certificate} from "../src/Certificate.sol";
import {PointsVault} from "../src/PointsVault.sol";

// ¿Qué? Despliega el protocolo entero: implementación, token, certificado, proxy y vault de
//   puntos, conecta el token como hook y el vault como destino del bonus. Siete transacciones,
//   firmadas por la cuenta que recibe `forge script`.
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
        PointsVault vault;
    }

    /// @notice Despliega con la capacidad de la variable de entorno CAPACITY (50 si no existe).
    function run() external returns (Deployment memory) {
        return deploy(vm.envOr("CAPACITY", uint256(50)));
    }

    /// @notice Despliega los cinco contratos, pone el token como hook y le da el vault.
    /// @param capacity Capacidad inicial del registro.
    function deploy(uint256 capacity) public returns (Deployment memory d) {
        vm.startBroadcast();
        // Quien firma: en un script es la cuenta de --account; en un test, el remitente por defecto.
        (, address deployer,) = vm.readCallers();

        d.implementation = address(new Registry());
        // El proxy es la tercera creación desde aquí: token, certificado, proxy.
        address proxy = vm.computeCreateAddress(deployer, vm.getNonce(deployer) + 2);
        d.loyalty = new LoyaltyToken(proxy);
        d.certificate = new Certificate(IRegistry(proxy));
        bytes memory init = abi.encodeCall(Registry.initialize, (capacity, d.loyalty, d.certificate));
        d.registry = Registry(address(new ERC1967Proxy(d.implementation, init)));

        d.registry.setHook(address(d.loyalty));
        // TODO (semana 30): despliega `new PointsVault(d.loyalty)` en `d.vault` y fíjalo en el token
        //   con `d.loyalty.setStakingVault`. Quien firma es el admin del registro desde `initialize`.
        vm.stopBroadcast();
    }
}
