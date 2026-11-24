// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Club} from "../src/Club.sol";

// ¿Qué? Cada variable de Club leída dos veces: con su getter y directamente de su slot, con
//   `vm.load`. Tu trabajo son los ayudantes `_...` de abajo: calculan el slot y decodifican la
//   palabra de 32 bytes que hay en él.
// ¿Para qué? Saber dónde está cada dato sin el getter: es lo que hace un auditor con
//   `cast storage`, un proxy con su slot de implementación y un atacante con lo `private`.
contract StorageTest is Test {
    Club club;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.warp(1_750_000_000);
        club = new Club("Club de ajedrez", keccak256("la clave del club"));
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.prank(alice);
        club.pay{value: 1 ether}(7);
        vm.warp(1_750_000_600);
        vm.prank(bob);
        club.pay{value: 0.25 ether}(7);
        vm.prank(alice);
        club.pay{value: 2 ether}(8);
    }

    function _word(uint256 slot) internal view returns (bytes32) {
        return vm.load(address(club), bytes32(slot));
    }

    // PASO 1: las tres variables del slot 0. `forge inspect Club storageLayout` da su offset en
    // bytes, contado desde la derecha de la palabra.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function _slot0() internal view returns (uint128 totalPaid, uint64 lastPayment, bool open) {
        revert("TODO: Paso 1");
        //> uint256 word = uint256(_word(0));
        //> totalPaid = uint128(word); // bytes 0-15: la conversión se queda con los 16 de la derecha
        //> lastPayment = uint64(word >> 128); // bytes 16-23
        //> open = (word >> 192) & 0xff == 1; // byte 24
    }

    // PASO 2: el slot de balanceOf[who]. El mapping está en el slot 2.
    function _balanceSlot(address who) internal pure returns (uint256) {
        revert("TODO: Paso 2");
        //> return uint256(keccak256(abi.encode(who, uint256(2))));
    }

    // PASO 3: el slot de usedNonce[who][nonce]. El mapping de fuera está en el slot 3; el de
    // dentro empieza donde caería el valor de `usedNonce[who]`.
    function _usedNonceSlot(address who, uint256 nonce) internal pure returns (uint256) {
        revert("TODO: Paso 3");
        //> uint256 inner = uint256(keccak256(abi.encode(who, uint256(3))));
        //> return uint256(keccak256(abi.encode(nonce, inner)));
    }

    // PASO 4: el slot del elemento `i` de payments. El array está en el slot 4.
    function _paymentSlot(uint256 i) internal pure returns (uint256) {
        revert("TODO: Paso 4");
        //> return uint256(keccak256(abi.encode(uint256(4)))) + i;
    }

    // PASO 5: el string `name`, del slot 5. Corto (31 bytes o menos): datos y longitud en el
    // mismo slot. Largo: en el slot va la longitud y los datos van a partir de keccak256(5).
    function _name() internal view returns (string memory) {
        revert("TODO: Paso 5");
        //> bytes32 word = _word(5);
        //> uint256 tag = uint256(word);
        //> if (tag & 1 == 0) {
        //>     // Corto: el último byte es la longitud por 2; los datos, desde la izquierda.
        //>     bytes memory short = new bytes((tag & 0xff) / 2);
        //>     for (uint256 i = 0; i < short.length; i++) {
        //>         short[i] = word[i];
        //>     }
        //>     return string(short);
        //> }
        //> // Largo: el slot guarda longitud * 2 + 1.
        //> bytes memory long = new bytes((tag - 1) / 2);
        //> uint256 data = uint256(keccak256(abi.encode(uint256(5))));
        //> for (uint256 i = 0; i < long.length; i++) {
        //>     long[i] = _word(data + i / 32)[i % 32];
        //> }
        //> return string(long);
    }

    // PASO 6: el socio `id` (mapping en el slot 6) y el secreto `private` (slot 7). Un struct
    // ocupa slots seguidos desde el suyo, empaquetados como variables sueltas.
    function _member(uint256 id) internal view returns (address account, uint96 points, uint256 since) {
        revert("TODO: Paso 6");
        //> uint256 slot = uint256(keccak256(abi.encode(id, uint256(6))));
        //> uint256 word = uint256(_word(slot));
        //> account = address(uint160(word));
        //> points = uint96(word >> 160);
        //> since = uint256(_word(slot + 1));
    }

    function _secret() internal view returns (bytes32) {
        revert("TODO: Paso 6");
        //> return _word(7);
    }

    function test_Paso1_PackedSlot() public view {
        (uint128 totalPaid, uint64 lastPayment, bool open) = _slot0();
        assertEq(totalPaid, club.totalPaid());
        assertEq(totalPaid, 3.25 ether);
        assertEq(lastPayment, club.lastPayment());
        assertEq(lastPayment, 1_750_000_600);
        assertTrue(open);
        assertEq(address(uint160(uint256(_word(1)))), club.owner());
    }

    function test_Paso2_MappingSlot() public view {
        assertEq(uint256(_word(_balanceSlot(alice))), 3 ether);
        assertEq(uint256(_word(_balanceSlot(bob))), 0.25 ether);
        // El slot 2 en sí no guarda nada: solo da la semilla del hash.
        assertEq(_word(2), bytes32(0));
    }

    function test_Paso3_NestedMappingSlot() public view {
        assertEq(uint256(_word(_usedNonceSlot(alice, 7))), 1);
        assertEq(uint256(_word(_usedNonceSlot(alice, 8))), 1);
        assertEq(uint256(_word(_usedNonceSlot(bob, 8))), 0);
        assertEq(club.usedNonce(bob, 7), true);
        assertEq(uint256(_word(_usedNonceSlot(bob, 7))), 1);
    }

    function test_Paso4_ArraySlot() public view {
        assertEq(uint256(_word(4)), 3); // el slot del array guarda su longitud
        assertEq(uint256(_word(_paymentSlot(0))), 1 ether);
        assertEq(uint256(_word(_paymentSlot(1))), 0.25 ether);
        assertEq(uint256(_word(_paymentSlot(2))), 2 ether);
        assertEq(uint256(_word(_paymentSlot(3))), 0);
    }

    function test_Paso5_ShortAndLongString() public {
        assertEq(_name(), "Club de ajedrez");
        club.rename("Club de ajedrez y damas del barrio de San Bernardo");
        assertEq(_name(), club.name());
        assertEq(bytes(_name()).length, 50);
    }

    function test_Paso6_StructAndPrivate() public {
        vm.prank(alice);
        club.join(42, 1500);
        (address account, uint96 points, uint256 since) = _member(42);
        (address getterAccount, uint96 getterPoints, uint256 getterSince) = club.members(42);
        assertEq(account, alice);
        assertEq(account, getterAccount);
        assertEq(points, getterPoints);
        assertEq(since, getterSince);
        assertEq(_secret(), keccak256("la clave del club"));
    }
}
