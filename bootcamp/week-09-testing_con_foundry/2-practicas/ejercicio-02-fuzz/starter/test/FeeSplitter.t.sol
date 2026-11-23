// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {FeeSplitter} from "../src/FeeSplitter.sol";

// ¿Qué? Los tests del ejercicio. Aquí trabajas: cada test es un paso.
// ¿Para qué? Pasar de "funciona con estos tres números" a "funciona con cualquier número
//   válido": un test con parámetros que forge rellena al azar.
// ¿Impacto? El fuzzer encuentra los bordes que no se te ocurrieron (desbordes, redondeos,
//   direcciones raras) y te da el caso exacto que falla.
contract FeeSplitterTest is Test {
    FeeSplitter splitter;
    uint256 constant MAX_BPS = 10_000;

    function setUp() public {
        splitter = new FeeSplitter(250);
    }

    // PASO 1: tu primer fuzz test. Las dos partes suman el importe.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function testFuzz_Step1_PartsAddUp(uint256 amount, uint256 bps) public view {
        revert("TODO: Paso 1");
        //> bps = bound(bps, 0, MAX_BPS);
        // PASO 2: acota también el importe. Descomenta esta línea solo en el paso 2.
        //> amount = bound(amount, 0, type(uint128).max);
        //> (uint256 fee, uint256 rest) = splitter.split(amount, bps);
        //> assertEq(fee + rest, amount);
        //> assertLe(fee, amount);
    }

    // PASO 3: el camino del error, con cualquier bps por encima del máximo.
    function testFuzz_Step3_RevertWhen_BpsTooHigh(uint256 bps) public {
        revert("TODO: Paso 3");
        //> bps = bound(bps, MAX_BPS + 1, type(uint256).max);
        //> vm.expectRevert(abi.encodeWithSelector(FeeSplitter.InvalidBps.selector, bps));
        //> splitter.split(1 ether, bps);
    }

    // PASO 4: una propiedad del redondeo. La comisión nunca supera el valor exacto y se
    // queda a menos de una unidad de él.
    /// forge-config: default.fuzz.runs = 1000
    function testFuzz_Step4_FeeRoundsDown(uint128 amount, uint16 bps) public view {
        revert("TODO: Paso 4");
        //> vm.assume(bps <= MAX_BPS);
        //> (uint256 fee,) = splitter.split(amount, bps);
        //> uint256 exact = uint256(amount) * bps;
        //> assertLe(fee * MAX_BPS, exact);
        //> assertLt(exact - fee * MAX_BPS, MAX_BPS);
    }

    // PASO 5: cualquier cuenta que pague recibe el resto y el dueño acumula la comisión.
    function testFuzz_Step5_AnyoneCanPay(address payer, uint96 value) public {
        revert("TODO: Paso 5");
        //> vm.assume(value > 0);
        //> assumePayable(payer);
        //> assumeNotPrecompile(payer);
        //> vm.assume(payer != address(splitter));
        //> vm.deal(payer, value);
        //> uint256 before = payer.balance;
        //> vm.prank(payer);
        //> uint256 rest = splitter.pay{value: value}();
        //> assertEq(payer.balance, before - value + rest);
        //> assertEq(splitter.ownerFees() + rest, value);
    }
}
