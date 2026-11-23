// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";

// ¿Qué? El mismo banco, corregido: primero comprobaciones, después efectos y al final la
//   interacción (checks-effects-interactions), y un cerrojo de reentrancy en las dos funciones
//   que tocan saldos.
// ¿Para qué? Que nadie pueda volver a entrar con un saldo que ya se ha pagado.
// ¿Impacto? El cerrojo vive en transient storage (EIP-1153): cuesta poco y se borra al final
//   de la transacción.
contract Bank is ReentrancyGuardTransient {
    mapping(address => uint256) public balanceOf;

    error NothingToWithdraw();
    error InsufficientBalance(uint256 balance, uint256 amount);
    error TransferFailed();

    /// @notice Guarda el ETH que envías a tu nombre.
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    /// @notice Pasa `amount` de tu saldo al de `to`, sin mover ETH.
    // PASO 5: el cerrojo, aquí y en `withdraw`. Descomenta la línea `//> nonReentrant`.
    function transfer(address to, uint256 amount)
        external
        //> nonReentrant
    {
        uint256 balance = balanceOf[msg.sender];
        if (balance < amount) revert InsufficientBalance(balance, amount);
        balanceOf[msg.sender] = balance - amount;
        balanceOf[to] += amount;
    }

    /// @notice Te envía todo tu saldo.
    function withdraw()
        external
        // PASO 5: el cerrojo también aquí.
        //> nonReentrant
    {
        // PASO 3: el saldo a cero antes de enviar.
        revert("TODO: Paso 3");
        //> uint256 amount = balanceOf[msg.sender];
        //> if (amount == 0) revert NothingToWithdraw();
        //> balanceOf[msg.sender] = 0;
        //> (bool ok,) = msg.sender.call{value: amount}("");
        //> if (!ok) revert TransferFailed();
    }
}
