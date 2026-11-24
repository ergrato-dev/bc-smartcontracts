# Teoría 03 — Halmos

## 🎯 Objetivos

- Preparar un proyecto Foundry para Halmos y ejecutarlo.
- Escribir tests `check_` con parámetros simbólicos, `vm.assume` y cheatcodes de forge.
- Leer su salida: resultado, caminos, contraejemplo y traza.
- Crear valores simbólicos dentro del test con `svm`, incluida una llamada simbólica.

## Halmos en la imagen

**Halmos** es un ejecutor simbólico para tests de Foundry, de a16z. Lee los artefactos que
compila forge, busca las funciones que empiezan por `check_` y las ejecuta con sus parámetros
como símbolos (teoría 01). Es una herramienta de Python; la imagen trae la versión 0.3.2,
instalada con uv con sus solvers, yices y z3:

```bash
halmos --version
```

```text
halmos 0.3.2
```

Como Medusa, solo está en la imagen amd64: sus solvers no publican paquetes para Linux arm64.

## Preparar el proyecto

Dos líneas en `foundry.toml`, las dos verificadas con forge 1.9:

```toml
dynamic_test_linking = false
ast = true
```

- **`dynamic_test_linking = false`.** La conoces de Medusa. Con el enlazado dinámico, `new Bookings()`
  en un test se compila como un cheatcode, `deployCode`, que Halmos no tiene:

  ```text
  WARNING  in setUp(), executing CALL failed with: Unsupported cheat code:
           deployCode(string)
  ERROR    setUp() failed: HalmosException: No successful path found in setUp()
  ```

- **`ast = true`.** Halmos necesita el árbol sintáctico de cada archivo en `out/`. Si forge ya
  compiló sin él, Halmos no recompila y no encuentra nada:

  ```text
  WARNING  Skipped FeeMathTest.json due to parsing failure: KeyError: 'ast'
  ERROR    No tests with --match-contract '' --match-test '^(check|invariant)_.*'
  ```

Fíjate en el patrón: Halmos ejecuta `check_` y también `invariant_`. En un proyecto con
invariantes de la semana 24, limítalo a tus specs con `--match-contract`.

### El solver

Halmos usa yices por defecto, y puede usar z3 con `--solver z3` o con un archivo propio,
`halmos.toml`, en la carpeta donde lo ejecutas:

```toml
[global]
solver = "z3"
```

Ninguno es mejor siempre. Los solvers usan heurísticas, y la misma pregunta puede tardar
milisegundos o un minuto según el camino que tomen. Medido en los ejercicios de esta semana:

| Spec | yices | z3 |
| ---- | ----- | -- |
| `check_NoDayTwice` (ejercicio 02) | `TIMEOUT` en 2 de 15 ejecuciones | En verde en 30 de 30, en menos de medio segundo |
| `check_TransferKeepsBalances` (ejercicio 03) | 0,4 segundos en 15 de 15 | Entre 0,8 y 17 segundos |

Por eso el ejercicio 02 trae un `halmos.toml` con z3 y el 03 no. Si una spec pasa unas veces y
otras da `TIMEOUT`, ejecútala varias veces con cada solver antes de tocar la spec.

## Un test `check_`

Un test de Halmos es un test de forge con otro prefijo. Vive en `test/`, hereda de `Test`, tiene
su `setUp` y usa los mismos cheatcodes:

```solidity
contract BookingsSpec is Test {
    Bookings internal bookings;

    function setUp() public {
        bookings = new Bookings();
    }

    function check_NoDayTwice(uint32 from1, uint32 to1, uint32 from2, uint32 to2, uint32 day) public {
        bookings.book(from1, to1);
        try bookings.book(from2, to2) {
            bool inFirst = from1 <= day && day <= to1;
            bool inSecond = from2 <= day && day <= to2;
            assertFalse(inFirst && inSecond);
        } catch {}
    }
}
```

Lo que cambia:

- **`setUp` es concreto.** Se ejecuta una vez, con valores normales.
- **Los parámetros son símbolos.** `from1`, `to1`... no toman 256 valores: los toman todos a la vez.
- **`forge test` no lo ejecuta**: no empieza por `test`. Lo ejecuta `halmos`, que compila con
  `forge build` y después explora.

```bash
halmos --no-status
```

`--no-status` quita la barra de progreso, que en un log se repite línea a línea. Otras opciones
que usarás:

| Opción | Qué hace |
| ------ | -------- |
| `--match-contract RegistrySpec` | Solo los contratos cuyo nombre encaja |
| `--function check_NoDayTwice` | Solo las funciones que empiezan así |
| `--loop 11` | Hasta cuántas vueltas sigue cada bucle con límite simbólico (por defecto, 2) |
| `-vv --early-exit` | Para en el primer contraejemplo e imprime su traza |

Termina con código 0 si todo pasa y 1 si algo falla, como `forge test`.

## Leer la salida

```text
Running 2 tests for test/BookingsSpec.t.sol:BookingsSpec
Counterexample:
    p_day_uint32_d7d3078_00 = 0x00
    p_from1_uint32_f54f622_00 = 0x00
    p_from2_uint32_4cb860c_00 = 0x00
    p_to1_uint32_fe84ef7_00 = 0x00
    p_to2_uint32_c7cb455_00 = 0x00
[FAIL] check_NoDayTwice(uint32,uint32,uint32,uint32,uint32) (paths: 24, time: 0.16s, bounds: [])
```

| Parte | Qué dice |
| ----- | -------- |
| `[PASS]`, `[FAIL]` | Demostrado para todas las entradas, o con contraejemplo. También hay `[TIMEOUT]` y `[ERROR]` (teoría 04) |
| `Counterexample:` | Un valor por símbolo: `p_<parámetro>_<tipo>_<id>`. Aquí, dos reservas del día 0 |
| `paths` | Cuántos caminos exploró. Cambia entre ejecuciones; no es un número que comparar |
| `time` | Lo que tardó esa función |
| `bounds` | Los tamaños de arrays y bytes simbólicos que usó |

Un contraejemplo es una afirmación: "con estas entradas, la aserción falla". Conviértelo en un
test unitario con esos valores: comprueba en la EVM real que es cierto y se queda como test de
regresión cuando lo corriges.

Si hay varios caminos que fallan, Halmos imprime un contraejemplo por camino.

## `vm.assume` y los caminos que revierten

`vm.assume(condición)` funciona como en el fuzz de forge, pero aquí no descarta entradas: añade
la condición a cada camino. Las entradas que no la cumplen no existen para esa spec.

Y una diferencia que muerde: **en Halmos, un camino que revierte no es un fallo.** Solo fallan las
aserciones (y los `panic` de `assert`). Este test pasa:

```solidity
function check_RevertIsNotFailure(uint256 x) public pure {
    require(x != 42, "boom");
    assertTrue(x != 42);
}
```

```text
[PASS] check_RevertIsNotFailure(uint256) (paths: 2, time: 0.00s, bounds: [])
```

Con `x == 42` el test revierte, y Halmos descarta ese camino como si fuera un `vm.assume`. Por
eso, cuando una spec dice "esto se tiene que **aceptar**", la llamada va dentro de un `try` o de
un `call`, con un `assert` sobre el resultado:

```solidity
bool accepted;
try bookings.book(from2, to2) {
    accepted = true;
} catch {}
assertTrue(accepted);
```

Si la llamas sin `try`, un contrato que rechaza de más pasa la spec: sus rechazos son caminos que
revierten. Lo ves en el ejercicio 02.

## Valores simbólicos dentro del test: `svm`

Los parámetros cubren casi todo. Para crear un símbolo en mitad del test, Halmos tiene sus
propios cheatcodes, en la biblioteca `halmos-cheatcodes` (la imagen la trae en `/opt/lib`):

```toml
remappings = ["halmos-cheatcodes/=/opt/lib/halmos-cheatcodes/src/"]
```

```solidity
import {SymTest} from "halmos-cheatcodes/SymTest.sol";

contract TokenSpec is Test, SymTest {
    // ...
}
```

`SymTest` da la variable `svm`, con, entre otras, `svm.createUint256("nombre")`,
`svm.createAddress("nombre")`, `svm.createBytes(tamaño, "nombre")` y la más potente,
`svm.createCalldata("Token")`: **una llamada simbólica** a cualquier función no `view` de
`Token`, con cualquier argumento.

```solidity
function check_NobodyTakesYourTokens(address caller, address victim, uint256 minted) public {
    vm.assume(caller != victim);
    vm.assume(caller != address(this));
    token.mint(victim, minted);
    bytes memory data = svm.createCalldata("Token");
    vm.prank(caller);
    (bool ok,) = address(token).call(data);
    vm.assume(ok);
    assertGe(token.balanceOf(victim), minted);
}
```

"Ninguna llamada de otra cuenta baja tu saldo", demostrado para todas las funciones a la vez,
también las que olvidaste probar. El contraejemplo dice los argumentos pero no la función; la
traza sí:

```bash
halmos --no-status --function check_NobodyTakesYourTokens -vv --early-exit
```

```text
        CALL 0xaaaa0002::burnFrom(Concat(p_from_address_72a1c33_05, p_amount_uint256_96a624d_06)) ...
```

`0xaaaa0002` es la dirección del token: Halmos numera los contratos que crea (teoría 04).

## Lo que Halmos tiene y lo que no

Halmos implementa los cheatcodes de forge más usados en specs: `vm.prank`, `vm.startPrank`,
`vm.deal`, `vm.assume`, `vm.warp`, `vm.etch` y `vm.store`, entre otros. Los de despliegue
(`deployCode`) y los de red (`createFork`) no. Si un `setUp` falla con "Unsupported cheat code",
la línea de antes dice cuál.

## ⚠️ Riesgos

- **Olvidar que revertir no falla.** Una spec que debía exigir una aceptación y no usa `try` pasa
  sin probar nada.
- **Creer en `paths`.** Más caminos no es mejor ni peor. Lo que dice si la exploración fue
  completa son los avisos (teoría 04).
- **Ejecutar las invariantes con Halmos sin querer.** Sin `--match-contract`, Halmos ejecuta
  también los `invariant_` de la semana 24, con su propio modelo.
- **`vm.assume` demasiado estrecho.** Cada `assume` quita entradas de la demostración. Escribe en
  el informe lo que excluiste y por qué.

## 📝 Resumen

- Halmos ejecuta los `check_` de tus tests con los parámetros como símbolos; necesita
  `dynamic_test_linking = false` y `ast = true`.
- La salida da, por función, `PASS`, `FAIL` con contraejemplo, `TIMEOUT` o `ERROR`.
- Un camino que revierte no es un fallo: las aceptaciones se comprueban con `try` y `assert`.
- `svm.createCalldata` prueba una llamada a cualquier función de un contrato a la vez.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — SMTChecker](02-smtchecker.md) | **Teoría 03 — Halmos** | [Teoría 04 — Especificaciones y límites →](04-especificaciones-y-limites.md) |
