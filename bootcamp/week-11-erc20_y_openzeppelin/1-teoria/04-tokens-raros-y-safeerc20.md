# Teoría 04 — Tokens raros y SafeERC20

## 🎯 Objetivos

- Reconocer los tokens que no cumplen el estándar como esperas: sin retorno, con `false` y
  con comisión.
- Mover tokens desde un contrato con `SafeERC20`.
- Apuntar lo que de verdad llegó, midiendo el saldo.

---

## 1. Qué problema resuelve

Hasta ahora tu contrato hablaba con un token que conocías: el tuyo. En cuanto un contrato
acepta **cualquier** token (una caja, un intercambio, un préstamo), habla con código que no
ha leído nadie de tu equipo. El estándar dice qué funciones existen, pero no impide que un
token:

| Comportamiento | Ejemplo real | Qué rompe |
| -------------- | ------------ | --------- |
| `transfer` y `transferFrom` **no devuelven nada** | USDT en mainnet, desplegado antes de que el estándar se cerrara | Un contrato que lee el `bool` revierte |
| Devuelven **`false`** en vez de revertir | Tokens antiguos | Un contrato que no lee el `bool` cree que cobró |
| Cobran una **comisión** al transferir | Tokens *fee-on-transfer* | Llega menos de lo pedido |
| Cambian los saldos solos | Tokens *rebasing* | El saldo apuntado deja de coincidir |
| Exigen poner el permiso a 0 antes de cambiarlo | USDT | Un segundo `approve` revierte |

Este archivo trata los tres primeros; con ellos verás el método para el resto.

## 2. Cómo funciona

**Sin retorno.** En Solidity, `IERC20(token).transferFrom(...)` espera 32 bytes de
respuesta para decodificarlos como `bool` (semana 10). Un token que no devuelve nada
responde con 0 bytes: la llamada al token sale bien y mueve los tokens, pero la decodificación
falla en **tu** contrato, que revierte. Y `try`/`catch` no atrapa ese fallo (semana 10).

**Con `false`.** Si tu contrato no lee el resultado, apunta un depósito que nunca llegó.

**`SafeERC20`** es una biblioteca de OpenZeppelin que hace la llamada a bajo nivel y acepta
las dos formas correctas de responder: 32 bytes con `true`, o 0 bytes de un contrato con
código. Cualquier otra respuesta revierte con `SafeERC20FailedOperation(token)`.

**Con comisión.** Pides 100, el token mueve 99 a tu contrato y quema o se queda 1. Si
apuntas 100, debes más de lo que tienes. La única forma de saber cuánto llegó es mirar el
saldo antes y después.

## 3. Cómo se escribe

En `src/Piggy.sol`, tres huchas que guardan cualquier token. Los tokens raros están en
`test/Tokens.sol` (los mismos del ejercicio 03): `NoReturnToken` como USDT, `FalseToken`
que devuelve `false` sin mover nada, y `FeeToken` que cobra un 1 %.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NaivePiggy {
    mapping(address => uint256) public saved;

    function save(IERC20 token, uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount); // ❌ no lee el bool
        saved[msg.sender] += amount;
    }
}

contract CheckedPiggy {
    mapping(address => uint256) public saved;

    function save(IERC20 token, uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "transfer failed");
        saved[msg.sender] += amount;
    }
}

contract SafePiggy {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public saved;

    function save(IERC20 token, uint256 amount) external {
        token.safeTransferFrom(msg.sender, address(this), amount);
        saved[msg.sender] += amount;
    }
}
```

`IERC20` es la interfaz del estándar en OpenZeppelin. `using SafeERC20 for IERC20` (la
sintaxis de bibliotecas de la semana 08) añade a cada `IERC20` las funciones
`safeTransfer`, `safeTransferFrom` y `forceApprove`.

Al compilar, el linter de forge ya avisa de la primera:

```
warning[erc20-unchecked-transfer]: ERC20 `transfer` or `transferFrom` call does not check the return value
   ╭▸ src/Piggy.sol:11:9
```

Los tests de `test/Piggy.t.sol` (cada uno deposita 100 tokens) dan:

| Test | Resultado | Qué pasó |
| ---- | --------- | -------- |
| `NaivePiggy` con `FalseToken` | `[PASS]`, `saved = 100 ether` | Apuntó 100 tokens que no llegaron |
| `CheckedPiggy` con `NoReturnToken` | `[FAIL: EvmError: Revert]` | El token movió los tokens, pero la respuesta vacía no se pudo decodificar |
| `SafePiggy` con `NoReturnToken` | `[PASS]` | Acepta la respuesta vacía |
| `SafePiggy` con `FalseToken` | `[FAIL: SafeERC20FailedOperation(0x2e23…470b)]` | Rechaza el `false` |
| `SafePiggy` con `FeeToken` | `[PASS]`, `saved = 100 ether` y saldo `99 ether` | Apuntó de más |

La traza del segundo con `-vvvv` muestra dónde falla:

```
    ├─ [59493] CheckedPiggy::save(NoReturnToken: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 100000000000000000000 [1e20])
    │   ├─ [33916] NoReturnToken::transferFrom(alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], CheckedPiggy: [0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f], 100000000000000000000 [1e20])
    │   │   └─ ← [Stop]
    │   └─ ← [Revert] EvmError: Revert
```

`[Stop]`: el token terminó bien, sin devolver nada. El revert es de `CheckedPiggy`, al
decodificar. Con este contrato, nadie podría guardar USDT.

### Medir lo que llegó

`SafeERC20` resuelve las respuestas; la comisión se resuelve midiendo:

```solidity
    function save(IERC20 token, uint256 amount) external {
        uint256 before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 received = token.balanceOf(address(this)) - before;
        saved[msg.sender] += received;
    }
```

En `test/Piggy.t.sol`, con esta versión en un contrato `MeasuredPiggy`:

```solidity
    function test_MeasuredFeeToken() public {
        MeasuredPiggy piggy = new MeasuredPiggy();
        FeeToken token = new FeeToken();
        token.mint(alice, 100 ether);
        vm.startPrank(alice);
        token.approve(address(piggy), 100 ether);
        piggy.save(IERC20(address(token)), 100 ether);
        vm.stopPrank();
        assertEq(piggy.saved(alice), 99 ether);
    }
```

`[PASS] test_MeasuredFeeToken() (gas: 1620486)`: se apuntan 99, lo que de verdad hay. El
ejercicio 03 lo hace en una caja con depósito y retirada.

### Para enviar y para aprobar

- `token.safeTransfer(to, amount)` para que tu contrato pague, con la misma protección.
- `token.forceApprove(spender, amount)` para que tu contrato apruebe a otro: si el token
  exige poner el permiso a 0 antes (como USDT), lo hace en dos pasos.

## 4. Antipatrones y riesgos

**Llamar a `transfer` o `transferFrom` de un token desconocido sin `SafeERC20`.** O revierte
con los que no devuelven nada, o se fía de los que devuelven `false`. No hay versión
correcta a mano que sea más corta que `SafeERC20`.

**Apuntar `amount` en vez de lo recibido.** Con un token con comisión, la caja debe más de lo
que tiene: los primeros en retirar cobran, y el último no puede. Si no quieres medir,
rechaza explícitamente los tokens que no conoces (una lista de tokens admitidos).

**Fiarse de `balanceOf` como prueba de quién pagó.** La diferencia de saldo dice cuánto
llegó, no quién lo envió: cualquiera puede enviar tokens al contrato con `transfer` en
cualquier momento. Mide antes y después **dentro de la misma función**, nunca comparando
con un saldo guardado de otra transacción.

**Llamar al token antes de apuntar, sin pensar en quién es el token.** Un token desconocido
puede ejecutar código al transferir y volver a llamar a tu contrato a mitad de la función
(reentrancy, semana 21). En una retirada, resta el saldo **antes** de enviar, como en la
semana 07 con el ETH.

**Aceptar un token por su dirección sin comprobar que tiene código.** `SafeERC20` revierte
si la dirección no tiene código y responde vacío, pero un contrato que guarde direcciones
de tokens para usarlas después debe comprobarlo al guardarlas (semana 10).

## 5. Trucos

- `deal(address(token), alice, 100 ether)` de forge-std da saldo de cualquier ERC-20 en un
  test, sin `mint`. Con un cuarto argumento `true`, ajusta también `totalSupply`.
- Para probar tu contrato contra tokens raros no necesitas un fork: un token de prueba de
  20 líneas, como los de `test/Tokens.sol`, reproduce el comportamiento.
- [weird-erc20](https://github.com/d-xo/weird-erc20) recopila los comportamientos raros
  conocidos, con un token de ejemplo para cada uno.

## ✅ Checklist

- [ ] Explico por qué un contrato que lee el `bool` no puede recibir USDT.
- [ ] Explico qué acepta y qué rechaza `safeTransferFrom`.
- [ ] Uso `safeTransfer`, `safeTransferFrom` y `forceApprove` con `using SafeERC20 for IERC20`.
- [ ] Apunto lo recibido midiendo el saldo antes y después, en la misma función.
- [ ] Resto el saldo antes de enviar tokens en una retirada.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — OpenZeppelin y forge install](03-openzeppelin-y-forge-install.md) | **Teoría 04 — Tokens raros y SafeERC20** | [Ejercicio 01 — ERC-20 a mano →](../2-practicas/ejercicio-01-erc20-a-mano/README.md) |
