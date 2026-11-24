// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Las entradas de una sala pequeña, en dos pasos: se reservan (`reserve`) y después se
//   confirman (`confirm`) o se cancelan (`cancel`).
// ¿Para qué? El contrato del ejercicio 01. Sus tests unitarios pasan; el SMTChecker comprueba en
//   test/TicketsSpec.sol que nunca se reservan ni venden más entradas que CAPACITY.
// ¿Impacto? Una reserva pendiente ocupa sitio igual que una entrada vendida: `sold + reserved`
//   nunca puede pasar de CAPACITY.
contract Tickets {
    uint256 public constant CAPACITY = 10;
    uint256 public constant MAX_PER_ORDER = 4;

    uint256 public sold;
    uint256 public reserved;
    mapping(address => uint256) public reservedOf;
    mapping(address => uint256) public ticketsOf;

    error InvalidAmount(uint256 amount); // <- Paso 2
    error SoldOut(uint256 requested, uint256 available); // <- Paso 2

    /// @notice Reserva `amount` entradas, de 1 a MAX_PER_ORDER, si queda sitio.
    function reserve(uint256 amount) external {
        if (amount == 0 || amount > MAX_PER_ORDER) revert InvalidAmount(amount); // <- Paso 2
        //> require(amount > 0 && amount <= MAX_PER_ORDER, "invalid amount");
        if (sold + amount > CAPACITY) revert SoldOut(amount, CAPACITY - sold); // <- Paso 2
        //> require(sold + amount <= CAPACITY, "sold out"); // <- Paso 3
        //> require(sold + reserved + amount <= CAPACITY, "sold out");
        reserved += amount;
        reservedOf[msg.sender] += amount;
    }

    /// @notice Convierte en entradas todas las reservas de quien llama.
    function confirm() external {
        uint256 amount = reservedOf[msg.sender];
        reservedOf[msg.sender] = 0;
        reserved -= amount;
        sold += amount;
        ticketsOf[msg.sender] += amount;
    }

    /// @notice Libera todas las reservas de quien llama.
    function cancel() external {
        uint256 amount = reservedOf[msg.sender];
        reservedOf[msg.sender] = 0;
        reserved -= amount;
    }
}
