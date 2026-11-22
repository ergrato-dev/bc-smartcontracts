# Ejercicio 02 — Tests con forge

> Al terminar habrás escrito los tests de un contrato ajeno: su estado inicial, sus
> cambios, quién lo llama, el caso que debe revertir y que dos despliegues no se mezclan.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 01](../ejercicio-01-primer-contrato/README.md) terminado;
[Teoría 04](../../1-teoria/04-tests-con-forge.md) leída.

## Contexto

Ahora el papel se invierte: el contrato ya está escrito y correcto, y lo que falta son los
tests.

| Archivo | Qué es |
| ------- | ------ |
| `src/Scoreboard.sol` | Un marcador: `addPoints`, `removePoints`, `getTotal`, `getLastPlayer`. **No lo modifiques** |
| `test/Scoreboard.t.sol` | Los tests, con `revert("TODO: Paso N");` y la solución en líneas `//> `. Aquí trabajas |

**Abre** `src/Scoreboard.sol` y léelo entero antes de empezar: un test se escribe
sabiendo qué promete el contrato.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-03-primer_contrato_con_foundry/2-practicas/ejercicio-02-tests-con-forge/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con seis `Warning (2018)`: los tests que solo revierten podrían ser `pure`.
Desaparecen al resolver los pasos.

**Verifica**: una sola línea de fallo:

```
[FAIL: TODO: Paso 1] setUp() (gas: 0)
```

Si `setUp` falla, `forge` no ejecuta ningún test: no hay contrato que probar.

## Paso 1: Preparar cada test

**Por qué**: cada test necesita un `Scoreboard` recién desplegado. `setUp` se ejecuta
antes de cada uno, así que ningún test ve los puntos de otro.

**Abre** `test/Scoreboard.t.sol`:

```solidity
function setUp() public {
    scoreboard = new Scoreboard();
}
```

**Verifica**: ahora `forge test` ejecuta los cinco tests y cada uno falla con su paso:
`[FAIL: TODO: Paso 2] test_StartsAtZero()`, `[FAIL: TODO: Paso 3] test_AddPoints()`... El
orden de la lista es alfabético, no el de los pasos.

## Paso 2: El estado inicial

**Por qué**: el primer caso que se prueba es "recién creado". Muchos fallos reales están
en el primer uso.

```solidity
function test_StartsAtZero() public view {
    assertEq(scoreboard.getTotal(), 0);
}
```

`view`: el test solo lee, y el compilador lo pide.

**Verifica**: `[PASS] test_StartsAtZero()`.

## Paso 3: Un cambio

**Por qué**: comprobar que dos llamadas se acumulan, no que la segunda pisa a la primera.

```solidity
function test_AddPoints() public {
    scoreboard.addPoints(10);
    scoreboard.addPoints(5);
    assertEq(scoreboard.getTotal(), 15);
}
```

**Verifica**: `[PASS] test_AddPoints()`. Cambia `15` por `16`, ejecuta y lee el fallo:
`[FAIL: assertion failed: 15 != 16]`. Vuelve a dejar `15`.

## Paso 4: Quién llama

**Por qué**: `Scoreboard` guarda `msg.sender`. Para probarlo hay que llamar desde una
dirección que no sea la del test.

```solidity
function test_RecordsLastPlayer() public {
    address alice = makeAddr("alice");
    vm.prank(alice);
    scoreboard.addPoints(1);
    assertEq(scoreboard.getLastPlayer(), alice);
}
```

**Verifica**: `[PASS] test_RecordsLastPlayer()`.

## Paso 5: Lo que debe fallar

**Por qué**: un contrato no solo tiene que hacer lo que debe; también tiene que negarse a
lo que no. `removePoints(4)` con 3 puntos daría negativo, y un `uint256` no puede serlo.

```solidity
function test_RevertWhen_RemovingMoreThanTotal() public {
    scoreboard.addPoints(3);
    vm.expectRevert();
    scoreboard.removePoints(4);
}
```

**Verifica**: `[PASS] test_RevertWhen_RemovingMoreThanTotal()`. Mira por qué revierte:

```bash
forge test --match-test Revert -vvvv
```

```
├─ [23928] Scoreboard::removePoints(4)
│   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
```

Cambia `4` por `3` y ejecuta: `[FAIL: next call did not revert as expected]`. Vuelve a
dejar `4`.

## Paso 6: Despliegues independientes

**Por qué**: cada despliegue es una cuenta con su propio storage. Lo que le pasa a uno no
toca al otro.

```solidity
function test_DeploymentsAreIndependent() public {
    Scoreboard other = new Scoreboard();
    scoreboard.addPoints(8);
    assertEq(other.getTotal(), 0);
    assertTrue(address(other) != address(scoreboard));
}
```

**Verifica**: `forge test` termina con
`5 tests passed, 0 failed, 0 skipped (5 total tests)` y sin warnings.

## ✅ Criterios de éxito

- `forge test` pasa los 5 tests sin warnings.
- Explicas qué hace `setUp` y por qué un test no ve los cambios de otro.
- Explicas qué tendría que pasar en `Scoreboard` para que el test del paso 5 fallara.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Primer contrato](../ejercicio-01-primer-contrato/README.md) | **Ejercicio 02 — Tests con forge** | [Ejercicio 03 — Desplegar y llamar →](../ejercicio-03-desplegar-y-llamar/README.md) |
