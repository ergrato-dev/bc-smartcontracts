// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un ERC-20 mínimo, sin OpenZeppelin: saldos, allowances, emisión del dueño y quema con
//   allowance (`burnFrom`).
// ¿Para qué? El contrato del ejercicio 03. Sus tests unitarios pasan; las specs de Halmos de
//   test/TokenSpec.t.sol comprueban, para cualquier cuenta y cualquier llamada, que nadie crea
//   ni quita tokens que no debe.
// ¿Impacto? Escrito a mano a propósito: OpenZeppelin no tiene estos dos fallos.
contract Token {
    address public immutable OWNER;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    error NotOwner(address caller);
    error InsufficientBalance(address account, uint256 balance, uint256 needed);
    error InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    constructor() {
        OWNER = msg.sender;
    }

    /// @notice Emite `amount` tokens para `to`. Solo el dueño.
    function mint(address to, uint256 amount) external {
        if (msg.sender != OWNER) revert NotOwner(msg.sender);
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        _spendAllowance(from, amount);
        _transfer(from, to, amount);
        return true;
    }

    /// @notice Quema `amount` tokens de `from`, con la allowance que `from` dio a quien llama.
    function burnFrom(address from, uint256 amount) external {
        //> _spendAllowance(from, amount);
        uint256 balance = balanceOf[from];
        if (balance < amount) revert InsufficientBalance(from, balance, amount);
        balanceOf[from] = balance - amount;
        totalSupply -= amount;
    }

    function _spendAllowance(address from, uint256 amount) internal {
        uint256 current = allowance[from][msg.sender];
        if (current < amount) revert InsufficientAllowance(msg.sender, current, amount);
        allowance[from][msg.sender] = current - amount;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        uint256 fromBalance = balanceOf[from];
        uint256 toBalance = balanceOf[to]; // <- Paso 2
        if (fromBalance < amount) revert InsufficientBalance(from, fromBalance, amount);
        balanceOf[from] = fromBalance - amount;
        balanceOf[to] = toBalance + amount; // <- Paso 2
        //> balanceOf[to] += amount;
    }
}
