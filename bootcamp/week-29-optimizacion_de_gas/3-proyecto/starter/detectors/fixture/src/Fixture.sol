// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

// ¿Qué? Un registro mínimo sobre el que se prueba el detector `unpaused-register`: cada función
//   es un caso. Los nombres dicen qué debería encontrar.
// ¿Impacto? No se despliega.
contract Fixture is Pausable {
    uint256 public count;

    /// @notice Llega a `_register` con el modificador: no es un hallazgo.
    function register() external whenNotPaused returns (uint256) {
        return _register();
    }

    /// @notice Llega a `_register` sin el modificador: hallazgo.
    function registerFor() external returns (uint256) {
        return _register();
    }

    /// @notice Llega a `_register` a través de otra función interna, sin el modificador: hallazgo.
    function registerViaHelper() external returns (uint256) {
        return _helper();
    }

    /// @notice No registra: no es un hallazgo aunque no lleve el modificador.
    function pause() external {
        _pause();
    }

    function _helper() internal returns (uint256) {
        return _register();
    }

    function _register() internal returns (uint256) {
        return ++count;
    }
}
