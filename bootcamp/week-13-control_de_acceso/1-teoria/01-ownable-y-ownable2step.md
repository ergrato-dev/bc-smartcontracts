# Teoría 01 — Ownable y Ownable2Step

## 🎯 Objetivos

- Explicar qué es el control de acceso y qué limita el `Owned` de la semana 08.
- Usar `Ownable` de OpenZeppelin: `onlyOwner`, `transferOwnership` y `renounceOwnership`.
- Ver en anvil cómo un dueño se pierde con una dirección mal escrita.
- Transferir la propiedad en dos pasos con `Ownable2Step`.

---

## 1. Qué problema resuelve

Casi todo contrato tiene funciones que no puede llamar cualquiera: retirar las tasas, cambiar
un parámetro, emitir tokens. El **control de acceso** es la parte del contrato que decide
quién puede llamar a cada función. En un servidor eso lo hace un sistema de usuarios con
contraseña; en la cadena no hay usuarios, solo direcciones: el contrato compara
`msg.sender` con las direcciones que tiene apuntadas.

Desde la semana 08 lo haces con `Owned`: una dirección `immutable` fijada en el constructor y
un modificador `onlyOwner`. Funciona, pero tiene dos límites:

- **El dueño no se puede cambiar.** Si la empresa cambia de cuenta, o la clave del dueño
  queda expuesta, no hay forma de pasar el control a otra dirección. Hay que desplegar otro
  contrato y mudar a todos los usuarios.
- **Es todo o nada.** Una sola cuenta hace todo: retirar dinero, pausar, configurar. Quien
  roba esa clave lo puede todo (teoría 02).

Esta teoría resuelve el primero; la 02, el segundo.

## 2. Cómo funciona

`Ownable` de OpenZeppelin guarda el dueño en una variable normal, no `immutable`, y trae:

| Pieza | Qué hace |
| ----- | -------- |
| `owner()` | Devuelve el dueño actual |
| `onlyOwner` | Revierte con `OwnableUnauthorizedAccount(msg.sender)` si no llama el dueño |
| `transferOwnership(newOwner)` | Solo el dueño. Pasa el control a `newOwner` en ese momento. Revierte con `OwnableInvalidOwner(address(0))` si `newOwner` es `address(0)` |
| `renounceOwnership()` | Solo el dueño. Deja el dueño en `address(0)`: nadie podrá volver a llamar las funciones `onlyOwner` |
| `OwnershipTransferred(previousOwner, newOwner)` | El evento de cada cambio, también el del despliegue |
| `_transferOwnership(newOwner)` | `internal`, sin comprobaciones: para que el contrato hijo cambie el dueño a su manera |

En la versión 5 de OpenZeppelin, el constructor de `Ownable` pide el dueño inicial:
`Ownable(msg.sender)` lo deja en quien despliega, y puedes pasar otra dirección.

`Ownable2Step` hereda de `Ownable` y cambia `transferOwnership`: ya no pasa el control, solo
lo **ofrece**. La dirección queda en `pendingOwner()`, el dueño sigue siendo el mismo, y el
cambio se completa cuando la dirección ofrecida llama a `acceptOwnership()`. Si la
dirección estaba mal escrita, nadie la acepta y el dueño puede ofrecer otra.

## 3. Cómo se escribe

En `src/Notice.sol`, un tablón con un mensaje que solo cambia el dueño:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Notice is Ownable {
    string public message;

    constructor() Ownable(msg.sender) {}

    function setMessage(string calldata newMessage) external onlyOwner {
        message = newMessage;
    }
}
```

`Ownable(msg.sender)` en la cabecera del constructor llama al constructor del padre con un
argumento, como en la semana 08. `onlyOwner` es el mismo modificador de siempre, ahora
heredado.

### En anvil

**Dónde**: en el contenedor, en la carpeta del proyecto, con `anvil --silent &` recién
arrancado. La cuenta 0 despliega; la 1 es otra persona:

```bash
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1); A1=$(cast wallet address "$PK1")
forge create src/Notice.sol:Notice --private-key "$PK0" --broadcast
N=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast call $N "owner()(address)"
cast send $N "setMessage(string)" "hola" --private-key "$PK1"
```

```
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x118cdaa7: ..., data: "0x118cdaa7...": OwnableUnauthorizedAccount(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
```

El dueño es la cuenta 0. La cuenta 1 recibe `OwnableUnauthorizedAccount` con su propia
dirección. `cast` lo traduce porque el error está en los artefactos de `out/`.

### Perder el dueño

`transferOwnership` no comprueba nada más que `address(0)`. Pásale la dirección de la
cuenta 1 con el **último carácter cambiado** (una `9` en vez de una `8`), un error de copiar
y pegar:

```bash
cast send $N "transferOwnership(address)" 0x0000000000000000000000000000000000000000 --private-key "$PK0"
cast send $N "transferOwnership(address)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C9 --private-key "$PK0" --json | jq -c '[.status, .logs[0].topics]'
cast call $N "owner()(address)"
cast send $N "setMessage(string)" "hola" --private-key "$PK0"
```

```
Error: ... custom error 0x1e4fbdf7: ...: OwnableInvalidOwner(0x0000000000000000000000000000000000000000)
["0x1",["0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0","0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266","0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c9"]]
0x70997970c51812dc3a010c7D01B50E0D17Dc79c9
Error: ... custom error 0x118cdaa7: ...: OwnableUnauthorizedAccount(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
```

`address(0)` se rechaza, pero la dirección mal escrita entra: es una dirección válida que no
es de nadie. El evento `OwnershipTransferred` (topic 0 `0x8be0079c…`) lo deja escrito, y la
cuenta 0 ya no es la dueña. Nadie tiene la clave de `…79c9`: el contrato no tendrá dueño
nunca más.

## 4. En dos pasos

En `src/SafeNotice.sol`, el mismo tablón con `Ownable2Step`. Se importa `Ownable` del mismo
archivo porque el constructor sigue siendo el de `Ownable`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract SafeNotice is Ownable2Step {
    string public message;

    constructor() Ownable(msg.sender) {}

    function setMessage(string calldata newMessage) external onlyOwner {
        message = newMessage;
    }
}
```

Despliégalo y ofrece la propiedad a la cuenta 1:

```bash
forge create src/SafeNotice.sol:SafeNotice --private-key "$PK0" --broadcast
S=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
cast send $S "transferOwnership(address)" $A1 --private-key "$PK0" --json | jq -c '[.status, .logs[0].topics]'
cast call $S "owner()(address)"
cast call $S "pendingOwner()(address)"
```

```
["0x1",["0x38d16b8cac22d99fc7c124b9cd0de2d3fa1faef420bfe791d8c362d765e22700","0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266","0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8"]]
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

El evento es otro, `OwnershipTransferStarted` (`0x38d16b8c…`), y la dueña sigue siendo la
cuenta 0. Solo la cuenta ofrecida puede aceptar:

```bash
cast send $S "acceptOwnership()" --private-key "$PK0"
cast send $S "acceptOwnership()" --private-key "$PK1" --json | jq -c '[.status, .logs[0].topics]'
cast call $S "owner()(address)"
cast call $S "pendingOwner()(address)"
```

```
Error: ... custom error 0x118cdaa7: ...: OwnableUnauthorizedAccount(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
["0x1",["0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0","0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266","0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8"]]
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
0x0000000000000000000000000000000000000000
```

Ahora sí sale `OwnershipTransferred`, y `pendingOwner` vuelve a `address(0)`. Aceptar
demuestra que alguien tiene la clave de la dirección nueva: con `…79c9` nadie habría
aceptado, y la cuenta 0 seguiría siendo la dueña.

## 5. Antipatrones y riesgos

**`renounceOwnership` sin querer.** Está en todo contrato `Ownable`, también en
`Ownable2Step`, y actúa en un paso:

```bash
cast send $S "renounceOwnership()" --private-key "$PK1" --json | jq -c '[.status, .logs[0].topics]'
cast call $S "owner()(address)"
cast send $S "setMessage(string)" "hola" --private-key "$PK1"
```

```
["0x1",["0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0","0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8","0x0000000000000000000000000000000000000000000000000000000000000000"]]
0x0000000000000000000000000000000000000000
Error: ... custom error 0x118cdaa7: ...: OwnableUnauthorizedAccount(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
```

Renunciar tiene sentido cuando quieres demostrar que nadie podrá cambiar el contrato. Si tu
contrato necesita un dueño para funcionar (retirar las tasas, por ejemplo), sobrescribe
`renounceOwnership` para que revierta (ejercicio 02).

**Un dueño que es una sola clave.** `Ownable` no dice nada de quién es el dueño. Si es una
cuenta normal, su clave privada es un punto único de fallo: se pierde o se roba, y con ella
el contrato. Lo habitual es que el dueño sea otro contrato que exige varias firmas o espera
un plazo (teoría 04).

**Un dueño que lo puede todo.** Los usuarios tienen que fiarse de que el dueño no abusará
de sus funciones: cuanto más pueda hacer, más confianza exige. Lista lo que puede hacer cada
función `onlyOwner` y pregúntate si un usuario aceptaría ese riesgo.

**Mezclar `Owned` y `Ownable`.** Los dos definen `onlyOwner`: si un contrato hereda de los
dos, no compila: `Error (6480): Derived contract must override modifier "onlyOwner"`. Elige uno.

## 6. Trucos

- `cast sig-event "OwnershipTransferred(address,address)"` da el topic 0 para buscar en los
  logs todos los cambios de dueño de un contrato con `cast logs`.
- Para ver si una transferencia está a medias, lee `pendingOwner()`: distinto de
  `address(0)` es una oferta sin aceptar. Ofrecer otra dirección la sustituye.
- En un test, `vm.prank(nuevo); c.acceptOwnership();` completa el segundo paso.

## ✅ Checklist

- [ ] Explico qué limita el `Owned` de la semana 08.
- [ ] Uso `Ownable(msg.sender)` y `onlyOwner`, y reconozco `OwnableUnauthorizedAccount`.
- [ ] Explico por qué `transferOwnership` de `Ownable` pierde el contrato con una dirección
      mal escrita.
- [ ] Transfiero la propiedad con `Ownable2Step` y leo `pendingOwner`.
- [ ] Sé qué hace `renounceOwnership` y cuándo hay que desactivarlo.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 13](../README.md) | **Teoría 01 — Ownable y Ownable2Step** | [Teoría 02 — AccessControl y roles →](02-accesscontrol-y-roles.md) |
