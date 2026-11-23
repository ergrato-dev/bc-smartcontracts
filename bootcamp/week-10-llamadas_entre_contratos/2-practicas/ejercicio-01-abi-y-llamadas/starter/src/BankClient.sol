// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Bank} from "./Bank.sol";

// ¿Qué? Un cliente que guarda su ETH en un Bank usando solo llamadas de bajo nivel.
// ¿Para qué? Construir a mano los bytes de cada llamada y leer a mano lo que vuelve.
// ¿Impacto? `call` no revierte por sí sola: cada función decide qué hacer con `ok`.
contract BankClient {
    address public immutable BANK;

    error NoCode(address target);
    error CallFailed(bytes reason);

    constructor(address bank) {
        // PASO 5: rechazar un banco sin código. Una llamada de bajo nivel a una cuenta sin
        //   código devuelve éxito, y el cliente creería que todo funcionó.
        //   Descomenta la línea que empieza con `//> `.
        //> if (bank.code.length == 0) revert NoCode(bank);
        BANK = bank;
    }

    // PASO 1: los bytes de la llamada `withdraw(amount)`, con los tipos comprobados.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function withdrawCalldata(uint256 amount) public pure returns (bytes memory) {
        revert("TODO: Paso 1");
        //> return abi.encodeCall(Bank.withdraw, (amount));
    }

    // PASO 2: depositar en el banco el ETH recibido. Si el banco revierte, revertir con
    //   sus bytes dentro de CallFailed.
    function deposit() external payable {
        revert("TODO: Paso 2");
        //> (bool ok, bytes memory reason) = BANK.call{value: msg.value}(abi.encodeCall(Bank.deposit, ()));
        //> if (!ok) revert CallFailed(reason);
    }

    // PASO 3: leer el saldo del cliente en el banco con staticcall y decodificarlo.
    function balance() external view returns (uint256) {
        revert("TODO: Paso 3");
        //> (bool ok, bytes memory data) = BANK.staticcall(abi.encodeCall(Bank.balanceOf, (address(this))));
        //> if (!ok) revert CallFailed(data);
        //> return abi.decode(data, (uint256));
    }

    // PASO 4: intentar una retirada sin revertir. Devuelve lo que devolvió la llamada.
    function tryWithdraw(uint256 amount) external returns (bool ok, bytes memory reason) {
        revert("TODO: Paso 4");
        //> (ok, reason) = BANK.call(withdrawCalldata(amount));
    }

    // ¿Qué? Recibe el ETH que devuelve el banco al retirar.
    receive() external payable {}
}
