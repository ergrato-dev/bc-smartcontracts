// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Lo que tiene que cumplir un contrato para que Alarm le avise.
// ¿Para qué? Que Alarm llame a cualquier oyente sabiendo solo su dirección.
// ¿Impacto? `Snoozed` es la forma pactada de decir "ahora no": Alarm la reconoce y no la
//   trata como un fallo.
interface IListener {
    error Snoozed(uint256 round);

    function onAlarm(uint256 round) external;
}
