# Ejercicio 02 — delegatecall y try/catch

> Al terminar tendrás una alarma que avisa a contratos ajenos sin depender de ellos: uno
> roto, uno que pide "ahora no" y uno que gasta todo el gas no detienen a los demás. Y un
> `multicall` con el que el dueño agrupa varias llamadas en una transacción.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teorías 03 y 04](../../1-teoria/03-delegatecall.md) leídas y
[ejercicio 01](../ejercicio-01-abi-y-llamadas/README.md) terminado.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/IListener.sol` | La interfaz de un oyente: `onAlarm(round)` y el error `Snoozed(round)`. Terminada |
| `src/Alarm.sol` | La alarma: `addListener`, `ring`, `isSnoozed`, `multicall` y `_notify`. Aquí trabajas |
| `test/Alarm.t.sol` | Cuatro oyentes de prueba (`GoodListener`, `BrokenListener`, `SnoozingListener`, `GasBurner`) y los tests. No lo modifiques |

`ring()` ya está escrita: sube la ronda y llama a `_notify` con cada oyente. Tu trabajo es
que `_notify` no revierta nunca.

Encima de `ring`, `multicall` y `_notify` verás comentarios
`// forge-lint: disable-next-item(...)`. Silencian avisos del linter de forge sobre riesgos
que esta alarma asume a propósito (llamadas en un bucle, eventos después de una llamada
externa); la teoría 04 explica cómo funcionan. No los borres: con `--deny warnings`, cada
aviso cuenta como un warning.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-10-llamadas_entre_contratos/2-practicas/ejercicio-02-delegatecall-y-try-catch/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5667)`, `(2018)` y un `(5740)` (`Unreachable code`): mientras
`_notify` solo revierte, el resto del bucle de `ring` nunca se ejecuta.

**Verifica**: `2 tests passed, 6 failed, 0 skipped (8 total tests)`. Ya pasan
`test_Step1_AddListener` y `test_Step4_MulticallRejectsEther`: la primera añade un oyente
que sí es un contrato; la segunda envía ETH a `multicall`, que de momento revierte con
cualquier cosa. Volverás a ella en el paso 4.

## Paso 1: Solo contratos

**Por qué**: `try` no atrapa una llamada a una cuenta sin código (teoría 04). Si el dueño
añadiera por error una cuenta así, cada `ring` revertiría y la alarma no avisaría a nadie
nunca más. Se comprueba al añadir, una vez, en vez de en cada aviso.

**Abre** `src/Alarm.sol`, en `addListener`, y descomenta:

```solidity
if (listener.code.length == 0) revert NoCode(listener);
```

**Verifica**: `3 tests passed, 5 failed`. Pasa `test_Step1_RevertWhen_ListenerHasNoCode`.

## Paso 2: Reconocer un error por su selector

**Por qué**: un oyente que revierte con `Snoozed(round)` no está roto, está diciendo "esta
vez no". Ese error llega a `catch (bytes memory reason)` como bytes, y se reconoce por sus 4
primeros bytes.

```solidity
// forge-lint: disable-next-line(unsafe-typecast)
return bytes4(reason) == IListener.Snoozed.selector;
```

**Verifica**: `4 tests passed, 4 failed`. `test_Step2_IsSnoozed` comprueba tres casos:
`Snoozed(7)` es `true`; `Error("roto")`, que es lo que produce `revert("roto")`, es
`false`; y unos bytes vacíos también son `false` (`bytes4("")` es `0x00000000`).

## Paso 3: Avisar sin depender del oyente

**Por qué**: `_notify` es el corazón de la alarma. Llama con `try`, con un tope de gas de
`LISTENER_GAS`, y deja constancia de lo que pasó con un evento. Sin el tope, un oyente con
un bucle infinito se llevaría 63/64 del gas de la transacción.

```solidity
try IListener(listener).onAlarm{gas: LISTENER_GAS}(current) {
    emit Notified(listener, current);
} catch (bytes memory reason) {
    if (isSnoozed(reason)) {
        emit ListenerSnoozed(listener, current);
    } else {
        emit NotifyFailed(listener, current, reason);
    }
}
```

**Verifica**: `6 tests passed, 2 failed`. Mira el oyente que gasta el gas:

```bash
forge test --match-test GasBurnerIsBounded -vvvv
```

```
    ├─ [133651] Alarm::ring()
    │   ├─ [50000] GasBurner::onAlarm(1)
    │   │   └─ ← [OutOfGas] EvmError: OutOfGas
```

Gastó exactamente los 50 000 del tope, sin datos de error (`reason: 0x` en el evento), y
después la alarma avisó a `GoodListener`. En `test_Step3_NotifiesEveryone`, el evento de
`BrokenListener` lleva `0x08c379a0…`: el selector de `Error(string)` seguido del texto
`"roto"` codificado.

## Paso 4: Un `multicall`

**Por qué**: el dueño quiere añadir varios oyentes de una vez. Con `delegatecall` a
`address(this)`, cada llamada se ejecuta como si la hubiera hecho él: `msg.sender` sigue
siendo el dueño y `onlyOwner` lo deja pasar; para cualquier otro, revierte igual que si
llamara directamente.

```solidity
for (uint256 i = 0; i < calls.length; i++) {
    (bool ok, bytes memory reason) = address(this).delegatecall(calls[i]);
    if (!ok) revert CallFailed(i, reason);
}
```

**Verifica**:

```bash
forge test --deny warnings
```

`8 tests passed, 0 failed, 0 skipped (8 total tests)`, sin warnings.
`test_Step4_MulticallKeepsTheSender` espera `CallFailed(0, NotOwner(bob))`: bob no es el
dueño ni dentro de un `multicall`. Y `test_Step4_MulticallRejectsEther` sigue pasando, ahora
por el motivo correcto: `multicall` no es `payable` y rechaza el ETH antes de ejecutar nada.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 8 tests.
- Explicas por qué `addListener` comprueba el código y `_notify` no.
- Explicas qué pasaría sin el tope de gas, con el gas de la traza.
- Explicas por qué `multicall` no puede ser `payable` (teoría 03).

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — ABI y llamadas de bajo nivel](../ejercicio-01-abi-y-llamadas/README.md) | **Ejercicio 02 — delegatecall y try/catch** | [Ejercicio 03 — CREATE y CREATE2 →](../ejercicio-03-create-y-create2/README.md) |
