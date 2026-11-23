// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ¿Qué? Una caja que guarda tokens ERC-20 de cualquier tipo, por cuenta y por token.
// ¿Para qué? Recibir tokens de un contrato que no conoces: los que no devuelven `bool`,
//   los que devuelven `false` y los que cobran una comisión al transferir.
// ¿Impacto? Apunta lo que de verdad llegó, no lo que se pidió: si apuntara de más, la caja
//   debería tokens que no tiene y el último en retirar no podría.
contract TokenVault {
    using SafeERC20 for IERC20;

    mapping(IERC20 => mapping(address => uint256)) public deposited;

    event Deposited(IERC20 indexed token, address indexed account, uint256 amount);
    event Withdrawn(IERC20 indexed token, address indexed account, uint256 amount);

    error NothingReceived();
    error InsufficientDeposit(uint256 deposited, uint256 needed);

    /// @notice Trae `amount` de tus tokens a la caja. Antes tienes que aprobar a la caja.
    /// @return received Lo que llegó de verdad, que es lo que se te apunta.
    function deposit(IERC20 token, uint256 amount) external returns (uint256 received) {
        uint256 before = token.balanceOf(address(this));
        // PASO 1: traer los tokens con safeTransferFrom.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 1");
        //> token.safeTransferFrom(msg.sender, address(this), amount);

        // PASO 2: apuntar lo que llegó, medido con el saldo, no `amount`.
        //   Descomenta las líneas que empiezan con `//> `.
        //> received = token.balanceOf(address(this)) - before;
        //> if (received == 0) revert NothingReceived();
        //> deposited[token][msg.sender] += received;
        //> emit Deposited(token, msg.sender, received);
    }

    // PASO 3: devolver tokens: primero se resta, después se envía.
    function withdraw(IERC20 token, uint256 amount) external {
        revert("TODO: Paso 3");
        //> uint256 balance = deposited[token][msg.sender];
        //> if (balance < amount) revert InsufficientDeposit(balance, amount);
        //> deposited[token][msg.sender] = balance - amount;
        //> emit Withdrawn(token, msg.sender, amount);
        //> token.safeTransfer(msg.sender, amount);
    }
}
