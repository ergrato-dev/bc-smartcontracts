# Teoría 04 — Mensajes entre cadenas

## 🎯 Objetivos

- Explicar cómo un contrato de una cadena llama a uno de otra con un mensajero.
- Escribir un mensajero con nonce, protección contra repetición y mensajes fallidos que se
  reintentan.
- Autenticar un mensaje en el destino con dos comprobaciones, y saber qué pasa si falta una.
- Calcular el alias de una dirección de L1 en la L2 y saber cuándo aparece.
- Gobernar desde la DAO de L1 un contrato de la L2.

## Qué problema resuelve

El puente de la teoría 03 es un caso particular: la mitad de L1 le dice a la de L2 "acuña esto".
En general, quieres que un contrato de una cadena haga una llamada en otra: que el timelock de tu
DAO, en L1, pause el registro de la L2 o le cambie la tasa. La llamada no puede ser directa: la L2
no ejecuta transacciones de L1. Lo que sí se puede es dejar en L1 un **mensaje** (una llamada
codificada con su destino) y que el rollup lo entregue en la L2.

## Cómo funciona

![El timelock llama a sendMessage del mensajero de L1, que emite SentMessage; el rollup lo lleva a la L2 y llama a relayMessage del mensajero de L2, que fija xDomainMessageSender al timelock y llama al ejecutor; el ejecutor comprueba que quien llama es el mensajero y que el remitente es el timelock](../0-assets/03-un-mensaje-entre-cadenas.svg)

### El mensajero

Cada cadena tiene un **mensajero** (en el OP Stack, `L1CrossDomainMessenger` en L1 y
`L2CrossDomainMessenger` en `0x4200000000000000000000000000000000000007`). Dos funciones:

- `sendMessage(target, message, minGasLimit)`: en el origen. Guarda quién lo envía (`msg.sender`),
  le da un **nonce** (un número que no se repite) y lo deja en un evento.
- `relayMessage(nonce, sender, target, message, minGasLimit)`: en el destino. Solo la acepta el
  sistema del rollup (o, en L1, una retirada demostrada). Llama a `target` con `message`.

Mientras dura esa llamada, el mensajero del destino responde a `xDomainMessageSender()` con el
`sender` del origen. Fuera de una entrega, revierte. Es la única forma que tiene el destino de
saber quién llamó al otro lado: para él, `msg.sender` siempre es el mensajero.

### Entregar una vez, y reintentar

El mensajero del destino guarda el hash de cada mensaje entregado (`successfulMessages`). Con el
nonce dentro, dos mensajes idénticos tienen hashes distintos, y el mismo mensaje no se entrega
dos veces.

Si la llamada al destino revierte, el mensajero **no revierte**: apunta el hash en
`failedMessages` y sigue. Revertir desharía también la entrega del rollup, y el mensaje se
perdería. Un mensaje fallido lo puede reintentar cualquiera, con los mismos datos, cuando la causa
del fallo desaparezca (por ejemplo, cuando el destino deje de estar pausado). Lo que nadie puede
hacer es entregar un mensaje nuevo: eso sigue siendo cosa del rollup.

### Dos comprobaciones en el destino

Un contrato que acepta mensajes de un remitente de la otra cadena comprueba **las dos** cosas:

1. `msg.sender == messenger`: la llamada viene del mensajero, no de cualquiera.
2. `messenger.xDomainMessageSender() == remitente`: el mensaje lo envió quien debe.

Sin la primera, cualquiera llama directamente. Sin la segunda, cualquiera envía un mensaje desde
la otra cadena con `sendMessage`, que no pide permiso, y el mensajero lo entrega.

### El alias de las direcciones de L1

Hay otra forma de llegar a la L2: un contrato de L1 que llama directamente al `OptimismPortal`
(sin pasar por el mensajero). Su transacción de depósito llega a la L2 con un `msg.sender` que no
es su dirección, sino su **alias**: la dirección más `0x1111000000000000000000000000000000001111`
(módulo 2¹⁶⁰). Así, un contrato de L1 no puede hacerse pasar por el contrato de la L2 que tenga la
misma dirección (teoría 02). El mensajero no tiene ese problema: `xDomainMessageSender()` devuelve
la dirección de L1 tal cual.

### Cuánto tarda cada sentido

| Sentido | En el OP Stack | Por qué |
| ------- | -------------- | ------- |
| L1 → L2 | Minutos | El rollup incluye en la L2 lo que ve en L1 |
| L2 → L1 | 7 días como mínimo | L1 solo se fía de la L2 cuando su raíz de estado ya no se puede disputar |

Otros sistemas tienen otras piezas con la misma idea: en Arbitrum, los mensajes de L1 a la L2 son
*retryable tickets* y los de vuelta pasan por un *outbox*. Y hay protocolos de mensajería entre
cadenas cualesquiera (Chainlink CCIP, LayerZero, Hyperlane, Wormhole), cada uno con su modelo de
confianza: de quién te fías para saber que el mensaje salió de donde dice.

## Cómo se escribe

### El destino

`RemoteGreeter` del ejercicio 02 solo acepta mensajes de `l1Owner`:

```solidity
modifier onlyFromL1Owner() {
    if (msg.sender != address(messenger)) revert NotMessenger(msg.sender);
    address remoteSender = messenger.xDomainMessageSender();
    if (remoteSender != l1Owner) revert NotL1Owner(remoteSender);
    _;
}
```

`l1Owner` es una dirección de L1. En la L2 no tiene código ni hace falta que lo tenga: solo se
compara.

### El mensajero

La entrega, en `CrossDomainMessenger.relayMessage` del ejercicio 02:

```solidity
if (xSender != DEFAULT_SENDER) revert ReentrantRelay();
bytes32 msgHash = hashMessage(nonce, sender, target, message, minGasLimit);
if (msg.sender != relayer && !failedMessages[msgHash]) revert NotRelayer();
if (successfulMessages[msgHash]) revert AlreadyRelayed(msgHash);

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

`DEFAULT_SENDER` (`0x…dEaD`) marca que no se entrega nada; la primera línea impide que el destino,
durante su llamada, entregue otro mensaje fallido en mitad de este.

### Gobernar la L2 desde L1

En el proyecto, el timelock de la DAO de L1 propone una llamada a `sendMessage` del mensajero de
L1 con destino el `L2Executor`, y el ejecutor, que es el administrador del registro de la L2,
ejecuta lo que el mensaje diga si pasa las dos comprobaciones. La votación, la cola y el plazo del
timelock son los de la semana 31: la L2 no tiene Governor propio.

### Calcular un alias

**Dónde**: en el contenedor.

```bash
chisel eval "address(uint160(0x5FbDB2315678afecb367f032d93F642f64180aa3) + uint160(0x1111000000000000000000000000000000001111))"
```

**Salida**:

```text
Type: address
└ Data: 0x70CEB2315678Afecb367F032D93f642f64181bB4
```

`0x5FbD…0aa3` es la dirección del primer contrato que despliega la cuenta 0 de anvil. Si ese
contrato de L1 llama al portal, en la L2 su `msg.sender` es `0x70CE…1bB4`.

## Antipatrones y riesgos

- **Una sola de las dos comprobaciones.** Es el error de Wormhole en la teoría 03: el destino
  acepta algo que no debía. Las dos, siempre, y un test que rompa cada una por separado.
- **Comparar `msg.sender` con la dirección de L1.** En el destino, `msg.sender` es el mensajero, o
  un alias si llegó por el portal. Nunca la dirección de L1.
- **Suponer que los mensajes llegan en orden.** Cada uno se entrega por separado y un fallido se
  reintenta más tarde. Si el mensaje 2 depende del 1, el destino lo tiene que comprobar.
- **Suponer que el mensaje se ejecuta.** Si revierte, queda en `failedMessages` hasta que alguien
  lo reintente, y quizá nunca. Lo que envió fondos con el mensaje queda en el limbo.
- **Un destino que no puede repetirse sin daño.** Un mensaje fallido se reintenta con los mismos
  datos: el destino tiene que dar el mismo resultado si llega tarde.
- **Poco gas en `minGasLimit`.** El destino se ejecuta con ese gas; si no llega, falla y queda
  fallido. Los mensajeros reales además comprueban que quien entrega deje gas de sobra, para que
  nadie haga fallar a propósito un mensaje dándole menos (el del ejercicio 02 no lo hace).
- **Olvidar el plazo de vuelta.** Una DAO de la L2 que gobierna L1 tarda 7 días en cada acción. Una
  de L1 que gobierna la L2 tarda minutos más su timelock: por eso en el proyecto la DAO se queda en
  L1 y el guardián de la L2 conserva la pausa.

## Trucos

- En un test, L1 y L2 caben en un solo EVM: dos mensajeros (o uno que hace de los dos, como
  `MockMessenger` del proyecto) y una cuenta que hace de rollup, leyendo los eventos con
  `vm.recordLogs()` y `vm.getRecordedLogs()`.
- `xDomainMessageSender()` solo tiene sentido durante una entrega. Léelo en la función que el
  mensaje llama, nunca en un constructor ni en una vista.
- Para depurar una entrega, mira el evento: `RelayedMessage` o `FailedRelayedMessage`, con el hash
  que calcula `hashMessage`.

## ✅ Checklist

- [ ] Sé qué hacen `sendMessage`, `relayMessage` y `xDomainMessageSender`.
- [ ] Sé por qué el mensajero no revierte si el destino falla y quién puede reintentar.
- [ ] Sé las dos comprobaciones del destino y qué pasa si falta cada una.
- [ ] Sé qué es el alias de una dirección de L1 y cuándo aparece.
- [ ] Sé cuánto tarda un mensaje en cada sentido y qué implica para una DAO.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Puentes](03-puentes.md) | **Teoría 04 — Mensajes entre cadenas** | [Ejercicio 01 — Un contrato en varias cadenas →](../2-practicas/ejercicio-01-un-contrato-en-varias-cadenas/README.md) |
