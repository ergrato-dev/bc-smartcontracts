# Ejercicio 02 — Un vault con comisiones

> Al terminar habrás convertido el `ERC4626` de OpenZeppelin en un vault con shares virtuales,
> una comisión de salida del 1 % que se queda para quienes siguen dentro y un tope de depósitos.
> Y habrás visto que cambiar una sola función del estándar rompe lo que prometen las demás.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 03 — Vaults ERC-4626](../../1-teoria/03-vaults-erc-4626.md) leída y el
[ejercicio 01](../ejercicio-01-un-amm/README.md) en verde.

## Contexto

Proyecto Foundry. `FeeVault` hereda el `ERC4626` de OpenZeppelin: las cuentas, el redondeo, las
llamadas y los eventos ya están. Tu trabajo es sobrescribir las funciones justas para que la
comisión y el tope cumplan el estándar: que `preview*` diga lo que hará la llamada y que `max*`
dé un importe que la llamada acepte.

| Archivo | Qué es |
| ------- | ------ |
| `src/FeeVault.sol` | El vault: tu trabajo, pasos 1 a 4 |
| `src/Token.sol` | El activo: un ERC-20 de prueba |
| `test/FeeVault.t.sol` | Tres tests de comportamiento, en verde desde el principio, y los de cada paso. No lo cambies |

El `setUp` crea un vault con un tope de 1000 tokens y da 1000 a `alice`, `bob` y `carol`. Cada
paso **sustituye** código: borra la línea que acaba en `// <- Paso N` y descomenta (quita el
`//> ` del principio) las de debajo. En el starter, cada función sobrescrita hace lo mismo que la
de OpenZeppelin: el vault funciona, sin offset, sin comisión y sin tope.

La comisión es "un 1 % de lo que recibes": quien saca 100 paga 1, y quien canjea shares que valen
101 recibe 100 y paga 1. Es como lo cuenta el ejemplo `ERC4626Fees` de OpenZeppelin.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-30-defi/2-practicas/ejercicio-02-vault-con-comisiones/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `3 tests passed, 6 failed`. Pasan `test_DepositMintsSharesWorthTheAssets`,
`testFuzz_RoundTripNeverProfits` y `testFuzz_WithdrawMaxBurnsEveryShare`: el vault de
OpenZeppelin cumple el estándar. Fallan los de los pasos, empezando por el ataque de inflación:

```text
[FAIL: alice pierde su deposito: 66666666666666666667 < 99900000000000000000] test_Paso1_DonationAttackDoesNotPay() (gas: 256297)
```

## Paso 1: Shares virtuales

**Por qué**: es la tabla de la teoría 03. `carol` deposita 1 wei, regala 100 tokens al vault y
`alice` deposita 100: con offset 0, `alice` solo puede sacar 66,67. Con offset 3, el vault cuenta
1000 shares virtuales, y el regalo de `carol` se lo quedan casi entero ellas.

**Abre** `src/FeeVault.sol` y cambia el offset:

```solidity
return 3;
```

**Verifica**: `4 tests passed, 5 failed`. `alice` puede sacar más de 99,9, y `carol` no recupera
lo que regaló. Las shares tienen ahora 21 decimales: los 18 del token y 3 más.

## Paso 2: La comisión al canjear

**Por qué**: `redeem` calcula con `previewRedeem` lo que te da por tus shares. Si la comisión se
descuenta ahí, `redeem` la cobra sola, y una página que llama a `previewRedeem` enseña la cifra
de verdad. La comisión es el 1 % de lo que recibes, así que de lo que valen tus shares se quita
`valor · 100 / 10 100`, redondeado hacia arriba: a favor del vault.

**Abre** `src/FeeVault.sol` y resuelve `previewRedeem`:

```solidity
return assets - assets.mulDiv(EXIT_FEE_BPS, EXIT_FEE_BPS + 10_000, Math.Rounding.Ceil);
```

`mulDiv` de OpenZeppelin multiplica y divide sin desbordar en medio, y redondea hacia donde le
digas.

**Verifica**: `5 tests passed, 4 failed`. `alice` deposita 101 y canjea todo: recibe 100, y el
1 se queda en el vault. Con `bob` dentro, ese 1 % sube lo que valen sus shares.

Pero `testFuzz_WithdrawMaxBurnsEveryShare`, que estaba en verde, ahora falla:

```text
[FAIL: assertion failed: 990099009900990100 > 1
```

El número cambia con la entrada que encuentre el fuzzer. `maxWithdraw` es, en OpenZeppelin,
`previewRedeem` de todas tus shares: ya descuenta la comisión. Pero `withdraw` todavía la cobra
gratis: retirar ese máximo quema menos shares de las que tienes, y te quedan shares con valor. Las
dos formas de salir ya no cuestan lo mismo.

## Paso 3: La comisión al retirar

**Por qué**: `withdraw(assets)` dice cuánto quieres recibir. Las shares que se queman, las de
`previewWithdraw`, tienen que ser las de `assets` más el 1 % de `assets`, redondeado hacia arriba.

**Abre** `src/FeeVault.sol` y resuelve `previewWithdraw`:

```solidity
uint256 fee = assets.mulDiv(EXIT_FEE_BPS, 10_000, Math.Rounding.Ceil);
return super.previewWithdraw(assets + fee);
```

**Verifica**: `7 tests passed, 2 failed`. `testFuzz_WithdrawMaxBurnsEveryShare` vuelve al verde: lo
que te dejan retirar cuesta todas tus shares, salvo las que valen menos de 1 wei. En
`test_Paso3_WithdrawChargesExitFee`, `alice` saca 50 justos y las shares de `bob` pasan a valer
más de 100.

## Paso 4: El tope

**Por qué**: `deposit` comprueba `maxDeposit` y `mint` comprueba `maxMint`. Si el tope solo
estuviera en una, se saltaría con la otra, y una integración que deposita `maxDeposit` se
encontraría un revert. Las dos tienen que decir cuánto cabe, en activo y en shares.

**Abre** `src/FeeVault.sol` y resuelve `maxDeposit` y `maxMint`:

```solidity
uint256 assets = totalAssets();
return assets >= CAP ? 0 : CAP - assets;
```

```solidity
return _convertToShares(maxDeposit(receiver), Math.Rounding.Floor);
```

**Verifica**: `9 tests passed, 0 failed`. Con 900 dentro, `bob` no puede depositar 200: revierte
con `ERC4626ExceededMaxDeposit(bob, 200 ether, 100 ether)`, el error del estándar, que dice cuánto
cabía. Y `mint` de `maxMint(bob)` llena el vault hasta el tope justo.

## Para pensar

- En el paso 2, la comisión se queda en el vault. ¿Quién la cobra si el último en salir canjea
  todo? Mira `test_Paso2_RedeemChargesExitFee`: ¿de quién es el 1 que queda?
- ¿Por qué `previewWithdraw` redondea la comisión hacia arriba y `previewRedeem` también, si una
  resta y la otra suma?
- `deposit` no tiene un mínimo de shares. ¿Qué tendría que comprobar un contrato que deposita en
  `FeeVault` justo después de que alguien regale tokens al vault?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Un AMM](../ejercicio-01-un-amm/README.md) | **Ejercicio 02 — Un vault con comisiones** | [Ejercicio 03 — Un préstamo con garantía →](../ejercicio-03-prestamo-con-garantia/README.md) |
