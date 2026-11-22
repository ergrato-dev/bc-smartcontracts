// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Las reglas de una etiqueta válida.
// ¿Para qué? Que cualquier contrato del protocolo valide etiquetas igual, sin heredar nada.
// ¿Impacto? Cuenta bytes, no letras: "ñ" ocupa 2 bytes.
library LabelLib {
    uint256 internal constant MAX_LENGTH = 32;

    function isValid(string calldata label) internal pure returns (bool) {
        // TODO: `true` si la etiqueta tiene entre 1 y MAX_LENGTH bytes. La regla está hoy en
        //   `_register`, en Registry.sol.
        revert("TODO: isValid");
    }
}
