# Ejercicio 03 — Allowance y SafeERC20

> Al terminar tendrás una caja que guarda cualquier token ERC-20: uno normal, uno como
> USDT que no devuelve nada, uno que devuelve `false` y uno que cobra comisión. Apunta a
> cada cuenta lo que de verdad llegó y lo devuelve sin deber nada.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teorías 02 y 04](../../1-teoria/04-tokens-raros-y-safeerc20.md) leídas
y [ejercicio 02](../ejercicio-02-token-con-openzeppelin/README.md) terminado.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/TokenVault.sol` | La caja: `deposit` y `withdraw`, con `using SafeERC20 for IERC20`. Aquí trabajas |
| `test/Tokens.sol` | Cuatro tokens de prueba: `TestToken` (normal), `NoReturnToken` (como USDT), `FalseToken` y `FeeToken` (1 % de comisión). No lo modifiques |
| `test/TokenVault.t.sol` | Los tests de cada paso. No lo modifiques |

`deposited[token][cuenta]` es un mapping de mappings con un `IERC20` como primera clave: en
storage, un tipo de contrato se guarda como su dirección.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-11-erc20_y_openzeppelin/2-practicas/ejercicio-03-allowance-y-safeerc20/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5667)`, `(2018)`, `(5740)` y un `(2072)` (`Unused local variable`):
`before` no se usa hasta el paso 2.

**Verifica**: `0 tests passed, 7 failed, 0 skipped (7 total tests)`.

## Paso 1: Traer los tokens

**Por qué**: la caja cobra con `transferFrom`, que gasta el permiso que el cliente le dio
(teoría 02). Con un token desconocido, `transferFrom` a secas revierte con los que no
devuelven nada y se fía de los que devuelven `false` (teoría 04). `safeTransferFrom`
acepta las dos respuestas correctas y rechaza el resto.

**Abre** `src/TokenVault.sol`, en `deposit`, borra el `revert` del paso 1 y descomenta:

```solidity
token.safeTransferFrom(msg.sender, address(this), amount);
```

**Verifica**: `3 tests passed, 4 failed`. Pasan los tres `test_Step1_*`: la caja recibe el
token normal y el que no devuelve nada, y `FalseToken` revierte con
`SafeERC20FailedOperation(token)`. Aún no apunta nada: `test_Step2_CreditsWhatArrived`
falla con `assertion failed: 0 != 99000000000000000000`.

## Paso 2: Apuntar lo que llegó

**Por qué**: con `FeeToken`, pedir 100 trae 99. Si la caja apuntara 100, debería un token
que no tiene, y el último en retirar no podría. Se mide el saldo antes (ya está escrito al
principio de la función) y después, en la misma función. Si no llegó nada, no hay depósito
que apuntar.

**Descomenta** las líneas del paso 2:

```solidity
received = token.balanceOf(address(this)) - before;
if (received == 0) revert NothingReceived();
deposited[token][msg.sender] += received;
emit Deposited(token, msg.sender, received);
```

**Verifica**: `5 tests passed, 2 failed`. `test_Step2_CreditsWhatArrived` comprueba que
`deposit` devuelve 99, que se apuntan 99 y que la caja tiene 99.

## Paso 3: Devolver

**Por qué**: la retirada es un pago del contrato, con `safeTransfer`. Primero se comprueba y
se resta, después se envía: un token desconocido podría volver a llamar a la caja mientras
recibe el envío, y para entonces el saldo ya tiene que estar restado (semana 07; la
reentrancy se estudia en la semana 21).

```solidity
uint256 balance = deposited[token][msg.sender];
if (balance < amount) revert InsufficientDeposit(balance, amount);
deposited[token][msg.sender] = balance - amount;
emit Withdrawn(token, msg.sender, amount);
token.safeTransfer(msg.sender, amount);
```

**Verifica**:

```bash
forge test --deny warnings
```

`7 tests passed, 0 failed, 0 skipped (7 total tests)`, sin warnings. `test_Step3_Withdraw`
deposita 100 de `NoReturnToken`, retira 40 y comprueba los dos saldos.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 7 tests.
- Explicas por qué la caja necesita un `approve` del cliente y qué permiso gasta.
- Explicas qué pasaría con `NoReturnToken` si usaras `token.transferFrom` sin `SafeERC20`, y
  qué pasaría con `FalseToken` si no leyeras el resultado.
- Explicas qué deuda tendría la caja con `FeeToken` si apuntara `amount`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Token con OpenZeppelin](../ejercicio-02-token-con-openzeppelin/README.md) | **Ejercicio 03 — Allowance y SafeERC20** | [Proyecto — Token de fidelidad →](../../3-proyecto/README.md) |
