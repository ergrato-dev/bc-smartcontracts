# Ejercicio 02 — Errores

> Al terminar habrás rechazado llamadas con `require` y un mensaje, con un error
> personalizado con y sin parámetros, con `require` y un error personalizado, habrás
> protegido un invariante con `assert` y habrás usado `unchecked`.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 01](../ejercicio-01-control-de-flujo/README.md) terminado;
[Teorías 02, 03 y 04](../../1-teoria/02-require-y-revert.md) leídas.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Tank.sol` | Un depósito con `level` y `alarm`, capacidad `CAPACITY = 100` y tres errores personalizados ya declarados. Aquí trabajas |
| `test/Tank.t.sol` | Seis tests, uno por paso. Cada uno prueba el camino que funciona y el que revierte. **No lo modifiques** |

Los tests usan `vm.expectRevert(datos)` (teoría 03): pasan solo si la siguiente llamada
revierte con esos datos exactos.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-05-control_y_errores/2-practicas/ejercicio-02-errores/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con `Warning (2018)` y `Warning (5667)`. Desaparecen al resolver los pasos.

**Verifica**: seis `FAIL`. Los tests de los pasos 2 y 4 fallan con `TODO: Paso 1`:
llaman a `fill` para preparar el estado.

## Paso 1: `require` con mensaje

**Por qué**: la regla más simple: el nivel no puede pasar de la capacidad.

**Abre** `src/Tank.sol`:

```solidity
function fill(uint256 amount) external {
    require(level + amount <= CAPACITY, "tank overflow");
    level += amount;
}
```

La guarda va antes de escribir.

**Verifica**: `[PASS] test_Step1_Fill()`. El test llena 60 y espera que 41 más revierta con
`bytes("tank overflow")`.

## Paso 2: Error personalizado con parámetros

**Por qué**: quien llama necesita saber cuánto había y cuánto pidió.

```solidity
function drain(uint256 amount) external {
    if (amount > level) revert InsufficientLevel(level, amount);
    level -= amount;
}
```

**Verifica**: `[PASS] test_Step2_Drain()`. Ahora borra la línea del `if` y ejecuta
`forge test --match-test test_Step2`. La resta `20 - 25` revierte igualmente, pero con
otro error, y el test lo dice:

```
[FAIL: Error != expected error: panic: arithmetic underflow or overflow (0x11) != InsufficientLevel(20, 25)] test_Step2_Drain() (gas: 113809)
```

Vuelve a ponerla: un panic dice que algo fue mal; tu error
dice qué.

## Paso 3: `require` con un error personalizado

**Por qué**: la forma "exijo que…" de `require` con los datos de un error personalizado.

```solidity
function setAlarm(uint256 newAlarm) external {
    require(newAlarm <= CAPACITY, InvalidAlarm(newAlarm));
    alarm = newAlarm;
}
```

**Verifica**: `[PASS] test_Step3_SetAlarm()`.

## Paso 4: Error sin parámetros

**Por qué**: vaciar un depósito vacío no tiene sentido, y no hay ningún dato que añadir.

```solidity
function empty() external {
    if (level == 0) revert AlreadyEmpty();
    level = 0;
}
```

**Verifica**: `[PASS] test_Step4_Empty()`. El test espera
`vm.expectRevert(Tank.AlreadyEmpty.selector)`: sin parámetros, el selector es todo el
error.

## Paso 5: `assert` de un invariante

**Por qué**: `level <= CAPACITY` tiene que cumplirse siempre. Si algún día no se cumple,
`CAPACITY - level` desbordaría; mejor que el contrato lo diga con un panic `0x01`, que
señala un bug, que con un `0x11` que parece un problema de quien llama.

```solidity
function freeSpace() external view returns (uint256) {
    assert(level <= CAPACITY);
    return CAPACITY - level;
}
```

**Verifica**: `[PASS] test_Step5_FreeSpace()`. Con el contrato correcto, este `assert` no
falla nunca: es lo que debe pasar.

## Paso 6: `unchecked`

**Por qué**: ver con tus manos que dentro de `unchecked` los valores dan la vuelta.

```solidity
function wrappingAdd(uint8 a, uint8 b) external pure returns (uint8) {
    unchecked {
        return a + b;
    }
}
```

**Verifica**: `forge test` termina con
`6 tests passed, 0 failed, 0 skipped (6 total tests)` y sin warnings.
`wrappingAdd(200, 100)` da `44`: 300 menos 256.

Quita el bloque `unchecked` (deja solo `return a + b;`) y vuelve a ejecutar
`forge test --match-test test_Step6`: falla con
`panic: arithmetic underflow or overflow (0x11)`. Vuelve a ponerlo.

## ✅ Criterios de éxito

- `forge test` pasa los 6 tests sin warnings.
- Explicas por qué en `drain` es mejor `InsufficientLevel` que dejar que la resta
  revierta sola.
- Explicas cuándo usarías `assert` y cuándo `require`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Control de flujo](../ejercicio-01-control-de-flujo/README.md) | **Ejercicio 02 — Errores** | [Ejercicio 03 — Modificadores →](../ejercicio-03-modificadores/README.md) |
