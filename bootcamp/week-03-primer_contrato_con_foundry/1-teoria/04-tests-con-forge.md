# Teoría 04 — Tests con forge

## 🎯 Objetivos

- Explicar por qué un contrato se prueba antes de desplegarlo.
- Escribir un test en Solidity con `setUp`, `assertEq` y `assertTrue`.
- Ejecutar `forge test`, leer un fallo y pedir una traza con `-vvvv`.
- Usar tres cheatcodes: `vm.prank`, `makeAddr` y `vm.expectRevert`.

---

## 1. Qué problema resuelve

Un contrato desplegado no se puede editar. Si tiene un fallo, el fallo se queda en la
cadena, y en una red real puede costar dinero de otros. Por eso se prueba **antes** de
desplegar, y de forma automática: cada cambio vuelve a pasar todos los tests.

Con Foundry los tests se escriben **en Solidity**, en el mismo lenguaje que el contrato.
`forge test` los compila, despliega el contrato en una EVM local en memoria (sin anvil,
sin red) y ejecuta cada test en milisegundos.

## 2. Un test

**Dónde**: en `test/Counter.t.sol` (los tests acaban en `.t.sol`).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter counter;

    function setUp() public {
        counter = new Counter();
    }

    function test_SetSeven() public {
        counter.set(7);
        assertEq(counter.get(), 7);
    }
}
```

| Pieza | Qué hace |
| ----- | -------- |
| `import {Test} from "forge-std/Test.sol";` | Trae el contrato `Test` de la biblioteca `forge-std` |
| `import {Counter} from "../src/Counter.sol";` | Trae tu contrato para poder desplegarlo |
| `contract CounterTest is Test` | El test es otro contrato. `is Test` le da las funciones `assertEq`, `vm`... (la herencia, `is`, se explica en la semana 08: por ahora es una plantilla) |
| `Counter counter;` | Variable de estado que guarda el contrato bajo prueba |
| `setUp()` | Se ejecuta **antes de cada test**: cada test empieza con un `Counter` nuevo |
| `new Counter()` | Despliega un `Counter` y devuelve su dirección, con el tipo `Counter` |
| `counter.set(7)` | Llama a la función del contrato desplegado, como haría `cast send` |
| `test_SetSeven` | Toda función que empieza por `test` es un test |
| `assertEq(a, b)` | Si `a` y `b` no son iguales, el test falla |

`forge test` ejecuta cada test de forma aislada: lo que un test cambia no lo ve el
siguiente. Por eso el orden de los tests no importa.

## 3. Ejecutar

**Dónde**: en el contenedor, en la carpeta del proyecto.

```bash
forge test
```

**Salida** (el número de gas es el que consumió el test entero):

```
Ran 1 test for test/Counter.t.sol:CounterTest
[PASS] test_SetSeven() (gas: 52415)
```

Para ejecutar solo algunos tests, `--match-test` filtra por nombre:

```bash
forge test --match-test Seven
```

## 4. Cuando falla

Un test que espera lo que no pasa:

```solidity
function test_Wrong() public {
    counter.increment();
    assertEq(counter.get(), 2, "deberia valer 2");
}
```

```
[FAIL: deberia valer 2: 1 != 2] test_Wrong() (gas: 55400)
```

Se lee así: el mensaje que pusiste como tercer argumento, el valor obtenido (`1`) y el
esperado (`2`). El mensaje es opcional, pero en un archivo con muchos tests ahorra
tiempo.

`assertTrue(condición)` falla si la condición es falsa. Úsalo cuando no comparas dos
valores, por ejemplo `assertTrue(address(other) != address(counter))`.

## 5. La traza: qué pasó por dentro

Con `-vvvv` (cuatro uves, máximo detalle) `forge` imprime la **traza** (*trace*): cada
llamada, con su gas, sus argumentos y lo que devolvió.

```bash
forge test --match-test test_SetSeven -vvvv
```

```
Traces:
  [52415] CounterTest::test_SetSeven()
    ├─ [43719] Counter::set(7)
    │   └─ ← [Stop]
    ├─ [2454] Counter::get() [staticcall]
    │   └─ ← [Return] 7
    └─ ← [Stop]
```

`[Stop]` es que la función terminó sin devolver nada; `[Return] 7`, que devolvió 7.
`[staticcall]` marca una llamada que no puede cambiar el estado: el compilador la usa para
las funciones `view`. Cuando un test falla y no entiendes por qué, la traza es lo primero
que se mira.

## 6. Cheatcodes

Un **cheatcode** (truco) es una función especial de `forge` que cambia las reglas de la
EVM de prueba: cosas imposibles en una red real pero útiles para probar. Se llaman con
`vm.`. Esta semana usas tres; la semana 09 presenta el resto.

### `makeAddr` y `vm.prank`: llamar como otra cuenta

En un test, quien llama al contrato es el propio contrato de test (`address(this)`).
Para probar `msg.sender` necesitas llamar desde otras direcciones:

```solidity
function test_PrankLastsOneCall() public {
    address alice = makeAddr("alice");
    vm.prank(alice);
    counter.touch();
    assertEq(counter.getLastCaller(), alice);
    counter.touch();
    assertEq(counter.getLastCaller(), address(this));
}
```

- `makeAddr("alice")` crea una dirección a partir de un nombre, siempre la misma:
  `0x328809Bc894f92807417D2dAD6b7C998c1aFdac6`. Más legible que inventar hexadecimal.
- `vm.prank(alice)` hace que **la siguiente llamada**, y solo esa, tenga
  `msg.sender == alice`. El segundo `touch()` ya lo hace el contrato de test.

### `vm.expectRevert`: probar lo que debe fallar

Una transacción **revierte** (*revert*) cuando algo la detiene a mitad: sus cambios se
deshacen y la cadena queda como estaba. En Solidity 0.8, restar por debajo de cero
revierte solo. `vm.expectRevert()` dice "la siguiente llamada tiene que revertir":

```solidity
function test_RevertWhen_RemovingMoreThanTotal() public {
    scoreboard.addPoints(3);
    vm.expectRevert();
    scoreboard.removePoints(4);
}
```

La traza muestra por qué revirtió:

```
├─ [23928] Scoreboard::removePoints(4)
│   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
```

Si la llamada **no** revierte, el test falla con:

```
[FAIL: next call did not revert as expected]
```

El nombre `test_RevertWhen_Condición` es la convención del bootcamp para estos tests.

## 7. Antipatrones y riesgos

- **Probar solo el camino feliz**: los fallos graves están en los casos que nadie probó:
  el primer uso, el valor cero, otra cuenta llamando. Por cada función, piensa quién más
  podría llamarla y con qué valores.
- **Un test sin `assert`**: un test que no comprueba nada pasa siempre y da falsa
  confianza.
- **Cambiar el test para que pase**: si un test bien escrito falla, el fallo está en el
  contrato. Los tests de los ejercicios y del proyecto no se modifican por eso.
- **`vm.expectRevert()` sin motivo**: acepta **cualquier** reversión, también la de otro
  fallo distinto del que querías probar. La semana 05 enseña a comprobar el motivo
  exacto.

## 8. Trucos

- `forge test --match-test NOMBRE -vvvv`: un solo test con su traza.
- `forge test --gas-report`: tabla con el gas de cada función del contrato.
- `forge test --rerun` vuelve a ejecutar solo los que fallaron la última vez.
- Escribe el test antes que la función: así sabes qué significa "terminado".

## ✅ Checklist

- [ ] Explico por qué se prueba antes de desplegar.
- [ ] Escribo un test con `setUp`, `assertEq` y `assertTrue`.
- [ ] Leo un `[FAIL: ...]` y obtengo la traza de un test.
- [ ] Uso `makeAddr` y `vm.prank` para llamar como otra cuenta.
- [ ] Pruebo con `vm.expectRevert()` una llamada que debe revertir.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Estado y funciones](03-estado-y-funciones.md) | **Teoría 04 — Tests con forge** | [Teoría 05 — Desplegar y llamar →](05-desplegar-y-llamar.md) |
