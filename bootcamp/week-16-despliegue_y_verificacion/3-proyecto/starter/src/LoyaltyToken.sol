// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IERC165} from "./IERC165.sol";
import {IRegistrationHook} from "./IRegistrationHook.sol";

// ¿Qué? Tu token de fidelidad de la semana 14: un ERC-20 con permit que es el hook del registro.
// ¿Para qué? Que los puntos se puedan transferir, mostrar en una wallet y gastar en el
//   registro (`registerWithPoints`), en vez de ser un número dentro de otro contrato.
// ¿Impacto? Solo el registro cuya dirección recibe el constructor emite tokens. Con el tope alcanzado, la emisión
//   revierte, el registro lo anota en `HookFailed` y el alta sigue. Desde la semana 14 acepta
//   `permit` (ERC-2612): gastar puntos en el registro ya no exige un `approve` aparte.
contract LoyaltyToken is ERC20, ERC20Burnable, ERC20Capped, ERC20Permit, IERC165, IRegistrationHook {
    uint256 public constant REWARD = 10 ether;
    uint256 public constant MAX_SUPPLY = 1_000_000 ether;
    address public immutable REGISTRY;

    error NotRegistry(address caller);

    /// @notice Se despliega antes que el proxy del registro, con la dirección que tendrá.
    /// @param registry El proxy del registro: el único que puede emitir puntos.
    // `Registry.initialize` comprueba que `registry` es el proxy: no hace falta mirar `address(0)`.
    // forge-lint: disable-next-line(missing-zero-check)
    constructor(address registry) ERC20("", "") ERC20Capped(MAX_SUPPLY) ERC20Permit("") {
        REGISTRY = registry;
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
