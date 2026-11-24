// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Script, console} from "forge-std/Script.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {RegistryV3} from "../src/RegistryV3.sol";
import {LoyaltyToken} from "../src/LoyaltyToken.sol";
import {PointsVault} from "../src/PointsVault.sol";
import {ProtocolGovernor} from "../src/ProtocolGovernor.sol";
import {SequencerAwareFeed} from "../src/SequencerAwareFeed.sol";
import {L2Executor} from "../src/L2Executor.sol";
import {ICrossDomainMessenger} from "../src/ICrossDomainMessenger.sol";

// ¿Qué? Comprueba un despliegue del protocolo solo con lecturas, en L1 o en la L2: la versión,
//   quién administra, que quien desplegó no conserve nada y que cada contrato apunte a los
//   demás. Revierte con un error que dice qué está mal. No firma nada.
// ¿Para qué? Que "desplegado" signifique "desplegado y comprobado": lo ejecutas después de cada
//   despliegue, contra las direcciones de broadcast/, y su salida va al informe.
// Uso: REGISTRY=0x... VAULT=0x... TIMELOCK=0x... GOVERNOR=0x... DEPLOYER=0x... GUARDIAN=0x... \
//        forge script script/CheckDeployment.s.sol --sig "runL1()" --rpc-url <red>
//      REGISTRY=0x... EXECUTOR=0x... FEED=0x... L1_DAO=0x... DEPLOYER=0x... GUARDIAN=0x... \
//        forge script script/CheckDeployment.s.sol --sig "runL2()" --rpc-url <l2>
contract CheckDeployment is Script {
    /// @notice Lo que se comprueba en L1.
    struct L1 {
        RegistryV3 registry;
        PointsVault vault;
        TimelockController timelock;
        ProtocolGovernor governor;
        address deployer;
        address guardian;
    }

    /// @notice Lo que se comprueba en la L2.
    struct L2 {
        RegistryV3 registry;
        L2Executor executor;
        SequencerAwareFeed feed;
        ICrossDomainMessenger messenger;
        address l1Dao;
        address deployer;
        address guardian;
    }

    /// @notice La versión del registro que tiene que estar desplegada.
    uint256 public constant VERSION = 3;
    /// @notice El plazo mínimo del timelock: el de HandOverToDao.
    uint256 public constant MIN_DELAY = 2 days;

    error WrongVersion(uint256 version);
    error NotAdmin(address target, address expected);
    error DeployerStillAdmin(address target);
    error DeployerStillProposer();
    error NotPauser(address guardian);
    error NotProposer(address governor);
    error DelayTooShort(uint256 delay);
    error WrongWiring(string what, address actual);

    function runL1() external view {
        (, address deployer,) = vm.readCallers();
        checkL1(
            L1(
                RegistryV3(vm.envAddress("REGISTRY")),
                PointsVault(vm.envAddress("VAULT")),
                TimelockController(payable(vm.envAddress("TIMELOCK"))),
                ProtocolGovernor(payable(vm.envAddress("GOVERNOR"))),
                vm.envOr("DEPLOYER", deployer),
                vm.envAddress("GUARDIAN")
            )
        );
        console.log("L1 comprobado");
    }

    function runL2() external view {
        (, address deployer,) = vm.readCallers();
        checkL2(
            L2(
                RegistryV3(vm.envAddress("REGISTRY")),
                L2Executor(vm.envAddress("EXECUTOR")),
                SequencerAwareFeed(vm.envAddress("FEED")),
                ICrossDomainMessenger(vm.envOr("L2_MESSENGER", 0x4200000000000000000000000000000000000007)),
                vm.envAddress("L1_DAO"),
                vm.envOr("DEPLOYER", deployer),
                vm.envAddress("GUARDIAN")
            )
        );
        console.log("L2 comprobado");
    }

    /// @notice Revierte si el despliegue de L1 no es el que dejan los scripts hasta HandOverToDao.
    function checkL1(L1 memory d) public view {
        _checkRegistry(d.registry, address(d.timelock), d.deployer, d.guardian);
        // TODO (semana 34): el timelock. Quien despliega no tiene DEFAULT_ADMIN_ROLE en él (si no,
        //   DeployerStillAdmin(timelock)); el Governor tiene PROPOSER_ROLE (si no,
        //   NotProposer(governor)); quien despliega no lo tiene (si no, DeployerStillProposer()); y
        //   getMinDelay() es al menos MIN_DELAY (si no, DelayTooShort(plazo)).

        // Las conexiones: el Governor vota con el vault, el vault guarda los puntos del registro
        // y los puntos dan el bonus a ese vault.
        if (address(d.governor.timelock()) != address(d.timelock)) {
            revert WrongWiring("governor.timelock", d.governor.timelock());
        }
        if (address(d.governor.token()) != address(d.vault)) {
            revert WrongWiring("governor.token", address(d.governor.token()));
        }
        LoyaltyToken loyalty = d.registry.loyalty();
        if (d.vault.asset() != address(loyalty)) revert WrongWiring("vault.asset", d.vault.asset());
        if (loyalty.stakingVault() != address(d.vault)) {
            revert WrongWiring("loyalty.stakingVault", loyalty.stakingVault());
        }
        if (d.registry.hook() != address(loyalty)) revert WrongWiring("registry.hook", d.registry.hook());
    }

    /// @notice Revierte si el despliegue de la L2 no es el que deja DeployToL2.
    function checkL2(L2 memory d) public view {
        _checkRegistry(d.registry, address(d.executor), d.deployer, d.guardian);
        // TODO (semana 34): el ejecutor y el feed. executor.l1Dao() es d.l1Dao y
        //   executor.messenger() es d.messenger, y el registro lee d.feed en priceFeed(). Si no,
        //   WrongWiring("executor.l1Dao", ...), WrongWiring("executor.messenger", ...) y
        //   WrongWiring("registry.priceFeed", ...), con la dirección que tiene.
        if (d.registry.hook() != address(d.registry.loyalty())) revert WrongWiring("registry.hook", d.registry.hook());
    }

    // Lo común a las dos cadenas: la versión y los roles del registro.
    function _checkRegistry(RegistryV3 registry, address admin, address deployer, address guardian) internal view {
        // TODO (semana 34): la versión es VERSION (si no, WrongVersion(versión)); `admin` tiene
        //   DEFAULT_ADMIN_ROLE (si no, NotAdmin(registro, admin)); quien despliega no lo tiene (si
        //   no, DeployerStillAdmin(registro)); y el guardián tiene PAUSER_ROLE (si no,
        //   NotPauser(guardián)).
        (registry, admin, deployer, guardian);
    }
}
