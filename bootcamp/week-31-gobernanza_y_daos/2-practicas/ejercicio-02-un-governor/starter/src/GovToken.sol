// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

// ¿Qué? El token de gobernanza del ejercicio: un ERC-20 con los votos de ERC20Votes (ejercicio 01).
//   Emite un millón de tokens a quien lo despliega, y nunca más.
// ¿Para qué? Darle al Governor algo que contar: los votos de cada cuenta en el bloque de la foto.
// ¿Impacto? `EIP712` es obligatorio: ERC20Votes permite delegar con una firma (`delegateBySig`).
contract GovToken is ERC20, ERC20Votes {
    constructor() ERC20("Gov Token", "GOV") EIP712("Gov Token", "1") {
        _mint(msg.sender, 1_000_000 ether);
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }
}
