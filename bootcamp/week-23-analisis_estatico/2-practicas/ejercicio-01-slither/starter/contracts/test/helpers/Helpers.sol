// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Crowdfund} from "../../src/Crowdfund.sol";

// ¿Qué? Contratos auxiliares de los tests. Slither no los analiza: no están en `src/`.

/// @notice Un ERC-20 de prueba que cualquiera puede emitir.
contract Token is ERC20 {
    constructor() ERC20("Reward", "RWD") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/// @notice Un token que no revierte cuando falla: devuelve `false`, como hacen algunos tokens reales.
contract FalseToken {
    function transfer(address, uint256) external pure returns (bool) {
        return false;
    }
}

/// @notice Aporta y, al recuperar su aporte, vuelve a llamar a `refund` una vez.
contract RefundAttacker {
    Crowdfund private immutable CROWDFUND;
    bool private reentered;

    constructor(Crowdfund crowdfund) {
        CROWDFUND = crowdfund;
    }

    function contribute() external payable {
        CROWDFUND.contribute{value: msg.value}();
    }

    function attack() external {
        CROWDFUND.refund();
    }

    receive() external payable {
        if (!reentered) {
            reentered = true;
            CROWDFUND.refund();
        }
    }
}

/// @notice Un contrato que promete un regalo y, si lo llama el dueño, le quita la campaña.
contract Phisher {
    function claimGift(Crowdfund crowdfund) external {
        crowdfund.setOwner(address(this));
    }
}
