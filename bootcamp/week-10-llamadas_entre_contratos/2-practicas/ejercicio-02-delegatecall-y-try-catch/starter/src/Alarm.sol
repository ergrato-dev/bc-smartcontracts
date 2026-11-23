// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IListener} from "./IListener.sol";

// ¿Qué? Una alarma que avisa a una lista de oyentes cada vez que alguien la hace sonar.
// ¿Para qué? Practicar try/catch (un oyente roto no detiene a los demás) y delegatecall
//   (un multicall que agrupa llamadas del dueño).
// ¿Impacto? Los oyentes son contratos ajenos: cualquiera puede fallar, gastar todo el gas o
//   no ser un contrato. Alarm tiene que seguir funcionando en todos los casos.
contract Alarm {
    uint256 public constant LISTENER_GAS = 50_000;
    address public immutable OWNER;
    address[] public listeners;
    uint256 public round;

    event Notified(address indexed listener, uint256 round);
    event ListenerSnoozed(address indexed listener, uint256 round);
    event NotifyFailed(address indexed listener, uint256 round, bytes reason);

    error NotOwner(address caller);
    error NoCode(address listener);
    error CallFailed(uint256 index, bytes reason);

    modifier onlyOwner() {
        if (msg.sender != OWNER) revert NotOwner(msg.sender);
        _;
    }

    constructor() {
        OWNER = msg.sender;
    }

    /// @notice Añade un oyente. Solo el dueño.
    /// @param listener Un contrato que cumple IListener.
    function addListener(address listener) external onlyOwner {
        // PASO 1: rechazar una cuenta sin código. `try` no atrapa una llamada a una cuenta
        //   sin código: un solo oyente así haría revertir cada `ring`, para todos.
        //   Descomenta la línea que empieza con `//> `.
        //> if (listener.code.length == 0) revert NoCode(listener);
        listeners.push(listener);
    }

    /// @notice Cuántos oyentes hay.
    function listenerCount() external view returns (uint256) {
        return listeners.length;
    }

    /// @notice Hace sonar la alarma: avisa a cada oyente con el número de ronda.
    // forge-lint: disable-next-item(calls-loop)
    function ring() external {
        uint256 current = ++round;
        for (uint256 i = 0; i < listeners.length; i++) {
            _notify(listeners[i], current);
        }
    }

    // PASO 2: `true` si `reason` es el error `Snoozed`, con cualquier ronda. Compara los 4
    //   primeros bytes con el selector. El comentario de forge-lint silencia el aviso de
    //   recorte: aquí recortar es justo lo que quieres.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function isSnoozed(bytes memory reason) public pure returns (bool) {
        revert("TODO: Paso 2");
        //> // forge-lint: disable-next-line(unsafe-typecast)
        //> return bytes4(reason) == IListener.Snoozed.selector;
    }

    /// @notice Ejecuta varias llamadas a este contrato en una transacción, como quien llama.
    /// @param calls Cada llamada codificada con `abi.encodeCall`.
    // PASO 4: delegatecall a este mismo contrato por cada llamada. Si una falla, revertir con
    //   su posición y sus bytes. No es `payable`: así ninguna llamada ve un `msg.value`.
    // forge-lint: disable-next-item(calls-loop, require-revert-in-loop)
    function multicall(bytes[] calldata calls) external {
        revert("TODO: Paso 4");
        //> for (uint256 i = 0; i < calls.length; i++) {
        //>     (bool ok, bytes memory reason) = address(this).delegatecall(calls[i]);
        //>     if (!ok) revert CallFailed(i, reason);
        //> }
    }

    // PASO 3: avisar a un oyente con tope de gas. Si termina bien, `Notified`; si revierte con
    //   `Snoozed`, `ListenerSnoozed`; si falla de cualquier otra forma, `NotifyFailed` con los
    //   bytes del error. Nunca revierte.
    // forge-lint: disable-next-item(reentrancy-events)
    function _notify(address listener, uint256 current) internal {
        revert("TODO: Paso 3");
        //> try IListener(listener).onAlarm{gas: LISTENER_GAS}(current) {
        //>     emit Notified(listener, current);
        //> } catch (bytes memory reason) {
        //>     if (isSnoozed(reason)) {
        //>         emit ListenerSnoozed(listener, current);
        //>     } else {
        //>         emit NotifyFailed(listener, current, reason);
        //>     }
        //> }
    }
}
