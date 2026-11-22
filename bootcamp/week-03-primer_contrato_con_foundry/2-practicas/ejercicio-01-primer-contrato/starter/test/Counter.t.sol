// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

// ¿Qué? Un test por paso del ejercicio. No lo modifiques: es el contrato del ejercicio.
contract CounterTest is Test {
    Counter counter;

    // ¿Qué? setUp corre antes de cada test: cada uno empieza con un Counter recién desplegado.
    function setUp() public {
        counter = new Counter();
    }

    function test_Step1_Answer() public view {
        assertEq(counter.answer(), 42);
    }

    function test_Step2_StartsAtZero() public view {
        assertEq(counter.get(), 0);
    }

    function test_Step3_Increment() public {
        counter.increment();
        counter.increment();
        assertEq(counter.get(), 2);
    }

    function test_Step4_Set() public {
        counter.set(7);
        assertEq(counter.get(), 7);
    }

    function test_Step5_Add() public view {
        assertEq(counter.add(2, 3), 5);
    }

    function test_Step6_LastCaller() public {
        address alice = address(0xA11CE);
        vm.prank(alice);
        counter.touch();
        assertEq(counter.getLastCaller(), alice);
    }
}
