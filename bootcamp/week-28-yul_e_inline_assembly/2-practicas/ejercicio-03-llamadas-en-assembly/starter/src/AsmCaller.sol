// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Cinco formas de hablar con otros contratos desde assembly: revertir con un custom error,
//   leer un saldo con `staticcall`, reenviar una llamada y su error, llamar copiando como mucho
//   unos bytes de la returndata y desplegar con `create2`.
// ¿Para qué? Ver lo que Solidity hace por ti en cada llamada (comprobar que hay código,
//   decodificar, propagar el error) y escribirlo a mano.
// ¿Impacto? Ninguno fuera del ejercicio. `forward` llama a lo que le pidan: solo el dueño.
contract AsmCaller {
    address public immutable OWNER;

    error NotOwner(address caller);
    error BadToken(address token);
    error DeployFailed();

    constructor() {
        OWNER = msg.sender;
    }

    /// @notice Revierte con `NotOwner(msg.sender)` si no lo llama el dueño.
    function checkOwner() public view {
        address owner = OWNER;
        // PASO 1: el custom error, codificado a mano: selector y argumento.
        revert("TODO: Paso 1");
        //> assembly ("memory-safe") {
        //>     if iszero(eq(caller(), owner)) {
        //>         mstore(0, shl(224, 0x245aecd3)) // NotOwner(address)
        //>         mstore(4, caller())
        //>         revert(0, 0x24)
        //>     }
        //> }
    }

    /// @notice El saldo de `account` en el ERC-20 `token`; revierte con `BadToken` si `token`
    ///   no devuelve una palabra.
    function balanceOf(address token, address account) external view returns (uint256 amount) {
        // PASO 2: `staticcall` a `balanceOf(address)`, con la calldata en el scratch space.
        revert("TODO: Paso 2");
        //> assembly ("memory-safe") {
        //>     mstore(0, shl(224, 0x70a08231)) // balanceOf(address)
        //>     mstore(4, account)
        //>     let ok := staticcall(gas(), token, 0, 0x24, 0, 0x20)
        //>     // Una dirección sin código "responde" bien y sin datos: hay que pedir 32 bytes.
        //>     if iszero(and(ok, gt(returndatasize(), 0x1f))) {
        //>         mstore(0, shl(224, 0x732d20af)) // BadToken(address)
        //>         mstore(4, token)
        //>         revert(0, 0x24)
        //>     }
        //>     amount := mload(0)
        //> }
    }

    /// @notice Llama a `target` con `data` y devuelve su returndata; si revierte, revierte con
    ///   los mismos bytes.
    function forward(address target, bytes calldata data) external returns (bytes memory result) {
        checkOwner();
        // PASO 3: copiar la calldata a memoria, llamar y, si falla, propagar el error tal cual.
        revert("TODO: Paso 3");
        //> assembly ("memory-safe") {
        //>     let ptr := mload(0x40)
        //>     calldatacopy(ptr, data.offset, data.length)
        //>     let ok := call(gas(), target, 0, ptr, data.length, 0, 0)
        //>     let size := returndatasize()
        //>     if iszero(ok) {
        //>         returndatacopy(ptr, 0, size)
        //>         revert(ptr, size)
        //>     }
        //>     // Un `bytes` en memoria: la longitud y, detrás, los datos.
        //>     result := ptr
        //>     mstore(result, size)
        //>     returndatacopy(add(result, 0x20), 0, size)
        //>     // Redondea a palabras enteras: `and(x, not(0x1f))` borra los 5 bits bajos.
        //>     mstore(0x40, add(add(result, 0x20), and(add(size, 0x1f), not(0x1f))))
        //> }
    }

    /// @notice Llama a `target` con `data` y copia como mucho `maxCopy` bytes de su returndata.
    function callCapped(address target, bytes calldata data, uint256 maxCopy)
        external
        returns (bool ok, bytes memory head)
    {
        bytes memory payload = data;
        // PASO 4: llamar sin copiar nada y copiar después `min(returndatasize(), maxCopy)`.
        revert("TODO: Paso 4");
        //> assembly ("memory-safe") {
        //>     ok := call(gas(), target, 0, add(payload, 0x20), mload(payload), 0, 0)
        //>     let size := returndatasize()
        //>     if gt(size, maxCopy) { size := maxCopy }
        //>     head := mload(0x40)
        //>     mstore(head, size)
        //>     returndatacopy(add(head, 0x20), 0, size)
        //>     mstore(0x40, add(add(head, 0x20), and(add(size, 0x1f), not(0x1f))))
        //> }
    }

    /// @notice Despliega `initCode` con `create2` y `salt`; revierte con `DeployFailed` si no
    ///   queda un contrato.
    function deploy(bytes memory initCode, bytes32 salt) external returns (address deployed) {
        // PASO 5: `create2` no revierte si el constructor falla: devuelve la dirección 0.
        revert("TODO: Paso 5");
        //> assembly ("memory-safe") {
        //>     deployed := create2(0, add(initCode, 0x20), mload(initCode), salt)
        //>     if iszero(deployed) {
        //>         mstore(0, shl(224, 0xb4f54111)) // DeployFailed()
        //>         revert(0, 4)
        //>     }
        //> }
    }
}
