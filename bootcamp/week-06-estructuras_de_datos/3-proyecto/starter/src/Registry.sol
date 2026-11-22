// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? El registro de tu protocolo, sexta capa: cada recurso es un struct con sus datos.
// ¿Para qué? Saber quién registró cada recurso, en qué estado está y cuáles tiene cada
//   cuenta; y poder retirarlo para liberar su plaza.
// ¿Impacto? Retirar libera capacidad, pero un id nunca se reutiliza: los tests lo comprueban.
contract Registry {
    // TODO: los nombres de tu dominio, los mismos de la semana 05.
    string public constant PROTOCOL_NAME = "";
    string public constant RESOURCE_NAME = "";
    uint256 public constant MAX_BATCH = 5;
    uint256 public constant MAX_LABEL_LENGTH = 32;

    // None es el valor por defecto: un id que nadie registró tiene status None.
    enum Status {
        None,
        Active,
        Retired
    }

    struct Item {
        uint256 id;
        address registrant;
        Status status;
        string label;
    }

    address public immutable OWNER;
    uint256 public immutable CAPACITY;

    // count: ids emitidos (nunca baja). activeCount: recursos con status Active.
    uint256 public count;
    uint256 public activeCount;
    bool public isOpen;

    mapping(uint256 => Item) private _items;
    mapping(address => uint256[]) private _idsOf;

    error NotOwner(address caller);
    error RegistryClosed();
    error RegistryFull(uint256 capacity);
    error InvalidCapacity();
    error InvalidAmount(uint256 amount);
    error InvalidLabel();
    error ItemNotFound(uint256 id);
    error NotRegistrant(address caller, uint256 id);
    error ItemNotActive(uint256 id);

    // Igual que en la semana 05.
    modifier onlyOwner() {
        if (msg.sender != OWNER) revert NotOwner(msg.sender);
        _;
    }

    // Igual que en la semana 05.
    modifier whenOpen() {
        if (!isOpen) revert RegistryClosed();
        _;
    }

    /// @notice Crea el registro abierto, con su dueño y su capacidad.
    /// @param capacity Cuántos recursos activos admite el registro. Tiene que ser mayor que 0.
    constructor(uint256 capacity) {
        require(capacity > 0, InvalidCapacity());
        OWNER = msg.sender;
        CAPACITY = capacity;
        isOpen = true;
    }

    // TODO: NatSpec. Solo abierto; RegistryFull(CAPACITY) si activeCount llegó a CAPACITY.
    //   Delega en _register(label).
    function register(string calldata label) external returns (uint256) {
        revert("TODO: register");
    }

    // TODO: NatSpec. Solo abierto; InvalidAmount(labels.length) si no está entre 1 y
    //   MAX_BATCH; RegistryFull si no caben todos. Un bucle llama a _register por etiqueta.
    function registerBatch(string[] calldata labels) external returns (uint256 firstId) {
        revert("TODO: registerBatch");
    }

    // TODO: NatSpec. Con una referencia storage al recurso: ItemNotFound si su status es
    //   None, NotRegistrant si quien llama no lo registró, ItemNotActive si no está Active.
    //   Pasa a Retired y libera una plaza.
    function retire(uint256 id) external {
        revert("TODO: retire");
    }

    /// @notice Abre o cierra el registro. Solo el dueño.
    /// @param open `true` para abrir, `false` para cerrar.
    function setOpen(bool open) external onlyOwner {
        isOpen = open;
    }

    // TODO: NatSpec. Devuelve el struct entero; ItemNotFound si su status es None.
    function getItem(uint256 id) external view returns (Item memory) {
        revert("TODO: getItem");
    }

    // TODO: NatSpec. Los ids que registró `account`.
    function idsOf(address account) external view returns (uint256[] memory) {
        revert("TODO: idsOf");
    }

    // TODO: NatSpec. Plazas libres: ahora cuentan solo los recursos activos.
    function remaining() external view returns (uint256) {
        revert("TODO: remaining");
    }

    // TODO: NatSpec.
    function isFull() external view returns (bool) {
        revert("TODO: isFull");
    }

    // TODO: InvalidLabel si la etiqueta está vacía o pasa de MAX_LABEL_LENGTH bytes.
    //   Toma el id de _nextId(), guarda count, el Item (Active) y el id en _idsOf;
    //   suma uno a activeCount y comprueba con assert que activeCount <= CAPACITY.
    function _register(string calldata label) internal returns (uint256 id) {
        revert("TODO: _register");
    }

    function _nextId() internal view returns (uint256) {
        return count + 1;
    }
}
