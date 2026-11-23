// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC165} from "./IERC165.sol";
import {IRegistry} from "./IRegistry.sol";
import {Openable} from "./Openable.sol";
import {LabelLib} from "./LabelLib.sol";

// ¿Qué? Starter del proyecto de la semana 09: el registro modular de la semana 08, resuelto.
//   Esta semana no cambias el contrato: escribes las pruebas que todavía no tiene.
// ¿Para qué? Los 44 tests de ejemplo pasan, pero cada uno prueba un caso elegido a mano.
//   Los fuzz tests prueban las mismas reglas con cientos de entradas, y el test de fork las
//   prueba contra el registro que desplegaste en anvil.
// ¿Impacto? Copia aquí tu `src/` de la semana 08: estas son las firmas de referencia.
contract Registry is IERC165, IRegistry, Openable {
    using LabelLib for string;

    // TODO: los nombres de tu dominio, los mismos de la semana 08.
    string public constant PROTOCOL_NAME = "";
    string public constant RESOURCE_NAME = "";
    uint256 public constant MAX_BATCH = 5;
    uint256 public constant MAX_LABEL_LENGTH = LabelLib.MAX_LENGTH;
    // TODO: la tasa de tu dominio, la misma de la semana 08.
    uint256 public constant REGISTRATION_FEE = 0.01 ether;

    uint256 public immutable CAPACITY;

    uint256 public count;
    uint256 public activeCount;

    mapping(uint256 => Item) private _items;
    mapping(address => uint256[]) private _idsOf;

    event FeesWithdrawn(address indexed to, uint256 amount);

    error InvalidCapacity();
    error NothingToWithdraw();
    error ZeroAddress();
    error TransferFailed(address to, uint256 amount);

    /// @notice Crea el registro abierto, con su dueño y su capacidad.
    /// @param capacity Cuántos recursos activos admite el registro. Tiene que ser mayor que 0.
    constructor(uint256 capacity) {
        require(capacity > 0, InvalidCapacity());
        CAPACITY = capacity;
    }

    /// @inheritdoc IRegistry
    function register(string calldata label) external payable whenOpen returns (uint256) {
        if (activeCount >= CAPACITY) revert RegistryFull(CAPACITY);
        if (msg.value != REGISTRATION_FEE) revert WrongFee(REGISTRATION_FEE, msg.value);
        return _register(label);
    }

    /// @inheritdoc IRegistry
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

    /// @inheritdoc IRegistry
    function retire(uint256 id) external {
        Item storage item = _items[id];
        if (item.status == Status.None) revert ItemNotFound(id);
        if (item.registrant != msg.sender) revert NotRegistrant(msg.sender, id);
        if (item.status != Status.Active) revert ItemNotActive(id);
        item.status = Status.Retired;
        activeCount--;
        emit ItemRetired(id, msg.sender);
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

    /// @inheritdoc IRegistry
    function getItem(uint256 id) external view returns (Item memory) {
        Item memory item = _items[id];
        if (item.status == Status.None) revert ItemNotFound(id);
        return item;
    }

    /// @inheritdoc IRegistry
    function idsOf(address account) external view returns (uint256[] memory) {
        return _idsOf[account];
    }

    /// @inheritdoc IRegistry
    function remaining() external view returns (uint256) {
        return CAPACITY - activeCount;
    }

    /// @inheritdoc IRegistry
    function isFull() external view returns (bool) {
        return activeCount >= CAPACITY;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IRegistry).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function _register(string calldata label) internal returns (uint256 id) {
        if (!label.isValid()) revert InvalidLabel();
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
