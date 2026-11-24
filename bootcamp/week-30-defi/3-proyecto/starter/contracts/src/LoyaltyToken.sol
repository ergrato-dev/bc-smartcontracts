// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
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
    /// @notice Puntos que cada alta emite al vault de puntos, además de los del registrante.
    uint256 public constant STAKING_BONUS = 1 ether;
    address public immutable REGISTRY;
    /// @notice El vault de puntos (semana 30): recibe el bonus de cada alta. Cero hasta que se fija.
    address public stakingVault;

    event StakingVaultSet(address indexed vault);

    error NotRegistry(address caller);
    error NotRegistryAdmin(address caller);
    error InvalidVault(address vault);
    error VaultAlreadySet(address vault);

    /// @notice Se despliega antes que el proxy del registro, con la dirección que tendrá.
    /// @param registry El proxy del registro: el único que puede emitir puntos.
    // `Registry.initialize` comprueba que `registry` es el proxy: no hace falta mirar `address(0)`.
    // forge-lint: disable-next-line(missing-zero-check)
    constructor(address registry) ERC20("", "") ERC20Capped(MAX_SUPPLY) ERC20Permit("") {
        // slither-disable-next-line missing-zero-check
        REGISTRY = registry;
    }

    /// @inheritdoc IRegistrationHook
    function onItemRegistered(uint256, address registrant, string calldata) external {
        if (msg.sender != REGISTRY) revert NotRegistry(msg.sender);
        _mint(registrant, REWARD);
        // TODO (semana 30): si `stakingVault` no es `address(0)`, emite `STAKING_BONUS` al vault.
        //   Léelo una vez a una variable local: es un SLOAD frío en cada alta.
    }

    /// @notice Fija el vault de puntos, una sola vez. Solo el administrador del registro.
    /// @dev Una vez fijado no se cambia: si se pudiera, quien controla al admin desviaría el bonus
    ///   a otra dirección, y los depositantes no sabrían a qué vault llega.
    function setStakingVault(address vault) external {
        // TODO (semana 30): tres comprobaciones, en este orden, y después guarda `vault` y emite
        //   `StakingVaultSet(vault)`:
        //   1. `IAccessControl(REGISTRY).hasRole(0x00, msg.sender)`, o `NotRegistryAdmin(msg.sender)`.
        //   2. `vault` no es `address(0)`, o `InvalidVault(vault)`.
        //   3. `stakingVault` todavía es `address(0)`, o `VaultAlreadySet(stakingVault)`.
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
