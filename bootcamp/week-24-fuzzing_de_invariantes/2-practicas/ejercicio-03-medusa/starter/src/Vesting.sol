// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ¿Qué? Un calendario de liberación (vesting): TOTAL tokens que se liberan en línea recta
//   durante DURATION segundos desde el despliegue. `release` envía al beneficiario lo liberado
//   y todavía no enviado.
// ¿Para qué? El contrato del ejercicio 03. Sus tests unitarios pasan.
// ¿Impacto? `released` es todo lo enviado hasta ahora: si no lo es, `release` vuelve a enviar
//   lo que ya envió.
contract Vesting {
    using SafeERC20 for IERC20;

    IERC20 public immutable TOKEN;
    address public immutable BENEFICIARY;
    uint256 public immutable START;
    uint256 public immutable DURATION;
    uint256 public immutable TOTAL;
    uint256 public released;

    constructor(IERC20 token, address beneficiary, uint256 duration, uint256 total) {
        TOKEN = token;
        BENEFICIARY = beneficiary;
        START = block.timestamp;
        DURATION = duration;
        TOTAL = total;
    }

    // Lo liberado en `timestamp`, enviado o no.
    function vested(uint256 timestamp) public view returns (uint256) {
        if (timestamp >= START + DURATION) return TOTAL;
        return TOTAL * (timestamp - START) / DURATION;
    }

    function release() external returns (uint256 amount) {
        amount = vested(block.timestamp) - released;
        // PASO 3: `released` acumula: suma lo de ahora a lo de antes.
        released = amount; // <- Paso 3
        //> released += amount;
        TOKEN.safeTransfer(BENEFICIARY, amount);
    }
}
