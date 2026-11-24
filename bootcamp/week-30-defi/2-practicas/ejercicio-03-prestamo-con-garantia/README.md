# Ejercicio 03 — Un préstamo con garantía

> Al terminar habrás escrito un protocolo de préstamos: lo que vale la garantía según un price
> feed, el máximo que se puede pedir, la salud de cada posición, la liquidación con premio y un
> índice que hace crecer todas las deudas a la vez.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 04 — Préstamos con garantía](../../1-teoria/04-prestamos-con-garantia.md)
leída y el [ejercicio 02](../ejercicio-02-vault-con-comisiones/README.md) en verde.

## Contexto

Proyecto Foundry. `LendingPool` presta `DEBT`, un dólar de prueba (1 token = 1 USD), contra
`COLLATERAL`, un "Wrapped Ether" de prueba cuyo precio da un price feed de Chainlink. `price()` ya
está escrita, con las comprobaciones de la semana 20: precio positivo y de menos de una hora, en
18 decimales.

| Archivo | Qué es |
| ------- | ------ |
| `src/LendingPool.sol` | El pool: tu trabajo, pasos 1 a 5 |
| `src/Token.sol` | Los dos tokens de prueba |
| `test/LendingPool.t.sol` | Uno o dos tests por paso, con números que puedes hacer a mano. No lo cambies |

| Parámetro | Valor |
| --------- | ----- |
| LTV | 75 % |
| Umbral de liquidación | 80 % |
| Premio del liquidador | 5 % |
| Close factor | 50 % |
| Interés | 5 % anual |

En el `setUp`, el feed (`MockV3Aggregator`, de 8 decimales, semana 20) empieza en 2000 USD, el
pool tiene un millón de `DEBT` para prestar, `alice` tiene 10 de garantía y `bob`, el liquidador,
100 000 `DEBT`. La deuda de cada cuenta se guarda **escalada** por el índice (teoría 04): en el
starter, el índice no se mueve y vale 1.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-30-defi/2-practicas/ejercicio-03-prestamo-con-garantia/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 tests passed, 9 failed`. Casi todos los tests piden prestado, así que fallan en
el paso 2:

```text
[FAIL: TODO: Paso 1] test_Paso1_CollateralValueUsesTheFeed() (gas: 92229)
[FAIL: TODO: Paso 2] test_Paso2_BorrowUpToLtv() (gas: 117863)
```

## Paso 1: Lo que vale la garantía

**Por qué**: todo el protocolo compara deudas en dólares con garantías en ETH. `price()` da el
precio de 1 de garantía en dólares con 18 decimales, y la garantía también tiene 18: el producto
tiene 36, y se divide por `1e18`.

**Abre** `src/LendingPool.sol` y resuelve `collateralValue`:

```solidity
return collateralOf[user] * price() / 1e18;
```

**Verifica**: `1 tests passed, 8 failed`. 2 de garantía valen 4000; con el feed a 1800, 3600.

## Paso 2: No prestar más del LTV

**Por qué**: antes de prestar, la deuda nueva (lo que ya debes más lo que pides) no puede pasar del
75 % de la garantía. La deuda se guarda escalada: `amount / borrowIndex`, redondeado hacia arriba,
para que nadie deba menos de lo que pidió. `_accrue()`, la primera línea, deja el índice al día
antes de tocar ninguna deuda.

**Abre** `src/LendingPool.sol` y resuelve `borrow`:

```solidity
uint256 debt = debtOf(msg.sender) + amount;
uint256 maxDebt = collateralValue(msg.sender) * LTV_BPS / 10_000;
if (debt > maxDebt) revert ExceedsLtv(debt, maxDebt);
_scaledDebt[msg.sender] += amount.mulDiv(1e18, borrowIndex, Math.Rounding.Ceil);
```

y las dos líneas que emiten `Borrowed` y envían el dinero.

**Verifica**: `3 tests passed, 6 failed`. Con 2 de garantía, `alice` puede pedir 3000 y ni 1 wei
más: `ExceedsLtv(3000000000000000000001, 3000000000000000000000)`.

## Paso 3: La salud de la posición

**Por qué**: la salud es la garantía por el umbral, entre la deuda, con 18 decimales: por debajo
de `1e18` la posición se puede liquidar. Sin deuda es infinita, y `withdrawCollateral` ya la usa
para no dejarte sacar garantía que te deje por debajo de 1.

**Abre** `src/LendingPool.sol` y resuelve `healthFactor`:

```solidity
uint256 debt = debtOf(user);
if (debt == 0) return type(uint256).max;
return (collateralValue(user) * LIQUIDATION_THRESHOLD_BPS / 10_000).mulDiv(1e18, debt);
```

**Verifica**: `5 tests passed, 4 failed`. Con 4000 de garantía y 3000 de deuda, la salud es
`1066666666666666666`: la tabla de la teoría 04. Con el feed a 1800, `0.96e18`. Y sacar 0,2 de
garantía con el precio a 2000 deja 3600 de garantía: revierte con `Unhealthy(960000000000000000)`.

## Paso 4: La liquidación

**Por qué**: con la salud por debajo de 1, cualquiera paga hasta la mitad de la deuda y se lleva
garantía por ese valor más un 5 %, al precio del feed. Comprueba la salud y el close factor antes
de tocar nada, actualiza las cuentas y, al final, mueve los tokens.

**Abre** `src/LendingPool.sol` y resuelve `liquidate`. La línea que calcula la garantía es:

```solidity
seized = (repayAmount * (10_000 + LIQUIDATION_BONUS_BPS) / 10_000).mulDiv(1e18, price());
```

**Verifica**: `7 tests passed, 2 failed`. A 1800, `bob` paga 1500 de la deuda de `alice` y se
lleva 0,875 de garantía: 1575 dólares. La posición queda en 1500 de deuda con 1,125 de garantía, y
su salud vuelve a pasar de 1. Liquidar a 2000 revierte con `Healthy`, y pagar 1501 con
`ExceedsCloseFactor(1501 ether, 1500 ether)`.

## Paso 5: El interés

**Por qué**: con el índice quieto, la deuda no crece. El índice de hoy es el guardado más su
interés desde `lastAccrual`: `índice · tipo por segundo · segundos`. `debtOf` lo calcula sin
guardarlo (es `view`), y `_accrue` lo guarda antes de cada cambio.

**Abre** `src/LendingPool.sol` y resuelve `_currentIndex`:

```solidity
return borrowIndex + borrowIndex * RATE_PER_SECOND * (block.timestamp - lastAccrual) / 1e18;
```

**Verifica**: `9 tests passed, 0 failed`. Un año después, los 1000 de `alice` son
`1049999999994064000000`: un 5 %, menos el redondeo de `RATE_PER_SECOND`, que es
`0.05e18 / 365 days` redondeado hacia abajo. `repay` con `type(uint256).max` solo cobra lo que
debe y deja la deuda a cero.

## Para pensar

- `price()` revierte si el feed tiene más de una hora. ¿Qué pasa entonces con `liquidate`? ¿Y con
  `repay`? ¿Es bueno que `repay` no lea el precio?
- En el paso 4, ¿qué pasa si el precio cae tanto que la garantía de `alice` vale menos que su
  deuda? ¿Cuánto puede llevarse `bob` y qué deuda queda sin respaldo?
- El pool presta su propio dinero. ¿Cómo lo conectarías con un vault como el del ejercicio 02,
  para que los intereses los cobren los depositantes?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Un vault con comisiones](../ejercicio-02-vault-con-comisiones/README.md) | **Ejercicio 03 — Un préstamo con garantía** | [Proyecto — Un vault de puntos →](../../3-proyecto/README.md) |
