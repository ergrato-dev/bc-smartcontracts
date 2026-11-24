// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Las butacas numeradas de una sala: se reservan, se cancelan y se pasan a otra cuenta.
// ¿Para qué? El contrato del ejercicio 01. Sus tests unitarios pasan; las invariantes de
//   test/SeatsInvariants.t.sol encuentran lo que esos tests no prueban.
// ¿Impacto? `booked` y `seatsOf` son contadores: cada función que cambia `holderOf` tiene que
//   mantenerlos al día, o dejan de decir la verdad.
contract Seats {
    uint256 public constant CAPACITY = 10;
    uint256 public constant MAX_PER_HOLDER = 2;

    mapping(uint256 seat => address) public holderOf;
    mapping(address holder => uint256) public seatsOf;
    uint256 public booked;

    error InvalidSeat(uint256 seat);
    error SeatTaken(uint256 seat);
    error NotHolder(uint256 seat, address caller);
    error TooManySeats(address holder);
    error ZeroAddress();

    function book(uint256 seat) external {
        if (seat >= CAPACITY) revert InvalidSeat(seat);
        if (holderOf[seat] != address(0)) revert SeatTaken(seat);
        if (seatsOf[msg.sender] >= MAX_PER_HOLDER) revert TooManySeats(msg.sender);
        holderOf[seat] = msg.sender;
        seatsOf[msg.sender]++;
        booked++;
    }

    function cancel(uint256 seat) external {
        if (holderOf[seat] != msg.sender) revert NotHolder(seat, msg.sender);
        delete holderOf[seat];
        seatsOf[msg.sender]--;
        booked--;
    }

    function transferSeat(uint256 seat, address to) external {
        if (holderOf[seat] != msg.sender) revert NotHolder(seat, msg.sender);
        // PASO 2: una butaca no se pasa a address(0), que significa "libre".
        //> if (to == address(0)) revert ZeroAddress();
        // PASO 4: quien recibe no pasa de MAX_PER_HOLDER, y el contador de cada cuenta sigue a
        //   la butaca.
        //> if (seatsOf[to] >= MAX_PER_HOLDER) revert TooManySeats(to);
        holderOf[seat] = to;
        //> seatsOf[msg.sender]--;
        //> seatsOf[to]++;
    }
}
