// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un libro de saldos con sus piezas en assembly: empaquetar una palabra, calcular el slot
//   de un mapping, apuntar un struct a un espacio de nombres ERC-7201, construir un array en
//   memoria y un cerrojo contra reentrancy en transient storage.
// ¿Para qué? Practicar las tres zonas de datos desde assembly: memoria (`mload`/`mstore` y el
//   puntero de memoria libre), storage (`sload`/`sstore` y `.slot`) y transient (`tload`/`tstore`).
// ¿Impacto? Ninguno fuera del ejercicio: guarda ETH de prueba en anvil o en los tests.
contract Ledger {
    /// @custom:storage-location erc7201:bootcamp.ledger.config
    struct Config {
        address owner;
        uint64 fee;
    }

    // keccak256(abi.encode(uint256(keccak256("bootcamp.ledger.config")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CONFIG_LOCATION = 0xdd5f1edd997c3883620047e02264e62911601722964f04716e490bb06f097900;
    // keccak256("bootcamp.ledger.lock"): un slot de transient storage que no usa nadie más.
    bytes32 private constant LOCK_SLOT = 0x5d1a025fc091446138c7afb342f52f95cb2b0f5e71c6c0c3f82bac91d1311d34;

    mapping(address => uint256) public balanceOf;

    error Reentrancy();
    error TransferFailed();
    error AlreadyInitialized();

    modifier nonReentrant() {
        // PASO 5: el cerrojo en transient storage. Si ya está puesto, revierte; si no, lo pone
        //   y lo quita al acabar la función.
        revert("TODO: Paso 5");
        //> assembly ("memory-safe") {
        //>     if tload(LOCK_SLOT) {
        //>         mstore(0, shl(224, 0xab143c06)) // Reentrancy()
        //>         revert(0, 4)
        //>     }
        //>     tstore(LOCK_SLOT, 1)
        //> }
        _;
        //> assembly ("memory-safe") {
        //>     tstore(LOCK_SLOT, 0)
        //> }
    }

    /// @notice Una dirección y un importe de 96 bits en una sola palabra: la dirección en los
    ///   20 bytes altos y el importe en los 12 bajos, como `abi.encodePacked(owner, amount)`.
    function pack(address owner, uint96 amount) external pure returns (bytes32 word) {
        // PASO 1: desplazar la dirección 96 bits a la izquierda y juntarla con el importe.
        revert("TODO: Paso 1");
        //> assembly {
        //>     word := or(shl(96, owner), amount)
        //> }
    }

    /// @notice Lo contrario de `pack`.
    function unpack(bytes32 word) external pure returns (address owner, uint96 amount) {
        revert("TODO: Paso 1");
        //> assembly {
        //>     owner := shr(96, word)
        //>     // Una máscara de 96 unos se queda con los 12 bytes bajos.
        //>     amount := and(word, 0xffffffffffffffffffffffff)
        //> }
    }

    /// @notice El slot donde vive `balanceOf[account]`, calculado en assembly.
    function balanceSlot(address account) public pure returns (bytes32 slot) {
        // PASO 2: keccak256 de la clave y el slot del mapping, en el scratch space (0x00-0x3f).
        revert("TODO: Paso 2");
        //> assembly ("memory-safe") {
        //>     mstore(0, account)
        //>     mstore(0x20, balanceOf.slot)
        //>     slot := keccak256(0, 0x40)
        //> }
    }

    /// @notice `balanceOf[account]`, leído con `sload` en el slot que calcula `balanceSlot`.
    function balanceOfAsm(address account) external view returns (uint256 amount) {
        bytes32 slot = balanceSlot(account);
        assembly {
            amount := sload(slot)
        }
    }

    /// @notice Fija el dueño y la tasa, una sola vez.
    function initialize(address owner, uint64 fee) external {
        Config storage $ = _config();
        if ($.owner != address(0)) revert AlreadyInitialized();
        $.owner = owner;
        $.fee = fee;
    }

    /// @notice El dueño y la tasa, guardados en su espacio de nombres ERC-7201.
    function config() external view returns (address owner, uint64 fee) {
        Config storage $ = _config();
        return ($.owner, $.fee);
    }

    /// @notice Un array con `0, 1, ..., n - 1` construido en memoria con assembly, y otro de `n`
    ///   sietes construido después con Solidity.
    function twoArrays(uint256 n) external pure returns (uint256[] memory range, uint256[] memory sevens) {
        range = _range(n);
        sevens = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            sevens[i] = 7;
        }
    }

    /// @notice Ingresa ETH a tu saldo.
    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    /// @notice Retira todo tu saldo. Envía antes de poner el saldo a cero, a propósito: sin el
    ///   cerrojo, es la reentrancy de la semana 21.
    function withdraw() external nonReentrant {
        uint256 amount = balanceOf[msg.sender];
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert TransferFailed();
        balanceOf[msg.sender] = 0;
    }

    function _config() private pure returns (Config storage $) {
        // PASO 3: apuntar el struct al slot del espacio de nombres.
        revert("TODO: Paso 3");
        //> assembly {
        //>     $.slot := CONFIG_LOCATION
        //> }
    }

    function _range(uint256 n) private pure returns (uint256[] memory arr) {
        // PASO 4: reservar `32 + 32 * n` bytes en el puntero de memoria libre, escribir la
        //   longitud y los elementos, y mover el puntero detrás del array.
        revert("TODO: Paso 4");
        //> assembly ("memory-safe") {
        //>     arr := mload(0x40)
        //>     mstore(arr, n)
        //>     for { let i := 0 } lt(i, n) { i := add(i, 1) } {
        //>         mstore(add(add(arr, 0x20), shl(5, i)), i)
        //>     }
        //>     mstore(0x40, add(add(arr, 0x20), shl(5, n)))
        //> }
    }
}
