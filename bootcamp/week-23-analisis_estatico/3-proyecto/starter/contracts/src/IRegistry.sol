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

    /// @notice Registra un recurso nuevo pagando la tasa y devuelve su identificador.
    /// @param label Nombre corto del recurso.
    function register(string calldata label) external payable returns (uint256);

    /// @notice Registra varios recursos pagando una tasa por cada uno y devuelve el id del primero.
    /// @param labels Las etiquetas.
    function registerBatch(string[] calldata labels) external payable returns (uint256 firstId);

    /// @notice Retira un recurso activo. Solo quien lo registró.
    /// @param id Identificador del recurso.
    function retire(uint256 id) external;

    /// @notice Devuelve un recurso entero.
    /// @param id Identificador del recurso.
    function getItem(uint256 id) external view returns (Item memory);

    /// @notice Identificadores que registró una cuenta, activos o retirados.
    /// @param account La cuenta que registró.
    function idsOf(address account) external view returns (uint256[] memory);

    /// @notice Cuántos recursos activos caben todavía.
    function remaining() external view returns (uint256);

    /// @notice Si el registro ya alcanzó su capacidad de recursos activos.
    function isFull() external view returns (bool);
}
