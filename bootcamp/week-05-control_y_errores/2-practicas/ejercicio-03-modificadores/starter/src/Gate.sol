// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Una puerta con dueño, apertura y aforo. Cada regla vive en un modificador.
// ¿Para qué? Escribir cada comprobación una vez y aplicarla a varias funciones.
// ¿Impacto? Una función sin su modificador queda abierta a cualquiera: revisa cada firma.
contract Gate {
    uint256 public constant LIMIT = 10;
    uint256 public constant MAX_BATCH = 3;

    address public immutable OWNER;
    bool public isOpen;
    uint256 public count;

    error NotOwner(address caller);
    error Closed();
    error LimitExceeded(uint256 count, uint256 limit);
    error InvalidAmount(uint256 amount);

    constructor() {
        OWNER = msg.sender;
    }

    // PASO 1: solo el dueño pasa; cualquier otra cuenta revierte con NotOwner.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    modifier onlyOwner() {
        revert("TODO: Paso 1");
        //> if (msg.sender != OWNER) revert NotOwner(msg.sender);
        _;
    }

    // PASO 2: solo se pasa con la puerta abierta; si no, Closed.
    modifier whenOpen() {
        revert("TODO: Paso 2");
        //> if (!isOpen) revert Closed();
        _;
    }

    // PASO 3: comprobar DESPUÉS de ejecutar la función que no se pasó del aforo.
    modifier withinLimit() {
        _;
        revert("TODO: Paso 3");
        //> if (count > LIMIT) revert LimitExceeded(count, LIMIT);
    }

    // PASO 4: un modificador con parámetro: `amount` entre 1 y MAX_BATCH.
    modifier validAmount(uint256 amount) {
        revert("TODO: Paso 4");
        //> if (amount == 0 || amount > MAX_BATCH) revert InvalidAmount(amount);
        _;
    }

    /// @notice Abre o cierra la puerta. Solo el dueño.
    function setOpen(bool open) external onlyOwner {
        isOpen = open;
    }

    /// @notice Entra una persona.
    function enter() external whenOpen withinLimit {
        count++;
    }

    /// @notice Entran `amount` personas de una vez.
    // PASO 5: el cuerpo, con un bucle que entra de una en una.
    function enterMany(uint256 amount) external whenOpen validAmount(amount) withinLimit {
        revert("TODO: Paso 5");
        //> for (uint256 i = 0; i < amount; i++) {
        //>     count++;
        //> }
    }

    /// @notice Cierra la puerta y vacía el recinto. Solo el dueño.
    // PASO 6: el cuerpo. onlyOwner ya protege la función: no repitas la comprobación.
    function close() external onlyOwner {
        revert("TODO: Paso 6");
        //> isOpen = false;
        //> count = 0;
    }
}
