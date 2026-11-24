# Ejercicio 03 — Un puente de tokens

> Al terminar habrás escrito un puente de bloquear y acuñar sobre el mensajero del ejercicio 02:
> los puntos que alice bloquea en L1 aparecen en la L2, vuelven a L1 al quemarlos, y lo bloqueado
> en L1 respalda siempre, unidad por unidad, lo que circula en la L2.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 03 — Puentes](../../1-teoria/03-puentes.md) leída y el
[ejercicio 02](../ejercicio-02-mensajes-entre-cadenas/README.md) en verde.

## Contexto

Proyecto Foundry, con L1 y L2 en el mismo EVM como en el ejercicio 02. El mensajero viene
resuelto.

| Archivo | Qué es |
| ------- | ------ |
| `src/ICrossDomainMessenger.sol`, `src/CrossDomainMessenger.sol` | El mensajero del ejercicio 02, resuelto |
| `src/BridgedToken.sol` | Los puntos en la L2: paso 1 |
| `src/BridgeBase.sol` | Lo común a las dos mitades: el mensajero, la otra mitad y `onlyOtherBridge` (paso 3) |
| `src/L1Bridge.sol` | La mitad de L1: pasos 2 y 5 |
| `src/L2Bridge.sol` | La mitad de L2: pasos 3 y 4 |
| `test/Bridge.t.sol` | Los tests de cada paso y un fuzz del respaldo. No lo cambies |

Cada mitad necesita la dirección de la otra en su constructor: el `setUp` la calcula con
`vm.computeCreateAddress` antes de desplegar. alice tiene 100 puntos en L1 y ha aprobado al
puente. `_deposit` y `_withdraw` hacen la operación y entregan el mensaje en la otra cadena; las
retiradas, después de `vm.warp` de siete días, como en un rollup optimista.

`L1Bridge` importa `L2Bridge` y `L2Bridge` importa `L1Bridge`: cada uno codifica la llamada a la
otra mitad con `abi.encodeCall`. Solidity acepta importaciones circulares mientras no haya
herencia circular.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-33-l2_y_cross_chain/2-practicas/ejercicio-03-un-puente-de-tokens/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `1 tests passed, 9 failed`. Solo pasa `test_Paso3_AFakeL1BridgeMintsNothing`, y por
la razón equivocada: el destino revierte con `TODO: Paso 3`. Lo primero en rojo es el token:

```text
[FAIL: Error != expected error: TODO: Paso 1 != NotBridge(0x9dF0C6b0066D5317aA5b38B36850548DaCCa6B4e)] test_Paso1_RevertWhen_StrangerMints() (gas: 34729)
```

## Paso 1: Solo el puente acuña y quema

**Por qué**: cada `BridgedToken` en la L2 tiene que tener detrás un punto bloqueado en L1. Si
alguien más que el puente puede acuñar, ese respaldo se rompe; si alguien más puede quemar, le
quita a alice lo suyo.

**Abre** `src/BridgedToken.sol`, borra el `revert` del modificador y descomenta:

```solidity
if (msg.sender != bridge) revert NotBridge(msg.sender);
```

**Verifica**: `3 tests passed, 7 failed`. Ahora para el depósito:

```text
[FAIL: TODO: Paso 2] test_Paso2_DepositLocksAndSends() (gas: 57663)
```

## Paso 2: Depositar en L1

**Por qué**: el mensaje es una promesa a la otra mitad: "estos puntos ya están aquí". Por eso
primero se bloquean y después se envía. `msg.sender` va dentro del mensaje solo como dato (para
el evento de la L2); quien recibe es `to`.

**Abre** `src/L1Bridge.sol`, borra el `revert` de `deposit` y descomenta:

```solidity
token.safeTransferFrom(msg.sender, address(this), amount);
messenger.sendMessage(
    otherBridge, abi.encodeCall(L2Bridge.finalizeDeposit, (msg.sender, to, amount)), FINALIZE_GAS
);
emit DepositInitiated(msg.sender, to, amount);
```

**Verifica**: `4 tests passed, 6 failed`. El mensaje sale y los puntos quedan en el puente. En la
L2 aún no llega nada:

```text
[FAIL: Paso 3: bob recibe en L2 lo que alice bloqueo en L1: 0 != 40] test_Paso3_DepositMintsOnL2() (gas: 199671)
```

## Paso 3: Acuñar en la L2, solo por mensaje del puente de L1

**Por qué**: `finalizeDeposit` acuña: es la función que todo atacante quiere llamar. Las dos
comprobaciones de la teoría 04, una vez, en `BridgeBase`, y las dos mitades las heredan.

**Abre** `src/BridgeBase.sol`, borra el `revert` del modificador y descomenta:

```solidity
if (msg.sender != address(messenger) || messenger.xDomainMessageSender() != otherBridge) {
    revert NotOtherBridge();
}
```

**Abre** `src/L2Bridge.sol`, borra el `revert` de `finalizeDeposit` y descomenta:

```solidity
token.mint(to, amount);
emit DepositFinalized(from, to, amount);
```

**Verifica**: `7 tests passed, 3 failed`. bob tiene 40 en la L2, la llamada directa revierte con
`NotOtherBridge` y el mensaje del atacante desde L1 llega, pero no acuña:
`test_Paso3_AFakeL1BridgeMintsNothing` ya pasa por la razón buena. Falta volver:

```text
[FAIL: TODO: Paso 4] test_Paso4_WithdrawBurnsAndSends() (gas: 281865)
```

## Paso 4: Retirar desde la L2

**Por qué**: el camino inverso. Quemar antes de avisar: lo que sale de la L2 deja de circular en
el mismo momento en que se pide en L1.

**Borra** el `revert` de `withdraw` en `src/L2Bridge.sol` y descomenta:

```solidity
token.burn(msg.sender, amount);
messenger.sendMessage(
    otherBridge, abi.encodeCall(L1Bridge.finalizeWithdrawal, (msg.sender, to, amount)), FINALIZE_GAS
);
emit WithdrawalInitiated(msg.sender, to, amount);
```

**Verifica**: `8 tests passed, 2 failed`. Se quema en la L2, pero en L1 no se libera nada, y el
fuzz encuentra en qué se nota:

```text
[FAIL: Paso 5: bob recibe en L1 lo que quemo en L2: 0 != 15] test_Paso5_WithdrawalReleasesOnL1() (gas: 401126)
```

El mensaje de retirada llega a `L1Bridge.finalizeWithdrawal`, revierte con `TODO: Paso 5` y el
mensajero de L1 lo guarda en `failedMessages`. Cuando lo resuelvas, cualquiera podría
reintentarlo (ejercicio 02, paso 4).

## Paso 5: Liberar en L1

**Por qué**: el último paso de la retirada devuelve lo bloqueado. Con `onlyOtherBridge`, porque
es la función que vacía el bote.

**Borra** el `revert` de `finalizeWithdrawal` en `src/L1Bridge.sol` y descomenta:

```solidity
token.safeTransfer(to, amount);
emit WithdrawalFinalized(from, to, amount);
```

**Verifica**: `10 tests passed, 0 failed`. Con `forge test --deny warnings`, sin warnings.
`testFuzz_Paso5_LockedBacksTheL2Supply` deposita y retira cantidades aleatorias y comprueba el
invariante de la teoría 03: lo bloqueado en `L1Bridge` es el `totalSupply()` de `BridgedToken`.

## Para pensar

- Si los puntos cobraran una comisión en cada transferencia, ¿cuánto quedaría en `L1Bridge` tras
  `deposit(bob, 40)`? ¿Cuánto acuñaría la L2? ¿Qué cambiarías en `deposit`?
- Si `to` en `finalizeWithdrawal` es un contrato que rechaza los puntos, el mensaje queda fallido.
  ¿Dónde están entonces esos puntos? ¿Quién puede sacarlos?
- Un atacante envía desde la L2 un mensaje con `finalizeWithdrawal` al puente de L1. ¿Qué lo
  para? ¿Y si consiguiera desplegar algo en la dirección de `L2Bridge` en L1?
- En un rollup optimista, la retirada tarda siete días. ¿Cómo haría un puente de liquidez para
  pagarte en L1 en minutos, y de quién te fiarías?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Mensajes entre cadenas](../ejercicio-02-mensajes-entre-cadenas/README.md) | **Ejercicio 03 — Un puente de tokens** | [Proyecto — Tu protocolo en una L2 →](../../3-proyecto/README.md) |
