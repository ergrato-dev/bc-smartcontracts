// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {IERC165} from "./IERC165.sol";
import {IRegistrationHook} from "./IRegistrationHook.sol";

// ¿Qué? Tu token de fidelidad de la semana 11: un ERC-20 que es el hook del registro.
// ¿Para qué? Que los puntos se puedan transferir, mostrar en una wallet y gastar en el
//   registro (`registerWithPoints`), en vez de ser un número dentro de otro contrato.
// ¿Impacto? Solo el registro que lo desplegó emite tokens. Con el tope alcanzado, la emisión
//   revierte, el registro lo anota en `HookFailed` y el alta sigue.
// TODO: hereda también de ERC20Permit (importa
//   "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol") y llama a su
//   constructor con el mismo nombre que el token: es el `name` de su dominio EIP-712.
contract LoyaltyToken is ERC20, ERC20Burnable, ERC20Capped, IERC165, IRegistrationHook {
    uint256 public constant REWARD = 10 ether;
    uint256 public constant MAX_SUPPLY = 1_000_000 ether;
    address public immutable REGISTRY;

    error NotRegistry(address caller);

    /// @notice Lo despliega el registro en su constructor: quien despliega es el registro.
    constructor() ERC20("", "") ERC20Capped(MAX_SUPPLY) {
        REGISTRY = msg.sender;
    }

    /// @inheritdoc IRegistrationHook
    function onItemRegistered(uint256, address registrant, string calldata) external {
        if (msg.sender != REGISTRY) revert NotRegistry(msg.sender);
        _mint(registrant, REWARD);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IRegistrationHook).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    // Mint, burn y transfer pasan por aquí: ERC20Capped comprueba el tope y ERC20 mueve saldos.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }
}
