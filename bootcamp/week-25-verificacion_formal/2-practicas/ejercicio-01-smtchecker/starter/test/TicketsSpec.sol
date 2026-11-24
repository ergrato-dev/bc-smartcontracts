// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Tickets} from "../src/Tickets.sol";

// ¿Qué? La spec de Tickets para el SMTChecker: hereda el contrato y añade funciones que solo
//   tienen un `assert`.
// ¿Para qué? El SMTChecker trata cada función pública como una transacción que puede llegar en
//   cualquier orden. Un `assert` en una función sin efectos se comprueba, así, en cualquier
//   estado al que lleve cualquier secuencia de reservas, confirmaciones y cancelaciones.
// ¿Impacto? No se despliega: existe solo para que el SMTChecker la analice (foundry.toml).
contract TicketsSpec is Tickets {
    /// @notice Reservas y ventas, juntas, nunca pasan de la capacidad.
    function checkWithinCapacity() external view {
        //> assert(sold + reserved <= CAPACITY);
    }
}
