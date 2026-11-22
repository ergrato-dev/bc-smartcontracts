# Ejercicio 01 — Control de flujo

> Al terminar habrás escrito un ternario, un `if`/`else if`/`else`, un `for`, un
> `do-while`, un bucle con `continue` y otro con `break`.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 01](../../1-teoria/01-condicionales-y-bucles.md) leída.

## Contexto

Mismo formato que los ejercicios de la semana 04:

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml` | Configuración del bootcamp. No lo cambies |
| `src/Flow.sol` | Seis funciones `pure`, una por paso. Aquí trabajas |
| `test/Flow.t.sol` | Seis tests, uno por paso. **No lo modifiques** |

Resolver un paso es borrar su `revert("TODO: Paso N");` y quitar el `//> ` de sus líneas.
Escríbelas tú en lugar de solo descomentarlas.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-05-control_y_errores/2-practicas/ejercicio-01-control-de-flujo/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con `Warning (5667)`: parámetros sin usar. Desaparecen al resolver los pasos.

**Verifica**: seis líneas `[FAIL: TODO: Paso N]` y
`0 tests passed, 6 failed, 0 skipped (6 total tests)`.

## Paso 1: El ternario

**Por qué**: elegir entre dos valores en una expresión, sin ramas.

**Abre** `src/Flow.sol`:

```solidity
function max(uint256 a, uint256 b) external pure returns (uint256) {
    return a >= b ? a : b;
}
```

**Verifica**: `[PASS] test_Step1_Max()`. El test incluye el empate: `max(5, 5)` da `5`.

## Paso 2: `if`, `else if`, `else`

**Por qué**: tres casos excluyentes. Cada rama devuelve un valor distinto.

```solidity
function sign(int256 x) external pure returns (int8) {
    if (x < 0) {
        return -1;
    } else if (x == 0) {
        return 0;
    } else {
        return 1;
    }
}
```

**Verifica**: `[PASS] test_Step2_Sign()`.

## Paso 3: `for`

**Por qué**: el bucle con contador, el más habitual.

```solidity
function sumTo(uint256 n) external pure returns (uint256 total) {
    for (uint256 i = 1; i <= n; i++) {
        total += i;
    }
}
```

`total` es un retorno con nombre (semana 04): empieza en `0` y se devuelve solo.

**Verifica**: `[PASS] test_Step3_SumTo()`. `sumTo(0)` da `0`: con `n = 0` la condición
`1 <= 0` es falsa desde el principio y el bucle no entra.

## Paso 4: `do-while`

**Por qué**: el `0` tiene una cifra. Un `while` normal no entraría ni una vez con `n = 0`;
`do-while` entra al menos una.

```solidity
function countDigits(uint256 n) external pure returns (uint256 digits) {
    do {
        digits++;
        n /= 10;
    } while (n > 0);
}
```

Los parámetros son variables locales: dividir `n` no cambia nada fuera de la función.

**Verifica**: `[PASS] test_Step4_CountDigits()` (`0` da `1`, `2026` da `4`).

## Paso 5: `continue`

**Por qué**: saltar las vueltas que no interesan sin anidar el resto en un `if`.

```solidity
function sumOdds(uint256 n) external pure returns (uint256 total) {
    for (uint256 i = 1; i <= n; i++) {
        if (i % 2 == 0) continue;
        total += i;
    }
}
```

**Verifica**: `[PASS] test_Step5_SumOdds()` (`1 + 3 + 5 + 7 + 9 = 25`).

## Paso 6: `break`

**Por qué**: en cuanto aparece el primer divisor, seguir buscando es gas tirado.

```solidity
function smallestDivisor(uint256 n) external pure returns (uint256 divisor) {
    divisor = n;
    for (uint256 i = 2; i * i <= n; i++) {
        if (n % i == 0) {
            divisor = i;
            break;
        }
    }
}
```

`i * i <= n` para en la raíz cuadrada: si `n` tiene un divisor mayor, también tiene uno
menor que ya se habría encontrado.

**Verifica**: `forge test` termina con
`6 tests passed, 0 failed, 0 skipped (6 total tests)` y sin warnings.

## ✅ Criterios de éxito

- `forge test` pasa los 6 tests sin warnings.
- Explicas por qué `countDigits` necesita `do-while` y no `while`.
- Explicas qué pasaría con una función que recibe `n` de quien llama y hace `n` vueltas
  dentro de una transacción.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 05 — Modificadores](../../1-teoria/05-modificadores.md) | **Ejercicio 01 — Control de flujo** | [Ejercicio 02 — Errores →](../ejercicio-02-errores/README.md) |
