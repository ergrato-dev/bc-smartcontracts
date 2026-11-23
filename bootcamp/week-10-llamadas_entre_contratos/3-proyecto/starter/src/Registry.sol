// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC165} from "./IERC165.sol";
import {IRegistry} from "./IRegistry.sol";
import {Openable} from "./Openable.sol";
import {LabelLib} from "./LabelLib.sol";
import {IRegistrationHook} from "./IRegistrationHook.sol";

// ¿Qué? Starter del proyecto de la semana 10: el registro de la semana 09, con las
//   declaraciones de la capa nueva y una función por completar en cada `// TODO:`.
// ¿Para qué? Que el registro avise de cada alta a otro contrato (un hook) sin depender de
//   él, y que ofrezca un multicall.
// ¿Impacto? Las reglas de la semana 09 no cambian: los 44 tests de ejemplo y tus propiedades
//   tienen que seguir pasando.
contract Registry is IERC165, IRegistry, Openable {
    using LabelLib for string;

    string public constant PROTOCOL_NAME = "";
    string public constant RESOURCE_NAME = "";
    uint256 public constant MAX_BATCH = 5;
    uint256 public constant MAX_LABEL_LENGTH = LabelLib.MAX_LENGTH;
    uint256 public constant REGISTRATION_FEE = 0.01 ether;

    uint256 public constant HOOK_GAS = 100_000;
    uint256 public constant HOOK_CHECK_GAS = 30_000;
    uint256 public immutable CAPACITY;

    uint256 public count;
    uint256 public activeCount;

    mapping(uint256 => Item) private _items;
    mapping(address => uint256[]) private _idsOf;
    address public hook;

    event FeesWithdrawn(address indexed to, uint256 amount);
    event HookChanged(address indexed hook);
    event HookFailed(uint256 indexed id, bytes reason);

    error InvalidCapacity();
    error NothingToWithdraw();
    error ZeroAddress();
    error TransferFailed(address to, uint256 amount);
    error InvalidHook(address hook);
    error CallFailed(uint256 index, bytes reason);

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
        // TODO: avisa al hook después de registrar, con `_notifyHook(id, label)`.
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
        // TODO: avisa al hook de cada alta del lote, en un segundo bucle: primero todas las
        //   altas, después todos los avisos, para que ningún hook vea un lote a medias.
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

    /// @notice Elige el contrato al que se avisa de cada alta. Solo el dueño.
    /// @param newHook Un contrato que declara IRegistrationHook con ERC-165.
    // TODO: `ZeroAddress()` si es `address(0)`, `InvalidHook(newHook)` si `_isHook` dice que
    //   no. Si pasa, guárdalo y emite `HookChanged`.
    function setHook(address newHook) external onlyOwner {
        revert("TODO: setHook");
    }

    /// @notice Deja de avisar a ningún contrato. Solo el dueño.
    // TODO: vuelve a `address(0)` y emite `HookChanged(address(0))`.
    function removeHook() external onlyOwner {
        revert("TODO: removeHook");
    }

    /// @notice Ejecuta varias llamadas a este registro en una transacción, como quien llama.
    /// @dev No es `payable`: con delegatecall, cada llamada vería el mismo `msg.value`.
    /// @param calls Cada llamada codificada con `abi.encodeCall`.
    /// @return results Lo que devolvió cada llamada, codificado.
    // forge-lint: disable-next-item(calls-loop, require-revert-in-loop)
    // TODO: delegatecall a `address(this)` por cada llamada; si una falla,
    //   `CallFailed(i, sus bytes)`; si no, guarda lo que devolvió en `results[i]`.
    function multicall(bytes[] calldata calls) external returns (bytes[] memory results) {
        revert("TODO: multicall");
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

    // Un lote es todo o nada: una etiqueta inválida revierte el lote entero, a propósito.
    // forge-lint: disable-next-item(require-revert-in-loop)
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

    // Avisa al hook al final, con el estado ya escrito. Si falla, deja el motivo en un evento
    // y el registro sigue.
    // TODO: sin hook, no hagas nada. Con hook, llama a `onItemRegistered` con `try` y tope de
    //   `HOOK_GAS`; si revierte, emite `HookFailed(id, reason)`. Nunca revierte.
    // forge-lint: disable-next-item(calls-loop, reentrancy-events)
    function _notifyHook(uint256 id, string calldata label) internal {}

    // `true` si `target` tiene código y declara IRegistrationHook con ERC-165.
    // TODO: `false` si no tiene código. Si lo tiene, pregúntale con `try` y tope de
    //   `HOOK_CHECK_GAS` si soporta `type(IRegistrationHook).interfaceId`; si revierte, `false`.
    function _isHook(address target) internal view returns (bool) {
        revert("TODO: _isHook");
    }
}
