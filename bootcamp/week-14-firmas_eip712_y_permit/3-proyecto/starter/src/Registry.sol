// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {IERC165} from "./IERC165.sol";
import {IRegistry} from "./IRegistry.sol";
import {LabelLib} from "./LabelLib.sol";
import {IRegistrationHook} from "./IRegistrationHook.sol";
import {LoyaltyToken} from "./LoyaltyToken.sol";
import {Certificate} from "./Certificate.sol";

// ¿Qué? Starter del proyecto de la semana 14: tu registro de la semana 13, que ya hereda de
//   EIP712 y Nonces, con el typehash, los errores y las cabeceras de las dos altas con firma
//   (`registerBySig` y `registerWithPermit`). Los cambios por hacer están en los `// TODO:`.
// ¿Para qué? Que un miembro sin ETH pueda darse de alta si alguien patrocina la tasa, y
//   que gastar puntos no exija una transacción `approve` aparte.
// ¿Impacto? Sin los `// TODO:`, las altas con firma revierten siempre. Al escribirlas, cada
//   comprobación que falte (plazo, firmante, nonce) es una firma que alguien puede reutilizar.
contract Registry is IRegistry, AccessControl, Pausable, EIP712, Nonces {
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
    bytes32 public constant REGISTRATION_TYPEHASH =
        keccak256("Registration(address registrant,string label,uint256 nonce,uint256 deadline)");
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
    error ExpiredSignature(uint256 deadline);
    error InvalidSigner(address signer, address registrant);

    /// @notice Crea el registro sin pausa, con quien despliega como administrador.
    /// @param capacity Cuántos recursos activos admite el registro. Tiene que ser mayor que 0.
    constructor(uint256 capacity) EIP712(PROTOCOL_NAME, "1") {
        require(capacity > 0, InvalidCapacity());
        CAPACITY = capacity;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        LOYALTY = new LoyaltyToken();
        CERTIFICATE = new Certificate();
    }

    /// @inheritdoc IRegistry
    function register(string calldata label) external payable whenNotPaused returns (uint256) {
        if (activeCount >= CAPACITY) revert RegistryFull(CAPACITY);
        if (msg.value != REGISTRATION_FEE) revert WrongFee(REGISTRATION_FEE, msg.value);
        uint256 id = _register(label);
        _notifyHook(id, label);
        return id;
    }

    /// @notice Registra un recurso a nombre de `registrant`, que firmó la orden fuera de la cadena.
    /// @dev Quien llama paga la tasa y el gas; el recurso, el certificado y los puntos son de
    ///   `registrant`. La orden es el struct `Registration` de EIP-712 con el nonce actual.
    /// @param registrant Quien firmó la orden y será dueño del recurso.
    /// @param label Etiqueta del recurso, la misma que se firmó.
    /// @param deadline Último timestamp en el que vale la orden.
    /// @param signature Los 65 bytes `r ‖ s ‖ v` de la firma EIP-712 de `registrant`.
    /// @return El identificador del recurso.
    function registerBySig(address registrant, string calldata label, uint256 deadline, bytes calldata signature)
        external
        payable
        whenNotPaused
        returns (uint256)
    {
        // TODO: en este orden:
        //   1. Plazo: con `block.timestamp > deadline`, ExpiredSignature(deadline).
        //   2. structHash = keccak256(abi.encode(REGISTRATION_TYPEHASH, registrant,
        //      keccak256(bytes(label)), _useNonce(registrant), deadline)).
        //   3. El firmante: ECDSA.recover(_hashTypedDataV4(structHash), signature). Si no es
        //      `registrant`, InvalidSigner(signer, registrant).
        //   4. Capacidad y tasa, como en `register`.
        //   5. _register(registrant, label) y _notifyHook(id, registrant, label).
        revert("TODO: registerBySig");
    }

    /// @notice Registra un recurso pagando `POINTS_PRICE` tokens de fidelidad en vez de ETH.
    /// @dev Antes hay que aprobar al registro: `LOYALTY.approve(registry, POINTS_PRICE)`.
    /// @param label Etiqueta del recurso.
    /// @return El identificador del recurso.
    function registerWithPoints(string calldata label) external whenNotPaused returns (uint256) {
        return _registerWithPoints(label);
    }

    /// @notice `registerWithPoints` en una transacción: el permit firmado sustituye al `approve`.
    /// @dev Si alguien ya envió este permit al token, `permit` revierte pero la allowance ya
    ///   está dada: se ignora el fallo y `burnFrom` decide.
    /// @param label Etiqueta del recurso.
    /// @param deadline Plazo del permit.
    /// @return El identificador del recurso.
    function registerWithPermit(string calldata label, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        whenNotPaused
        returns (uint256)
    {
        // TODO: el permit de quien llama por POINTS_PRICE a este registro, dentro de un
        //   `try ... {} catch {}` (teoría 04), y después `_registerWithPoints(label)`.
        revert("TODO: registerWithPermit");
    }

    /// @inheritdoc IRegistry
    function registerBatch(string[] calldata labels) external payable whenNotPaused returns (uint256 firstId) {
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
        _pause();
    }

    /// @notice Reanuda las altas. Solo el administrador: decide que el peligro pasó.
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Envía todo el ETH del registro a `to`. Solo `TREASURER_ROLE`.
    /// @param to Cuenta que recibe las tasas. No puede ser `address(0)`.
    function withdrawFees(address payable to) external onlyRole(TREASURER_ROLE) {
        if (to == address(0)) revert ZeroAddress();
        uint256 amount = address(this).balance;
        if (amount == 0) revert NothingToWithdraw();
        emit FeesWithdrawn(to, amount);
        // Solo TREASURER_ROLE llega aquí. El linter reconoce `onlyOwner`, no `onlyRole`.
        // forge-lint: disable-next-line(arbitrary-send-eth)
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert TransferFailed(to, amount);
    }

    /// @notice Elige el contrato al que se avisa de cada alta. Solo el administrador.
    /// @param newHook Un contrato que declara IRegistrationHook con ERC-165.
    function setHook(address newHook) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newHook == address(0)) revert ZeroAddress();
        if (!_isHook(newHook)) revert InvalidHook(newHook);
        hook = newHook;
        emit HookChanged(newHook);
    }

    /// @notice Deja de avisar a ningún contrato. Solo el administrador.
    function removeHook() external onlyRole(DEFAULT_ADMIN_ROLE) {
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
        return interfaceId == type(IRegistry).interfaceId || super.supportsInterface(interfaceId);
    }

    // Quema POINTS_PRICE puntos de quien llama, con la allowance que dio al registro, y registra.
    function _registerWithPoints(string calldata label) internal returns (uint256 id) {
        if (activeCount >= CAPACITY) revert RegistryFull(CAPACITY);
        LOYALTY.burnFrom(msg.sender, POINTS_PRICE);
        id = _register(label);
        _notifyHook(id, label);
    }

    // Un lote es todo o nada: una etiqueta inválida revierte el lote entero, a propósito.
    // forge-lint: disable-next-item(require-revert-in-loop, calls-loop)
    // TODO: recibe `address registrant` como primer parámetro y úsalo en vez de `msg.sender`:
    //   con una orden firmada, quien llama (el patrocinador) no es quien registra. Pasa
    //   `msg.sender` desde las altas de siempre.
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
    // TODO: lo mismo que en `_register`: `address registrant` en vez de `msg.sender`.
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
