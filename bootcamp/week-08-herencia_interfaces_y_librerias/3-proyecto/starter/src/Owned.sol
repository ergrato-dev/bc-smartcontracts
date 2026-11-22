// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un dueño fijo desde el despliegue y el modificador que lo exige.
// ¿Para qué? Escribir el control de acceso una vez y heredarlo.
// ¿Impacto? `abstract`: solo tiene sentido dentro de otro contrato. El dueño no se puede
//   cambiar; si pierde su clave, nadie más tiene permisos (la semana 13 trae roles).
abstract contract Owned {
    address public immutable OWNER;

    error NotOwner(address caller);

    modifier onlyOwner() {
        // TODO: NotOwner(msg.sender) si quien llama no es OWNER. Cópialo de Registry.sol.
        _;
    }

    constructor() {
        OWNER = msg.sender;
    }
}
