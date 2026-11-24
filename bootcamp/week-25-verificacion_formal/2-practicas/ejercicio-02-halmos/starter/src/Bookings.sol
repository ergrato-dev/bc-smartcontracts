// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? El calendario de una habitación: cada reserva ocupa los días de `from` a `to`, los dos
//   incluidos. Un día no puede estar en dos reservas.
// ¿Para qué? El contrato del ejercicio 02. Sus tests unitarios pasan; las specs de Halmos de
//   test/BookingsSpec.t.sol comprueban la regla para cualquier par de reservas.
// ¿Impacto? Los días son números (por ejemplo, días desde una fecha): `from == to` es una
//   reserva de un solo día.
contract Bookings {
    struct Booking {
        uint32 from;
        uint32 to;
        address guest;
    }

    Booking[] public bookings;

    error InvalidRange(uint32 from, uint32 to);
    error Overlaps(uint256 index);

    /// @notice Reserva los días de `from` a `to`, los dos incluidos, si ninguno está ocupado.
    /// @return El índice de la reserva.
    function book(uint32 from, uint32 to) external returns (uint256) {
        if (from > to) revert InvalidRange(from, to);
        for (uint256 i = 0; i < bookings.length; i++) {
            Booking storage other = bookings[i];
            // Revertir dentro del bucle es lo que se quiere: un solo solape rechaza la reserva.
            // forge-lint: disable-next-line(require-revert-in-loop)
            if (from < other.to && other.from < to) revert Overlaps(i); // <- Paso 2
            //> if (from <= other.to && other.from <= to) revert Overlaps(i);
        }
        bookings.push(Booking(from, to, msg.sender));
        return bookings.length - 1;
    }

    /// @notice Cuántas reservas hay.
    function count() external view returns (uint256) {
        return bookings.length;
    }
}
