# Ejercicio 01 — ERC-20 a mano

> Al terminar tendrás un token ERC-20 completo escrito por ti, con saldos, permisos y
> permiso ilimitado, y lo habrás movido entre tres cuentas de anvil con `cast`.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teorías 01 y 02](../../1-teoria/01-tokens-y-erc20.md) leídas.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/MiniToken.sol` | El token: metadatos, constructor y `transfer` ya escritos; `_transfer`, `approve` y `transferFrom` por completar |
| `test/MiniToken.t.sol` | Un test por comportamiento, con el número del paso en el nombre. No lo modifiques |

`transfer` ya está escrita: llama a `_transfer(msg.sender, to, value)`. Tu trabajo es
`_transfer`, que también usará `transferFrom`.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-11-erc20_y_openzeppelin/2-practicas/ejercicio-01-erc20-a-mano/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5667)`, `(2018)` y un `(5740)` (`Unreachable code`), los de las
funciones que solo revierten.

**Verifica**: `0 tests passed, 7 failed, 0 skipped (7 total tests)`, cada uno con su
`TODO`.

## Paso 1: Mover saldos

**Por qué**: es el corazón del token. Dos comprobaciones antes de tocar nada: que el destino
no sea `address(0)` (los tokens se perderían y los logs lo confundirían con una
destrucción) y que haya saldo. Después, restar, sumar y anunciarlo con `Transfer`, que es
lo que leen las wallets.

**Abre** `src/MiniToken.sol`, en `_transfer`, borra el `revert` y descomenta:

```solidity
if (to == address(0)) revert InvalidReceiver(to);
uint256 fromBalance = balanceOf[from];
if (fromBalance < value) revert InsufficientBalance(from, fromBalance, value);
balanceOf[from] = fromBalance - value;
balanceOf[to] += value;
emit Transfer(from, to, value);
```

La resta no necesita más comprobación: ya sabes que `fromBalance >= value`.

**Verifica**: `3 tests passed, 4 failed`. Pasan los tres `test_Step1_*`;
`test_Step1_Transfer` comprueba además que `totalSupply` no cambia al transferir.

## Paso 2: Dar permiso

**Por qué**: `approve` no mueve tokens, solo apunta cuánto puede mover otro. Sustituye el
valor anterior, no lo suma (teoría 02).

```solidity
allowance[msg.sender][spender] = value;
emit Approval(msg.sender, spender, value);
return true;
```

**Verifica**: `4 tests passed, 3 failed`. `test_Step2_Approve` comprueba que el saldo de
alice sigue en 100 después de aprobar.

## Paso 3: Gastar un permiso

**Por qué**: `transferFrom` es lo que usa un contrato para cobrar. Quien llama es el
spender: se mira y se resta `allowance[from][msg.sender]`, no el de otro. Un permiso igual
a `type(uint256).max` se trata como ilimitado y no se resta: es la convención que usan
OpenZeppelin y las dApps, y ahorra una escritura en cada cobro.

```solidity
uint256 allowed = allowance[from][msg.sender];
if (allowed != type(uint256).max) {
    if (allowed < value) revert InsufficientAllowance(msg.sender, allowed, value);
    allowance[from][msg.sender] = allowed - value;
}
_transfer(from, to, value);
return true;
```

**Verifica**:

```bash
forge test --deny warnings
```

`7 tests passed, 0 failed, 0 skipped (7 total tests)`, sin warnings.
`test_Step3_InfiniteAllowance` comprueba que, tras mover 40, el permiso sigue en el máximo.

## Paso 4: Tres cuentas en anvil

**Por qué**: en los tests, `vm.prank` cambia de cuenta con una línea. En la red, cada
`approve` y cada `transferFrom` es una transacción firmada por su cuenta. Hazlo con tres:
la 0 despliega, la 1 recibe un permiso y la 2 recibe tokens.

Este paso no tiene código. Arranca anvil y despliega con 1000 tokens:

```bash
anvil --silent &
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1)
A0=$(cast wallet address "$PK0"); A1=$(cast wallet address "$PK1")
A2=$(cast wallet address $(cast wallet private-key "$M" 2))
forge create src/MiniToken.sol:MiniToken --private-key "$PK0" --broadcast --constructor-args $(cast to-wei 1000)
T=0x5FbDB2315678afecb367f032d93F642f64180aa3
```

`cast to-wei 1000` sirve aquí porque el token tiene 18 decimales, como el ETH. La cuenta 0
da a la 1 un permiso de 100, y la 1 mueve 60 de la 0 a la 2:

```bash
cast send $T "approve(address,uint256)" $A1 $(cast to-wei 100) --private-key "$PK0"
cast send $T "transferFrom(address,address,uint256)" $A0 $A2 $(cast to-wei 60) --private-key "$PK1"
cast call $T "allowance(address,address)(uint256)" $A0 $A1
cast call $T "balanceOf(address)(uint256)" $A2
```

Dos recibos con `status 1 (success)`, `40000000000000000000 [4e19]` (quedan 40 de permiso)
y `60000000000000000000 [6e19]`. La cuenta 1 movió tokens que no eran suyos, firmando ella.

**Verifica**: la cuenta 1 intenta mover otros 60:

```bash
cast send $T "transferFrom(address,address,uint256)" $A0 $A2 $(cast to-wei 60) --private-key "$PK1"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x192b9e4e: ..., data: "0x192b9e4e...": InsufficientAllowance(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 40000000000000000000 [4e19], 60000000000000000000 [6e19])
```

El spender es la cuenta 1 (`0x7099…`), que solo tiene 40.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 7 tests.
- Explicas por qué `_transfer` rechaza `address(0)` y por qué la resta no puede fallar.
- Explicas de quién es el permiso que gasta `transferFrom` y por qué el máximo no se resta.
- Lees en el error del paso 4 quién es el spender y cuánto le quedaba.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Tokens raros y SafeERC20](../../1-teoria/04-tokens-raros-y-safeerc20.md) | **Ejercicio 01 — ERC-20 a mano** | [Ejercicio 02 — Token con OpenZeppelin →](../ejercicio-02-token-con-openzeppelin/README.md) |
