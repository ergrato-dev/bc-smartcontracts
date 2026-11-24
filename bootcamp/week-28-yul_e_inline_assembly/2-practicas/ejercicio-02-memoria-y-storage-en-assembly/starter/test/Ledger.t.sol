// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Ledger} from "../src/Ledger.sol";

// Un atacante de la semana 21: al recibir ETH, vuelve a llamar a `withdraw`.
contract Reenterer {
    Ledger public immutable LEDGER;
    bytes public lastError;

    constructor(Ledger ledger) {
        LEDGER = ledger;
    }

    function attack() external payable {
        LEDGER.deposit{value: msg.value}();
        LEDGER.withdraw();
    }

    receive() external payable {
        // Si la segunda entrada revierte, se guarda el motivo y el primer retiro sigue.
        try LEDGER.withdraw() {} catch (bytes memory reason) {
            lastError = reason;
        }
    }
}

// Retira dos veces dentro de una sola llamada, así que dentro de una sola transacción: el
//   transient storage no se borra entre los dos retiros.
contract TwiceWithdrawer {
    function run(Ledger ledger) external payable {
        ledger.deposit{value: msg.value / 2}();
        ledger.withdraw();
        ledger.deposit{value: msg.value / 2}();
        ledger.withdraw();
    }

    receive() external payable {}
}

// ¿Qué? Cada pieza de Ledger, comprobada desde fuera: contra `abi.encodePacked`, contra
//   `vm.load` en el slot calculado aquí, contra un array construido con Solidity y contra un
//   atacante que vuelve a entrar.
// ¿Para qué? El assembly no tiene más red que estos tests: lo que no comprueban, nadie lo
//   comprueba.
contract LedgerTest is Test {
    Ledger ledger;
    address alice = makeAddr("alice");

    function setUp() public {
        ledger = new Ledger();
    }

    function testFuzz_Paso1_PackLikeEncodePacked(address owner, uint96 amount) public view {
        bytes32 word = ledger.pack(owner, amount);
        assertEq(word, bytes32(abi.encodePacked(owner, amount)));
        (address o, uint96 a) = ledger.unpack(word);
        assertEq(o, owner);
        assertEq(a, amount);
    }

    function testFuzz_Paso2_BalanceSlot(address account, uint96 amount) public {
        vm.deal(account, amount);
        vm.prank(account);
        ledger.deposit{value: amount}();
        // `balanceOf` es la primera variable de estado: el mapping está en el slot 0.
        bytes32 expected = keccak256(abi.encode(account, uint256(0)));
        assertEq(ledger.balanceSlot(account), expected);
        assertEq(uint256(vm.load(address(ledger), expected)), amount);
        assertEq(ledger.balanceOfAsm(account), ledger.balanceOf(account));
    }

    function test_Paso3_ConfigInNamespace() public {
        ledger.initialize(alice, 250);
        (address owner, uint64 fee) = ledger.config();
        assertEq(owner, alice);
        assertEq(fee, 250);
        // El struct empieza en el slot del espacio de nombres: `owner` en los 20 bytes bajos
        //   y `fee` empaquetado justo encima.
        bytes32 root = keccak256(abi.encode(uint256(keccak256("bootcamp.ledger.config")) - 1)) & ~bytes32(uint256(0xff));
        uint256 word = uint256(vm.load(address(ledger), root));
        assertEq(address(uint160(word)), alice);
        assertEq(uint64(word >> 160), 250);
        vm.expectRevert(Ledger.AlreadyInitialized.selector);
        ledger.initialize(address(this), 0);
    }

    function testFuzz_Paso4_RangeSurvivesNextAllocation(uint8 n) public view {
        (uint256[] memory range, uint256[] memory sevens) = ledger.twoArrays(n);
        assertEq(range.length, n);
        assertEq(sevens.length, n);
        for (uint256 i = 0; i < n; i++) {
            assertEq(range[i], i);
            assertEq(sevens[i], 7);
        }
    }

    function test_Paso5_ReentrancyBlocked() public {
        Reenterer attacker = new Reenterer(ledger);
        vm.deal(address(ledger), 5 ether);
        attacker.attack{value: 1 ether}();
        assertEq(address(attacker).balance, 1 ether);
        assertEq(address(ledger).balance, 5 ether);
        assertEq(attacker.lastError(), abi.encodeWithSelector(Ledger.Reentrancy.selector));
    }

    function test_Paso5_LockReleasedWithinSameTransaction() public {
        // Si el cerrojo no se quita al acabar `withdraw`, el segundo retiro revierte.
        TwiceWithdrawer twice = new TwiceWithdrawer();
        twice.run{value: 2 ether}(ledger);
        assertEq(address(twice).balance, 2 ether);
    }
}
