// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

/// @title Nivel 2 — Banco con cerrojo
/// @notice ¿Qué? Un banco de ETH con saldos internos que se pueden transferir entre cuentas.
///   `withdraw` lleva un cerrojo contra reentrancy.
contract LockedBank {
    mapping(address => uint256) public balanceOf;
    bool private locked;

    error Locked();
    error InsufficientBalance();
    error TransferFailed();

    modifier nonReentrant() {
        if (locked) revert Locked();
        locked = true;
        _;
        locked = false;
    }

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    /// @notice Retira todo tu saldo.
    function withdraw() external nonReentrant {
        uint256 amount = balanceOf[msg.sender];
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert TransferFailed();
        balanceOf[msg.sender] = 0;
    }

    /// @notice Pasa `amount` de tu saldo a `to`, sin mover ETH.
    function transfer(address to, uint256 amount) external {
        if (balanceOf[msg.sender] < amount) revert InsufficientBalance();
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }
}

/// @notice ¿Qué? Despliega el nivel: el banco con 10 ETH depositados por este contrato.
contract Level2Setup {
    LockedBank public immutable BANK;

    constructor() payable {
        BANK = new LockedBank();
        BANK.deposit{value: msg.value}();
    }

    function isSolved() external view returns (bool) {
        return address(BANK).balance == 0;
    }
}
