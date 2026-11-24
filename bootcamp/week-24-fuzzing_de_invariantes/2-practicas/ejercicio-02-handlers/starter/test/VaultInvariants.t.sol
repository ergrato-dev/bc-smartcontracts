// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {Vault} from "../src/Vault.sol";
import {VaultHandler} from "./VaultHandler.sol";

// ¿Qué? Invariantes con el vault como objetivo directo, sin handler.
// ¿Para qué? Ver qué pasa cuando el fuzzer llama a deposit y withdraw desde cuentas sin tokens.
contract VaultOpenTest is Test {
    Vault vault;

    function setUp() public {
        vault = new Vault(new Token());
        targetContract(address(vault));
    }

    // PASO 1: nunca hay más participaciones que tokens (sin rendimiento, son 1:1).
    function invariant_SharesBackedByAssets() public view {
        revert("TODO: Paso 1");
        //> assertLe(vault.totalShares(), vault.totalAssets());
    }
}

// ¿Qué? Las invariantes del vault, con el handler como único objetivo.
contract VaultInvariantsTest is Test {
    Vault vault;
    VaultHandler handler;

    function setUp() public {
        Token token = new Token();
        vault = new Vault(token);
        handler = new VaultHandler(token, vault);
        // PASO 2: el fuzzer llama solo al handler; el handler llama al vault.
        revert("TODO: Paso 2");
        //> targetContract(address(handler));
    }

    // PASO 3: la suma de las participaciones de las tres cuentas es totalShares.
    function invariant_SharesAddUp() public view {
        revert("TODO: Paso 3");
        //> uint256 sum;
        //> for (uint256 i = 0; i < handler.actorCount(); i++) {
        //>     sum += vault.sharesOf(handler.actors(i));
        //> }
        //> assertEq(sum, vault.totalShares());
    }

    // PASO 5: los tokens del vault son lo depositado más el rendimiento menos lo retirado.
    function invariant_AssetsAccounted() public view {
        revert("TODO: Paso 5");
        //> assertEq(vault.totalAssets(), handler.ghostDeposited() + handler.ghostYield() - handler.ghostWithdrawn());
    }
}
