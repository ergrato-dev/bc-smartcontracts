# Ejercicio 01 — Tipos de valor

> Al terminar habrás usado los límites de los enteros, un `int` negativo, una comparación,
> una conversión que trunca, un `bytes4` calculado con keccak256 y la dirección cero.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 01](../../1-teoria/01-tipos-de-valor.md) leída.

## Contexto

Mismo formato que los ejercicios de la semana 03:

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml` | Configuración del bootcamp. No lo cambies |
| `src/Types.sol` | Seis funciones `pure`, una por paso. Aquí trabajas |
| `test/Types.t.sol` | Seis tests, uno por paso. **No lo modifiques** |

Resolver un paso es borrar su `revert("TODO: Paso N");` y quitar el `//> ` de sus líneas.
Escríbelas tú en lugar de solo descomentarlas.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-04-tipos_y_funciones/2-practicas/ejercicio-01-tipos-de-valor/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con cuatro `Warning (5667)`: parámetros sin usar. Desaparecen al resolver los
pasos.

**Verifica**: seis líneas `[FAIL: TODO: Paso N]` y
`0 tests passed, 6 failed, 0 skipped (6 total tests)`.

## Paso 1: El máximo de un `uint8`

**Por qué**: cada tamaño de entero tiene su techo. Conocerlo es saber cuándo una suma va a
revertir.

**Abre** `src/Types.sol`:

```solidity
function maxUint8() external pure returns (uint8) {
    return type(uint8).max;
}
```

**Verifica**: `[PASS] test_Step1_MaxUint8()`. El test espera `255`. Compruébalo también
con `cast max-uint uint8`.

## Paso 2: El mínimo de un `int8`

**Por qué**: un entero con signo reparte su rango entre negativos y positivos.

```solidity
function minInt8() external pure returns (int8) {
    return type(int8).min;
}
```

**Verifica**: `[PASS] test_Step2_MinInt8()` (espera `-128`).

## Paso 3: Una comparación

**Por qué**: las comparaciones producen `bool`. Es lo que la semana 05 usará para decidir
si una llamada sigue o se rechaza.

```solidity
function isAdult(uint256 age) external pure returns (bool) {
    return age >= 18;
}
```

**Verifica**: `[PASS] test_Step3_IsAdult()`. El test prueba el borde: `18` da `true` y `17`
da `false`.

## Paso 4: Una conversión que trunca

**Por qué**: la conversión explícita no comprueba nada. Es una de las trampas más
silenciosas de Solidity.

```solidity
function toUint8(uint256 value) external pure returns (uint8) {
    return uint8(value);
}
```

**Verifica**: `[PASS] test_Step4_ToUint8Truncates()`. El test comprueba que `200` se queda
igual, que `256` da `0` y que `300` da `44`: se quedan los 8 bits bajos. Cambia el cuerpo
por `uint8 small = value; return small;` y ejecuta `forge build`: verás el
`Error (9574)` de la conversión implícita. Vuelve a dejarlo como estaba.

## Paso 5: Un selector en `bytes4`

**Por qué**: `keccak256` devuelve un `bytes32`; convertirlo a `bytes4` se queda con los
4 primeros bytes. Es exactamente lo que hace `cast sig`.

```solidity
function selectorOf(string memory signature) external pure returns (bytes4) {
    return bytes4(keccak256(bytes(signature)));
}
```

`bytes(signature)` ve el texto como bytes, que es lo que acepta `keccak256`.

**Verifica**: `[PASS] test_Step5_SelectorOf()`. El test espera `0xd09de08a`, el selector de
`increment()` de la semana 03.

## Paso 6: La dirección cero

**Por qué**: `address(0)` es el valor por defecto de toda dirección. Comprobarla es la
forma de saber que "no hay nadie".

```solidity
function isZeroAddress(address account) external pure returns (bool) {
    return account == address(0);
}
```

**Verifica**: `forge test` termina con
`6 tests passed, 0 failed, 0 skipped (6 total tests)` y sin warnings.

## ✅ Criterios de éxito

- `forge test` pasa los 6 tests sin warnings.
- Explicas por qué `toUint8(300)` devuelve 44 y no revierte.
- Explicas qué tipo usarías para una cantidad, un saldo que puede ser negativo, un hash y
  un "sí o no".

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 05 — Constructor, constant e immutable](../../1-teoria/05-constructor-constant-e-immutable.md) | **Ejercicio 01 — Tipos de valor** | [Ejercicio 02 — Visibilidad →](../ejercicio-02-visibilidad/README.md) |
