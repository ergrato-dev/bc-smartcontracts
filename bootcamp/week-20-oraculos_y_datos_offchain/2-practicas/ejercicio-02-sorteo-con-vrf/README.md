# Ejercicio 02 — Sorteo con VRF

> Al terminar tendrás un sorteo que cobra la entrada, pide un número aleatorio a Chainlink VRF,
> elige al ganador cuando llega la respuesta, le deja retirar el bote y se puede reabrir si VRF
> no responde, sin que una respuesta tardía decida el sorteo nuevo.

**Duración estimada**: 2 h 30 min
**Prerrequisitos**: [Ejercicio 01](../ejercicio-01-precio-con-chainlink/README.md) terminado;
[Teoría 03 — Aleatoriedad con VRF](../../1-teoria/03-aleatoriedad-con-vrf.md) leída.

## Contexto

Proyecto Foundry. `Raffle` hereda de `VRFConsumerBaseV2Plus`, la base de Chainlink: ya trae el
dueño (`onlyOwner`, quien despliega), el coordinador en `s_vrfCoordinator` y
`rawFulfillRandomWords`, que comprueba que responde el coordinador antes de llamar a tu
`fulfillRandomWords`.

Los tests montan `VRFCoordinatorV2_5Mock` con una suscripción con saldo y el sorteo como
consumidor (teoría 03), y responden con `fulfillRandomWordsWithOverride` y el número que eligen.
Su ayuda `fulfill` devuelve el `success` del evento `RandomWordsFulfilled`: si tu callback
revirtió.

| Archivo | Qué es |
| ------- | ------ |
| `src/Raffle.sol` | El sorteo y los cinco pasos. Aquí trabajas |
| `test/Raffle.t.sol` | Los tests y `Rejecter`, un jugador que no acepta ETH. **No lo modifiques** |
| `foundry.toml` | Remapping de Chainlink y `ignored_warnings_from` para su código |

`ignored_warnings_from` hace falta porque la copia de OpenZeppelin 4.7 que traen los contratos de
Chainlink tiene una función llamada `at`, y solc 0.8.38 avisa de que será palabra reservada. Con
`--deny warnings`, ese aviso ajeno pararía la compilación.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-20-oraculos_y_datos_offchain/2-practicas/ejercicio-02-sorteo-con-vrf/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 passed; 7 failed`. Casi todos con `TODO: Paso 1`, porque empiezan entrando en
el sorteo.

## Paso 1: Entrar

**Por qué**: la entrada se cierra mientras se espera el número (teoría 03): quien viera la
respuesta en el mempool podría entrar justo antes con la posición ganadora.

```solidity
if (drawing) revert DrawInProgress();
if (msg.value != ENTRY_FEE) revert WrongFee(msg.value);
if (players.length >= MAX_PLAYERS) revert RaffleFull();
players.push(msg.sender);
emit Entered(msg.sender);
```

`MAX_PLAYERS` limita el gas de la respuesta: el paso 3 borra el array entero, y el coordinador
solo da `CALLBACK_GAS_LIMIT` (200 000). Con 20 jugadores, la respuesta gasta 164 008.

**Abre** `src/Raffle.sol`, resuelve `enter` y ejecuta `forge test`.

**Verifica**: `2 passed; 5 failed`. `test_Paso1_Enter` (con `0.02 ether`, `WrongFee`) y
`test_Paso1_RevertWhen_Full` (el jugador 21, `RaffleFull`).

## Paso 2: Pedir el número

**Por qué**: es la primera de las dos transacciones. Marca el sorteo como en curso y guarda qué
petición espera.

```solidity
if (drawing) revert DrawInProgress();
if (players.length == 0) revert NoPlayers();
drawing = true;
drawRequestedAt = block.timestamp;
requestId = s_vrfCoordinator.requestRandomWords(
    VRFV2PlusClient.RandomWordsRequest({
        keyHash: KEY_HASH,
        subId: SUBSCRIPTION_ID,
        requestConfirmations: REQUEST_CONFIRMATIONS,
        callbackGasLimit: CALLBACK_GAS_LIMIT,
        numWords: 1,
        extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
    })
);
pendingRequestId = requestId;
emit DrawRequested(requestId);
```

El estado cambia **antes** de llamar al coordinador: aunque la llamada devolviera el control, el
sorteo ya está cerrado.

**Verifica**: `3 passed; 4 failed`. `test_Paso2_Draw`: sin jugadores, `NoPlayers`; desde otra
cuenta, `Only callable by owner` (el `revert` con texto de `ConfirmedOwner`, la base de Chainlink);
la primera petición del mock es la `1`, y mientras espera nadie entra.

## Paso 3: Elegir al ganador

**Por qué**: la segunda transacción. Aquí no se envía ETH: si el ganador fuera un contrato que lo
rechaza, el callback revertiría y el coordinador no reintenta. Se le apunta el premio.

```solidity
if (!drawing || requestId != pendingRequestId) revert UnknownRequest(requestId);
address winner = players[randomWords[0] % players.length];
uint256 prize = players.length * ENTRY_FEE;
delete players;
drawing = false;
lastWinner = winner;
prizes[winner] += prize;
emit WinnerPicked(requestId, winner, prize);
```

- `randomWords[0] % players.length` da una posición entre 0 y el número de jugadores menos 1.
- Revertir con un `requestId` que no es el esperado no deja nada a medias: no cambia nada y el
  coordinador lo registra como `success = false`.

**Verifica**: `4 passed; 3 failed`. `test_Paso3_Fulfill` responde con `7`: `7 % 3 = 1`, gana el
segundo jugador (`bob`) con `0.03 ether` apuntados y el sorteo vuelve a abrirse. Al llamar a
`rawFulfillRandomWords` desde otra cuenta, `OnlyCoordinatorCanFulfill(alice, coordinador)`.

## Paso 4: Retirar el premio

**Por qué**: el patrón *pull* de la semana 07: cada ganador retira lo suyo. Si su retirada falla,
solo le afecta a él.

```solidity
uint256 amount = prizes[msg.sender];
if (amount == 0) revert NothingToWithdraw();
prizes[msg.sender] = 0;
(bool ok,) = msg.sender.call{value: amount}("");
if (!ok) revert TransferFailed();
```

El saldo se pone a 0 **antes** de enviar: una reentrada encontraría 0.

**Verifica**: `6 passed; 1 failed`. `test_Paso4_Withdraw`: `carol` gana con `2` y cobra
`0.02 ether` más; una segunda retirada da `NothingToWithdraw`. `test_Paso4_WinnerThatRejectsEth`:
gana `Rejecter`, un contrato sin `receive`; la respuesta termina con `success = true` y solo su
retirada falla, con `TransferFailed`.

## Paso 5: Reabrir si VRF no responde

**Por qué**: una suscripción sin saldo o un carril de gas desbordado dejan la petición sin
respuesta, y el sorteo cerrado para siempre con el ETH dentro. Tras un plazo largo, el dueño
puede reabrir. Largo a propósito: si pudiera cancelar enseguida, vería la respuesta en el mempool
y cancelaría hasta que ganase quien él quiere.

```solidity
if (!drawing) revert NoDrawPending();
uint256 availableAt = drawRequestedAt + DRAW_TIMEOUT;
if (block.timestamp < availableAt) revert TooEarly(availableAt);
drawing = false;
emit DrawCancelled(pendingRequestId);
pendingRequestId = 0;
```

**Verifica**: `7 passed; 0 failed`. `test_Paso5_CancelDraw`: antes de 1 hora, `TooEarly`; después,
el sorteo se reabre con los 3 jugadores dentro y se pide otra vez. La respuesta tardía de la
petición vieja llega con `success = false` (el `UnknownRequest` del paso 3) y no elige a nadie; la
nueva elige a `bob`.

## Qué aprendiste

- Un consumidor de VRF pide en una transacción y recibe en otra, y cierra lo que pueda cambiar el
  resultado mientras espera.
- `fulfillRandomWords` no envía ETH ni hace nada que pueda fallar por otros: apunta y el ganador
  retira.
- Cada respuesta se compara con la petición pendiente; una cancelada no decide nada.
- `VRFCoordinatorV2_5Mock` permite probar todo sin red, eligiendo el número en cada test.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Precio con Chainlink](../ejercicio-01-precio-con-chainlink/README.md) | **Ejercicio 02 — Sorteo con VRF** | [Ejercicio 03 — Metadatos en IPFS →](../ejercicio-03-metadatos-en-ipfs/README.md) |
