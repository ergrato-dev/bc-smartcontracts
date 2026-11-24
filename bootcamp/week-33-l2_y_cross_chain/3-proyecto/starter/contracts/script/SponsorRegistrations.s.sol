// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Script} from "forge-std/Script.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {IEntryPoint as IOzEntryPoint} from "@openzeppelin/contracts/interfaces/IERC4337.sol";
import {Registry} from "../src/Registry.sol";
import {ProtocolAccount} from "../src/ProtocolAccount.sol";
import {RegistrationPaymaster} from "../src/RegistrationPaymaster.sol";

// ¿Qué? Despliega el código de las cuentas y el paymaster de las altas, le deposita ETH en el
//   EntryPoint, le pone stake y le da el paymaster a la DAO. Cinco transacciones.
// ¿Para qué? Que alguien con puntos y sin ETH pueda darse de alta: delega su EOA en
//   ProtocolAccount y el paymaster paga el gas de su primera alta.
// ¿Impacto? Tras el script, solo la DAO (el timelock) retira el depósito y el stake: quien firma
//   ya no es dueño del paymaster.
// Uso: REGISTRY=0x... DAO=0x... forge script script/SponsorRegistrations.s.sol --rpc-url <red> --account <keystore> --broadcast
contract SponsorRegistrations is Script {
    /// @notice El EntryPoint v0.8.0 en mainnet y en las testnets: la misma dirección en todas.
    address public constant ENTRY_POINT_V08 = 0x4337084D9E255Ff0702461CF8895CE9E3b5Ff108;
    /// @notice El ETH que paga las altas patrocinadas.
    uint256 public constant DEPOSIT = 0.5 ether;
    /// @notice El stake que los bundlers piden a un paymaster que guarda estado, y su plazo.
    uint256 public constant STAKE = 0.1 ether;
    uint32 public constant UNSTAKE_DELAY = 1 days;

    /// @notice Lo que despliega el script.
    struct Sponsorship {
        ProtocolAccount account;
        RegistrationPaymaster paymaster;
    }

    function run() external returns (Sponsorship memory) {
        return sponsor(
            IEntryPoint(vm.envOr("ENTRY_POINT", ENTRY_POINT_V08)),
            Registry(vm.envAddress("REGISTRY")),
            vm.envAddress("DAO")
        );
    }

    /// @notice Despliega la cuenta y el paymaster y le da el paymaster a `dao`.
    /// @param entryPoint El EntryPoint de ERC-4337 de la red.
    /// @param registry El registro cuyas altas se patrocinan.
    /// @param dao El dueño final del paymaster: el timelock de la DAO.
    function sponsor(IEntryPoint entryPoint, Registry registry, address dao) public returns (Sponsorship memory s) {
        vm.startBroadcast();
        s.account = new ProtocolAccount(IOzEntryPoint(address(entryPoint)));
        s.paymaster = new RegistrationPaymaster(entryPoint, registry);
        s.paymaster.deposit{value: DEPOSIT}();
        s.paymaster.addStake{value: STAKE}(UNSTAKE_DELAY);
        s.paymaster.transferOwnership(dao);
        vm.stopBroadcast();
    }
}
