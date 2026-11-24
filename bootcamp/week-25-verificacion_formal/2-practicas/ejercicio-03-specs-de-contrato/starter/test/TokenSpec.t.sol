// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {Token} from "../src/Token.sol";

// ¿Qué? Las specs de Token para Halmos, con cuentas simbólicas y, en la segunda, una llamada
//   simbólica: cualquier función de Token con cualquier argumento.
// ¿Para qué? Comprobar lo que promete cualquier token para todas las cuentas, también las que
//   coinciden (`from == to`), y para todas las funciones, también las que nadie pensó en probar.
// ¿Impacto? `SymTest` da `svm`, los cheatcodes de Halmos. forge compila este archivo, pero no
//   ejecuta sus `check_`.
contract TokenSpec is Test, SymTest {
    Token internal token;

    function setUp() public {
        token = new Token();
    }

    /// @notice Una transferencia mueve `amount` de `from` a `to`, y nada más.
    function check_TransferKeepsBalances(address from, address to, uint256 minted, uint256 amount) public {
        assertTrue(false, "TODO: Paso 1"); // <- Paso 1
        //> token.mint(from, minted);
        //> uint256 fromBefore = token.balanceOf(from);
        //> uint256 toBefore = token.balanceOf(to);
        //> vm.prank(from);
        //> token.transfer(to, amount);
        //> if (from == to) {
        //>     assertEq(token.balanceOf(from), fromBefore);
        //> } else {
        //>     assertEq(token.balanceOf(from), fromBefore - amount);
        //>     assertEq(token.balanceOf(to), toBefore + amount);
        //> }
    }

    /// @notice Ninguna llamada de otra cuenta, sin allowance, baja el saldo de `victim`.
    function check_NobodyTakesYourTokens(address caller, address victim, uint256 minted) public {
        assertTrue(false, "TODO: Paso 3"); // <- Paso 3
        //> vm.assume(caller != victim);
        //> vm.assume(caller != address(this));
        //> token.mint(victim, minted);
        //> bytes memory data = svm.createCalldata("Token");
        //> vm.prank(caller);
        //> (bool ok,) = address(token).call(data);
        //> vm.assume(ok);
        //> assertGe(token.balanceOf(victim), minted);
    }
}
