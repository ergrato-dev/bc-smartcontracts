// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Bookings} from "../src/Bookings.sol";

// ¿Qué? Las specs de Bookings para Halmos: cada `check_` se comprueba para todos los valores de
//   sus parámetros.
// ¿Para qué? Lo que prometen las reservas, dicho una vez: ningún día en dos reservas, y dos
//   reservas que no comparten días se aceptan las dos.
// ¿Impacto? `forge test` no las ejecuta (no empiezan por `test`); las ejecuta `halmos`.
contract BookingsSpec is Test {
    Bookings internal bookings;

    function setUp() public {
        bookings = new Bookings();
    }

    /// @notice Si las dos reservas se aceptan, ningún día está en las dos.
    function check_NoDayTwice(uint32 from1, uint32 to1, uint32 from2, uint32 to2, uint32 day) public {
        assertTrue(false, "TODO: Paso 1"); // <- Paso 1
        //> bookings.book(from1, to1);
        //> try bookings.book(from2, to2) {
        //>     bool inFirst = from1 <= day && day <= to1;
        //>     bool inSecond = from2 <= day && day <= to2;
        //>     assertFalse(inFirst && inSecond);
        //> } catch {}
    }

    /// @notice Dos reservas válidas que no comparten ningún día se aceptan las dos.
    function check_DisjointAccepted(uint32 from1, uint32 to1, uint32 from2, uint32 to2) public {
        assertTrue(false, "TODO: Paso 3"); // <- Paso 3
        //> vm.assume(from1 <= to1 && from2 <= to2);
        //> vm.assume(to1 < from2 || to2 < from1);
        //> bookings.book(from1, to1);
        //> bool accepted;
        //> try bookings.book(from2, to2) {
        //>     accepted = true;
        //> } catch {}
        //> assertTrue(accepted);
    }
}
