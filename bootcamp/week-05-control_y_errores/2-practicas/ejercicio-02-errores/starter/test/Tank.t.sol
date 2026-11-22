// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Tank} from "../src/Tank.sol";

// ¿Qué? Un test por paso del ejercicio. No los modifiques.
// ¿Para qué? vm.expectRevert(datos) hace que el test pase solo si la siguiente llamada
//   revierte exactamente con esos datos.
contract TankTest is Test {
    Tank tank;

    function setUp() public {
        tank = new Tank();
    }

    function test_Step1_Fill() public {
        tank.fill(60);
        assertEq(tank.level(), 60);
        vm.expectRevert(bytes("tank overflow"));
        tank.fill(41);
    }

    function test_Step2_Drain() public {
        tank.fill(30);
        tank.drain(10);
        assertEq(tank.level(), 20);
        vm.expectRevert(abi.encodeWithSelector(Tank.InsufficientLevel.selector, 20, 25));
        tank.drain(25);
    }

    function test_Step3_SetAlarm() public {
        tank.setAlarm(80);
        assertEq(tank.alarm(), 80);
        vm.expectRevert(abi.encodeWithSelector(Tank.InvalidAlarm.selector, 101));
        tank.setAlarm(101);
    }

    function test_Step4_Empty() public {
        tank.fill(5);
        tank.empty();
        assertEq(tank.level(), 0);
        vm.expectRevert(Tank.AlreadyEmpty.selector);
        tank.empty();
    }

    function test_Step5_FreeSpace() public {
        assertEq(tank.freeSpace(), 100);
        tank.fill(70);
        assertEq(tank.freeSpace(), 30);
    }

    function test_Step6_WrappingAdd() public view {
        assertEq(tank.wrappingAdd(2, 3), 5);
        assertEq(tank.wrappingAdd(200, 100), 44);
    }
}
