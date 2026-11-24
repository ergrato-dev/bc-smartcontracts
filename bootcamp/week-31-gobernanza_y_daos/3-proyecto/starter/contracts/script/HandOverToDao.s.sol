// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Script} from "forge-std/Script.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {Registry} from "../src/Registry.sol";
import {PointsVault} from "../src/PointsVault.sol";
import {ProtocolGovernor} from "../src/ProtocolGovernor.sol";

// ¿Qué? Pasa el registro a la DAO: despliega el timelock y el Governor, da al timelock el rol de
//   administrador del registro, deja al guardián solo la pausa y renuncia al rol de quien firma.
//   Cinco transacciones, firmadas por el administrador actual del registro.
// ¿Para qué? Cerrar el hallazgo de centralización de la semana 26: después de este script,
//   ninguna clave puede actualizar el registro ni cambiar su hook; solo una propuesta aprobada
//   que haya esperado el plazo del timelock.
// ¿Impacto? No tiene vuelta atrás: quien firma deja de ser administrador, y el timelock no tiene
//   más administrador que él mismo. Si algo sale mal después, solo lo arregla una propuesta.
// Uso: REGISTRY=0x... VAULT=0x... forge script script/HandOverToDao.s.sol --rpc-url <red> --account <keystore> --broadcast
contract HandOverToDao is Script {
    /// @notice El plazo mínimo entre aprobar una propuesta y ejecutarla.
    uint256 public constant MIN_DELAY = 2 days;

    /// @notice Lo que deja el traspaso.
    struct Dao {
        TimelockController timelock;
        ProtocolGovernor governor;
    }

    /// @notice Traspasa REGISTRY a una DAO que vota con las shares de VAULT. El guardián es
    ///   GUARDIAN, o quien firma si no existe.
    function run() external returns (Dao memory) {
        (, address deployer,) = vm.readCallers();
        return handOver(
            Registry(vm.envAddress("REGISTRY")), PointsVault(vm.envAddress("VAULT")), vm.envOr("GUARDIAN", deployer)
        );
    }

    /// @notice Despliega el timelock y el Governor y les traspasa el registro.
    /// @param registry El registro, con quien firma como administrador.
    /// @param vault El vault de puntos: sus shares son los votos.
    /// @param guardian Quien conserva PAUSER_ROLE para parar las altas sin esperar a la DAO.
    function handOver(Registry registry, PointsVault vault, address guardian) public returns (Dao memory dao) {
        vm.startBroadcast();
        (, address deployer,) = vm.readCallers();

        // El timelock necesita al Governor como proponente, y el Governor al timelock en su
        // constructor: se calcula la dirección del Governor, la segunda creación desde aquí.
        address[] memory proposers = new address[](1);
        proposers[0] = vm.computeCreateAddress(deployer, vm.getNonce(deployer) + 1);
        // Ejecutor address(0): cualquiera ejecuta lo que ya esperó el plazo. Sin administrador:
        // los roles del timelock solo los cambia una propuesta.
        address[] memory executors = new address[](1);
        dao.timelock = new TimelockController(MIN_DELAY, proposers, executors, address(0));
        dao.governor = new ProtocolGovernor(vault, dao.timelock);

        // TODO (semana 31): traspasa el registro a la DAO (teoría 03), en este orden:
        //   1. `DEFAULT_ADMIN_ROLE` del registro al timelock, con `registry.grantRole`.
        //   2. `PAUSER_ROLE` al guardián.
        //   3. Quien firma (`deployer`) renuncia a su `DEFAULT_ADMIN_ROLE` con `registry.renounceRole`.
        //   Después del 3, quien firma ya no puede dar roles: el orden importa.
        vm.stopBroadcast();
    }
}
