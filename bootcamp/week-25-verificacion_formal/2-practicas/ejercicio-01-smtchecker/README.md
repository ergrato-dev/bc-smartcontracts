# Ejercicio 01 — SMTChecker

> Al terminar habrás escrito una spec para el SMTChecker, habrás descartado un contraejemplo
> imposible, habrás corregido el fallo real que encuentra y habrás visto cómo demuestra la
> propiedad para cualquier secuencia de transacciones.

**Duración estimada**: 1 h 15 min
**Prerrequisitos**: [Teoría 01](../../1-teoria/01-de-probar-a-demostrar.md) y
[Teoría 02](../../1-teoria/02-smtchecker.md) leídas.

## Contexto

`Tickets` vende las diez entradas de una sala pequeña en dos pasos: `reserve(amount)` aparta de 1
a 4 entradas, y después quien reservó las confirma (`confirm`) o las libera (`cancel`). Una
reserva pendiente ocupa sitio igual que una entrada vendida, así que `sold + reserved` nunca
puede pasar de 10. Sus cinco tests unitarios pasan.

`foundry.toml` ya activa el SMTChecker sobre `TicketsSpec`, con el motor CHC: cada `forge build` y
cada `forge test` lo ejecutan.

| Archivo | Qué es |
| ------- | ------ |
| `src/Tickets.sol` | El contrato. Pasos 2 y 3 |
| `test/TicketsSpec.sol` | La spec para el SMTChecker. Paso 1 |
| `test/Tickets.t.sol` | Cinco tests unitarios, en verde, y dos para los contraejemplos. Pasos 2 y 3 |
| `foundry.toml` | Con la sección `[profile.default.model_checker]`. **No la modifiques** |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-25-verificacion_formal/2-practicas/ejercicio-01-smtchecker/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `5 tests passed, 2 failed`. Fallan `test_FirstCounterexample` y
`test_SecondCounterexample` con su `TODO`. Entre los avisos de la compilación:

```text
Warning (5724): SMTChecker: 2 unsupported language feature(s). Enable the model checker option "show unsupported" to see all of them.
```

Todavía no hay ningún `assert`: el SMTChecker no tiene nada que demostrar.

## Paso 1: La spec

**Por qué**: lo que promete `Tickets` es que reservas y ventas, juntas, no pasan de la capacidad.
En una función de la spec, el SMTChecker lo comprueba tras cualquier secuencia de `reserve`,
`confirm` y `cancel`, de cualquier longitud y desde cualquier cuenta.

```solidity
function checkWithinCapacity() external view {
    assert(sold + reserved <= CAPACITY);
}
```

**Abre** `test/TicketsSpec.sol` y descomenta la línea del `assert`.

**Verifica**: `forge build` imprime una violación con su contraejemplo:

```text
Warning (6328): CHC: Assertion violation happens here.
Counterexample:
CAPACITY = 10, MAX_PER_ORDER = 4, sold = 0, reserved = 11

Transaction trace:
TicketsSpec.constructor()
State: CAPACITY = 10, MAX_PER_ORDER = 4, sold = 0, reserved = 0
Tickets.reserve(3){ msg.sender: 0x34c9 }
State: CAPACITY = 10, MAX_PER_ORDER = 4, sold = 0, reserved = 3
Tickets.reserve(8){ msg.sender: 0x3cf5 }
State: CAPACITY = 10, MAX_PER_ORDER = 4, sold = 0, reserved = 11
TicketsSpec.checkWithinCapacity()
```

Tus números y tus `msg.sender` pueden ser otros. Mira las cantidades de `reserve`: alguna pasa
de 4.

## Paso 2: ¿Es posible ese contraejemplo?

**Por qué**: `MAX_PER_ORDER` es 4, y `reserve` revierte con más. Un contraejemplo es una
afirmación, y la EVM la decide: escribe la secuencia como test. Si la reserva grande revierte, el
contraejemplo es imposible. La causa son los avisos del paso 0: el SMTChecker de Solidity 0.8.38
no entiende `revert InvalidAmount(amount)` (teoría 02) y da por buena una llamada que revierte.

```solidity
function test_FirstCounterexample() public {
    tickets.reserve(4);
    vm.expectRevert();
    tickets.reserve(7);
}
```

```solidity
require(amount > 0 && amount <= MAX_PER_ORDER, "invalid amount");
require(sold + amount <= CAPACITY, "sold out");
```

**Abre** `test/Tickets.t.sol` y, en `test_FirstCounterexample`, borra el `revert` y descomenta
las tres líneas (pon tu segunda cantidad si quieres). Después, en `src/Tickets.sol`, borra las
cuatro líneas marcadas `// <- Paso 2` (los dos `error` y los dos `if ... revert`) y, en `reserve`,
descomenta las dos primeras líneas `//>`: los dos `require`. La tercera `//>` es del paso 3.

**Verifica**: `test_FirstCounterexample` pasa: la reserva grande revierte, el contraejemplo era
imposible. Y `forge build` ya no avisa de `unsupported`, y da otro contraejemplo, ahora con
cantidades válidas:

```text
Tickets.reserve(4){ msg.sender: 0x08bb }
State: CAPACITY = 10, MAX_PER_ORDER = 4, sold = 0, reserved = 4
Tickets.reserve(3){ msg.sender: 0x08bb }
State: CAPACITY = 10, MAX_PER_ORDER = 4, sold = 0, reserved = 7
Tickets.reserve(4){ msg.sender: 0x08bb }
State: CAPACITY = 10, MAX_PER_ORDER = 4, sold = 0, reserved = 11
```

## Paso 3: Las reservas pendientes ocupan sitio

**Por qué**: `reserve` compara con `sold`, lo vendido, y olvida `reserved`, lo apartado. Con las
reservas sin confirmar, se aparta más de lo que cabe. Los tests unitarios confirman cada reserva
antes de la siguiente, y así no se ve. Primero el test, con la secuencia del contraejemplo;
después la corrección.

```solidity
function test_SecondCounterexample() public {
    vm.prank(alice);
    tickets.reserve(4);
    vm.prank(bob);
    tickets.reserve(3);
    vm.prank(bob);
    vm.expectRevert(bytes("sold out"));
    tickets.reserve(4);
}
```

```solidity
require(sold + reserved + amount <= CAPACITY, "sold out");
```

**Abre** `test/Tickets.t.sol` y, en `test_SecondCounterexample`, borra el `revert` y descomenta
el cuerpo. Ejecuta `forge test --mt Second`: falla con `next call did not revert as expected`.
Después, en `src/Tickets.sol`, sustituye la línea `// <- Paso 3` por la de debajo.

**Verifica**: `forge test` sin error, `7 passed`, y el SMTChecker demuestra la spec y dice por qué:

```text
Info (1180): Contract invariant(s) for src/Tickets.sol:Tickets:
(true || true || true || true)
Contract invariant(s) for test/TicketsSpec.sol:TicketsSpec:
(true || !((sold + reserved) >= 11))
Info (9576): CHC: Assertion violation check is safe!
  --> test/TicketsSpec.sol:15:9:
```

La invariante que encontró, `!((sold + reserved) >= 11)`, es tu spec: el constructor la cumple y
ninguna de las tres funciones la rompe. Vale para cualquier secuencia, de cualquier longitud.

## Paso 4: Verdad, pero sin demostrar

Sin escribir nada que se entregue: añade a `TicketsSpec` otra propiedad, verdadera en `Tickets`,
y ejecuta `forge build`:

```solidity
function checkOwnWithinTotal() external view {
    assert(reservedOf[msg.sender] <= reserved);
}
```

**Verifica**: tras unos 25 segundos, la primera propiedad sigue `safe` y la nueva no sale ni como
violación ni como demostrada:

```text
Warning (5840): CHC: 1 verification condition(s) could not be proved. Enable the model checker option "show unproved" to see all of them. ...
```

Para demostrarla, CHC necesitaría una invariante sobre la suma de todo `reservedOf`, y no la
encuentra. "Could not be proved" no es ni un fallo ni una demostración. Borra la función antes de
seguir.

## Para pensar

- En el paso 2 cambiaste los errores personalizados por mensajes de texto para que el SMTChecker
  te entendiera. ¿Qué pierdes en un contrato real? ¿Lo harías en tu protocolo?
- El contraejemplo del paso 2 hace tres reservas. ¿Cuál es la secuencia más corta que rompe la
  spec con el fallo del paso 3? ¿Por qué no puede ser de una sola reserva?
- ¿Cómo escribirías `checkOwnWithinTotal` como invariante de forge, con un handler de tres
  cuentas? ¿La demostraría eso?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Especificaciones y límites](../../1-teoria/04-especificaciones-y-limites.md) | **Ejercicio 01 — SMTChecker** | [Ejercicio 02 — Halmos →](../ejercicio-02-halmos/README.md) |
