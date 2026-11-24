// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Script, console} from "forge-std/Script.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {Points} from "../src/Points.sol";
import {Shop} from "../src/Shop.sol";
import {Deploy} from "./Deploy.s.sol";

// ¿Qué? Comprueba un despliegue de la tienda solo con lecturas: quién administra, que nadie más
//   tenga roles y que los contratos estén conectados entre sí. Revierte con un error que dice qué
//   está mal.
// ¿Para qué? Lo llama Deploy.s.sol al terminar y lo puedes ejecutar tú, cuando quieras, contra
//   las direcciones de una red: sin --broadcast no firma nada.
// Uso: POINTS=0x... SHOP=0x... TIMELOCK=0x... DEPLOYER=0x... forge script script/CheckDeployment.s.sol --rpc-url <red>
contract CheckDeployment is Script {
    /// @notice El plazo mínimo que se acepta en el timelock.
    uint256 public constant MIN_DELAY = 2 days;

    error NotAdmin(address target, address expected);
    error DeployerStillAdmin(address target);
    error NotMinter(address expected);
    error UnexpectedMembers(bytes32 role, uint256 count);
    error WrongOwner(address owner);
    error WrongPoints(address points);
    error DelayTooShort(uint256 delay);

    function run() external view {
        Deploy.Deployment memory d = Deploy.Deployment(
            Points(vm.envAddress("POINTS")), Shop(vm.envAddress("SHOP")), TimelockController(payable(vm.envAddress("TIMELOCK")))
        );
        check(d, vm.envAddress("DEPLOYER"));
        console.log("Despliegue comprobado");
    }

    /// @notice Revierte si algo del despliegue `d` no es lo esperado.
    /// @param deployer Quien firmó el despliegue: no puede conservar ningún poder.
    function check(Deploy.Deployment memory d, address deployer) public view {
        _checkAdmins(d, deployer);
        _checkNoOneElse(d);
        _checkWiring(d);
    }

    function _checkAdmins(Deploy.Deployment memory d, address deployer) internal view {
        // PASO 3: el timelock administra los puntos y quien despliega no administra ni los puntos
        // ni el timelock.
        revert("TODO: Paso 3");
        //> bytes32 admin = d.points.DEFAULT_ADMIN_ROLE();
        //> if (!d.points.hasRole(admin, address(d.timelock))) revert NotAdmin(address(d.points), address(d.timelock));
        //> if (d.points.hasRole(admin, deployer)) revert DeployerStillAdmin(address(d.points));
        //> if (d.timelock.hasRole(d.timelock.DEFAULT_ADMIN_ROLE(), deployer)) revert DeployerStillAdmin(address(d.timelock));
    }

    function _checkNoOneElse(Deploy.Deployment memory d) internal view {
        // PASO 4: un solo administrador y un solo minter, y el minter es la tienda.
        revert("TODO: Paso 4");
        //> bytes32 admin = d.points.DEFAULT_ADMIN_ROLE();
        //> bytes32 minter = d.points.MINTER_ROLE();
        //> if (d.points.getRoleMemberCount(admin) != 1) revert UnexpectedMembers(admin, d.points.getRoleMemberCount(admin));
        //> if (d.points.getRoleMemberCount(minter) != 1) revert UnexpectedMembers(minter, d.points.getRoleMemberCount(minter));
        //> if (!d.points.hasRole(minter, address(d.shop))) revert NotMinter(address(d.shop));
    }

    function _checkWiring(Deploy.Deployment memory d) internal view {
        // PASO 5: la tienda es del timelock, acuña estos puntos y el timelock espera lo suficiente.
        revert("TODO: Paso 5");
        //> if (d.shop.owner() != address(d.timelock)) revert WrongOwner(d.shop.owner());
        //> if (address(d.shop.points()) != address(d.points)) revert WrongPoints(address(d.shop.points()));
        //> if (d.timelock.getMinDelay() < MIN_DELAY) revert DelayTooShort(d.timelock.getMinDelay());
    }
}
