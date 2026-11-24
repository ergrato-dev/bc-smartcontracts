// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Vm} from "forge-std/Vm.sol";
import {Token} from "../src/Token.sol";
import {Vesting} from "../src/Vesting.sol";

// ¿Qué? El harness del vesting: despliega el sistema en su constructor, ofrece las acciones y
//   declara las propiedades (`property_`, devuelven `true` si se cumplen).
// ¿Para qué? Lo usan los dos motores. Medusa lo despliega sin argumentos y lo llama directamente
//   (medusa.json); forge lo usa como objetivo en VestingInvariants.t.sol.
// ¿Impacto? El harness es el beneficiario: lo que libera el vesting llega a este contrato.
contract VestingProperties {
    // La dirección de los cheatcodes, la misma en forge y en Medusa.
    Vm internal constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    uint256 internal constant TOTAL = 1_000_000e18;

    Token internal token;
    Vesting internal vesting;

    constructor() {
        token = new Token();
        vesting = new Vesting(token, address(this), 365 days, TOTAL);
        token.mint(address(vesting), TOTAL);
    }

    function release() external {
        // PASO 2: lo enviado en esta llamada es exactamente lo que sube `released`.
        //> uint256 releasedBefore = vesting.released();
        uint256 amount = vesting.release();
        //> assert(vesting.released() == releasedBefore + amount);
    }

    // Medusa avanza el reloj solo entre llamadas; forge no, y necesita esta acción.
    function skipTime(uint256 seconds_) external {
        vm.warp(block.timestamp + seconds_ % 30 days);
    }

    // PASO 1: el beneficiario nunca ha recibido más de lo liberado hasta ahora.
    function property_receivedWithinVested() external view returns (bool) {
        revert("TODO: Paso 1");
        //> return token.balanceOf(address(this)) <= vesting.vested(block.timestamp);
    }
}
