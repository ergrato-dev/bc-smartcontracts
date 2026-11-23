// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {IERC165} from "./IERC165.sol";
import {IRegistrationHook} from "./IRegistrationHook.sol";

// ¿Qué? El token de fidelidad del registro: un ERC-20 de OpenZeppelin con tope y quema.
// ¿Para qué? Ser el hook del registro (cada alta da `REWARD` tokens a quien registró) y que
//   esos tokens se puedan transferir y gastar en `registerWithPoints`.
// ¿Impacto? Solo el registro que lo desplegó puede emitir. Sin esa comprobación, cualquiera
//   llamaría a onItemRegistered y se daría los tokens que quisiera.
contract LoyaltyToken is ERC20, ERC20Burnable, ERC20Capped, IERC165, IRegistrationHook {
    uint256 public constant REWARD = 10 ether;
    uint256 public constant MAX_SUPPLY = 1_000_000 ether;
    address public immutable REGISTRY;

    error NotRegistry(address caller);

    /// @notice Lo despliega el registro en su constructor: quien despliega es el registro.
    // TODO: el nombre y el símbolo del token de tu dominio.
    constructor() ERC20("", "") ERC20Capped(MAX_SUPPLY) {
        REGISTRY = msg.sender;
    }

    /// @inheritdoc IRegistrationHook
    // TODO: `NotRegistry(msg.sender)` si no llama el registro; si no, emite `REWARD` tokens
    //   para `registrant`.
    function onItemRegistered(uint256, address registrant, string calldata) external {
        revert("TODO: onItemRegistered");
    }

    /// @inheritdoc IERC165
    // TODO: `true` para IRegistrationHook e IERC165, `false` para el resto.
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        revert("TODO: supportsInterface");
    }

    // Mint, burn y transfer pasan por aquí: ERC20Capped comprueba el tope y ERC20 mueve saldos.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }
}
