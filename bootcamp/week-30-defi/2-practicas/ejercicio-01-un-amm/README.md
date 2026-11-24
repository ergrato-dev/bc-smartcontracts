# Ejercicio 01 — Un AMM

> Al terminar habrás escrito las cuentas de un AMM de producto constante: el precio con comisión,
> la primera liquidez, la liquidez proporcional, el swap con mínimo y la retirada. Y habrás visto
> que la comisión hace crecer lo que vale cada LP share.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 01 — El AMM de producto constante](../../1-teoria/01-el-amm-de-producto-constante.md)
y [Teoría 02 — La liquidez de un AMM](../../1-teoria/02-la-liquidez-de-un-amm.md) leídas.

## Contexto

Proyecto Foundry. `Pair` es un pool de dos tokens al estilo de Uniswap V2: el propio contrato es el
ERC-20 de sus LP shares, cobra un 0,3 % por swap y bloquea 1000 shares de la primera liquidez en
`0xdead`. Las reservas son las que anota, no su saldo.

| Archivo | Qué es |
| ------- | ------ |
| `src/Pair.sol` | El pool: tu trabajo, pasos 1 a 5 |
| `src/Token.sol` | Un ERC-20 de prueba que cualquiera puede emitir |
| `test/Pair.t.sol` | Dos tests por paso (uno en el paso 1 y tres en el 4) con los números exactos. No lo cambies |

En el `setUp`, `alice` y `bob` tienen 1000 de cada token y han aprobado al pool. Casi todos los
tests empiezan con `_seed()`: `alice` abre el pool con 100 A y 400 B, así que 1 A vale 4 B.

Cada paso borra la línea `revert("TODO: Paso N");` y descomenta (quita el `//> ` del principio)
las líneas de debajo.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-30-defi/2-practicas/ejercicio-01-un-amm/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 tests passed, 10 failed`. Cada test falla con el `TODO` del paso que necesita:

```text
[FAIL: TODO: Paso 1] test_Paso1_AmountOutChargesFee() (gas: 6862)
[FAIL: Error != expected error: TODO: Paso 2 != InsufficientLiquidity()] test_Paso2_RevertWhen_FirstLiquidityTooSmall() (gas: 35790)
```

## Paso 1: El precio con comisión

**Por qué**: es la fórmula de la teoría 01. La comisión se descuenta de la entrada: el pool cobra
`amountIn` entero pero solo paga por el 99,7 %. Todo en puntos básicos, para no usar decimales, y
la división al final: redondea hacia abajo, a favor del pool.

**Abre** `src/Pair.sol` y resuelve `getAmountOut`:

```solidity
uint256 amountInWithFee = amountIn * (10_000 - FEE_BPS);
return amountInWithFee * reserveOut / (reserveIn * 10_000 + amountInWithFee);
```

**Verifica**: `1 tests passed, 9 failed`. `test_Paso1_AmountOutChargesFee` pide 10 a un pool de 100
y 100: salen 9,0661, menos que los 9,0909 que daría la fórmula sin comisión.

## Paso 2: La primera liquidez

**Por qué**: quien abre el pool fija el precio y el tamaño de una share. Sus shares son
`√(amount0 · amount1)`, menos 1000 que se envían a `DEAD` para siempre: sin ellas, el primero
podría dejar una share carísima con un regalo y que las aportaciones de otros redondearan a cero
(teoría 02). Si la raíz no llega a 1000, no hay nada que dar.

**Abre** `src/Pair.sol` y resuelve `_firstLiquidity`:

```solidity
uint256 root = Math.sqrt(amount0 * amount1);
if (root <= MINIMUM_LIQUIDITY) revert InsufficientLiquidity();
_mint(DEAD, MINIMUM_LIQUIDITY);
return root - MINIMUM_LIQUIDITY;
```

`_mint` de OpenZeppelin no acepta `address(0)`: por eso las shares bloqueadas van a `0xdead`, una
dirección que nadie controla.

**Verifica**: `3 tests passed, 7 failed`. `alice` recibe `200 ether - 1000` shares, hay 200 en
total, y abrir con 1000 y 1000 wei revierte con `InsufficientLiquidity`.

## Paso 3: La liquidez proporcional

**Por qué**: después del primero, las shares son la parte que aportas de cada reserva, por las
shares que ya hay. Si las dos partes no son iguales, cuenta la menor: el token de más se queda en
el pool, para todos.

**Abre** `src/Pair.sol` y resuelve `_nextLiquidity`:

```solidity
return Math.min(amount0 * supply / reserve0, amount1 * supply / reserve1);
```

**Verifica**: `5 tests passed, 5 failed`. `bob` aporta 50 A y 200 B, la mitad de cada reserva, y
recibe 100 shares, la mitad de las 200. Con 50 A y solo 100 B recibe 50, y la reserva de A pasa a
150: los 25 A de más son ahora de `alice` y de él.

## Paso 4: El swap

**Por qué**: el swap anota las reservas nuevas y después mueve los tokens: si un token llamara a
quien lo recibe, este encontraría el pool ya actualizado (semana 21). Y revierte si sale menos de
`minAmountOut`, la defensa contra el sándwich de la semana 22.

**Abre** `src/Pair.sol` y resuelve `swap`. Son las líneas de debajo de `PASO 4`: elige el sentido,
calcula con `getAmountOut`, comprueba el mínimo, anota las reservas, emite `Swapped` y mueve los
tokens.

```solidity
amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
if (amountOut < minAmountOut) revert InsufficientOutput(amountOut, minAmountOut);
```

`address(tokenIn) == address(TOKEN0)` compara direcciones: solc 0.8.38 avisa de que comparar dos
variables de tipo contrato está obsoleto.

**Verifica**: `8 tests passed, 2 failed`. 10 A dan `36264435755205965263`, 36,26 B: la cifra de la
teoría 01. `testFuzz_Paso4_SwapNeverLowersK` prueba 256 swaps al azar, en los dos sentidos, de 1
wei a 900 tokens: en ninguno baja el producto de las reservas.

## Paso 5: Retirar

**Por qué**: quemar shares devuelve la misma parte de cada reserva, redondeando hacia abajo. Las
shares se queman antes de mover nada, y las reservas se actualizan antes de las transferencias.

**Abre** `src/Pair.sol` y resuelve `removeLiquidity`.

**Verifica**: `10 tests passed, 0 failed`. En `test_Paso5_FeesGrowEachShare`, `bob` cambia 10 A por
B y todo ese B otra vez por A: paga dos comisiones. Después `alice` retira todas sus shares y
recibe 100,0545 A y `399999999999999998000` de B: más A del que puso, y 2000 wei menos de B, su
parte de las 1000 shares bloqueadas. Las comisiones de `bob` son ahora de `alice`. Míralo en la
traza:

```bash
forge test --mt test_Paso5_FeesGrowEachShare -vvvv
```

```text
    │   └─ ← [Return] 100054493315404780413 [1e20], 399999999999999998000 [3.999e20]
```

## Para pensar

- En el paso 3, `bob` pierde 25 A por aportar fuera de proporción. ¿Qué tendría que calcular una
  página antes de llamar a `addLiquidity`, y con qué función de `Pair`?
- `swap` no tiene `deadline`. ¿Qué puede pasar con un swap que se queda horas sin entrar en un
  bloque, aunque tenga `minAmountOut`?
- El pool anota `amountIn` sin mirar cuánto llegó. ¿Qué pasa con un token que se queda un 1 % de
  cada transferencia? ¿Cómo lo resuelve Uniswap V2?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Préstamos con garantía](../../1-teoria/04-prestamos-con-garantia.md) | **Ejercicio 01 — Un AMM** | [Ejercicio 02 — Un vault con comisiones →](../ejercicio-02-vault-con-comisiones/README.md) |
