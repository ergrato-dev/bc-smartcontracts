// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC165} from "./IERC165.sol";
import {IRegistry} from "./IRegistry.sol";
import {LabelLib} from "./LabelLib.sol";
import {IRegistrationHook} from "./IRegistrationHook.sol";
import {LoyaltyToken} from "./LoyaltyToken.sol";
import {Certificate} from "./Certificate.sol";

// ¿Qué? Starter del proyecto de la semana 13: tu registro de la semana 12, que ya hereda de
//   AccessControl y Pausable en vez de Openable, y los cambios por hacer en los `// TODO:`.
// ¿Para qué? Mínimo privilegio: quien pausa no retira dinero, quien retira dinero no
//   configura, y el administrador (un timelock en anvil) cambia la configuración con plazo.
// ¿Impacto? Sin los `// TODO:`, nadie tiene roles y las funciones de dueño están abiertas a
//   cualquiera: no despliegues el starter tal cual.
contract Registry is IRegistry, AccessControl, Pausable {
    using LabelLib for string;

    string public constant PROTOCOL_NAME = "";
    string public constant RESOURCE_NAME = "";
    uint256 public constant MAX_BATCH = 5;
    uint256 public constant MAX_LABEL_LENGTH = LabelLib.MAX_LENGTH;
    uint256 public constant REGISTRATION_FEE = 0.01 ether;

    uint256 public constant HOOK_GAS = 100_000;
    uint256 public constant HOOK_CHECK_GAS = 30_000;
    uint256 public constant POINTS_PRICE = 30 ether;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER_ROLE");
    uint256 public immutable CAPACITY;
    LoyaltyToken public immutable LOYALTY;
    Certificate public immutable CERTIFICATE;

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

    /// @notice Crea el registro sin pausa, con quien despliega como administrador.
    /// @param capacity Cuántos recursos activos admite el registro. Tiene que ser mayor que 0.
    constructor(uint256 capacity) {
        require(capacity > 0, InvalidCapacity());
        CAPACITY = capacity;
        // TODO: quien despliega recibe DEFAULT_ADMIN_ROLE, y ningún rol más.
        LOYALTY = new LoyaltyToken();
        CERTIFICATE = new Certificate();
    }

    /// @inheritdoc IRegistry
    // TODO: las tres funciones de alta se bloquean en pausa.
    function register(string calldata label) external payable returns (uint256) {
        if (activeCount >= CAPACITY) revert RegistryFull(CAPACITY);
        if (msg.value != REGISTRATION_FEE) revert WrongFee(REGISTRATION_FEE, msg.value);
        uint256 id = _register(label);
        _notifyHook(id, label);
        return id;
    }

    /// @notice Registra un recurso pagando `POINTS_PRICE` tokens de fidelidad en vez de ETH.
    /// @dev Antes hay que aprobar al registro: `LOYALTY.approve(registry, POINTS_PRICE)`.
    /// @param label Etiqueta del recurso.
    /// @return El identificador del recurso.
    function registerWithPoints(string calldata label) external returns (uint256) {
        if (activeCount >= CAPACITY) revert RegistryFull(CAPACITY);
        LOYALTY.burnFrom(msg.sender, POINTS_PRICE);
        uint256 id = _register(label);
        _notifyHook(id, label);
        return id;
    }

    /// @inheritdoc IRegistry
    function registerBatch(string[] calldata labels) external payable returns (uint256 firstId) {
        uint256 amount = labels.length;
        if (amount == 0 || amount > MAX_BATCH) revert InvalidAmount(amount);
        if (activeCount + amount > CAPACITY) revert RegistryFull(CAPACITY);
        uint256 fee = REGISTRATION_FEE * amount;
        if (msg.value != fee) revert WrongFee(fee, msg.value);
        firstId = count + 1;
        for (uint256 i = 0; i < amount; i++) {
            _register(labels[i]);
        }
        // Primero todas las altas, después todos los avisos: ningún hook ve un lote a medias.
        for (uint256 i = 0; i < amount; i++) {
            _notifyHook(firstId + i, labels[i]);
        }
    }

    /// @notice Retira el recurso `id`. Solo quien tiene su certificado.
    /// @param id El id del recurso.
    function retire(uint256 id) external {
        Item storage item = _items[id];
        if (item.status == Status.None) revert ItemNotFound(id);
        if (CERTIFICATE.ownerOf(id) != msg.sender) revert NotRegistrant(msg.sender, id);
        if (item.status != Status.Active) revert ItemNotActive(id);
        item.status = Status.Retired;
        activeCount--;
        emit ItemRetired(id, msg.sender);
    }

    /// @notice Para las altas en una emergencia. Solo `PAUSER_ROLE`, sin plazo.
    function pause() external onlyRole(PAUSER_ROLE) {
        revert("TODO: pause");
    }

    /// @notice Reanuda las altas. Solo el administrador: decide que el peligro pasó.
    // TODO: solo DEFAULT_ADMIN_ROLE.
    function unpause() external {
        revert("TODO: unpause");
    }

    /// @notice Envía todo el ETH del registro a `to`. Solo `TREASURER_ROLE`.
    /// @param to Cuenta que recibe las tasas. No puede ser `address(0)`.
    // TODO: solo TREASURER_ROLE.
    function withdrawFees(address payable to) external {
        if (to == address(0)) revert ZeroAddress();
        uint256 amount = address(this).balance;
        if (amount == 0) revert NothingToWithdraw();
        emit FeesWithdrawn(to, amount);
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert TransferFailed(to, amount);
    }

    /// @notice Elige el contrato al que se avisa de cada alta. Solo el administrador.
    /// @param newHook Un contrato que declara IRegistrationHook con ERC-165.
    // TODO: solo DEFAULT_ADMIN_ROLE.
    function setHook(address newHook) external {
        if (newHook == address(0)) revert ZeroAddress();
        if (!_isHook(newHook)) revert InvalidHook(newHook);
        hook = newHook;
        emit HookChanged(newHook);
    }

    /// @notice Deja de avisar a ningún contrato. Solo el administrador.
    // TODO: solo DEFAULT_ADMIN_ROLE.
    function removeHook() external {
        hook = address(0);
        emit HookChanged(address(0));
    }

    /// @notice Ejecuta varias llamadas a este registro en una transacción, como quien llama.
    /// @dev No es `payable`: con delegatecall, cada llamada vería el mismo `msg.value`.
    /// @param calls Cada llamada codificada con `abi.encodeCall`.
    /// @return results Lo que devolvió cada llamada, codificado.
    // forge-lint: disable-next-item(calls-loop, require-revert-in-loop)
    function multicall(bytes[] calldata calls) external returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool ok, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!ok) revert CallFailed(i, result);
            results[i] = result;
        }
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

    /// @notice IRegistry, más lo que declara AccessControl: IAccessControl e IERC165.
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // TODO: también `type(IRegistry).interfaceId`.
        return super.supportsInterface(interfaceId);
    }

    // Un lote es todo o nada: una etiqueta inválida revierte el lote entero, a propósito.
    // forge-lint: disable-next-item(require-revert-in-loop, calls-loop)
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
        // Con el alta ya escrita: el certificado es nuestro y `_mint` no llama a nadie más.
        CERTIFICATE.mint(msg.sender, id);
    }

    // Avisa al hook al final, con el estado ya escrito. Si falla, deja el motivo en un evento
    // y el registro sigue.
    // forge-lint: disable-next-item(calls-loop, reentrancy-events)
    function _notifyHook(uint256 id, string calldata label) internal {
        address current = hook;
        if (current == address(0)) return;
        try IRegistrationHook(current).onItemRegistered{gas: HOOK_GAS}(id, msg.sender, label) {}
        catch (bytes memory reason) {
            emit HookFailed(id, reason);
        }
    }

    // `true` si `target` tiene código y declara IRegistrationHook con ERC-165.
    function _isHook(address target) internal view returns (bool) {
        if (target.code.length == 0) return false;
        try IERC165(target).supportsInterface{gas: HOOK_CHECK_GAS}(type(IRegistrationHook).interfaceId) returns (
            bool ok
        ) {
            return ok;
        } catch {
            return false;
        }
    }
}
