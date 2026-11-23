// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

// ¿Qué? Una caja de ETH: cada cuenta deposita y retira lo suyo. Su dueño la pausa en una
//   emergencia, y la propiedad cambia de manos en dos pasos.
// ¿Para qué? Practicar `Pausable` con `Ownable2Step`, y decidir qué se pausa y qué no.
// ¿Impacto? La pausa bloquea los depósitos, nunca los retiros: el dueño no puede dejar el
//   dinero de nadie dentro. Y la caja no se puede quedar sin dueño.
contract Vault is Ownable2Step, Pausable {
    mapping(address => uint256) public balanceOf;

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    error ZeroAmount();
    error InsufficientBalance(uint256 balance, uint256 needed);
    error TransferFailed();
    error RenounceDisabled();

    constructor() Ownable(msg.sender) {}

    // PASO 1: pausar y reanudar, solo el dueño.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function pause() external onlyOwner {
        revert("TODO: Paso 1");
        //> _pause();
    }

    function unpause() external onlyOwner {
        revert("TODO: Paso 1");
        //> _unpause();
    }

    // PASO 2: depositar. `whenNotPaused` ya está en la cabecera.
    function deposit() external payable whenNotPaused {
        revert("TODO: Paso 2");
        //> if (msg.value == 0) revert ZeroAmount();
        //> balanceOf[msg.sender] += msg.value;
        //> emit Deposited(msg.sender, msg.value);
    }

    // PASO 3: retirar, también con la caja en pausa. Apunta antes de enviar (semana 07).
    function withdraw(uint256 amount) external {
        revert("TODO: Paso 3");
        //> uint256 balance = balanceOf[msg.sender];
        //> if (balance < amount) revert InsufficientBalance(balance, amount);
        //> balanceOf[msg.sender] = balance - amount;
        //> emit Withdrawn(msg.sender, amount);
        //> (bool ok,) = msg.sender.call{value: amount}("");
        //> if (!ok) revert TransferFailed();
    }

    // PASO 4: sin `renounceOwnership`. La caja necesita un dueño que pueda reanudarla.
    //   Descomenta las líneas que empiezan con `//> `.
    //> function renounceOwnership() public pure override {
    //>     revert RenounceDisabled();
    //> }
}
