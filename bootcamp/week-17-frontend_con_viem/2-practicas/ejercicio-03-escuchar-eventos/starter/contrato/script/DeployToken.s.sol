// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Script} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";

// ¿Qué? Despliega el Token y reparte 100 tokens a la cuenta 1 de anvil y 50 a la cuenta 2.
// ¿Para qué? Que el ejercicio empiece con saldos y tres eventos `Transfer` en la cadena:
//   la emisión del bloque 1 y las transferencias de los bloques 2 y 3.
// Uso: forge script script/DeployToken.s.sol --rpc-url <red> --private-key <clave> --broadcast
contract DeployToken is Script {
    address internal constant ACCOUNT_1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address internal constant ACCOUNT_2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    function run() external returns (Token token) {
        vm.startBroadcast();
        token = new Token();
        token.transfer(ACCOUNT_1, 100 ether);
        token.transfer(ACCOUNT_2, 50 ether);
        vm.stopBroadcast();
    }
}
