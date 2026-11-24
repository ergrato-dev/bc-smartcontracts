// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Payroll} from "../src/Payroll.sol";

// ¿Qué? Los tests de comportamiento de la nómina, que pasan desde el principio, y uno de gas o de
//   tamaño por paso, que falla hasta que haces el paso.
// ¿Para qué? Que cada paso abarate sin cambiar lo que hace `payAll`.
// ¿Impacto? Los topes son los de este contrato con solc 0.8.38 sin optimizador.
contract PayrollTest is Test {
    Payroll payroll;
    address[] to;
    uint256[] amounts;

    function setUp() public {
        payroll = new Payroll(1000);
        for (uint256 i = 1; i <= 10; i++) {
            address account = address(uint160(i));
            payroll.hire(account, "Empleado");
            to.push(account);
            // Dos importes a cero: el 3 y el 7.
            amounts.push(i == 3 || i == 7 ? 0 : i);
        }
        payroll.setBlocked(address(5), true);
    }

    function _lastGas() internal view returns (uint256) {
        return vm.lastFrameGas().gasTotalUsed;
    }

    function test_PayAllSkipsZerosAndBlocked() public {
        payroll.payAll(to, amounts);
        assertEq(payroll.paid(address(1)), 1);
        assertEq(payroll.paid(address(3)), 0);
        assertEq(payroll.paid(address(5)), 0);
        assertEq(payroll.paid(address(10)), 10);
        // 55 menos el 3, el 5 y el 7.
        assertEq(payroll.budget(), 1000 - 40);
    }

    function test_RevertWhen_OverBudgetOrWrongCaller() public {
        amounts[9] = 1000;
        vm.expectRevert();
        payroll.payAll(to, amounts);
        vm.prank(address(1));
        vm.expectRevert();
        payroll.payAll(to, amounts);
        amounts.pop();
        vm.expectRevert();
        payroll.payAll(to, amounts);
    }

    function test_Paso1_PayAllFitsBudget() public {
        payroll.payAll(to, amounts);
        assertLt(_lastGas(), 250_500, "Paso 1: payAll gasta demasiado");
    }

    function test_Paso2_BytecodeFitsBudget() public pure {
        assertLt(type(Payroll).creationCode.length, 4800, "Paso 2: el bytecode ocupa demasiado");
    }

    function test_Paso3_PayAllFitsBudget() public {
        payroll.payAll(to, amounts);
        assertLt(_lastGas(), 230_000, "Paso 3: payAll gasta demasiado");
    }

    function test_Paso4_PayAllFitsBudget() public {
        payroll.payAll(to, amounts);
        assertLt(_lastGas(), 217_000, "Paso 4: payAll gasta demasiado");
    }

    function test_Paso5_PayAllFitsBudget() public {
        payroll.payAll(to, amounts);
        assertLt(_lastGas(), 214_500, "Paso 5: payAll gasta demasiado");
    }
}
