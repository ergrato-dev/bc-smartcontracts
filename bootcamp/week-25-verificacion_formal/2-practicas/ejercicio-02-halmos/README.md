# Ejercicio 02 — Halmos

> Al terminar habrás escrito tus primeras specs de Halmos, habrás convertido un contraejemplo en
> un test, habrás demostrado una regla para todos los pares de reservas posibles y habrás visto
> por qué una aceptación se comprueba con `try`.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 03 — Halmos](../../1-teoria/03-halmos.md) leída y el
[ejercicio 01](../ejercicio-01-smtchecker/README.md) terminado.

## Contexto

`Bookings` es el calendario de una habitación. `book(from, to)` reserva los días de `from` a
`to`, **los dos incluidos**: `book(5, 5)` es una noche, el día 5. Un día no puede estar en dos
reservas, así que `book` revierte con `Overlaps` si la nueva comparte algún día con otra. Sus
tres tests unitarios pasan.

`test.sh` ejecuta `forge test`, una compilación sin warnings y `halmos --no-status`.

| Archivo | Qué es |
| ------- | ------ |
| `src/Bookings.sol` | El calendario. Paso 2 |
| `test/Bookings.t.sol` | Tres tests unitarios, en verde, y uno para el contraejemplo. Paso 1 |
| `test/BookingsSpec.t.sol` | Las specs de Halmos. Pasos 1 y 3 |
| `foundry.toml` | Con `dynamic_test_linking = false` y `ast = true` para Halmos (teoría 03) |
| `halmos.toml` | z3 como solver (teoría 03). **No lo modifiques** |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-25-verificacion_formal/2-practicas/ejercicio-02-halmos/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
halmos --no-status
```

**Verifica**: `forge test` da `3 passed` y falla `test_HalmosCounterexample` con `TODO: Paso 1`.
`halmos` encuentra las dos specs y las dos fallan con su `TODO`:

```text
[FAIL] check_DisjointAccepted(uint32,uint32,uint32,uint32) (paths: 6, time: 0.05s, bounds: [])
[FAIL] check_NoDayTwice(uint32,uint32,uint32,uint32,uint32) (paths: 7, time: 0.05s, bounds: [])
Symbolic test result: 0 passed; 2 failed; time: 0.12s
```

## Paso 1: Ningún día en dos reservas

**Por qué**: la promesa del calendario, para cualquier par de reservas: si las dos se aceptan,
ningún día está en las dos. La primera reserva puede revertir (si `from1 > to1`); para Halmos,
ese camino no cuenta. La segunda va en un `try`: si se rechaza, no hay nada que comprobar.

```solidity
function check_NoDayTwice(uint32 from1, uint32 to1, uint32 from2, uint32 to2, uint32 day) public {
    bookings.book(from1, to1);
    try bookings.book(from2, to2) {
        bool inFirst = from1 <= day && day <= to1;
        bool inSecond = from2 <= day && day <= to2;
        assertFalse(inFirst && inSecond);
    } catch {}
}
```

**Abre** `test/BookingsSpec.t.sol` y, en `check_NoDayTwice`, borra el `assertTrue(false, ...)` y
descomenta el cuerpo.

**Verifica**: `halmos --no-status --function check_NoDayTwice` falla con dos contraejemplos:

```text
Counterexample:
    p_day_uint32_87f576d_00 = 0xd7dd0db7
    p_from1_uint32_619d6de_00 = 0xd7dd0db7
    p_from2_uint32_a2170f8_00 = 0x89dd47c0
    p_to1_uint32_34afc2a_00 = 0xd7ff497f
    p_to2_uint32_517b012_00 = 0xd7dd0db7
Counterexample:
    p_day_uint32_87f576d_00 = 0x00
    p_from1_uint32_619d6de_00 = 0x00
    p_from2_uint32_a2170f8_00 = 0x00
    p_to1_uint32_34afc2a_00 = 0x00
    p_to2_uint32_517b012_00 = 0xfffffffe
[FAIL] check_NoDayTwice(uint32,uint32,uint32,uint32,uint32) (paths: 24, time: 0.19s, bounds: [])
```

Tus contraejemplos pueden ser otros. Léelos como reservas: en el segundo, la primera es solo el
día 0 y la segunda va del día 0 al `0xfffffffe`; las dos tienen el día 0 y las dos se aceptan. En
el primero, `to2 == from1 == day`: la segunda reserva acaba justo el día que empieza la primera.
El caso más pequeño de esta familia son dos reservas del día 0. Conviértelo en un test:

```solidity
function test_HalmosCounterexample() public {
    bookings.book(0, 0);
    vm.expectRevert(abi.encodeWithSelector(Bookings.Overlaps.selector, 0));
    bookings.book(0, 0);
}
```

**Abre** `test/Bookings.t.sol` y, en `test_HalmosCounterexample`, borra el `revert` y descomenta
el cuerpo, con tus valores si quieres.

**Verifica**: `forge test --mt Halmos` falla con `next call did not revert as expected`: el
contraejemplo es real.

## Paso 2: Los extremos cuentan

**Por qué**: `book` compara con `<`, la fórmula de los intervalos que **no** incluyen su final.
Con los dos extremos incluidos, dos reservas que comparten justo un día de borde (`to` de una
igual a `from` de la otra) no cuentan como solapadas.

```solidity
if (from <= other.to && other.from <= to) revert Overlaps(i);
```

**Abre** `src/Bookings.sol` y sustituye la línea `// <- Paso 2` por la de debajo.

**Verifica**: `forge test` da `4 passed`, y `halmos --no-status --function check_NoDayTwice`:

```text
[PASS] check_NoDayTwice(uint32,uint32,uint32,uint32,uint32) (paths: 23, time: 0.21s, bounds: [])
```

Ese `PASS` no dice "no encontré nada en 256 intentos". Dice que, para **todos** los valores de
los cinco parámetros (2¹⁶⁰ combinaciones), ningún día queda en dos reservas aceptadas.

## Paso 3: Lo que se tiene que aceptar

**Por qué**: un calendario que lo rechaza todo también cumple el paso 1. La otra mitad de la
promesa: dos reservas válidas que no comparten ningún día se aceptan las dos. Y como en Halmos
revertir no es fallar, la aceptación se comprueba con `try` y un `assert`.

```solidity
function check_DisjointAccepted(uint32 from1, uint32 to1, uint32 from2, uint32 to2) public {
    vm.assume(from1 <= to1 && from2 <= to2);
    vm.assume(to1 < from2 || to2 < from1);
    bookings.book(from1, to1);
    bool accepted;
    try bookings.book(from2, to2) {
        accepted = true;
    } catch {}
    assertTrue(accepted);
}
```

**Abre** `BookingsSpec.t.sol` y, en `check_DisjointAccepted`, borra el `assertTrue(false, ...)` y
descomenta el cuerpo.

**Verifica**: `bash test.sh` termina sin error, con las dos specs demostradas:

```text
[PASS] check_DisjointAccepted(uint32,uint32,uint32,uint32) (paths: 6, time: 0.09s, bounds: [])
[PASS] check_NoDayTwice(uint32,uint32,uint32,uint32,uint32) (paths: 23, time: 0.17s, bounds: [])
Symbolic test result: 2 passed; 0 failed; time: 0.28s
```

Tus `paths` y tus tiempos pueden ser otros.

## Paso 4: Una spec que no mira

Sin escribir nada que se entregue. Haz `book` demasiado estricto, como si alguien hubiera dejado
un día de margen entre reservas:

```solidity
if (from <= other.to + 1 && other.from <= to + 1) revert Overlaps(i);
```

Ejecuta `halmos --no-status --function check_DisjointAccepted`: falla, con reservas que no se
tocan y se rechazan. Ahora, en `check_DisjointAccepted`, sustituye las cinco líneas del `try` por
una llamada directa, `bookings.book(from2, to2);`, y vuelve a ejecutarlo.

**Verifica**: `[PASS] check_DisjointAccepted`. Con la llamada directa, cada rechazo es un camino
que revierte, y Halmos lo descarta. La spec pasa sin mirar lo que tenía que mirar. Devuelve el
`try` y la línea de `book` a su sitio.

## Para pensar

- Escribe `check_NoDayTwice` como test de fuzz (`testFuzz_NoDayTwice`, los mismos parámetros) y
  ejecútalo con el fallo del paso 2 sin corregir. ¿Lo encuentra forge? ¿En cuántas ejecuciones?
  (Pista: el fuzzer de forge prueba primero valores como 0.) Si los dos lo encuentran, ¿qué te
  da Halmos que el fuzz no te da?
- `check_NoDayTwice` solo mira dos reservas. ¿Demuestra algo para tres? ¿Qué cambiarías en la
  spec, y qué pasa con el bucle de `book` (teoría 04)?
- En el paso 4, Halmos no avisó de que la spec sin `try` era vacía. ¿Por qué no salió el aviso
  "all paths have been reverted"?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — SMTChecker](../ejercicio-01-smtchecker/README.md) | **Ejercicio 02 — Halmos** | [Ejercicio 03 — Specs de contrato →](../ejercicio-03-specs-de-contrato/README.md) |
