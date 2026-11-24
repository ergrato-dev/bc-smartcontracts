# Ejercicio 02 — Mensajes entre cadenas

> Al terminar habrás escrito un mensajero entre dos cadenas, como el del OP Stack en pequeño: envía
> mensajes con nonce, los entrega una sola vez con el remitente a la vista, guarda los que fallan
> para reintentarlos, y un contrato de la L2 que solo obedece a una cuenta de L1.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 04 — Mensajes entre cadenas](../../1-teoria/04-mensajes-entre-cadenas.md)
leída.

## Contexto

Proyecto Foundry. Hay un `CrossDomainMessenger` en cada cadena, `l1Messenger` y `l2Messenger`,
los dos en el mismo EVM de pruebas. La cuenta `rollup` hace de sistema del rollup: es el
`relayer` de los dos mensajeros, y el test la usa para llevar cada mensaje de uno a otro. En un
rollup de verdad, en lugar de `relayer` habría una prueba de que el mensaje salió de la otra
cadena (teoría 03).

| Archivo | Qué es |
| ------- | ------ |
| `src/ICrossDomainMessenger.sol` | Las dos funciones que usan los contratos: `sendMessage` y `xDomainMessageSender` |
| `src/CrossDomainMessenger.sol` | El mensajero: pasos 1 a 4 |
| `src/RemoteGreeter.sol` | Un saludo en la L2 que solo cambia `l1Owner` desde L1: paso 5 |
| `test/Messenger.t.sol` | Los tests de cada paso. No lo cambies |

En los tests, `_send(from, target, data)` envía por `l1Messenger` como `from` y lee el evento
`SentMessage` con `vm.recordLogs()`; `_relay(as, m)` llama a `l2Messenger.relayMessage` como `as`.
`Recorder` es un destino que apunta quién lo llamó y qué dijo `xDomainMessageSender()`, y que se
puede "romper" para que revierta.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-33-l2_y_cross_chain/2-practicas/ejercicio-02-mensajes-entre-cadenas/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `2 tests passed, 10 failed`. Casi todos paran al enviar:

```text
[FAIL: TODO: Paso 1] test_Paso1_SendEmitsTheMessage() (gas: 41345)
```

Pasan `test_Paso2_RevertWhen_NothingIsBeingRelayed` (`xDomainMessageSender()` ya revierte fuera
de una entrega) y `test_Paso4_RevertWhen_StrangerForgesTheSender` (hoy solo entrega el `relayer`).

## Paso 1: Enviar

**Por qué**: en el origen, enviar es dejar constancia. El evento `SentMessage` es lo que el
rollup lee para llevar el mensaje al otro lado, y `messageNonce` hace que dos mensajes iguales
sean distintos: sin él, el segundo "aumenta el contador" sería una repetición del primero.

**Abre** `src/CrossDomainMessenger.sol`, borra el `revert` de `sendMessage` y descomenta:

```solidity
emit SentMessage(target, msg.sender, message, messageNonce, minGasLimit);
messageNonce++;
```

`msg.sender` es quien envía en el origen: el dato que el destino necesitará.

**Verifica**: `5 tests passed, 7 failed`. Ahora paran al entregar:

```text
[FAIL: TODO: Paso 2] test_Paso2_DeliversWithTheRemoteSender() (gas: 103979)
```

## Paso 2: Entregar con el remitente a la vista

**Por qué**: para el destino, `msg.sender` siempre es el mensajero. Durante la llamada, el
mensajero guarda el remitente del origen en `xSender` y lo devuelve en `xDomainMessageSender()`;
al acabar, vuelve a `DEFAULT_SENDER`. Y si la llamada falla, el mensajero no revierte: revertir
desharía la entrega entera y el mensaje se perdería. Lo apunta como fallido.

**Borra** el `revert` de `relayMessage` y descomenta las líneas de `// PASO 2`:

```solidity
xSender = sender;
(bool ok,) = target.call{gas: minGasLimit}(message);
xSender = DEFAULT_SENDER;
if (ok) {
    successfulMessages[msgHash] = true;
    emit RelayedMessage(msgHash);
} else {
    failedMessages[msgHash] = true;
    emit FailedRelayedMessage(msgHash);
}
```

**Verifica**: `8 tests passed, 4 failed`. `Recorder` ve al mensajero como `msg.sender` y a
`l1Owner` como remitente. Pero el mismo mensaje se entrega dos veces:

```text
[FAIL: next call did not revert as expected] test_Paso3_RevertWhen_RelayedTwice() (gas: 238586)
```

## Paso 3: Una vez

**Por qué**: el hash del mensaje (nonce, remitente, destino, datos y gas) lo identifica. Si ya se
entregó con éxito, entregarlo otra vez es repetir la acción: otro depósito acuñado, otra
propuesta ejecutada.

**Descomenta** la línea de `// PASO 3`:

```solidity
if (successfulMessages[msgHash]) revert AlreadyRelayed(msgHash);
```

**Verifica**: `9 tests passed, 3 failed`. Un mensaje que falló no se puede reintentar:

```text
[FAIL: NotRelayer()] test_Paso4_AnyoneRetriesAFailedMessage() (gas: 243829)
```

## Paso 4: Reintentar lo que falló

**Por qué**: si el destino falló por algo pasajero (estaba pausado, le faltaba un permiso), el
mensaje tiene que poder entregarse más tarde, aunque el rollup ya no lo vuelva a intentar.
Cualquiera puede reintentar un mensaje **fallido**, con sus mismos datos. Lo que sigue siendo
solo del `relayer` es entregar uno nuevo: si no, cualquiera inventaría mensajes "de `l1Owner`".

**Borra** la línea que acaba en `// <- Paso 4` y descomenta la de `// PASO 4`:

```solidity
if (msg.sender != relayer && !failedMessages[msgHash]) revert NotRelayer();
```

**Verifica**: `10 tests passed, 2 failed`. El reintento lleva el remitente original, y
`test_Paso4_RevertWhen_StrangerForgesTheSender` sigue en verde: un mensaje inventado no está en
`failedMessages`. Quedan los del saludo:

```text
[FAIL: Paso 5: el mensaje de l1Owner cambia el saludo: hola != buenas] test_Paso5_L1OwnerSetsTheGreeting() (gas: 147230)
```

## Paso 5: Las dos comprobaciones del destino

**Por qué**: `RemoteGreeter` tiene que saber que la llamada viene del mensajero (si no, cualquiera
llama a `setGreeting` directamente) y que el mensaje lo envió `l1Owner` (si no, cualquiera envía
un mensaje desde L1 con `sendMessage`, que no pide permiso).

**Abre** `src/RemoteGreeter.sol`, borra el `revert` del modificador y descomenta:

```solidity
if (msg.sender != address(messenger)) revert NotMessenger(msg.sender);
address remoteSender = messenger.xDomainMessageSender();
if (remoteSender != l1Owner) revert NotL1Owner(remoteSender);
```

**Verifica**: `12 tests passed, 0 failed`. Con `forge test --deny warnings`, sin warnings. El
mensaje del atacante desde L1 llega, revierte con `NotL1Owner` y el mensajero lo apunta en
`failedMessages`: `test_Paso5_AnotherL1SenderChangesNothing`.

## Para pensar

- El mensaje del atacante queda en `failedMessages`. ¿Puede alguien reintentarlo con éxito más
  tarde? ¿Qué tendría que cambiar en `RemoteGreeter` para que sí?
- `target.call{gas: minGasLimit}` da como mucho 63/64 del gas que queda. Si el `relayer` envía la
  entrega con poco gas, ¿qué pasa con el mensaje? ¿Qué comprobaría un mensajero de verdad antes de
  llamar?
- Sin la primera línea de `relayMessage` (`ReentrantRelay`), ¿qué podría hacer un destino durante
  su llamada con otro mensaje fallido?
- Si mañana `l1Owner` es un contrato de L1 y alguien despliega otro contrato en la misma
  dirección en la L2, ¿puede cambiar el saludo?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Un contrato en varias cadenas](../ejercicio-01-un-contrato-en-varias-cadenas/README.md) | **Ejercicio 02 — Mensajes entre cadenas** | [Ejercicio 03 — Un puente de tokens →](../ejercicio-03-un-puente-de-tokens/README.md) |
