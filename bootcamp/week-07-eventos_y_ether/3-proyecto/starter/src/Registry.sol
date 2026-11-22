// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Starter del proyecto de la semana 07: el registro de la semana 06 (ya resuelto)
//   más las declaraciones nuevas: la tasa, el campo `registeredAt`, cuatro eventos y cuatro
//   errores. Completa cada `// TODO:`.
// ¿Para qué? Registrar un recurso cuesta una tasa en ETH, cada cambio de estado emite un
//   evento y el dueño retira lo recaudado.
// ¿Impacto? El registro guarda dinero: cobra el importe exacto, no acepta ETH por otras
//   vías y paga en orden checks-effects-interactions.
contract Registry {
    // TODO: los nombres de tu dominio, los mismos de la semana 06.
    string public constant PROTOCOL_NAME = "";
    string public constant RESOURCE_NAME = "";
    uint256 public constant MAX_BATCH = 5;
    uint256 public constant MAX_LABEL_LENGTH = 32;
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
        // TODO: WrongFee(REGISTRATION_FEE, msg.value) si no llega la tasa exacta.
        return _register(label);
    }

    /// @notice Registra varios recursos pagando una tasa por cada uno y devuelve el id del primero.
    /// @param labels Las etiquetas, entre 1 y MAX_BATCH.
    function registerBatch(string[] calldata labels) external payable whenOpen returns (uint256 firstId) {
        uint256 amount = labels.length;
        if (amount == 0 || amount > MAX_BATCH) revert InvalidAmount(amount);
        if (activeCount + amount > CAPACITY) revert RegistryFull(CAPACITY);
        // TODO: WrongFee(tasa del lote, msg.value) si no llega una tasa por recurso.
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
        // TODO: emitir ItemRetired.
    }

    /// @notice Abre o cierra el registro. Solo el dueño.
    /// @param open `true` para abrir, `false` para cerrar.
    function setOpen(bool open) external onlyOwner {
        isOpen = open;
        // TODO: emitir OpenChanged.
    }

    // TODO: NatSpec. Envía todo el ETH del registro a `to`. Solo el dueño.
    function withdrawFees(address payable to) external onlyOwner {
        // TODO: ZeroAddress, NothingToWithdraw, el evento FeesWithdrawn y el envío con
        //   `call`, comprobando el resultado. En orden checks-effects-interactions.
        revert("TODO: withdrawFees");
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

    function _register(string calldata label) internal returns (uint256 id) {
        uint256 length = bytes(label).length;
        if (length == 0 || length > MAX_LABEL_LENGTH) revert InvalidLabel();
        id = _nextId();
        count = id;
        _items[id] = Item({
            id: id,
            registrant: msg.sender,
            status: Status.Active,
            registeredAt: 0, // TODO: el momento del registro.
            label: label
        });
        _idsOf[msg.sender].push(id);
        activeCount++;
        assert(activeCount <= CAPACITY);
        // TODO: emitir ItemRegistered.
    }

    function _nextId() internal view returns (uint256) {
        return count + 1;
    }
}
