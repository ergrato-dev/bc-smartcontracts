// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// ¿Qué? Puntos de fidelidad que se gastan y se bloquean durante un plazo. El plazo se guarda en
//   un `uint64` para que cuenta y fecha quepan juntos en un slot.
// ¿Para qué? Corregir los dos fallos aritméticos que la checked math de Solidity no detecta
//   sola: un bloque `unchecked` y una conversión a un tipo más pequeño.
contract Points {
    struct Lock {
        uint192 amount;
        uint64 unlockAt;
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => Lock) public locks;

    error StillLocked(uint64 unlockAt);

    /// @notice Te da `amount` puntos. Abierto a cualquiera: es un ejercicio.
    function mint(uint256 amount) external {
        balanceOf[msg.sender] += amount;
    }

    /// @notice Gasta `amount` de tus puntos.
    function spend(uint256 amount) external {
        // PASO 4: restar con checked math. La versión vulnerable era:
        //   unchecked { balanceOf[msg.sender] -= amount; }
        revert("TODO: Paso 4");
        //> balanceOf[msg.sender] -= amount;
    }

    /// @notice Bloquea `amount` puntos durante `duration` segundos.
    function lock(uint256 amount, uint256 duration) external {
        balanceOf[msg.sender] -= amount;
        // PASO 5: convertir con SafeCast. La versión vulnerable era:
        //   locks[msg.sender] = Lock(uint192(amount), uint64(block.timestamp + duration));
        revert("TODO: Paso 5");
        //> locks[msg.sender] = Lock(SafeCast.toUint192(amount), SafeCast.toUint64(block.timestamp + duration));
    }

    /// @notice Recupera los puntos bloqueados cuando vence el plazo.
    function unlock() external {
        Lock memory current = locks[msg.sender];
        if (block.timestamp < current.unlockAt) revert StillLocked(current.unlockAt);
        delete locks[msg.sender];
        balanceOf[msg.sender] += current.amount;
    }
}
