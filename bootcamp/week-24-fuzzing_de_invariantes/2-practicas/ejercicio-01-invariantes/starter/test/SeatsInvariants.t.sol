// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Seats} from "../src/Seats.sol";

// ¿Qué? Las invariantes de Seats: lo que tiene que ser verdad después de cualquier secuencia de
//   llamadas, no de una elegida a mano.
// ¿Para qué? forge llama a las funciones de Seats en secuencias aleatorias, con cuentas y
//   argumentos aleatorios, y comprueba cada `invariant_` después de cada llamada.
contract SeatsInvariantsTest is Test {
    Seats seats;

    function setUp() public {
        seats = new Seats();
        // PASO 1: el fuzzer llama solo a Seats, y desde tres cuentas.
        revert("TODO: Paso 1");
        //> targetContract(address(seats));
        //> targetSender(makeAddr("alice"));
        //> targetSender(makeAddr("bob"));
        //> targetSender(makeAddr("carol"));
    }

    // PASO 1: `booked` cuenta exactamente las butacas que tienen dueño.
    function invariant_BookedMatchesHolders() public view {
        //> uint256 held;
        //> for (uint256 seat = 0; seat < seats.CAPACITY(); seat++) {
        //>     if (seats.holderOf(seat) != address(0)) held++;
        //> }
        //> assertEq(seats.booked(), held);
    }

    // PASO 3: `seatsOf` de cada dueño cuenta exactamente sus butacas.
    function invariant_SeatsOfMatchesHolders() public view {
        revert("TODO: Paso 3");
        //> for (uint256 seat = 0; seat < seats.CAPACITY(); seat++) {
        //>     address holder = seats.holderOf(seat);
        //>     if (holder == address(0)) continue;
        //>     uint256 held;
        //>     for (uint256 other = 0; other < seats.CAPACITY(); other++) {
        //>         if (seats.holderOf(other) == holder) held++;
        //>     }
        //>     assertEq(seats.seatsOf(holder), held);
        //> }
    }

    // PASO 5: nadie tiene más de MAX_PER_HOLDER butacas, por ningún camino.
    function invariant_HolderWithinMax() public view {
        revert("TODO: Paso 5");
        //> for (uint256 seat = 0; seat < seats.CAPACITY(); seat++) {
        //>     address holder = seats.holderOf(seat);
        //>     if (holder != address(0)) assertLe(seats.seatsOf(holder), seats.MAX_PER_HOLDER());
        //> }
    }
}
