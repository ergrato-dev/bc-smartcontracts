// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// ¿Qué? Un ERC-20 mínimo (semana 11) que emite 1000 tokens a quien lo despliega.
// ¿Para qué? Tener en anvil un contrato con lecturas, escrituras, un error propio
//   (`ERC20InsufficientBalance`) y un evento (`Transfer`) para practicar con viem.
contract Token is ERC20 {
    constructor() ERC20("Bootcamp Token", "BCT") {
        _mint(msg.sender, 1000 ether);
    }
}
