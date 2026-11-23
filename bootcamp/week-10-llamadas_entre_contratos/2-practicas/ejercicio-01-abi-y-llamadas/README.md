# Ejercicio 01 — ABI y llamadas de bajo nivel

> Al terminar tendrás un contrato que guarda su ETH en un banco sin usar la interfaz del
> banco: construye cada llamada con `abi.encodeCall`, la envía con `call` o `staticcall`
> y lee a mano lo que vuelve, también cuando el banco revierte.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teorías 01 y 02](../../1-teoria/01-codificacion-abi.md) leídas.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Bank.sol` | Un banco: `deposit()`, `withdraw(amount)` y `balanceOf(account)`, con tres errores personalizados. **Terminado: no lo cambies** |
| `src/BankClient.sol` | El cliente que llama al banco. Aquí trabajas |
| `test/BankClient.t.sol` | Un test por paso. No lo modifiques |

Como en las semanas anteriores: en cada paso borra el `revert("TODO: Paso N");` y
descomenta las líneas que empiezan con `//> `.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-10-llamadas_entre_contratos/2-practicas/ejercicio-01-abi-y-llamadas/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con cuatro `Warning (5667)` y dos `Warning (2018)`: parámetros que aún no usas y
funciones que, mientras solo revierten, podrían ser `pure`.

**Verifica**: `0 tests passed, 6 failed, 0 skipped (6 total tests)`. Cinco fallan con su
`TODO`; `test_Step5_RevertWhen_BankHasNoCode`, con `next call did not revert as expected`.

## Paso 1: Los bytes de una llamada

**Por qué**: con una llamada de bajo nivel tú construyes los bytes. `abi.encodeCall`
comprueba en compilación que los argumentos encajan con la función; una firma escrita a
mano, no (teoría 01).

**Abre** `src/BankClient.sol`, en `withdrawCalldata`:

```solidity
return abi.encodeCall(Bank.withdraw, (amount));
```

**Verifica**: compara con `cast`, en el contenedor:

```bash
cast calldata "withdraw(uint256)" 1000000000000000000
```

```
0x2e1a7d4d0000000000000000000000000000000000000000000000000de0b6b3a7640000
```

Son los bytes que espera `test_Step1_WithdrawCalldata`. `forge test`:
`1 tests passed, 5 failed`.

## Paso 2: Depositar con `call`

**Por qué**: `call` envía los bytes y el ETH, y nunca revierte por sí misma. Si el banco
revierte, el cliente lo sabe por `ok` y recibe el error codificado en `reason`. Aquí el
cliente decide revertir, envolviendo esos bytes en su propio error para no perderlos.

```solidity
(bool ok, bytes memory reason) = BANK.call{value: msg.value}(abi.encodeCall(Bank.deposit, ()));
if (!ok) revert CallFailed(reason);
```

**Verifica**: `3 tests passed, 3 failed`. Pasan los dos tests del paso 2. En el segundo,
el cliente deposita 0 y el banco revierte con `ZeroAmount()`. Míralo con
`forge test --match-test RevertWhen_BankReverts -vvvv`: el error del cliente lleva dentro
`0x1f2a2005`, el selector de `ZeroAmount()` (`cast sig "ZeroAmount()"`).

## Paso 3: Leer con `staticcall`

**Por qué**: para leer, `staticcall`. Lo que vuelve son `bytes` y tú les das el tipo con
`abi.decode`. Solo decodificas si `ok`: si no, `data` no es un `uint256`, es un error.

```solidity
(bool ok, bytes memory data) = BANK.staticcall(abi.encodeCall(Bank.balanceOf, (address(this))));
if (!ok) revert CallFailed(data);
return abi.decode(data, (uint256));
```

`Bank.balanceOf` es una función `external` del banco. Si fuese el getter de un `mapping`
`public`, `abi.encodeCall` no la aceptaría
y el compilador diría
`Member "balanceOf" not found or not visible after argument-dependent lookup in type(contract Bank).`
Por eso el banco la declara a mano.

**Verifica**: `4 tests passed, 2 failed`.

## Paso 4: Intentar sin revertir

**Por qué**: a veces no quieres revertir, sino saber qué pasó y seguir. `tryWithdraw`
devuelve lo mismo que devolvió `call`. Reutiliza los bytes del paso 1.

```solidity
(ok, reason) = BANK.call(withdrawCalldata(amount));
```

**Verifica**: `5 tests passed, 1 failed`. `test_Step4_TryWithdraw` comprueba dos casos:

- Retirar 2 ether con 1 depositado: `ok` es `false` y `reason` es
  `InsufficientBalance(1 ether, 2 ether)` codificado. La función no revirtió.
- Retirar 0,4 ether: `ok` es `true`, `reason` está vacío (`withdraw` no devuelve nada) y
  los 0,4 ether llegan al `receive` del cliente.

## Paso 5: Un banco sin código

**Por qué**: una llamada de bajo nivel a una cuenta sin código devuelve **éxito** y
`0x`. Si el cliente apuntara a una dirección equivocada, `deposit` enviaría el ETH a esa
cuenta y no revertiría. El constructor lo impide desde el principio. Este paso no tiene
`revert` que borrar: solo una línea que descomentar.

```solidity
if (bank.code.length == 0) revert NoCode(bank);
```

**Verifica**:

```bash
forge test --deny warnings
```

`6 tests passed, 0 failed, 0 skipped (6 total tests)`, sin warnings.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 6 tests.
- Lees en una traza el error que viaja dentro de `CallFailed` y sabes qué es cada parte.
- Explicas por qué `balance` decodifica solo si `ok`.
- Explicas qué habría pasado en `deposit` sin la comprobación del paso 5.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 05 — CREATE y CREATE2](../../1-teoria/05-create-y-create2.md) | **Ejercicio 01 — ABI y llamadas de bajo nivel** | [Ejercicio 02 — delegatecall y try/catch →](../ejercicio-02-delegatecall-y-try-catch/README.md) |
