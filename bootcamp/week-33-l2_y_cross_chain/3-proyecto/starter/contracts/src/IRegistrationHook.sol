// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Lo que tiene que cumplir un contrato para que el registro le avise de cada alta.
// ¿Para qué? Que el registro avise a otro contrato (puntos, un token desde la semana 11) sin
//   saber cuál es: solo su dirección y esta interfaz.
// ¿Impacto? El registro llama con tope de gas y dentro de un try: un hook que falla no
//   bloquea ningún registro, pero tampoco recibe ese aviso.
interface IRegistrationHook {
    /// @notice El registro avisa de que `registrant` registró el recurso `id`.
    /// @param id Identificador del recurso.
    /// @param registrant Quien lo registró.
    /// @param label Su etiqueta.
    function onItemRegistered(uint256 id, address registrant, string calldata label) external;
}
