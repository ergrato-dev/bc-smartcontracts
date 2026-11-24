// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

// ¿Qué? El vault de puntos (semana 30): un ERC-4626 de OpenZeppelin sobre tu token de fidelidad.
//   Depositas puntos y recibes shares; cada alta del registro emite un bonus de puntos al vault,
//   así que cada share vale cada vez más puntos.
// ¿Para qué? Que quien guarda sus puntos en el protocolo gane una parte de su actividad, con la
//   interfaz estándar que entienden wallets, agregadores y otros contratos.
// ¿Impacto? El precio de una share es totalAssets / totalSupply, y totalAssets es el saldo del
//   vault: un regalo de puntos lo sube (semana 22). Las shares virtuales del offset hacen que ni
//   el ataque de inflación ni el bonus acumulado con el vault vacío los gane quien llega primero.
contract PointsVault is ERC4626 {
    /// @param points El token de fidelidad: el activo del vault.
    constructor(IERC20 points) ERC20("Staked Points", "sPTS") ERC4626(points) {}

    // TODO (semana 30): las shares virtuales contra el ataque de inflación (semana 22 y teoría 03).
    //   Sobrescribe `function _decimalsOffset() internal pure override returns (uint8)` para que
    //   devuelva 6: las shares tendrán 24 decimales.
}
