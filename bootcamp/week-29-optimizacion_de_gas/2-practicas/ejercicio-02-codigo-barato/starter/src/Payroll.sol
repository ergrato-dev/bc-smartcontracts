// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Una nómina: el dueño contrata empleados, fija un presupuesto y paga a muchos en una
//   llamada. Solo lleva la cuenta de lo pagado; no mueve ETH.
// ¿Para qué? `payAll` gasta de más sin tocar el storage de más: copia lo que no necesita, carga
//   mensajes de error en el bytecode, lee antes lo caro que lo barato y comprueba dos veces lo
//   mismo. Cada paso arregla una cosa sin cambiar lo que hace.
// ¿Impacto? Ninguno fuera del ejercicio.
contract Payroll {
    struct Employee {
        string name;
        bool blocked;
        uint64 hiredAt;
    }

    address public immutable OWNER;
    uint256 public budget;
    mapping(address => Employee) public employees;
    mapping(address => uint256) public paid;

    // PASO 2: custom errors en vez de mensajes de texto.
    //> error NotOwner(address caller);
    //> error LengthMismatch(uint256 to, uint256 amounts);
    //> error OverBudget(uint256 amount, uint256 remaining);

    constructor(uint256 initialBudget) {
        OWNER = msg.sender;
        budget = initialBudget;
    }

    /// @notice Contrata a `account` con el nombre `name`. Solo el dueño.
    function hire(address account, string calldata name) external {
        require(msg.sender == OWNER, "Payroll: only the owner can do this"); // <- Paso 2
        //> if (msg.sender != OWNER) revert NotOwner(msg.sender);
        employees[account] = Employee({name: name, blocked: false, hiredAt: uint64(block.timestamp)});
    }

    /// @notice Bloquea o desbloquea los pagos a `account`. Solo el dueño.
    function setBlocked(address account, bool blocked) external {
        require(msg.sender == OWNER, "Payroll: only the owner can do this"); // <- Paso 2
        //> if (msg.sender != OWNER) revert NotOwner(msg.sender);
        employees[account].blocked = blocked;
    }

    /// @notice Paga `amounts[i]` a `to[i]`, saltando importes a cero y empleados bloqueados.
    // PASO 1: los arrays no se modifican: que se queden en la calldata.
    function payAll(address[] memory to, uint256[] memory amounts) external { // <- Paso 1
    //> function payAll(address[] calldata to, uint256[] calldata amounts) external {
        require(msg.sender == OWNER, "Payroll: only the owner can do this"); // <- Paso 2
        require(to.length == amounts.length, "Payroll: to and amounts have different lengths"); // <- Paso 2
        //> if (msg.sender != OWNER) revert NotOwner(msg.sender);
        //> if (to.length != amounts.length) revert LengthMismatch(to.length, amounts.length);
        uint256 remaining = budget;
        for (uint256 i = 0; i < to.length; i++) {
            // PASO 3: un puntero a storage en vez de una copia en memoria.
            Employee memory e = employees[to[i]]; // <- Paso 3
            //> Employee storage e = employees[to[i]];
            // PASO 4: primero lo barato.
            if (e.blocked || amounts[i] == 0) continue; // <- Paso 4
            //> if (amounts[i] == 0 || e.blocked) continue;
            require(amounts[i] <= remaining, "Payroll: payment over the remaining budget"); // <- Paso 2
            //> if (amounts[i] > remaining) revert OverBudget(amounts[i], remaining);
            // PASO 5: la línea de arriba ya garantiza que la resta no baja de cero.
            remaining -= amounts[i]; // <- Paso 5
            //> unchecked {
            //>     remaining -= amounts[i];
            //> }
            paid[to[i]] += amounts[i];
        }
        budget = remaining;
    }
}
