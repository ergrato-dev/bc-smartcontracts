// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Programs} from "../src/Programs.sol";

// ¿Qué? Un test por programa: lo instala con `vm.etch` y lo llama como a cualquier contrato.
// ¿Para qué? Comprobar cada programa por lo que devuelve y por lo que deja en storage.
contract ProgramsTest is Test {
    // Pone `code` como código de una dirección nueva, sin desplegar: es el código que la EVM
    // ejecuta cuando alguien llama a esa dirección (runtime bytecode).
    function _install(bytes memory code) internal returns (address program) {
        program = makeAddr("program");
        vm.etch(program, code);
    }

    function test_Paso1_Answer() public {
        address program = _install(Programs.answer());
        (bool ok, bytes memory ret) = program.call("");
        assertTrue(ok);
        assertEq(ret.length, 32);
        assertEq(abi.decode(ret, (uint256)), 42);
    }

    function testFuzz_Paso2_Double(uint128 x) public {
        address program = _install(Programs.double());
        (bool ok, bytes memory ret) = program.call(abi.encode(x));
        assertTrue(ok);
        assertEq(abi.decode(ret, (uint256)), 2 * uint256(x));
    }

    function test_Paso3_Counter() public {
        address program = _install(Programs.counter());
        bytes memory ret;
        for (uint256 i = 0; i < 3; i++) {
            bool ok;
            (ok, ret) = program.call("");
            assertTrue(ok);
        }
        assertEq(abi.decode(ret, (uint256)), 3);
        assertEq(vm.load(program, bytes32(0)), bytes32(uint256(3)));
    }

    function test_Paso4_NoValue() public {
        address program = _install(Programs.noValue());
        vm.deal(address(this), 1 ether);
        uint256 gasBefore = gasleft();
        (bool ok, bytes memory ret) = program.call{value: 1 wei}("");
        assertFalse(ok);
        assertEq(ret.length, 0);
        // REVERT devuelve el gas que sobra. Un salto a un sitio sin JUMPDEST también falla, pero
        // se lo gasta todo: ese error pasaría las dos comprobaciones de arriba, no esta.
        assertLt(gasBefore - gasleft(), 50_000);
        (ok, ret) = program.call("");
        assertTrue(ok);
        assertEq(abi.decode(ret, (uint256)), 1);
    }

    function testFuzz_Paso5_Echo(bytes memory data) public {
        address program = _install(Programs.echo());
        (bool ok, bytes memory ret) = program.call(data);
        assertTrue(ok);
        assertEq(ret, data);
    }
}
