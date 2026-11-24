// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {ERC20FlashMint} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

// ¿Qué? El token de gobernanza del ejercicio 02 con flash loans de ERC-3156 (semana 22): cualquiera
//   puede pedir prestados tantos tokens como quiera, sin garantía, si los devuelve en la misma
//   transacción.
// ¿Para qué? Probar el ataque de Beanstalk contra esta DAO: con un millón de tokens prestados,
//   ¿cuántos votos cuentan?
// ¿Impacto? Ninguno para la DAO, porque cuenta los votos de la foto. Una gobernanza que leyera
//   `balanceOf` o `getVotes` en el momento de votar sería del primero que pida un préstamo.
contract GovToken is ERC20, ERC20Votes, ERC20FlashMint {
    constructor() ERC20("Gov Token", "GOV") EIP712("Gov Token", "1") {
        _mint(msg.sender, 1_000_000 ether);
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }
}
