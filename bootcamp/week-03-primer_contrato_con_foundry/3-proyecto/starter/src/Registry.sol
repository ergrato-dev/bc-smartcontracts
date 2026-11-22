// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? El registro del recurso principal de tu protocolo: cuenta cuántos hay y recuerda
//   quién registró el último.
// ¿Para qué? Primera capa on-chain del protocolo. Las semanas siguientes le añaden reglas,
//   datos de cada recurso, eventos y pagos.
// ¿Impacto? Cualquier cuenta puede registrar: todavía no hay control de acceso (semana 05).
contract Registry {
    // TODO: declara las dos variables de estado del registro:
    //   `uint256 count;` (cuántos recursos hay) y `address latest;` (quién registró el último).
    //   No pueden llamarse como las funciones total() y lastRegistrant(): el nombre chocaría.

    // TODO: devuelve el nombre de tu protocolo, en inglés (el PROTOCOL de la semana 02).
    // Pista: return "Book Lending";
    function protocolName() external pure returns (string memory) {
        revert("TODO: protocolName");
    }

    // TODO: devuelve el nombre del recurso principal de tu dominio, en inglés y en singular.
    // Pista: return "Book";
    function resourceName() external pure returns (string memory) {
        revert("TODO: resourceName");
    }

    // TODO: registra un recurso nuevo: suma 1 al total, guarda msg.sender como último
    //   registrante y devuelve el total nuevo, que sirve de identificador (el primero es 1).
    // Pista: tres líneas: count += 1; latest = ...; return count;
    function register() external returns (uint256) {
        revert("TODO: register");
    }

    // TODO: devuelve cuántos recursos hay registrados.
    function total() external view returns (uint256) {
        revert("TODO: total");
    }

    // TODO: devuelve quién registró el último recurso (address(0) si no hay ninguno).
    function lastRegistrant() external view returns (address) {
        revert("TODO: lastRegistrant");
    }
}
