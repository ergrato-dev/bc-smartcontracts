// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20FlashMint} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// ¿Qué? Un ERC-20 de prueba que presta con flash loans (ERC-3156): `flashLoan` crea los
//   tokens, se los da al prestatario y, al volver, los quema con una comisión del 0,1 %.
// ¿Para qué? Que el atacante tenga millones durante una transacción sin tener nada.
// ¿Impacto? `mint` lo puede llamar cualquiera: es un token de test, nunca de una red real.
contract Token is ERC20, ERC20FlashMint {
    uint256 public constant FLASH_FEE_BPS = 10;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /// @notice Crea `amount` tokens para `to`. Solo para los tests.
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    // 10 puntos básicos (0,1 %) de lo prestado, redondeando hacia arriba: un préstamo de
    // menos de 1000 unidades no sale gratis.
    function _flashFee(address, uint256 value) internal pure override returns (uint256) {
        return Math.mulDiv(value, FLASH_FEE_BPS, 10_000, Math.Rounding.Ceil);
    }
}
