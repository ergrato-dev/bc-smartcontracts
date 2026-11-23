// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC165} from "./IERC165.sol";
import {IRegistrationHook} from "./IRegistrationHook.sol";

// ¿Qué? Puntos por cada alta en el registro. Cambia el nombre de los puntos por los de tu
//   dominio en los comentarios; las firmas no se cambian.
// ¿Para qué? Ser el hook del registro: cada recurso registrado suma puntos a quien lo
//   registró. La semana 11 lo sustituye por un token ERC-20.
// ¿Impacto? Solo el registro puede sumar puntos. Sin esa comprobación, cualquiera llamaría a
//   onItemRegistered y se daría los puntos que quisiera.
contract RegistrationPoints is IERC165, IRegistrationHook {
    uint256 public constant POINTS_PER_ITEM = 10;
    address public immutable REGISTRY;

    mapping(address => uint256) public pointsOf;

    error NotRegistry(address caller);
    error ZeroAddress();

    /// @notice Crea el contador de puntos de un registro.
    /// @param registry El único contrato que puede sumar puntos.
    // TODO: `ZeroAddress()` si `registry` es `address(0)`; si no, guárdalo en REGISTRY.
    constructor(address registry) {
        REGISTRY = registry;
    }

    /// @inheritdoc IRegistrationHook
    // TODO: `NotRegistry(msg.sender)` si no llama el registro; si no, suma POINTS_PER_ITEM a
    //   `registrant`.
    function onItemRegistered(uint256, address registrant, string calldata) external {
        revert("TODO: onItemRegistered");
    }

    /// @inheritdoc IERC165
    // TODO: `true` para IRegistrationHook y para IERC165; `false` para el resto.
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        revert("TODO: supportsInterface");
    }
}
