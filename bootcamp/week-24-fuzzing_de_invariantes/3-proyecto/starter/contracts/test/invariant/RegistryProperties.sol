// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {RegistryHandler} from "./RegistryHandler.sol";

// ¿Qué? Las invariantes del protocolo, como funciones `property_` que devuelven `true` si se
//   cumplen. Hereda las acciones del handler.
// ¿Para qué? Escribirlas una vez: Medusa las llama tras cada llamada y RegistryInvariants.t.sol
//   las comprueba con forge.
contract RegistryProperties is RegistryHandler {
    // Nunca hay más recursos activos que la capacidad.
    function property_activeWithinCapacity() external view returns (bool) {
        return registry.activeCount() <= registry.capacity();
    }

    // Cada alta suma un activo y cada retirada lo resta.
    function property_activeMatchesRetired() external view returns (bool) {
        // TODO (semana 24)
        return false;
    }

    // Un certificado por alta, y todos en manos de las cuentas del handler.
    function property_certificatesMatchCount() external view returns (bool) {
        // TODO (semana 24)
        return false;
    }

    // El registro guarda exactamente las tasas cobradas y no retiradas: lo de más se devuelve.
    function property_feesAccounted() external view returns (bool) {
        // TODO (semana 24)
        return false;
    }

    // REWARD puntos por alta, menos POINTS_PRICE por cada alta pagada con puntos.
    function property_pointsAccounted() external view returns (bool) {
        // TODO (semana 24)
        return false;
    }

    // Ninguna cuenta pasa de maxPerAccount altas.
    function property_perAccountLimit() external view returns (bool) {
        // TODO (semana 24)
        return false;
    }
}
