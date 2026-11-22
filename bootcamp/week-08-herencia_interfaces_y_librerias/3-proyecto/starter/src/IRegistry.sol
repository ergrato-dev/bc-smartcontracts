// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Lo que el registro ofrece a quien registra recursos: tipos, eventos, errores y
//   funciones.
// ¿Para qué? Que otro contrato, el frontend (semana 17) o el indexador (semana 19) usen el
//   registro conociendo solo su dirección y esta interfaz.
// ¿Impacto? Cambiar una firma cambia el `interfaceId`: quien preguntaba por la anterior deja
//   de reconocer el registro.
interface IRegistry {
    enum Status {
        None,
        Active,
        Retired
    }

    struct Item {
        uint256 id;
        address registrant;
        Status status;
        uint256 registeredAt;
        string label;
    }

    event ItemRegistered(uint256 indexed id, address indexed registrant, string label);
    event ItemRetired(uint256 indexed id, address indexed registrant);

    error RegistryFull(uint256 capacity);
    error InvalidAmount(uint256 amount);
    error InvalidLabel();
    error ItemNotFound(uint256 id);
    error NotRegistrant(address caller, uint256 id);
    error ItemNotActive(uint256 id);
    error WrongFee(uint256 expected, uint256 sent);

    // TODO: declara aquí el resto de funciones que el registro ofrece a quien registra:
    //   register, registerBatch, retire, idsOf, remaining e isFull, con la misma firma que en
    //   Registry.sol y su NatSpec. getItem ya está, como ejemplo. Las del dueño (setOpen,
    //   withdrawFees) no van: no son para quien usa el registro.

    /// @notice Devuelve un recurso entero.
    /// @param id Identificador del recurso.
    function getItem(uint256 id) external view returns (Item memory);
}
