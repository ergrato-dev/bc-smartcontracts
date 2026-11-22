// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

// ¿Qué? Un bote de propinas que acepta ETH durante un plazo.
// ¿Para qué? Practicar `payable`, `msg.value`, `receive`, `fallback`, `block.timestamp`
//   y las unidades `ether`, `gwei` y `days`.
// ¿Impacto? Una función sin `payable` rechaza el ETH; un contrato sin `receive` rechaza
//   las transferencias sin datos. Lo que no aceptas a propósito, no entra.
contract TipJar {
    uint256 public constant MIN_TIP = 0.001 ether;

    uint256 public immutable CLOSES_AT;
    uint256 public totalTips;
    mapping(address => uint256) public tipsOf;

    event Tipped(address indexed from, uint256 amount);

    error TipTooSmall(uint256 minimum, uint256 sent);
    error JarClosed(uint256 closedAt);
    error UnknownFunction(bytes4 selector);

    // ¿Qué? El cierre queda `duration` segundos después del bloque del despliegue.
    // ¿Impacto? `block.timestamp` lo pone quien produce el bloque: vale para plazos de
    //   días u horas, no para precisión de segundos.
    constructor(uint256 duration) {
        CLOSES_AT = block.timestamp + duration;
    }

    // PASO 1: aceptar una propina. `payable` deja entrar el ETH; `msg.value` dice cuánto.
    // Borra la línea del revert y descomenta las líneas que empiezan con `//> `.
    function tip() public payable {
        revert("TODO: Paso 1");
        //> if (block.timestamp >= CLOSES_AT) revert JarClosed(CLOSES_AT);
        //> if (msg.value < MIN_TIP) revert TipTooSmall(MIN_TIP, msg.value);
        //> tipsOf[msg.sender] += msg.value;
        //> totalTips += msg.value;
        //> emit Tipped(msg.sender, msg.value);
    }

    // PASO 2: el ETH enviado sin datos (un envío "a pelo") también es una propina.
    receive() external payable {
        revert("TODO: Paso 2");
        //> tip();
    }

    // PASO 3: cualquier función que no existe revierte con su selector. Sin `payable`.
    fallback() external {
        revert("TODO: Paso 3");
        //> revert UnknownFunction(msg.sig);
    }

    // PASO 4: el saldo del contrato, en wei.
    function balance() external view returns (uint256) {
        revert("TODO: Paso 4");
        //> return address(this).balance;
    }

    // PASO 5: las propinas de `from` en gwei, y cuántos días completos le
    //   quedan abierto (0 si ya cerró).
    function stats(address from) external view returns (uint256 tipsInGwei, uint256 daysLeft) {
        revert("TODO: Paso 5");
        //> tipsInGwei = tipsOf[from] / 1 gwei;
        //> if (block.timestamp < CLOSES_AT) daysLeft = (CLOSES_AT - block.timestamp) / 1 days;
    }
}
