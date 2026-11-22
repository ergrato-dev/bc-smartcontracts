// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un libro de cuentas: suma importes descontando una comisión del 1 % y recuerda quién
//   escribió el último.
// ¿Para qué? Practicar las cuatro visibilidades, el getter automático de `public`, funciones
//   que se llaman entre sí y funciones que devuelven varios valores.
// ¿Impacto? `private` solo impide que otros contratos lean la variable: su valor sigue siendo
//   público en la cadena.
contract Ledger {
    // ¿Qué? `public` genera una función total() que devuelve el valor.
    uint256 public total;
    // ¿Qué? `private`: sin getter automático; solo las funciones de este contrato la leen.
    address private lastWriter;

    // PASO 1: calcular la comisión (1 %) en una función interna y exponerla con otra externa.
    // Borra las líneas del revert y descomenta las líneas que empiezan con `//> `.
    function _fee(uint256 amount) internal pure returns (uint256) {
        revert("TODO: Paso 1");
        //> return amount / 100;
    }

    /// @notice Comisión que se descuenta al sumar `amount`.
    function quoteFee(uint256 amount) external pure returns (uint256) {
        revert("TODO: Paso 1");
        //> return _fee(amount);
    }

    // PASO 2: sumar `amount` menos la comisión y guardar quién llama.
    // `public` porque el paso 3 la llama desde dentro del contrato.
    function add(uint256 amount) public {
        revert("TODO: Paso 2");
        //> total += amount - _fee(amount);
        //> lastWriter = msg.sender;
    }

    // PASO 3: sumar dos veces el mismo importe reutilizando add().
    function addTwice(uint256 amount) external {
        revert("TODO: Paso 3");
        //> add(amount);
        //> add(amount);
    }

    // PASO 4: devolver dos valores a la vez: el total y el último que escribió.
    function summary() external view returns (uint256, address) {
        revert("TODO: Paso 4");
        //> return (total, lastWriter);
    }

    // PASO 5: devolver el neto y la comisión con valores de retorno con nombre.
    function preview(uint256 amount) external pure returns (uint256 net, uint256 fee) {
        revert("TODO: Paso 5");
        //> fee = _fee(amount);
        //> net = amount - fee;
    }

    // PASO 6: decir si `account` fue la última en escribir.
    function wasWrittenBy(address account) external view returns (bool) {
        revert("TODO: Paso 6");
        //> return lastWriter == account;
    }
}
