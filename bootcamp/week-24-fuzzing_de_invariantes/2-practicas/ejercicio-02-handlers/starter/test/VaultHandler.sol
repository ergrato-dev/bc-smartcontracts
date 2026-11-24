// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";
import {Vault} from "../src/Vault.sol";

// ¿Qué? El handler del vault: las acciones que el fuzzer puede hacer, con tres cuentas que
//   tienen tokens y han dado allowance, y entradas acotadas con `bound`.
// ¿Para qué? Que casi ninguna llamada revierta y que el fuzzer llegue a estados con varios
//   depositantes y rendimiento. Las variables `ghost*` cuentan lo que debería haber en el vault.
contract VaultHandler is Test {
    Token public token;
    Vault public vault;
    address[] public actors;

    uint256 public ghostDeposited;
    uint256 public ghostWithdrawn;
    uint256 public ghostYield;

    constructor(Token token_, Vault vault_) {
        token = token_;
        vault = vault_;
        actors.push(makeAddr("alice"));
        actors.push(makeAddr("bob"));
        actors.push(makeAddr("carol"));
    }

    function actorCount() external view returns (uint256) {
        return actors.length;
    }

    // PASO 2: una de las tres cuentas deposita entre 1 y un millón de tokens.
    function deposit(uint256 actorSeed, uint256 assets) external {
        //> address actor = actors[actorSeed % actors.length];
        //> assets = bound(assets, 1, 1_000_000e18);
        //> // Con rendimiento, un depósito muy pequeño daría 0 participaciones y el vault lo
        //> // rechaza: el handler no lo intenta.
        //> uint256 supply = vault.totalShares();
        //> if (supply != 0 && assets * supply / vault.totalAssets() == 0) return;
        //> token.mint(actor, assets);
        //> vm.startPrank(actor);
        //> token.approve(address(vault), assets);
        //> vault.deposit(assets);
        //> vm.stopPrank();
        // PASO 5: cuenta lo depositado.
        //> ghostDeposited += assets;
    }

    // PASO 2: una de las tres cuentas retira hasta todas sus participaciones.
    function withdraw(uint256 actorSeed, uint256 shares) external {
        //> address actor = actors[actorSeed % actors.length];
        //> shares = bound(shares, 0, vault.sharesOf(actor));
        //> if (shares == 0) return;
        //> vm.prank(actor);
        //> uint256 assets = vault.withdraw(shares);
        // PASO 5: cuenta lo retirado.
        //> ghostWithdrawn += assets;
    }

    // PASO 3: rendimiento: tokens que llegan al vault sin depósito y suben el precio.
    function addYield(uint256 assets) external {
        //> assets = bound(assets, 1, 100_000e18);
        //> token.mint(address(vault), assets);
        // PASO 5: cuenta el rendimiento.
        //> ghostYield += assets;
    }
}
