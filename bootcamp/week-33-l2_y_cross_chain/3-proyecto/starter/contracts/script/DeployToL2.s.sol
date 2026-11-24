// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Script} from "forge-std/Script.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {RegistryV3} from "../src/RegistryV3.sol";
import {SequencerAwareFeed} from "../src/SequencerAwareFeed.sol";
import {L2Executor} from "../src/L2Executor.sol";
import {ICrossDomainMessenger} from "../src/ICrossDomainMessenger.sol";

// ¿Qué? Termina el despliegue en una L2, después de DeployProtocol, UpgradeToV2 y UpgradeToV3:
//   pone delante del feed de precios el del secuenciador, despliega el ejecutor de la DAO de L1 y
//   le pasa el registro. Seis transacciones, firmadas por el administrador actual del registro.
// ¿Para qué? Que el registro de la L2 no cobre con precios viejos cuando el secuenciador se cae,
//   y que su único administrador sea la DAO de L1, como en L1.
// ¿Impacto? Como HandOverToDao: quien firma deja de ser administrador y no hay vuelta atrás.
// Uso: REGISTRY=0x... L1_DAO=0x... SEQUENCER_UPTIME_FEED=0x... forge script script/DeployToL2.s.sol --rpc-url <l2> --account <keystore> --broadcast
contract DeployToL2 is Script {
    /// @notice El mensajero de L2 del OP Stack: la misma dirección en OP, Base y sus testnets.
    address public constant L2_MESSENGER = 0x4200000000000000000000000000000000000007;

    /// @notice Lo que despliega el script.
    struct L2 {
        SequencerAwareFeed feed;
        L2Executor executor;
    }

    function run() external returns (L2 memory) {
        (, address deployer,) = vm.readCallers();
        return goL2(
            RegistryV3(vm.envAddress("REGISTRY")),
            ICrossDomainMessenger(vm.envOr("L2_MESSENGER", L2_MESSENGER)),
            vm.envAddress("L1_DAO"),
            AggregatorV3Interface(vm.envAddress("SEQUENCER_UPTIME_FEED")),
            vm.envOr("GUARDIAN", deployer)
        );
    }

    /// @notice Despliega el feed y el ejecutor y les pasa el registro.
    /// @param registry El registro de la L2, ya en V3, con quien firma como administrador.
    /// @param messenger El mensajero de la L2.
    /// @param l1Dao El timelock de la DAO en L1: el único remitente que acepta el ejecutor.
    /// @param sequencerFeed El feed de disponibilidad del secuenciador de esta L2.
    /// @param guardian Quien conserva PAUSER_ROLE en la L2.
    function goL2(
        RegistryV3 registry,
        ICrossDomainMessenger messenger,
        address l1Dao,
        AggregatorV3Interface sequencerFeed,
        address guardian
    ) public returns (L2 memory l2) {
        vm.startBroadcast();
        (, address deployer,) = vm.readCallers();
        l2.feed = new SequencerAwareFeed(sequencerFeed, registry.priceFeed());
        l2.executor = new L2Executor(messenger, l1Dao);
        // TODO (semana 33): el registro lee el feed nuevo (con la misma tasa y antigüedad), el
        //   ejecutor es el administrador, el guardián pausa y quien firma renuncia. Cuatro llamadas,
        //   como en HandOverToDao.
        (deployer, guardian);
        vm.stopBroadcast();
    }
}
