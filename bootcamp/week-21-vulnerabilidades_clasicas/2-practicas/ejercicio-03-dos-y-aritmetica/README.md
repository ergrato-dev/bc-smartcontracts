# Ejercicio 03 — DoS y aritmética

> Al terminar habrás bloqueado para siempre una subasta con un contrato que no acepta ETH, la
> habrás rehecho con el patrón pull, y habrás cerrado dos fallos aritméticos que la checked math
> de Solidity no ve: un bloque `unchecked` y una conversión que corta bits.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 03 — Denegación de servicio](../../1-teoria/03-denegacion-de-servicio.md)
y [Teoría 04 — Aritmética y `unchecked`](../../1-teoria/04-aritmetica-y-unchecked.md) leídas.

## Contexto

Proyecto Foundry. Alice y Bob pujan de buena fe; Mallory quiere quedarse la subasta sin pagar
lo que vale.

| Archivo | Qué es |
| ------- | ------ |
| `src/PushAuction.sol` | Subasta que devuelve cada puja superada en el acto. **No la arregles** |
| `src/Blocker.sol` | El pujador que rechaza ETH. Paso 1 |
| `src/Auction.sol` | La subasta con patrón pull. Pasos 2 y 3 |
| `src/Points.sol` | Puntos que se gastan y se bloquean. Pasos 4 y 5 |
| `test/DosAndMath.t.sol` | Los tests. **No lo modifiques** |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-21-vulnerabilidades_clasicas/2-practicas/ejercicio-03-dos-y-aritmetica/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 passed; 7 failed`, todos con el `TODO` de su paso.

## Paso 1: El bloqueador

**Por qué**: `PushAuction.bid` devuelve el ETH al pujador anterior y, si la devolución falla,
revierte. Un contrato sin `receive` ni `fallback` rechaza todo el ETH que le llega con una
llamada sin datos. Si ese contrato es el pujador más alto, ninguna puja nueva puede
devolverle su ETH: todas revierten y gana con la puja que hizo.

```solidity
auction.bid{value: msg.value}();
```

**Abre** `src/Blocker.sol`, borra el `revert` de `attack` y descomenta su línea. Ejecuta
`forge test`.

**Verifica**: `1 passed; 6 failed`. En `test_Paso1_BlockerFreezesPushAuction`, Mallory puja
1,1 ETH a través del bloqueador y Bob, que ofrece 3, recibe
`RefundFailed(<dirección del bloqueador>)`. Nadie podrá pujar nunca más.

## Paso 2: Apuntar en vez de enviar

**Por qué**: el problema es que la puja de Bob depende de que el bloqueador acepte ETH. Con el
patrón **pull**, `bid` no envía nada: suma la puja superada a `pendingReturns` del perdedor.
Mover un número en storage no puede fallar por culpa de otro contrato.

```solidity
pendingReturns[highestBidder] += highestBid;
```

En la primera puja, `highestBidder` es `address(0)` y `highestBid` es 0: se suma 0 a una entrada
que nadie usa. Más barato que un `if`.

**Abre** `src/Auction.sol`, borra el `revert` de `bid` y descomenta su línea.

**Verifica**: `2 passed; 5 failed`. En `test_Paso2_BlockerCannotFreezeAuction`, Bob gana con 3
ETH; Alice tiene 1 ETH apuntado y el bloqueador, 1,1. El bloqueador nunca podrá retirarlos
(rechaza ETH), pero eso solo le perjudica a él.

## Paso 3: Retirar

**Por qué**: el ETH apuntado sale cuando su dueño lo pide, y cada uno paga el gas de lo suyo. Es
una función que envía ETH, así que sigue el orden del ejercicio 01: el saldo a 0 antes de
enviar.

```solidity
uint256 amount = pendingReturns[msg.sender];
if (amount == 0) revert NothingToWithdraw();
pendingReturns[msg.sender] = 0;
(bool ok,) = msg.sender.call{value: amount}("");
if (!ok) revert TransferFailed();
```

**Abre** `src/Auction.sol`, borra el `revert` de `withdraw` y descomenta sus cinco líneas.

**Verifica**: `3 passed; 4 failed`. Alice recupera su 1 ETH, en la subasta quedan los 2 de Bob y
un segundo `withdraw` da `NothingToWithdraw`.

## Paso 4: Restar sin `unchecked`

**Por qué**: desde Solidity 0.8, `a - b` revierte si el resultado sería negativo, con el pánico
`0x11` (semana 05). Dentro de `unchecked { ... }` no se comprueba: `1 - 2` da `2²⁵⁶ - 1`, el
mayor `uint256`. Quien gaste más de lo que tiene se queda con puntos casi infinitos.

```solidity
balanceOf[msg.sender] -= amount;
```

**Abre** `src/Points.sol`, borra el `revert` de `spend` y descomenta su línea.

**Verifica**: `5 passed; 2 failed`. `test_Paso4_RevertWhen_SpendMoreThanBalance` espera
`stdError.arithmeticError`, el pánico `0x11`, y el saldo de Mallory sigue en 1.

Prueba la versión vulnerable: cambia la línea por `unchecked { balanceOf[msg.sender] -= amount; }`
y ejecuta `forge test`. Ese test falla con `next call did not revert as expected`: Mallory acaba
de gastar 2 puntos teniendo 1. Vuelve a dejar la línea sin `unchecked`.

## Paso 5: Convertir con SafeCast

**Por qué**: la checked math vigila sumas, restas y multiplicaciones, pero **no** las
conversiones. `uint64(x)` se queda con los 64 bits bajos de `x` sin avisar. El test elige una
duración tal que `block.timestamp + duration` vale exactamente `2⁶⁴`; cortado a 64 bits es 0, y un
bloqueo que vence en el instante 0 ya ha vencido.

`SafeCast.toUint64` de OpenZeppelin revierte si el valor no cabe.

```solidity
locks[msg.sender] = Lock(SafeCast.toUint192(amount), SafeCast.toUint64(block.timestamp + duration));
```

**Abre** `src/Points.sol`, borra el `revert` de `lock` y descomenta su línea.

**Verifica**: `7 passed; 0 failed`. `test_Paso5_RevertWhen_DurationOverflowsUint64` recibe
`SafeCastOverflowedUintDowncast(64, 18446744073709551616)`: los bits que pedías y el valor que
no cabía, `2⁶⁴`. Con la conversión directa, ese test daría `next call did not revert as
expected`. Comprueba que no queda ningún warning:

```bash
forge test --deny warnings
```

## Para pensar

- `PushAuction` revierte si la devolución falla. ¿Y si ignorara el fallo (`call` sin comprobar
  `ok`)? ¿Quién perdería el ETH?
- En `Auction`, ¿puede alguien bloquear a Alice para que no retire? ¿Y gastar todo el gas de
  su `withdraw`?
- `unlock` suma `current.amount`, un `uint192`, a un `uint256`. ¿Hace falta SafeCast ahí? ¿Por
  qué no?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Control de acceso y `tx.origin`](../ejercicio-02-control-de-acceso-y-tx-origin/README.md) | **Ejercicio 03 — DoS y aritmética** | [Proyecto — Ataques clásicos a tu protocolo →](../../3-proyecto/README.md) |
