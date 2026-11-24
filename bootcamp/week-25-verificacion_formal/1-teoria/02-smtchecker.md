# Teoría 02 — SMTChecker

## 🎯 Objetivos

- Activar el SMTChecker de `solc` desde `foundry.toml` y elegir qué contratos analiza.
- Escribir una spec para el SMTChecker: un contrato que hereda el tuyo y solo tiene `assert`.
- Leer sus tres resultados: violación con contraejemplo, demostrado y no demostrado.
- Saber qué no entiende y cómo eso puede inventar un contraejemplo.

## El SMTChecker

El **SMTChecker** es un verificador formal que viene dentro del compilador de Solidity. No hay
que instalar nada aparte de un solver: mientras compila, traduce el contrato a fórmulas y le pide
a z3 que demuestre sus `assert`. La imagen trae z3 4.12.6 en el `PATH`, el que viene con Halmos.
Sin él, `solc` avisa y no demuestra nada:

```text
Warning (8158): Solver z3 was selected for SMTChecker but it is not available.
```

Tiene dos motores:

| Motor | Qué hace |
| ----- | -------- |
| **BMC** (*bounded model checking*) | Mira cada función por separado, con el estado como incógnita, sin seguir secuencias |
| **CHC** (*constrained Horn clauses*) | Razona sobre **cualquier secuencia de transacciones**, de cualquier longitud, desde el constructor |

Esta semana usas CHC. Lo que lo hace potente es que no prueba secuencias una a una: busca una
**invariante del contrato**, una fórmula sobre el estado que el constructor cumple y que ninguna
función puede romper. Si la encuentra y la invariante implica tu `assert`, el `assert` se cumple
después de **cualquier** secuencia. Si no, busca una secuencia que lo rompa.

## Activarlo en `foundry.toml`

El SMTChecker se configura en una sección propia del perfil. `forge build` y `forge test` lo
ejecutan en cada compilación:

```toml
[profile.default.model_checker]
contracts = { "test/TicketsSpec.sol" = ["TicketsSpec"] }
engine = "chc"
targets = ["assert"]
invariants = ["contract"]
show_proved_safe = true
timeout = 20000
```

| Clave | Qué hace |
| ----- | -------- |
| `contracts` | Qué contratos analiza, por archivo. Sin ella, todos, también forge-std y OpenZeppelin: la compilación se alarga y los avisos se multiplican |
| `engine` | `chc`, `bmc` o `all` |
| `targets` | Qué comprueba. `assert` son tus aserciones; hay otros, como `overflow`, `underflow` o `divByZero` |
| `invariants` | Con `["contract"]`, imprime la invariante del contrato que encontró |
| `show_proved_safe` | Escribe también lo que demostró, no solo lo que falla |
| `timeout` | Milisegundos por consulta al solver |

Los resultados salen como avisos e informaciones del compilador, mezclados con la compilación.
No hacen fallar el build: si quieres que fallen, `forge build --deny warnings`.

## La spec: un contrato que hereda

El SMTChecker comprueba los `assert` que encuentra en el código. Para no llenar tu contrato de
aserciones, escribe la especificación aparte: un contrato que **hereda** el tuyo y añade
funciones que solo afirman.

```solidity
contract TicketsSpec is Tickets {
    function checkWithinCapacity() external view {
        assert(sold + reserved <= CAPACITY);
    }
}
```

CHC trata **cada función pública como una transacción** que cualquiera puede enviar en cualquier
orden: las de `Tickets` y `checkWithinCapacity`. Así, el `assert` se comprueba en cualquier
estado al que llegue cualquier secuencia de reservas, confirmaciones y cancelaciones. Es una
invariante de la semana 24, pero demostrada para todas las secuencias.

`TicketsSpec` no se despliega nunca. Vive en `test/` y `contracts` la señala.

## Los tres resultados

### Violación, con contraejemplo

```text
Warning (6328): CHC: Assertion violation happens here.
Counterexample:
CAPACITY = 10, MAX_PER_ORDER = 4, sold = 0, reserved = 11

Transaction trace:
TicketsSpec.constructor()
State: CAPACITY = 10, MAX_PER_ORDER = 4, sold = 0, reserved = 0
Tickets.reserve(4){ msg.sender: 0x08bb }
State: CAPACITY = 10, MAX_PER_ORDER = 4, sold = 0, reserved = 4
Tickets.reserve(3){ msg.sender: 0x08bb }
State: CAPACITY = 10, MAX_PER_ORDER = 4, sold = 0, reserved = 7
Tickets.reserve(4){ msg.sender: 0x08bb }
State: CAPACITY = 10, MAX_PER_ORDER = 4, sold = 0, reserved = 11
TicketsSpec.checkWithinCapacity()
  --> test/TicketsSpec.sol:15:9:
```

Se lee como la secuencia encogida de forge: el estado tras el constructor y, después de cada
transacción, el estado nuevo. `msg.sender` es una dirección que elige el solver, normalmente
corta. Los números pueden cambiar de una ejecución a otra; la secuencia rompe la propiedad igual.

### Demostrado

```text
Info (1180): Contract invariant(s) for test/TicketsSpec.sol:TicketsSpec:
(true || !((sold + reserved) >= 11))
Info (9576): CHC: Assertion violation check is safe!
  --> test/TicketsSpec.sol:15:9:
```

`safe` es la demostración: ninguna secuencia rompe el `assert`. Encima, la invariante que encontró
CHC, escrita a su manera: `!((sold + reserved) >= 11)`, es decir, `sold + reserved <= 10`. Con
`invariants = ["contract"]` puedes ver **por qué** es verdad.

### No demostrado

```text
Warning (5840): CHC: 1 verification condition(s) could not be proved. Enable the model checker
option "show unproved" to see all of them. ...
```

Ni violación ni demostración: el solver agotó su tiempo o no encontró una invariante. **No es un
fallo y no es una demostración.** Pasa, por ejemplo, con `assert(reservedOf[msg.sender] <=
reserved)`, que es verdad en `Tickets` pero necesita una invariante sobre la **suma** de todo un
mapping, y CHC no la encuentra. `show_unproved = true` dice cuál quedó sin demostrar.

## Lo que no entiende

El SMTChecker no modela todo Solidity. Lo que no entiende lo avisa, a veces sin detalle:

```text
Warning (5724): SMTChecker: 2 unsupported language feature(s). Enable the model checker option
"show unsupported" to see all of them.
```

Con `show_unsupported = true`, el detalle. En Solidity 0.8.38, los **errores personalizados**
son uno de esos casos:

```text
Warning (8364): Assertion checker does not yet implement type error
  --> src/Tickets.sol:24:59:
   |
24 |         if (amount == 0 || amount > MAX_PER_ORDER) revert InvalidAmount(amount);
   |                                                           ^^^^^^^^^^^^^^^^^^^^^
```

Y no es un aviso inofensivo. Con ese `revert` sin entender, el contraejemplo puede ser imposible:

```text
Tickets.reserve(3){ msg.sender: 0x34c9 }
Tickets.reserve(8){ msg.sender: 0x3cf5 }
```

`reserve(8)` revierte en la EVM real (el máximo es 4), pero el SMTChecker no lo sabe. Es un
**contraejemplo espurio**: una secuencia que la herramienta cree posible y no lo es. Por eso cada
contraejemplo se comprueba con un test antes de creerlo. Con `require(condición, "mensaje")` o
`revert()` sin error personalizado, el SMTChecker sí entiende el `revert`.

El resto de la lista crece con cada contrato real: llamadas a otros contratos (las trata como
desconocidas), bucles con muchas vueltas, ensamblador, herencia larga de OpenZeppelin. En un
protocolo como el tuyo, el SMTChecker da sobre todo avisos de lo que no entiende y consultas sin
resolver. Para eso está Halmos.

## ⚠️ Riesgos

- **Creer un contraejemplo sin reproducirlo.** Si el contrato usa algo que el SMTChecker no
  entiende, el contraejemplo puede ser imposible. Un test con la misma secuencia lo decide.
- **Leer "could not be proved" como "está bien".** Es "no lo sé". Si la propiedad importa, se
  prueba de otra forma (invariantes, Halmos) y el informe dice que no se demostró.
- **Analizar demasiado.** Sin `contracts`, el SMTChecker analiza todo lo que compila, también las
  bibliotecas. La compilación se vuelve lenta y los avisos tapan lo importante.
- **Cambiar el código solo para el verificador.** Pasar de errores personalizados a mensajes de
  texto cuesta gas y pierde datos del error. En un contrato real, decide si compensa; si no,
  verifica con Halmos.

## 📝 Resumen

- El SMTChecker va dentro de `solc`; forge lo activa con `[profile.default.model_checker]` y usa
  el z3 de la imagen.
- Con el motor CHC, un `assert` en una función de la spec se comprueba tras cualquier secuencia
  de transacciones, de cualquier longitud.
- Tres resultados: violación con contraejemplo, `safe` con su invariante, y "could not be
  proved", que no es nada.
- No entiende todo: con errores personalizados, sus contraejemplos pueden ser espurios.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — De probar a demostrar](01-de-probar-a-demostrar.md) | **Teoría 02 — SMTChecker** | [Teoría 03 — Halmos →](03-halmos.md) |
