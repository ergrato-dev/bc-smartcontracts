// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Script} from "forge-std/Script.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {RegistryV2} from "../src/RegistryV2.sol";
import {RegistryV3} from "../src/RegistryV3.sol";

// ¿Qué? Actualiza un registro V2 a RegistryV3: despliega la implementación nueva y llama a
//   `upgradeToAndCall` con `initializeV3` en la misma transacción.
// ¿Para qué? Lo mismo que UpgradeToV2: repetible, y la simulación falla antes de gastar gas si
//   el feed no responde o la cuenta no es la administradora.
// ¿Impacto? Desde esta transacción, las altas con ETH cobran según el feed.
// Uso: REGISTRY=0x... PRICE_FEED=0x... forge script script/UpgradeToV3.s.sol --rpc-url <red> --account <keystore> --broadcast
contract UpgradeToV3 is Script {
    /// @notice Actualiza REGISTRY con el feed PRICE_FEED, USD_FEE (25 dólares si no existe) y
    ///   MAX_PRICE_AGE (3 horas si no existe).
    function run() external returns (RegistryV3) {
        return upgrade(
            RegistryV2(vm.envAddress("REGISTRY")),
            AggregatorV3Interface(vm.envAddress("PRICE_FEED")),
            vm.envOr("USD_FEE", uint256(25e18)),
            vm.envOr("MAX_PRICE_AGE", uint256(3 hours))
        );
    }

    /// @notice Despliega RegistryV3 y actualiza el proxy a ella.
    function upgrade(RegistryV2 registry, AggregatorV3Interface feed, uint256 usdFee, uint256 maxPriceAge)
        public
        returns (RegistryV3)
    {
        vm.startBroadcast();
        RegistryV3 implementation = new RegistryV3();
        registry.upgradeToAndCall(
            address(implementation), abi.encodeCall(RegistryV3.initializeV3, (feed, usdFee, maxPriceAge))
        );
        vm.stopBroadcast();
        RegistryV3 upgraded = RegistryV3(address(registry));
        // Si el feed no da un precio válido, la simulación para aquí y no se envía nada.
        upgraded.registrationFee();
        return upgraded;
    }
}
