// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Scoreboard} from "../src/Scoreboard.sol";

// ¿Qué? Los tests del marcador. Aquí escribes tú: un test por paso.
contract ScoreboardTest is Test {
    Scoreboard scoreboard;

    // PASO 1: desplegar un Scoreboard nuevo antes de cada test.
    // En cada paso, borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function setUp() public {
        revert("TODO: Paso 1");
        //> scoreboard = new Scoreboard();
    }

    // PASO 2: un marcador recién desplegado empieza en 0.
    function test_StartsAtZero() public view {
        revert("TODO: Paso 2");
        //> assertEq(scoreboard.getTotal(), 0);
    }

    // PASO 3: sumar 10 y luego 5 deja 15.
    function test_AddPoints() public {
        revert("TODO: Paso 3");
        //> scoreboard.addPoints(10);
        //> scoreboard.addPoints(5);
        //> assertEq(scoreboard.getTotal(), 15);
    }

    // PASO 4: la próxima llamada la hace alice, y queda como último jugador.
    function test_RecordsLastPlayer() public {
        revert("TODO: Paso 4");
        //> address alice = makeAddr("alice");
        //> vm.prank(alice);
        //> scoreboard.addPoints(1);
        //> assertEq(scoreboard.getLastPlayer(), alice);
    }

    // PASO 5: restar más de lo que hay revierte.
    function test_RevertWhen_RemovingMoreThanTotal() public {
        revert("TODO: Paso 5");
        //> scoreboard.addPoints(3);
        //> vm.expectRevert();
        //> scoreboard.removePoints(4);
    }

    // PASO 6: dos despliegues no comparten estado.
    function test_DeploymentsAreIndependent() public {
        revert("TODO: Paso 6");
        //> Scoreboard other = new Scoreboard();
        //> scoreboard.addPoints(8);
        //> assertEq(other.getTotal(), 0);
        //> assertTrue(address(other) != address(scoreboard));
    }
}
