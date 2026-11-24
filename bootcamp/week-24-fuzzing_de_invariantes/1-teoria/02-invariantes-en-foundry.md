# Teoría 02 — Invariantes en Foundry

## 🎯 Objetivos

- Escribir un test de invariantes con forge: `setUp`, `targetContract` y funciones `invariant_`.
- Elegir a qué contratos, funciones y cuentas llama el fuzzer.
- Leer la salida: la secuencia encogida, la tabla de llamadas y los fallos guardados.
- Configurar la campaña con `[invariant]` y con configuración en línea.

## Un test de invariantes

Es un contrato de test como los de la semana 09, con dos diferencias: en `setUp` dices a qué
contrato llamar, y las comprobaciones van en funciones que empiezan por `invariant_`:

```solidity
import {Test} from "forge-std/Test.sol";
import {Seats} from "../src/Seats.sol";

contract SeatsInvariantsTest is Test {
    Seats seats;

    function setUp() public {
        seats = new Seats();
        targetContract(address(seats));
    }

    function invariant_BookedMatchesHolders() public view {
        uint256 held;
        for (uint256 seat = 0; seat < seats.CAPACITY(); seat++) {
            if (seats.holderOf(seat) != address(0)) held++;
        }
        assertEq(seats.booked(), held);
    }
}
```

**Dónde**: en `test/SeatsInvariants.t.sol` del ejercicio 01. **Cómo**: `forge test`, como
cualquier test.

Lo que hace forge con cada `invariant_`:

1. Ejecuta `setUp`.
2. Elige una función del objetivo, unos argumentos y una cuenta, y la llama. Repite hasta `depth`
   llamadas (500 por defecto): eso es una **secuencia**, o un *run*.
3. Después de cada llamada, ejecuta las funciones `invariant_`. Si una falla, se para.
4. Vuelve a 1, hasta `runs` secuencias (256 por defecto).

Que una llamada del objetivo revierta no es un fallo: forge la cuenta y sigue. Lo que falla es una
`invariant_`, con un `assert*` de forge-std o con un `revert`.

## A quién llama el fuzzer

Sin `targetContract`, forge llama a **todos** los contratos desplegados en `setUp`. En el
ejercicio 02, sin esa línea, la tabla de llamadas sale así:

```text
| Contract     | Selector     | Calls | Reverts | Discards |
| Token        | approve      | 14165 | 29      | 0        |
| Token        | mint         | 14320 | 464     | 0        |
| Token        | transfer     | 14220 | 14036   | 0        |
| Token        | transferFrom | 14236 | 14173   | 0        |
| Vault        | deposit      | 14174 | 14174   | 0        |
| Vault        | withdraw     | 14378 | 14296   | 0        |
| VaultHandler | addYield     | 14205 | 165     | 0        |
| VaultHandler | deposit      | 14047 | 171     | 0        |
| VaultHandler | withdraw     | 14255 | 3       | 0        |
```

Y una invariante correcta falla: `Token.mint` puede acuñar directamente al vault, por un camino
que la contabilidad del test no conoce. Por eso, **siempre** `targetContract`. Las otras
herramientas de `StdInvariant`, que hereda `Test`:

| Función | Qué hace |
| ------- | -------- |
| `targetContract(addr)` | Solo llama a estos contratos (puedes llamarla varias veces) |
| `excludeContract(addr)` | A este no lo llama nunca |
| `targetSelector(FuzzSelector({addr: a, selectors: s}))` | De `a`, solo estas funciones |
| `targetSender(addr)` | Las llamadas salen solo de estas cuentas |
| `excludeSender(addr)` | Ninguna llamada sale de esta cuenta |

Las funciones `view` y `pure` del objetivo no se llaman: no cambian el estado.

`targetSender` importa más de lo que parece. Con cuentas aleatorias, la que reserva una butaca
casi nunca es la que después la pasa a otro. Con tres cuentas fijas, el ejercicio 01 encuentra
la secuencia de `transferSeat` en cada ejecución:

```solidity
targetSender(makeAddr("alice"));
targetSender(makeAddr("bob"));
targetSender(makeAddr("carol"));
```

## Leer un fallo

Esta es la salida real del ejercicio 01 con el paso 1 hecho:

```text
[FAIL: assertion failed: 2 != 1] invariant_BookedMatchesHolders
	[Sequence] (original: 5, shrunk: 2)
		sender=0xA4d4c1f8a763Ef6a0140D04291eCEef913Ffc272 addr=[src/Seats.sol:Seats]0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f calldata=book(uint256) args=[0]
		sender=0xA4d4c1f8a763Ef6a0140D04291eCEef913Ffc272 addr=[src/Seats.sol:Seats]0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f calldata=transferSeat(uint256,address) args=[0, 0x0000000000000000000000000000000000000000]
...
SeatsInvariantsTest invariants: 3/3 invariants broken
3 invariant failure(s) persisted to cache/invariant/failures/SeatsInvariantsTest — rerun to shrink
 SeatsInvariantsTest invariants (runs: 256, calls: 318, reverts: 286)
```

- **`assertion failed: 2 != 1`**: lo que dijo el `assertEq`, con los valores tras la última
  llamada de la secuencia **original**.
- **`[Sequence] (original: 5, shrunk: 2)`**: forge encontró el fallo con 5 llamadas y lo
  **encogió** (*shrinking*): quitó llamadas mientras la invariante siguiera fallando. Quedan las
  2 imprescindibles, cada una con su cuenta (`sender`), su función y sus argumentos.
- **`3/3 invariants broken`**: forge 1.9 ejecuta todas las `invariant_` de un contrato en la misma
  campaña, y las cuenta como **un** test en el resumen.
- **`persisted to cache/invariant/failures`**: forge guarda la secuencia. La próxima vez que
  ejecutes `forge test`, la repite primero (`runs: 1, calls: 2`) y la encoge más si puede. Cuando
  la corrijas, la repetición pasa y sigue la campaña normal.
- **`runs: 256, calls: 318, reverts: 286`**: 256 secuencias empezadas, 318 llamadas hechas antes
  de fallar, y 286 de ellas revertidas.

Si te cuesta leer la secuencia, pídela en Solidity, lista para pegar en un test unitario:

```bash
FOUNDRY_INVARIANT_SHOW_SOLIDITY=true forge test --mt invariant_BookedMatchesHolders
```

```text
	[Sequence] (original: 2, shrunk: 2)
		vm.prank(0xA4d4c1f8a763Ef6a0140D04291eCEef913Ffc272);
		Seats(0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f).book(2);
		vm.prank(0xA4d4c1f8a763Ef6a0140D04291eCEef913Ffc272);
		Seats(0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f).transferSeat(2, 0x0000000000000000000000000000000000000000);
```

Cada ejecución usa una semilla aleatoria y la imprime al final (`Fuzz seed: 0x...`). Para
repetir exactamente la misma campaña: `forge test --fuzz-seed 0x...`. Por eso tus números, y a
veces tu secuencia, no serán los de esta página.

## La tabla de llamadas

Con `show_metrics = true` (el valor por defecto), forge imprime cuántas veces llamó a cada
función y cuántas revirtieron. Con los pasos del ejercicio 01 resueltos:

```text
| Contract | Selector     | Calls | Reverts | Discards |
| Seats    | book         | 42552 | 39879   | 0        |
| Seats    | cancel       | 42476 | 40842   | 0        |
| Seats    | transferSeat | 42972 | 42153   | 0        |
```

Más del 95 % de las llamadas revierten. Las tres invariantes pasan, pero sobre muy pocas
llamadas útiles. La teoría 03 baja ese número a cero.

## Configurar la campaña

Las claves de `[invariant]` en `foundry.toml` que vas a tocar, con su valor por defecto en
Foundry v1.9.0 (`forge config` las imprime todas):

| Clave | Por defecto | Qué hace |
| ----- | ----------- | -------- |
| `runs` | `256` | Cuántas secuencias |
| `depth` | `500` | Cuántas llamadas por secuencia |
| `fail_on_revert` | `false` | Si `true`, una llamada que revierte también es un fallo (teoría 03) |
| `shrink_run_limit` | `5000` | Cuántos intentos de encoger una secuencia |
| `failure_persist_dir` | `"cache/invariant"` | Dónde guarda las secuencias que fallan |
| `show_metrics` | `true` | La tabla de llamadas |
| `show_solidity` | `false` | La secuencia en Solidity |

Para una sola función, configuración en línea con un comentario encima:

```solidity
/// forge-config: default.invariant.runs = 10
/// forge-config: default.invariant.depth = 20
function invariant_Cheap() public view { ... }
```

Encima del contrato, vale para todas sus funciones. Y cualquier clave se cambia para una
ejecución con una variable de entorno: `FOUNDRY_INVARIANT_RUNS=1000 forge test`.

Más `runs` y `depth` es más tiempo. Las invariantes de tu protocolo tardan unos 25 segundos con
los valores por defecto. Para una campaña larga antes de una entrega, súbelos en la línea de
comandos, no en `foundry.toml`.

## ⚠️ Riesgos

- **Sin `targetContract`.** El fuzzer llama a tokens de prueba, mocks y a todo lo demás, y una
  invariante correcta falla por un camino que en producción no existe.
- **Ignorar la tabla.** `[PASS]` con un 99 % de reverts casi no ha probado nada.
- **Invariantes que modifican estado.** Una `invariant_` que escribe cambia lo que prueba la
  siguiente. Decláralas `view`.
- **Borrar `cache/` para que pase.** Si una secuencia guardada falla, el fallo sigue ahí: la
  repetición es justo lo que te dice que lo has arreglado.

## 📝 Resumen

- Un test de invariantes es un contrato de test con `targetContract` en `setUp` y funciones
  `invariant_`, comprobadas tras cada llamada de cada secuencia.
- `targetContract`, `targetSelector` y `targetSender` dicen a quién, qué y desde dónde llama el
  fuzzer.
- El fallo trae la secuencia encogida; forge la guarda y la repite en la siguiente ejecución.
- `[invariant]` y la configuración en línea fijan `runs`, `depth` y `fail_on_revert`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — Del fuzz a las invariantes](01-de-fuzz-a-invariantes.md) | **Teoría 02 — Invariantes en Foundry** | [Teoría 03 — Handlers →](03-handlers.md) |
