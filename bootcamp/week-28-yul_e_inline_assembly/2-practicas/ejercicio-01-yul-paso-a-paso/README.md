# Ejercicio 01 — Yul paso a paso

> Al terminar habrás escrito en assembly una suma que da la vuelta, otra que revierte con el mismo
> error que Solidity, una comparación con signo y un bucle sobre la calldata, y un contrato entero
> en Yul, con su dispatcher, desplegado desde su bytecode.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 01 — Yul, el lenguaje](../../1-teoria/01-yul-el-lenguaje.md) leída.

## Contexto

Proyecto Foundry con dos piezas:

| Archivo | Qué es |
| ------- | ------ |
| `src/MathAsm.sol` | Cuatro funciones de aritmética con el cuerpo en assembly: tu trabajo, pasos 1 a 4 |
| `src/Counter.yul` | Un contador escrito entero en Yul: tu trabajo, paso 5 |
| `test/MathAsm.t.sol` | Cada función contra la misma cuenta en Solidity, con fuzzing. No lo cambies |
| `test/Counter.t.sol` | Despliega el contador desde su bytecode y lo llama por su interfaz. No lo cambies |

Un objeto Yul no tiene ABI, y `deployCode` de forge no lo acepta. `test/Counter.t.sol` lee su
bytecode del artefacto que deja forge (`out/Counter.yul/Counter.json`) y lo despliega con `create`
(teoría 03). Para leer ese archivo, `foundry.toml` da permiso de lectura sobre `out/`
(`fs_permissions`).

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-28-yul_e_inline_assembly/2-practicas/ejercicio-01-yul-paso-a-paso/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `1 tests passed, 8 failed`. Los ocho fallan con su `TODO: Paso N`, o con
`EvmError: Revert` los del contador. El que pasa, `test_Paso5_UnknownSelectorReverts`, comprueba
que un selector desconocido revierte: el contador del starter revierte con todo.

## Paso 1: Una suma sin comprobar

**Por qué**: el opcode `add` suma módulo `2²⁵⁶`. Es la suma de Solidity dentro de `unchecked`, no
la normal.

**Abre** `src/MathAsm.sol` y, en `addUnchecked`, borra el `revert` y descomenta las líneas `//> `:

```solidity
assembly {
    c := add(a, b)
}
```

`c` es la variable de retorno de Solidity; el bloque la ve como una palabra y le asigna con `:=`.

**Verifica**: `forge test` da `3 tests passed, 6 failed`. `test_Paso1_MaxPlusOneIsZero` comprueba
que `type(uint256).max + 1` da 0, sin revertir.

## Paso 2: La misma suma, con el error de Solidity

**Por qué**: en Solidity, `a + b` revierte con `Panic(0x11)` si se desborda. Una suma sin signo se
ha desbordado si el resultado es menor que uno de los sumandos. Para que quien llama no note la
diferencia, el error tiene que ser el mismo, byte a byte: el selector de `Panic(uint256)`,
`0x4e487b71`, y el código `0x11`.

**Abre** `src/MathAsm.sol` y resuelve `addChecked`:

```solidity
assembly {
    c := add(a, b)
    if lt(c, a) {
        mstore(0, shl(224, 0x4e487b71))
        mstore(4, 0x11)
        revert(0, 0x24)
    }
}
```

`shl(224, ...)` sube el selector a los 4 bytes altos de la palabra. `mstore(4, 0x11)` escribe el
código de `0x04` a `0x23`, y `revert(0, 0x24)` devuelve esos 36 bytes.

**Verifica**: `4 tests passed, 5 failed`. `testFuzz_Paso2_AddCheckedLikeSolidity` compara con
`stdError.arithmeticError` en los desbordamientos y con la suma en el resto. Cambia `revert(0, 0x24)`
por `revert(0, 0)` y vuelve a ejecutar: falla la rama del error con
`call reverted as expected, but without data`. Deshaz el cambio.

## Paso 3: Comparar con signo

**Por qué**: para Yul, `-1` es una palabra con todos los bits a uno, el número más grande que
cabe. `gt(x, 0)` lo da por positivo. `sgt` y `slt` leen la palabra en complemento a dos. El signo
es `(x > 0) - (x < 0)`: `1 - 0`, `0 - 0` o `0 - 1`.

**Abre** `src/MathAsm.sol` y resuelve `sign`:

```solidity
assembly {
    s := sub(sgt(x, 0), slt(x, 0))
}
```

**Verifica**: `5 tests passed, 4 failed`. Prueba a poner `gt` y `lt` en vez de `sgt` y `slt`: el
fuzzer encuentra un negativo que da 1
(`assertion failed: 1 != -1`).

## Paso 4: Un bucle sobre la calldata

**Por qué**: `xs` es `calldata`, así que el bloque no ve un array: ve `xs.offset`, dónde empiezan
sus elementos en la calldata, y `xs.length`. El elemento `i` está en `xs.offset + i * 32`. La suma
tiene que comprobar el desbordamiento, como en el paso 2; una función de Yul evita escribirlo dos
veces.

**Abre** `src/MathAsm.sol` y resuelve `sum`:

```solidity
assembly {
    function checkedAdd(a, b) -> c {
        c := add(a, b)
        if lt(c, a) {
            mstore(0, shl(224, 0x4e487b71))
            mstore(4, 0x11)
            revert(0, 0x24)
        }
    }
    for { let i := 0 } lt(i, xs.length) { i := add(i, 1) } {
        total := checkedAdd(total, calldataload(add(xs.offset, shl(5, i))))
    }
}
```

`checkedAdd` no ve `total` ni `xs`: solo sus parámetros. `total` empieza a 0, como toda variable
de retorno.

**Verifica**: `7 tests passed, 2 failed`. `testFuzz_Paso4_Sum` usa elementos de 128 bits para que
la suma no se desborde, y `test_Paso4_SumOverflows` suma `1` y el máximo: `Panic(0x11)`.

## Paso 5: Un contrato en Yul

**Por qué**: `src/Counter.yul` es un objeto Yul. Su código de despliegue ya está escrito: guarda
7 en el slot 0 y devuelve el código del objeto `runtime`. Falta el runtime: el **dispatcher** que
lee el selector y salta a cada función. Es lo que solc genera al principio de cada contrato
(semana 27); aquí lo escribes tú.

| Función | Selector (`cast sig`) | Qué hace |
| ------- | --------------------- | -------- |
| `count()` | `0x06661abd` | Devuelve el slot 0 como una palabra |
| `increment()` | `0xd09de08a` | Suma 1 al slot 0 y no devuelve nada |
| Cualquier otra | — | Revierte sin datos |

**Abre** `src/Counter.yul`, borra la línea `revert(0, 0) // <- Paso 5` y descomenta las líneas
`//> `:

```text
switch shr(224, calldataload(0))
case 0x06661abd {
    mstore(0, sload(0))
    return(0, 0x20)
}
case 0xd09de08a {
    sstore(0, add(sload(0), 1))
    return(0, 0)
}
default {
    revert(0, 0)
}
```

`calldataload(0)` lee los 32 primeros bytes de la calldata, y `shr(224, ...)` deja los 4 de arriba,
el selector.

**Verifica**: `9 tests passed, 0 failed`. Después, mira el bytecode que compila solc:

```bash
~/.svm/0.8.38/solc-0.8.38 --strict-assembly --bin src/Counter.yul
```

```text
Binary representation:
60075f55602f600f5f39602f5ff3fe5f3560e01c806306661abd1460265763d09de08a14601b575f80fd5b60015f54015f555f80f35b5f545f5260205ff3
```

Busca los dos selectores dentro: `6306661abd` es `PUSH4 0x06661abd`.

## Para pensar

- El contador no comprueba `callvalue()`. ¿Qué pasa si alguien llama a `increment()` con 1 ETH?
  ¿Dónde se queda ese ETH? ¿Qué añade solc a una función que no es `payable`?
- `count()` con 4 bytes de calldata funciona. ¿Y con 3? ¿Qué devuelve `calldataload(0)` cuando la
  calldata es más corta que 32 bytes?
- En el paso 4, ¿qué pasa con `sum` si `xs.length` es enorme y la calldata no trae los elementos?
  ¿Lo comprobaría el decodificador de Solidity antes de entrar en la función?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Probar y auditar assembly](../../1-teoria/04-probar-y-auditar-assembly.md) | **Ejercicio 01 — Yul paso a paso** | [Ejercicio 02 — Memoria y storage en assembly →](../ejercicio-02-memoria-y-storage-en-assembly/README.md) |
