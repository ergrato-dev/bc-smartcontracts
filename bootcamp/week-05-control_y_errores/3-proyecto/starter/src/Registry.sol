// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? El registro de tu protocolo, quinta capa: hace cumplir sus reglas.
// ¿Para qué? Que nadie registre de más, con el registro cerrado o en nombre del dueño.
// ¿Impacto? Cada regla que falte es una puerta abierta: los tests comprueban todas.
contract Registry {
    // TODO: los nombres de tu dominio, los mismos de la semana 04.
    string public constant PROTOCOL_NAME = "";
    string public constant RESOURCE_NAME = "";
    uint256 public constant MAX_BATCH = 5;

    address public immutable OWNER;
    uint256 public immutable CAPACITY;

    uint256 public count;
    address public lastRegistrant;
    bool public isOpen;

    error NotOwner(address caller);
    error RegistryClosed();
    error RegistryFull(uint256 capacity);
    error InvalidCapacity();
    error InvalidAmount(uint256 amount);

    // TODO: revertir con NotOwner si quien llama no es OWNER.
    modifier onlyOwner() {
        revert("TODO: onlyOwner");
        _;
    }

    // TODO: revertir con RegistryClosed si el registro está cerrado.
    modifier whenOpen() {
        revert("TODO: whenOpen");
        _;
    }

    // TODO: NatSpec (@notice y @param).
    // TODO: rechazar capacity == 0 con InvalidCapacity; guardar OWNER y CAPACITY; abrir.
    constructor(uint256 capacity) {}

    // TODO: NatSpec. Solo con el registro abierto; RegistryFull(CAPACITY) si ya está lleno.
    function register() external returns (uint256) {
        revert("TODO: register");
    }

    // TODO: NatSpec. Solo abierto; InvalidAmount si amount no está entre 1 y MAX_BATCH;
    //   RegistryFull si no caben todos. Registra con un bucle y devuelve el primer id.
    function registerBatch(uint256 amount) external returns (uint256 firstId) {
        revert("TODO: registerBatch");
    }

    // TODO: NatSpec. Solo el dueño.
    function setOpen(bool open) external {
        revert("TODO: setOpen");
    }

    // TODO: NatSpec.
    function remaining() external view returns (uint256) {
        revert("TODO: remaining");
    }

    // TODO: NatSpec.
    function isFull() external view returns (bool) {
        revert("TODO: isFull");
    }

    // TODO: asignar _nextId() a count, comprobar con assert que count <= CAPACITY y
    //   devolver count.
    function _register() internal returns (uint256) {
        revert("TODO: _register");
    }

    function _nextId() internal view returns (uint256) {
        return count + 1;
    }
}
