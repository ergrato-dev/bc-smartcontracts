// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Script} from "forge-std/Script.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {Points} from "../src/Points.sol";
import {Shop} from "../src/Shop.sol";
import {CheckDeployment} from "./CheckDeployment.s.sol";

// ¿Qué? Despliega la tienda entera en tres fases: los contratos, sus conexiones y el traspaso al
//   timelock. Al final, sin firmar nada más, comprueba el resultado con CheckDeployment.
// ¿Para qué? Que el despliegue no termine "bien" con una configuración mala: si quien firma sigue
//   de administrador, el script revierte y no se emite ninguna transacción.
// Uso: PROPOSER=0x... forge script script/Deploy.s.sol --rpc-url <red> --account <keystore> --broadcast
contract Deploy is Script {
    /// @notice Lo que deja el despliegue.
    struct Deployment {
        Points points;
        Shop shop;
        TimelockController timelock;
    }

    /// @notice El plazo del timelock: lo que espera cualquier cambio del dueño.
    uint256 public constant MIN_DELAY = 2 days;

    /// @notice Despliega con PRICE (0.01 ether si no existe) y PROPOSER, y comprueba el resultado.
    function run() external returns (Deployment memory d) {
        (, address deployer,) = vm.readCallers();
        d = deploy(vm.envOr("PRICE", uint256(0.01 ether)), MIN_DELAY, vm.envAddress("PROPOSER"));
        new CheckDeployment().check(d, deployer);
    }

    /// @notice Las tres fases seguidas.
    /// @param price El precio de una compra, en wei.
    /// @param minDelay El plazo del timelock.
    /// @param proposer Quien propone cambios al timelock: una multifirma o una DAO.
    function deploy(uint256 price, uint256 minDelay, address proposer) public returns (Deployment memory d) {
        d = deployContracts(price, minDelay, proposer);
        wire(d);
        handOver(d);
    }

    /// @notice Fase 1: los tres contratos. Quien firma es el administrador de los puntos y el dueño
    ///   de la tienda.
    function deployContracts(uint256 price, uint256 minDelay, address proposer)
        public
        returns (Deployment memory d)
    {
        vm.startBroadcast();
        d.points = new Points();
        d.shop = new Shop(d.points, price);
        address[] memory proposers = new address[](1);
        proposers[0] = proposer;
        // Ejecutor address(0): cualquiera ejecuta lo que ya esperó el plazo. Sin administrador: los
        // roles del timelock solo los cambia el propio timelock.
        address[] memory executors = new address[](1);
        d.timelock = new TimelockController(minDelay, proposers, executors, address(0));
        vm.stopBroadcast();
    }

    /// @notice Fase 2: la tienda acuña puntos.
    function wire(Deployment memory d) public {
        vm.startBroadcast();
        // PASO 1: dar a la tienda el rol que le deja acuñar.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 1");
        //> d.points.grantRole(d.points.MINTER_ROLE(), address(d.shop));
        vm.stopBroadcast();
    }

    /// @notice Fase 3: todo pasa al timelock y quien firma se queda sin nada.
    function handOver(Deployment memory d) public {
        vm.startBroadcast();
        (, address deployer,) = vm.readCallers();
        // PASO 2: el timelock administra los puntos y es dueño de la tienda; quien firma renuncia.
        revert("TODO: Paso 2");
        //> d.points.grantRole(d.points.DEFAULT_ADMIN_ROLE(), address(d.timelock));
        //> d.points.renounceRole(d.points.DEFAULT_ADMIN_ROLE(), deployer);
        //> d.shop.transferOwnership(address(d.timelock));
        vm.stopBroadcast();
    }
}
