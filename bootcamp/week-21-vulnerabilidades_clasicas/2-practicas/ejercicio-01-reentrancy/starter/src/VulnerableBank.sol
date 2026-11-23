// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un banco de ETH con dos fallos de reentrancy: `withdraw` envía antes de poner el saldo
//   a cero, y `transfer` se puede llamar mientras tanto.
// ¿Para qué? Ser el blanco de tus atacantes. **No lo arregles**: los tests lo necesitan roto.
// ¿Impacto? Cualquier contrato que retire puede volver a entrar y llevarse el ETH de los demás.
contract VulnerableBank {
    mapping(address => uint256) public balanceOf;

    error NothingToWithdraw();
    error InsufficientBalance(uint256 balance, uint256 amount);
    error TransferFailed();

    /// @notice Guarda el ETH que envías a tu nombre.
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    /// @notice Pasa `amount` de tu saldo al de `to`, sin mover ETH.
    function transfer(address to, uint256 amount) external {
        uint256 balance = balanceOf[msg.sender];
        if (balance < amount) revert InsufficientBalance(balance, amount);
        balanceOf[msg.sender] = balance - amount;
        balanceOf[to] += amount;
    }

    /// @notice Te envía todo tu saldo.
    function withdraw() external {
        uint256 amount = balanceOf[msg.sender];
        if (amount == 0) revert NothingToWithdraw();
        // ❌ Interacción antes del efecto: quien recibe ejecuta código con su saldo intacto.
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert TransferFailed();
        balanceOf[msg.sender] = 0;
    }
}
