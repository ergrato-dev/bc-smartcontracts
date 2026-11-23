# Teoría 03 — delegatecall

## 🎯 Objetivos

- Explicar qué cambia entre `call` y `delegatecall`: de quién es el storage, quién es
  `msg.sender` y cuánto vale `msg.value`.
- Ejecutar código de otro contrato sobre tu propio storage.
- Escribir un `multicall` con `delegatecall` a ti mismo.
- Reconocer los dos riesgos que hacen famoso a `delegatecall`: storage que no coincide y
  `msg.value` contado dos veces.

---

## 1. Qué problema resuelve

Con `call`, el destino ejecuta **su** código sobre **su** storage. A veces quieres ejecutar
el código de otro contrato sobre **tu** storage:

- **Reutilizar código desplegado una vez.** Una librería con funciones `public` o `external`
  (semana 08) vive en su propia dirección, y quien la usa la llama con `delegatecall`.
- **Cambiar el código sin cambiar la dirección.** Un **proxy** guarda el estado y delega
  toda la lógica en otro contrato, que se puede sustituir. Es la semana 15.
- **Agrupar llamadas.** Un `multicall` ejecuta varias funciones tuyas en una transacción,
  como si las hubiera llamado el usuario una a una.

## 2. Cómo funciona

`destino.delegatecall(datos)` ejecuta el **código** de `destino` en el **contexto** de quien
llama: su storage, su saldo, su `msg.sender` y su `msg.value`. Devuelve `(bool, bytes)`, igual
que `call`, y no admite `{value: …}`: el valor es el de la llamada original.

![Comparación. Con call, alice llama a Host y Host llama a Logic: Logic ve msg.sender igual a Host y escribe en el storage de Logic. Con delegatecall, alice llama a Host y Host ejecuta el código de Logic: el código ve msg.sender igual a alice y escribe en el storage de Host. El storage de Logic no cambia](../0-assets/02-call-y-delegatecall.svg)

| | `call` | `delegatecall` |
| - | ------ | -------------- |
| Código que se ejecuta | El del destino | El del destino |
| Storage que lee y escribe | El del destino | **El de quien llama** |
| `msg.sender` dentro | Quien llama | **El que llamó a quien llama** |
| `msg.value` dentro | El que envías con `{value: …}` | **El de la llamada original** |
| `address(this)` dentro | El destino | **Quien llama** |

El código de destino no sabe nombres de variables: escribe en **slots**, las posiciones
numeradas del storage (0, 1, 2...), en el orden en que se declararon las variables. Si quien
llama no tiene las mismas variables en el mismo orden, el código escribe donde no debe.

## 3. Cómo se escribe

En `src/Delegate.sol`, una lógica y un contrato que la usa de las dos formas:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract CounterLogic {
    uint256 public count;
    address public lastCaller;

    function increment() external {
        count++;
        lastCaller = msg.sender;
    }
}

contract Host {
    uint256 public count;
    address public lastCaller;
    address public immutable LOGIC;

    error LogicFailed(bytes reason);

    constructor(address logic) {
        LOGIC = logic;
    }

    function viaCall() external {
        (bool ok, bytes memory reason) = LOGIC.call(abi.encodeCall(CounterLogic.increment, ()));
        if (!ok) revert LogicFailed(reason);
    }

    function viaDelegatecall() external {
        (bool ok, bytes memory reason) = LOGIC.delegatecall(abi.encodeCall(CounterLogic.increment, ()));
        if (!ok) revert LogicFailed(reason);
    }
}
```

`Host` repite `count` y `lastCaller` en el mismo orden que `CounterLogic`: slots 0 y 1.
`LOGIC` es `immutable`, así que no ocupa storage (semana 04). En `test/Delegate.t.sol`:

```solidity
CounterLogic logic = new CounterLogic();
Host host = new Host(address(logic));
address alice = makeAddr("alice");

function test_Call() public {
    vm.prank(alice);
    host.viaCall();
    assertEq(logic.count(), 1);
    assertEq(logic.lastCaller(), address(host));
    assertEq(host.count(), 0);
}

function test_Delegatecall() public {
    vm.prank(alice);
    host.viaDelegatecall();
    assertEq(host.count(), 1);
    assertEq(host.lastCaller(), alice);
    assertEq(logic.count(), 0);
}
```

```bash
forge test --match-path test/Delegate.t.sol
```

Los dos pasan. Con `call`, cambia la lógica y quien la llamó fue `host`. Con
`delegatecall`, cambia `host`, quien llamó fue `alice` y la lógica sigue a 0.

## 4. Un `multicall`

Con `delegatecall` a **ti mismo** (`address(this)`) ejecutas cualquiera de tus funciones a
partir de sus bytes, y `msg.sender` sigue siendo el usuario. Así, un usuario hace varias
cosas en una transacción, y los modificadores como `onlyOwner` siguen viendo quién es:

```solidity
error CallFailed(uint256 index, bytes reason);

function multicall(bytes[] calldata calls) external {
    for (uint256 i = 0; i < calls.length; i++) {
        (bool ok, bytes memory reason) = address(this).delegatecall(calls[i]);
        if (!ok) revert CallFailed(i, reason);
    }
}
```

Si una falla, revierte todo y dice cuál y por qué. Cada elemento se construye con
`abi.encodeCall(Contrato.funcion, (args))`. El proyecto de la semana añade uno al registro.

## 5. Antipatrones y riesgos

- **Storage que no coincide.** `BadHost` declara las mismas variables en otro orden:

  ```solidity
  contract BadHost {
      address public owner;   // slot 0
      uint256 public count;   // slot 1
      // ...constructor y viaDelegatecall iguales que en Host
  }
  ```

  `increment` suma 1 al slot 0 y escribe `msg.sender` en el slot 1. Un test que lo imprime:

  ```
  owner antes  0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
  owner despues 0x7Fa9385Be102aC3eac297483DD6233d62B3e1497
  count 288483288054367906220850725411644340988520946374
  ```

  El dueño pasó a ser otra dirección (la anterior más 1), y `count` es la dirección de
  alice leída como número (`cast to-hex` lo confirma). Nadie revirtió: para la EVM todo fue
  correcto. Los proxies (semana 15) existen para resolver esto con reglas fijas.
- **`msg.value` contado dos veces.** Si `multicall` fuese `payable`, cada `delegatecall` ve
  el mismo `msg.value`. Con un `deposit()` que suma `msg.value` al saldo de quien llama:

  ```solidity
  hoax(alice, 1 ether);
  piggy.multicall{value: 1 ether}(calls); // calls = [deposit(), deposit()]
  ```

  ```
  saldo apuntado 2000000000000000000
  ETH en Piggy   1000000000000000000
  ```

  Alice pagó 1 ether y tiene 2 apuntados. Fallos así han vaciado contratos reales. Un
  `multicall` con `delegatecall` no lleva `payable`: así, cualquier llamada con ETH revierte.
- **`delegatecall` a una dirección que elige otro.** El código del destino hace lo que
  quiera con tu storage: cambiar el dueño, mover todo el saldo. Solo `delegatecall` a
  código que tú fijaste (un `immutable`, `address(this)`), nunca a uno que llega como
  parámetro.
- **La lógica, llamada directamente.** `CounterLogic` también es un contrato normal y
  cualquiera puede llamarlo. Aquí no pasa nada, pero si la lógica tuviera permisos
  propios, cualquiera podría usarlos. La semana 15 lo trata con los proxies.

## 6. Trucos

- `forge inspect Host storageLayout` imprime qué variable ocupa cada slot: compara dos
  contratos antes de que uno delegue en otro.
- En la traza (`-vvvv`), una llamada delegada aparece marcada con `[delegatecall]`.
- Dentro de un `multicall`, `msg.sender` es el usuario, pero `address(this)` sigue siendo
  el contrato: no es una llamada externa nueva.

## ✅ Checklist

- [ ] Explico de quién es el storage, `msg.sender` y `msg.value` con `call` y con
  `delegatecall`.
- [ ] Escribo un `multicall` con `delegatecall` a `address(this)` que dice qué llamada
  falló.
- [ ] Explico por qué ese `multicall` no puede ser `payable`.
- [ ] Reconozco un storage que no coincide entre quien delega y la lógica.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — call y staticcall](02-call-y-staticcall.md) | **Teoría 03 — delegatecall** | [Teoría 04 — try/catch →](04-try-catch.md) |
