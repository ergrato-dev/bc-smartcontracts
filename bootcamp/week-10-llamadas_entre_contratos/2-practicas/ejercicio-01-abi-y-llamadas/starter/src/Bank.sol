// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un banco mínimo: cada cuenta deposita ETH y retira lo suyo.
// ¿Para qué? Ser el contrato al que BankClient llama con llamadas de bajo nivel.
// ¿Impacto? Terminado: no lo cambies. Sus errores son los que BankClient recibe en `bytes`.
contract Bank {
    mapping(address => uint256) private _balances;

    error ZeroAmount();
    error InsufficientBalance(uint256 available, uint256 requested);
    error TransferFailed();

    /// @notice Saldo de `account` en el banco, en wei.
    /// @param account La cuenta.
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @notice Suma el ETH enviado al saldo de quien llama.
    function deposit() external payable {
        if (msg.value == 0) revert ZeroAmount();
        _balances[msg.sender] += msg.value;
    }

    /// @notice Envía `amount` wei del saldo de quien llama a quien llama.
    /// @param amount Cuánto retirar. No puede superar el saldo.
    function withdraw(uint256 amount) external {
        uint256 available = _balances[msg.sender];
        if (amount > available) revert InsufficientBalance(available, amount);
        _balances[msg.sender] = available - amount;
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }
}
