# Ejercicio 01 — Primer contrato

> Al terminar habrás escrito tu primer contrato en Solidity: un contador que devuelve un
> valor fijo, guarda un número, lo cambia, suma sin tocar el estado y recuerda quién lo
> llamó. Seis tests escritos de antemano te dicen cuándo está bien.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teorías 01 a 03](../../1-teoria/01-solidity-y-el-compilador.md)
leídas.

## Contexto

El starter es un proyecto Foundry (Teoría 02):

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml` | Configuración: compilador 0.8.38 y `forge-std` de la imagen |
| `src/Counter.sol` | El contrato. Aquí trabajas |
| `test/Counter.t.sol` | Seis tests, uno por paso. **No lo modifiques** |

Cada paso de `src/Counter.sol` tiene una línea `revert("TODO: Paso N");` y, debajo, la
solución comentada con `//> `. Resolver un paso es borrar el `revert` y quitar el `//> `
de sus líneas. Escríbelas tú en lugar de solo descomentarlas: así es como se aprende la
sintaxis.

Resuelve los pasos **en orden**: los tests de los pasos 3 y 4 leen el número con `get()`,
que escribes en el paso 2.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-03-primer_contrato_con_foundry/2-practicas/ejercicio-01-primer-contrato/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

El starter compila con avisos (`Warning (2018)` y `Warning (5667)`): las funciones solo
revierten y no usan sus parámetros. Desaparecen al resolver los pasos.

**Verifica**: seis líneas `[FAIL: TODO: Paso N]` y
`0 tests passed, 6 failed, 0 skipped (6 total tests)`.

## Paso 1: Una función pura

**Por qué**: el contrato más simple: una función que devuelve un valor fijo. Es el 42 de
la semana 02, ahora en Solidity.

**Abre** `src/Counter.sol`:

```solidity
function answer() external pure returns (uint256) {
    return 42;
}
```

**Verifica**: `forge test` muestra `[PASS] test_Step1_Answer()` y los otros cinco siguen en
`FAIL`.

## Paso 2: Una variable de estado

**Por qué**: un contrato que recuerda. La variable vive en el storage, en el slot 0.

Descomenta la declaración, arriba del contrato:

```solidity
uint256 number;
```

Y la función que la lee:

```solidity
function get() external view returns (uint256) {
    return number;
}
```

**Verifica**: `[PASS] test_Step2_StartsAtZero()`. Nadie asignó `number`: vale 0, como todo
slot sin escribir.

## Paso 3: Cambiar el estado

**Por qué**: una función que escribe. Sin `view` ni `pure`: puede cambiar el storage, y en
una red hará falta una transacción para llamarla.

```solidity
function increment() external {
    number += 1;
}
```

**Verifica**: `[PASS] test_Step3_Increment()`. El test llama dos veces y espera `2`.

## Paso 4: Un parámetro

**Por qué**: los datos que llegan en la llamada. `newNumber` viaja en el `input`, detrás
del selector.

```solidity
function set(uint256 newNumber) external {
    number = newNumber;
}
```

**Verifica**: `[PASS] test_Step4_Set()`.

## Paso 5: Calcular sin estado

**Por qué**: una función `pure` con parámetros: ni lee ni escribe, solo calcula. Se puede
llamar sin transacción y sin gas.

```solidity
function add(uint256 a, uint256 b) external pure returns (uint256) {
    return a + b;
}
```

**Verifica**: `[PASS] test_Step5_Add()`.

## Paso 6: Quién llama

**Por qué**: `msg.sender` es la base de todo control de acceso. El test usa `vm.prank`
para llamar como otra dirección (Teoría 04).

Descomenta la segunda variable de estado:

```solidity
address lastCaller;
```

Y las dos funciones:

```solidity
function touch() external {
    lastCaller = msg.sender;
}

function getLastCaller() external view returns (address) {
    return lastCaller;
}
```

**Verifica**: `forge test` termina con
`6 tests passed, 0 failed, 0 skipped (6 total tests)` y sin warnings. Mira la traza del
último test:

```bash
forge test --match-test Step6 -vvvv
```

```
├─ [0] VM::prank(0x00000000000000000000000000000000000A11cE)
│   └─ ← [Return]
├─ [43416] Counter::touch()
│   └─ ← [Stop]
├─ [2537] Counter::getLastCaller() [staticcall]
│   └─ ← [Return] 0x00000000000000000000000000000000000A11cE
```

## ✅ Criterios de éxito

- `forge test` pasa los 6 tests sin warnings.
- `forge inspect Counter storageLayout` muestra `number` en el slot 0 y `lastCaller` en
  el 1, y sabes por qué.
- Explicas por qué `get` es `view`, `add` es `pure` e `increment` no lleva ninguno.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 05 — Desplegar y llamar](../../1-teoria/05-desplegar-y-llamar.md) | **Ejercicio 01 — Primer contrato** | [Ejercicio 02 — Tests con forge →](../ejercicio-02-tests-con-forge/README.md) |
