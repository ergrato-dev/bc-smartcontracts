// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
// Nuevo en la semana 31: ERC20Votes y EIP712.
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

// ¿Qué? El vault de puntos (semana 30): un ERC-4626 de OpenZeppelin sobre tu token de fidelidad.
//   Depositas puntos y recibes shares; cada alta del registro emite un bonus de puntos al vault,
//   así que cada share vale cada vez más puntos. Desde la semana 31, las shares son además los
//   votos de la gobernanza (ERC20Votes): quien guarda sus puntos en el protocolo lo gobierna.
// ¿Para qué? Que quien guarda sus puntos en el protocolo gane una parte de su actividad, con la
//   interfaz estándar que entienden wallets, agregadores y otros contratos.
// ¿Impacto? El precio de una share es totalAssets / totalSupply, y totalAssets es el saldo del
//   vault: un regalo de puntos lo sube (semana 22). Las shares virtuales del offset hacen que ni
//   el ataque de inflación ni el bonus acumulado con el vault vacío los gane quien llega primero.
//   Los votos son los del bloque de cada propuesta: depositar después, aunque sea con un flash
//   loan, no da votos en ella.
// Semana 31: `ERC20Votes` en la herencia, `EIP712` en el constructor y las dos funciones que
//   existen en dos padres (`decimals` y `_update`). El resto es el vault de la semana 30.
contract PointsVault is ERC4626, ERC20Votes {
    /// @param points El token de fidelidad: el activo del vault.
    constructor(IERC20 points) ERC20("Staked Points", "sPTS") ERC4626(points) EIP712("Staked Points", "1") {}

    /// @inheritdoc ERC4626
    function decimals() public view override(ERC20, ERC4626) returns (uint8) {
        return super.decimals();
    }

    // 6 decimales más que el token: un millón de shares virtuales frente a 1 punto virtual. Para
    // robar con un regalo, el atacante tendría que regalar un millón de veces lo que roba.
    function _decimalsOffset() internal pure override returns (uint8) {
        return 6;
    }

    // Cada movimiento de shares (depósito, retirada o transferencia) mueve también sus votos y
    // guarda un checkpoint de los delegados que cambian.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }
}
