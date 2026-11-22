// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Una caja de ahorro: cada cuenta deposita ETH y retira lo suyo.
// ¿Para qué? Practicar el envío de ETH con `call`, comprobar si llegó y ordenar el código
//   en checks-effects-interactions.
// ¿Impacto? Enviar ETH le pasa el control a quien lo recibe. Si el saldo se actualiza
//   después del envío, quien recibe puede volver a entrar y cobrar dos veces.
contract Vault {
    uint256 public totalDeposits;
    mapping(address => uint256) public balanceOf;

    event Deposited(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    error ZeroAmount();
    error InsufficientBalance(uint256 available, uint256 requested);
    error NothingToWithdraw();
    error TransferFailed(address to, uint256 amount);

    // PASO 1: apuntar el depósito a quien llama. Sin ETH no hay depósito.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function deposit() external payable {
        revert("TODO: Paso 1");
        //> if (msg.value == 0) revert ZeroAmount();
        //> balanceOf[msg.sender] += msg.value;
        //> totalDeposits += msg.value;
        //> emit Deposited(msg.sender, msg.value);
    }

    // PASO 2: retirar una parte. Primero las comprobaciones, luego el saldo y el evento, y
    //   al final el envío, comprobando que llegó.
    function withdraw(uint256 amount) external {
        revert("TODO: Paso 2");
        //> uint256 available = balanceOf[msg.sender];
        //> if (amount > available) revert InsufficientBalance(available, amount);
        //> balanceOf[msg.sender] = available - amount;
        //> totalDeposits -= amount;
        //> emit Withdrawn(msg.sender, amount);
        //> (bool ok,) = payable(msg.sender).call{value: amount}("");
        //> if (!ok) revert TransferFailed(msg.sender, amount);
    }

    // PASO 3: retirar todo, con el mismo orden: el saldo queda a 0 antes de enviar.
    function withdrawAll() external {
        revert("TODO: Paso 3");
        //> uint256 amount = balanceOf[msg.sender];
        //> if (amount == 0) revert NothingToWithdraw();
        //> balanceOf[msg.sender] = 0;
        //> totalDeposits -= amount;
        //> emit Withdrawn(msg.sender, amount);
        //> (bool ok,) = payable(msg.sender).call{value: amount}("");
        //> if (!ok) revert TransferFailed(msg.sender, amount);
    }

    // PASO 4: la caja es solvente si tiene al menos lo depositado. Puede tener más: a un
    //   contrato le puede llegar ETH sin pasar por `deposit`.
    function isSolvent() external view returns (bool) {
        revert("TODO: Paso 4");
        //> return address(this).balance >= totalDeposits;
    }
}
