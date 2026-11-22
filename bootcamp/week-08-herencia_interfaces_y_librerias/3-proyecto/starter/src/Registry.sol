// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Starter del proyecto de la semana 08: el registro de la semana 07, resuelto y todavía
//   en un solo contrato, junto a las piezas en las que se va a partir (IRegistry, Owned,
//   Openable, LabelLib e IERC165). Completa cada `// TODO:`.
// ¿Para qué? Que el control de acceso, la apertura y la validación de etiquetas se escriban
//   una vez y se hereden o se usen, y que otros contratos usen el registro por su interfaz.
// ¿Impacto? El comportamiento no cambia: los 37 tests de la semana 07 tienen que seguir
//   pasando después de cada paso del refactor.
//
// TODO: hereda de IERC165, IRegistry y Openable (en ese orden) e importa los cuatro archivos.
//   Después borra de aquí todo lo que ya declaran: el enum, el struct, los eventos y errores
//   de IRegistry; OWNER, NotOwner y onlyOwner de Owned; isOpen, OpenChanged, RegistryClosed,
//   whenOpen y setOpen de Openable. El compilador te dice qué sobra: `Error (9097):
//   Identifier already declared.` y, para eventos, funciones y modificadores repetidos,
//   `Error (5883)`, `Error (4334)` o `Error (9456)`.
contract Registry {
    // TODO: los nombres de tu dominio, los mismos de la semana 07.
    string public constant PROTOCOL_NAME = "";
    string public constant RESOURCE_NAME = "";
    uint256 public constant MAX_BATCH = 5;
    // TODO: que valga LabelLib.MAX_LENGTH, para que la regla viva en un solo sitio.
    uint256 public constant MAX_LABEL_LENGTH = 32;
    // TODO: la tasa de tu dominio, la misma de la semana 07.
    uint256 public constant REGISTRATION_FEE = 0.01 ether;

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

    address public immutable OWNER;
    uint256 public immutable CAPACITY;

    uint256 public count;
    uint256 public activeCount;
    bool public isOpen;

    mapping(uint256 => Item) private _items;
    mapping(address => uint256[]) private _idsOf;

    event ItemRegistered(uint256 indexed id, address indexed registrant, string label);
    event ItemRetired(uint256 indexed id, address indexed registrant);
    event OpenChanged(bool isOpen);
    event FeesWithdrawn(address indexed to, uint256 amount);

    error NotOwner(address caller);
    error RegistryClosed();
    error RegistryFull(uint256 capacity);
    error InvalidCapacity();
    error InvalidAmount(uint256 amount);
    error InvalidLabel();
    error ItemNotFound(uint256 id);
    error NotRegistrant(address caller, uint256 id);
    error ItemNotActive(uint256 id);
    error WrongFee(uint256 expected, uint256 sent);
    error NothingToWithdraw();
    error ZeroAddress();
    error TransferFailed(address to, uint256 amount);

    modifier onlyOwner() {
        if (msg.sender != OWNER) revert NotOwner(msg.sender);
        _;
    }

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

    /// @notice Registra un recurso nuevo pagando REGISTRATION_FEE y devuelve su identificador.
    /// @param label Nombre corto del recurso, de 1 a MAX_LABEL_LENGTH bytes.
    function register(string calldata label) external payable whenOpen returns (uint256) {
        if (activeCount >= CAPACITY) revert RegistryFull(CAPACITY);
        if (msg.value != REGISTRATION_FEE) revert WrongFee(REGISTRATION_FEE, msg.value);
        return _register(label);
    }

    /// @notice Registra varios recursos pagando una tasa por cada uno y devuelve el id del primero.
    /// @param labels Las etiquetas, entre 1 y MAX_BATCH.
    function registerBatch(string[] calldata labels) external payable whenOpen returns (uint256 firstId) {
        uint256 amount = labels.length;
        if (amount == 0 || amount > MAX_BATCH) revert InvalidAmount(amount);
        if (activeCount + amount > CAPACITY) revert RegistryFull(CAPACITY);
        uint256 fee = REGISTRATION_FEE * amount;
        if (msg.value != fee) revert WrongFee(fee, msg.value);
        firstId = count + 1;
        for (uint256 i = 0; i < amount; i++) {
            _register(labels[i]);
        }
    }

    /// @notice Retira un recurso activo y libera su plaza. Solo quien lo registró. La tasa no se devuelve.
    /// @param id Identificador del recurso.
    function retire(uint256 id) external {
        Item storage item = _items[id];
        if (item.status == Status.None) revert ItemNotFound(id);
        if (item.registrant != msg.sender) revert NotRegistrant(msg.sender, id);
        if (item.status != Status.Active) revert ItemNotActive(id);
        item.status = Status.Retired;
        activeCount--;
        emit ItemRetired(id, msg.sender);
    }

    /// @notice Abre o cierra el registro. Solo el dueño.
    /// @param open `true` para abrir, `false` para cerrar.
    function setOpen(bool open) external onlyOwner {
        isOpen = open;
        emit OpenChanged(open);
    }

    /// @notice Envía todo el ETH del registro a `to`. Solo el dueño.
    /// @param to Cuenta que recibe las tasas. No puede ser `address(0)`.
    function withdrawFees(address payable to) external onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        uint256 amount = address(this).balance;
        if (amount == 0) revert NothingToWithdraw();
        emit FeesWithdrawn(to, amount);
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert TransferFailed(to, amount);
    }

    /// @notice Devuelve un recurso entero.
    /// @param id Identificador del recurso.
    function getItem(uint256 id) external view returns (Item memory) {
        Item memory item = _items[id];
        if (item.status == Status.None) revert ItemNotFound(id);
        return item;
    }

    /// @notice Identificadores que registró una cuenta, activos o retirados.
    /// @param account La cuenta que registró.
    function idsOf(address account) external view returns (uint256[] memory) {
        return _idsOf[account];
    }

    /// @notice Cuántos recursos activos caben todavía.
    function remaining() external view returns (uint256) {
        return CAPACITY - activeCount;
    }

    /// @notice Si el registro ya alcanzó su capacidad de recursos activos.
    function isFull() external view returns (bool) {
        return activeCount >= CAPACITY;
    }

    // TODO: NatSpec. `true` para type(IRegistry).interfaceId y type(IERC165).interfaceId, y
    //   `false` para cualquier otro identificador.
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        revert("TODO: supportsInterface");
    }

    function _register(string calldata label) internal returns (uint256 id) {
        // TODO: cambia estas dos líneas por LabelLib, con `using LabelLib for string;`.
        uint256 length = bytes(label).length;
        if (length == 0 || length > MAX_LABEL_LENGTH) revert InvalidLabel();
        id = count + 1;
        count = id;
        _items[id] =
            Item({id: id, registrant: msg.sender, status: Status.Active, registeredAt: block.timestamp, label: label});
        _idsOf[msg.sender].push(id);
        activeCount++;
        assert(activeCount <= CAPACITY);
        emit ItemRegistered(id, msg.sender, label);
    }
}
