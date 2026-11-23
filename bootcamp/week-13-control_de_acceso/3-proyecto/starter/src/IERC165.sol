// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? ERC-165: un contrato dice qué interfaces cumple.
// ¿Para qué? Que otro contrato o una dApp pregunte antes de usarlo.
// ¿Impacto? Es una declaración, no una garantía: cualquiera puede responder `true`.
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
