# Ejercicio 03 — Arrays

> Al terminar habrás añadido y quitado elementos de un array dinámico con un límite,
> quitado sin huecos con swap-and-pop, recorrido el array con un bucle acotado, guardado
> un array fijo recibido en `calldata` y creado un array nuevo en `memory`.

**Duración estimada**: 2 h 30 min
**Prerrequisitos**: [Ejercicio 02](../ejercicio-02-structs-y-enums/README.md) terminado;
[Teorías 03, 04 y 05](../../1-teoria/03-arrays.md) leídas.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Readings.sol` | Lecturas de un sensor: el array dinámico `values` (como mucho `MAX_LENGTH = 10`), el array fijo `podium` de 3, tres errores y `getAll()`, ya escrita. Aquí trabajas |
| `test/Readings.t.sol` | Seis tests, uno por paso. **No lo modifiques**. Su función `_fill(n)` añade `10, 20, 30...` |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-06-estructuras_de_datos/2-practicas/ejercicio-03-arrays/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con `Warning (2018)` y `Warning (5667)`.

**Verifica**: seis `FAIL`. Los de los pasos 1, 2, 3 y 6 fallan con `TODO: Paso 1`: usan
`_fill`, que llama a `add`.

## Paso 1: `push` con límite

**Por qué**: un array que cualquiera hace crecer sin límite es un DoS en cuanto algo lo
recorre (teoría 03). El límite va antes de añadir.

**Abre** `src/Readings.sol`:

```solidity
function add(uint256 value) external {
    if (values.length >= MAX_LENGTH) revert ListFull(MAX_LENGTH);
    values.push(value);
}
```

**Verifica**: `[PASS] test_Step1_Add()`. El test añade 10 y espera `ListFull(10)` en el
undécimo.

## Paso 2: `pop` con tu propio error

**Por qué**: `pop()` de un array vacío ya revierte, pero con `Panic(0x31)`. Tu error dice
qué pasó.

```solidity
function removeLast() external {
    if (values.length == 0) revert EmptyList();
    values.pop();
}
```

**Verifica**: `[PASS] test_Step2_RemoveLast()`.

## Paso 3: Swap-and-pop

**Por qué**: quitar de en medio sin dejar huecos y con coste fijo.

```solidity
function removeAt(uint256 index) external {
    uint256 length = values.length;
    if (index >= length) revert IndexOutOfBounds(index, length);
    values[index] = values[length - 1];
    values.pop();
}
```

**Verifica**: `[PASS] test_Step3_RemoveAt()`. De `[10, 20, 30, 40]`, quitar la posición 1
deja `[10, 40, 30]`.

Prueba la alternativa ingenua: cambia las dos últimas líneas por `delete values[index];` y
ejecuta `forge test --match-test test_Step3`:

```
[FAIL: assertion failed: 4 != 3] test_Step3_RemoveAt() (gas: 269623)
```

La longitud sigue en 4: `delete` dejó un 0 en la posición 1. Vuelve a swap-and-pop.

## Paso 4: Recorrer con un bucle acotado

**Por qué**: el bucle recorre todo el array, pero `MAX_LENGTH` garantiza que nunca son más
de 10 vueltas.

```solidity
function sum() external view returns (uint256 total) {
    uint256 length = values.length;
    for (uint256 i = 0; i < length; i++) {
        total += values[i];
    }
}
```

Leer `values.length` una vez, en una variable local, evita leer storage en cada vuelta.

**Verifica**: `[PASS] test_Step4_Sum()`: `0` vacío y `100` con `[10, 20, 30, 40]`.

## Paso 5: Array fijo en `calldata`

**Por qué**: un `uint256[3]` llega entero en los datos de la transacción. Asignarlo a la
variable de estado copia los tres valores al storage.

```solidity
function setPodium(uint256[3] calldata top) external {
    podium = top;
}
```

**Verifica**: `[PASS] test_Step5_SetPodium()`. El test pasa `[uint256(90), 80, 70]`: el
`uint256(...)` del primer elemento fija el tipo del array literal.

## Paso 6: Array nuevo en `memory`

**Por qué**: para devolver una parte del array, creas uno nuevo del tamaño exacto. Un
array en memory no tiene `push`: su tamaño se fija al crearlo.

```solidity
function firstN(uint256 n) external view returns (uint256[] memory result) {
    uint256 length = values.length;
    if (n > length) revert IndexOutOfBounds(n, length);
    result = new uint256[](n);
    for (uint256 i = 0; i < n; i++) {
        result[i] = values[i];
    }
}
```

**Verifica**: `forge test` termina con
`6 tests passed, 0 failed, 0 skipped (6 total tests)` y sin warnings.

## ✅ Criterios de éxito

- `forge test` pasa los 6 tests sin warnings.
- Explicas por qué `removeAt` cambia el orden y cuándo eso sería un problema.
- Explicas qué pasaría con `sum()` si quitaras `MAX_LENGTH` y cualquiera pudiera llamar a
  `add`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Structs y enums](../ejercicio-02-structs-y-enums/README.md) | **Ejercicio 03 — Arrays** | [Proyecto — Registro de recursos →](../../3-proyecto/README.md) |
