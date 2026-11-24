// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Inbox} from "../src/Inbox.sol";

// ¿Qué? La calldata de Inbox escrita byte a byte, las reglas con las que el decodificador de
//   Solidity la acepta o la rechaza, la returndata de un revert abierta a mano y el coste de la
//   memoria. Tu trabajo son los ayudantes `_...`.
// ¿Para qué? Leer y escribir lo que viaja entre contratos sin `abi.encodeCall` ni
//   `abi.decode` de por medio: es lo que haces al depurar una transacción que falla o al auditar
//   un contrato que hashea o reenvía calldata.
contract CalldataTest is Test {
    Inbox inbox;
    address bob = makeAddr("bob");

    function setUp() public {
        inbox = new Inbox();
    }

    // Ceros hasta completar la última palabra de 32 bytes.
    function _padding(uint256 length) internal pure returns (bytes memory) {
        return new bytes((32 - length % 32) % 32);
    }

    // PASO 1: la calldata de post(to, amount, note), sin abi.encode. Dos palabras estáticas, el
    // offset del string y, en la cola, su longitud y sus bytes.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function _postCalldata(address to, uint256 amount, string memory note)
        internal
        pure
        returns (bytes memory)
    {
        revert("TODO: Paso 1");
        //> bytes memory text = bytes(note);
        //> return abi.encodePacked(
        //>     Inbox.post.selector,
        //>     uint256(uint160(to)), // 0x00: la dirección, con ceros a la izquierda
        //>     amount, // 0x20
        //>     uint256(0x60), // 0x40: el string empieza en el byte 0x60
        //>     text.length, // 0x60: la cola, con la longitud
        //>     text, // 0x80: los bytes y su relleno
        //>     _padding(text.length)
        //> );
    }

    // PASO 2: la calldata de totalLength(notes). Cada string es dinámico dentro de un array
    // dinámico: el array lleva una tabla de offsets, contados desde justo después de su longitud.
    function _totalLengthCalldata(string[] memory notes) internal pure returns (bytes memory) {
        revert("TODO: Paso 2");
        //> bytes memory offsets;
        //> bytes memory elements;
        //> for (uint256 i = 0; i < notes.length; i++) {
        //>     offsets = abi.encodePacked(offsets, notes.length * 32 + elements.length);
        //>     bytes memory text = bytes(notes[i]);
        //>     elements = abi.encodePacked(elements, text.length, text, _padding(text.length));
        //> }
        //> return abi.encodePacked(
        //>     Inbox.totalLength.selector,
        //>     uint256(0x20), // el array empieza en el byte 0x20
        //>     notes.length,
        //>     offsets,
        //>     elements
        //> );
    }

    // PASO 3: dos calldatas que el decodificador rechaza. La primera, con basura en los 12
    // bytes altos de la dirección; la segunda, sin su última palabra.
    function _withDirtyAddress(bytes memory data) internal pure returns (bytes memory dirty) {
        revert("TODO: Paso 3");
        //> dirty = bytes.concat(data); // una copia
        //> dirty[4] = 0xff; // primer byte de la palabra 0x00, detrás del selector
    }

    function _withoutLastWord(bytes memory data) internal pure returns (bytes memory short) {
        revert("TODO: Paso 3");
        //> short = new bytes(data.length - 32);
        //> for (uint256 i = 0; i < short.length; i++) {
        //>     short[i] = data[i];
        //> }
    }

    // PASO 4: separar la returndata de un revert en su selector y sus argumentos.
    function _split(bytes memory ret) internal pure returns (bytes4 selector, bytes memory args) {
        revert("TODO: Paso 4");
        //> selector = bytes4(ret);
        //> args = new bytes(ret.length - 4);
        //> for (uint256 i = 0; i < args.length; i++) {
        //>     args[i] = ret[i + 4];
        //> }
    }

    // PASO 5: el gas que gasta una llamada a allocate(size).
    function _allocateGas(uint256 size) internal view returns (uint256) {
        revert("TODO: Paso 5");
        //> uint256 before = gasleft();
        //> inbox.allocate(size);
        //> return before - gasleft();
    }

    function testFuzz_Paso1_PostByHand(address to, uint256 amount, string memory note) public pure {
        assertEq(_postCalldata(to, amount, note), abi.encodeCall(Inbox.post, (to, amount, note)));
    }

    function test_Paso1_CallWithHandMadeCalldata() public {
        (bool ok, bytes memory ret) = address(inbox).call(_postCalldata(bob, 5, "hola"));
        assertTrue(ok);
        assertEq(ret, abi.encode(uint256(1)));
    }

    function test_Paso2_NestedDynamicByHand() public {
        string[] memory notes = new string[](4);
        notes[0] = "ab";
        notes[1] = "cde";
        notes[2] = "";
        notes[3] = "una nota larga, con cuarenta y tantos bytes";
        bytes memory data = _totalLengthCalldata(notes);
        assertEq(data, abi.encodeCall(Inbox.totalLength, (notes)));
        (bool ok, bytes memory ret) = address(inbox).call(data);
        assertTrue(ok);
        assertEq(abi.decode(ret, (uint256)), 48);
    }

    function test_Paso3_DecoderRules() public {
        bytes memory data = _postCalldata(bob, 5, "hola");

        // Basura en la dirección: revierte sin datos de error.
        (bool ok, bytes memory ret) = address(inbox).call(_withDirtyAddress(data));
        assertFalse(ok);
        assertEq(ret.length, 0);

        // Calldata corta: el string promete 4 bytes que no llegan.
        (ok, ret) = address(inbox).call(_withoutLastWord(data));
        assertFalse(ok);
        assertEq(ret.length, 0);

        // Bytes de más al final: se ignoran. Dos calldatas distintas, la misma llamada.
        bytes memory longer = bytes.concat(data, hex"deadbeef");
        assertNotEq(keccak256(longer), keccak256(data));
        (ok, ret) = address(inbox).call(longer);
        assertTrue(ok);
        assertEq(inbox.posted(), 1);
    }

    function test_Paso4_ThreeRevertFormats() public {
        // Error personalizado: su selector y sus argumentos.
        (bool ok, bytes memory ret) =
            address(inbox).call(abi.encodeCall(Inbox.post, (bob, 1, string(new bytes(65)))));
        assertFalse(ok);
        (bytes4 selector, bytes memory args) = _split(ret);
        assertEq(selector, Inbox.NoteTooLong.selector);
        (uint256 length, uint256 max) = abi.decode(args, (uint256, uint256));
        assertEq(length, 65);
        assertEq(max, 64);

        // `require` con texto: Error(string).
        (ok, ret) = address(inbox).call(abi.encodeCall(Inbox.post, (address(0), 1, "hola")));
        assertFalse(ok);
        (selector, args) = _split(ret);
        assertEq(selector, bytes4(keccak256("Error(string)")));
        assertEq(abi.decode(args, (string)), "Inbox: zero address");

        // Fallo del propio Solidity (aquí, dividir entre cero): Panic(uint256).
        (ok, ret) = address(inbox).call(abi.encodeCall(Inbox.split, (10, 0)));
        assertFalse(ok);
        (selector, args) = _split(ret);
        assertEq(selector, bytes4(keccak256("Panic(uint256)")));
        assertEq(abi.decode(args, (uint256)), 0x12);
    }

    function test_Paso5_MemoryCostIsQuadratic() public {
        inbox.allocate(0); // calienta la dirección: la primera llamada paga 2600 de acceso en frío
        uint256 small = _allocateGas(32 * 1024);
        uint256 large = _allocateGas(4 * 32 * 1024);
        emit log_named_uint("gas con 32 KiB", small);
        emit log_named_uint("gas con 128 KiB", large);
        assertGt(large, 4 * small);

        // Un megabyte con un millón de gas: la llamada se queda sin gas y falla.
        (bool ok,) = address(inbox).call{gas: 1_000_000}(abi.encodeCall(Inbox.allocate, (1024 * 1024)));
        assertFalse(ok);
    }
}
