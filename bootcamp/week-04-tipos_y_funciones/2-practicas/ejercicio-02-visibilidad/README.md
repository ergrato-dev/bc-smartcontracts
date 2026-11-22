# Ejercicio 02 — Visibilidad

> Al terminar habrás escrito una función interna y su puerta externa, una función `public`
> que se llama desde dentro, una que devuelve dos valores y otra con retornos con nombre.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 01](../ejercicio-01-tipos-de-valor/README.md) terminado;
[Teorías 03 y 04](../../1-teoria/03-visibilidad.md) leídas.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Ledger.sol` | Un libro de cuentas con comisión del 1 %. Trae ya sus dos variables de estado: `total` (`public`) y `lastWriter` (`private`). Aquí trabajas |
| `test/Ledger.t.sol` | Seis tests, uno por paso. **No lo modifiques** |

Resuelve los pasos **en orden**: casi todas las funciones usan `_fee` (paso 1) o `add`
(paso 2).

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-04-tipos_y_funciones/2-practicas/ejercicio-02-visibilidad/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con `Warning (2018)` y `Warning (5667)`. Desaparecen al resolver los pasos.

**Verifica**: seis `FAIL`. Los tests de los pasos 4 y 6 fallan con `TODO: Paso 2`:
llaman a `add` para preparar el estado.

## Paso 1: Una función interna y su puerta

**Por qué**: el cálculo de la comisión lo usan varias funciones. Va en una función
`internal`, que nadie de fuera puede llamar; `quoteFee` es la puerta `external` para
consultarlo.

**Abre** `src/Ledger.sol`:

```solidity
function _fee(uint256 amount) internal pure returns (uint256) {
    return amount / 100;
}

/// @notice Comisión que se descuenta al sumar `amount`.
function quoteFee(uint256 amount) external pure returns (uint256) {
    return _fee(amount);
}
```

**Verifica**: `[PASS] test_Step1_QuoteFee()`. `quoteFee(99)` da `0`: la división entera
descarta los decimales.

## Paso 2: Una función `public`

**Por qué**: `add` se llama desde fuera y, en el paso 3, desde dentro. `external` no lo
permitiría.

```solidity
function add(uint256 amount) public {
    total += amount - _fee(amount);
    lastWriter = msg.sender;
}
```

**Verifica**: `[PASS] test_Step2_Add()`. El test lee el resultado con `ledger.total()`, el
getter que genera `public` en la variable.

## Paso 3: Llamar a una función desde dentro

**Por qué**: reutilizar `add` en lugar de repetir su código.

```solidity
function addTwice(uint256 amount) external {
    add(amount);
    add(amount);
}
```

**Verifica**: `[PASS] test_Step3_AddTwice()`. Ahora cambia `add` a `external` y ejecuta
`forge build`:
`Error (7576): Undeclared identifier. "add" is not (or not yet) visible at this point.`. Vuelve a dejarla `public`.

## Paso 4: Dos valores de retorno

**Por qué**: `lastWriter` es `private` y no tiene getter. Una función `view` decide qué se
expone y cómo.

```solidity
function summary() external view returns (uint256, address) {
    return (total, lastWriter);
}
```

**Verifica**: `[PASS] test_Step4_Summary()`. El test desestructura:
`(uint256 total, address writer) = ledger.summary();`.

## Paso 5: Retornos con nombre

**Por qué**: dos `uint256` sin nombre se confunden fácilmente. Con nombre, la ABI dice
cuál es cuál.

```solidity
function preview(uint256 amount) external pure returns (uint256 net, uint256 fee) {
    fee = _fee(amount);
    net = amount - fee;
}
```

No hay `return`: los valores con nombre se devuelven solos.

**Verifica**: `[PASS] test_Step5_Preview()` (`500` da neto `495` y comisión `5`).

## Paso 6: Exponer solo lo necesario

**Por qué**: en lugar de devolver la dirección privada, la función responde una pregunta
concreta.

```solidity
function wasWrittenBy(address account) external view returns (bool) {
    return lastWriter == account;
}
```

**Verifica**: `forge test` termina con
`6 tests passed, 0 failed, 0 skipped (6 total tests)` y sin warnings. Después mira la ABI:

```bash
forge inspect Ledger abi --json | jq -r '[.[].name] | join(" ")'
```

```
add addTwice preview quoteFee summary total wasWrittenBy
```

**Verifica**: está `total` (el getter), pero no `_fee` ni `lastWriter`.

## ✅ Criterios de éxito

- `forge test` pasa los 6 tests sin warnings.
- Explicas por qué `add` es `public` y `addTwice` puede ser `external`.
- Explicas por qué `lastWriter` no es secreta aunque sea `private`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Tipos de valor](../ejercicio-01-tipos-de-valor/README.md) | **Ejercicio 02 — Visibilidad** | [Ejercicio 03 — Constructor y constantes →](../ejercicio-03-constructor-y-constantes/README.md) |
