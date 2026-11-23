# Ejercicio 01 — Proxy a mano

> Al terminar tendrás un proxy escrito por ti: reenvía cada llamada a un contador con
> `delegatecall`, guarda la implementación en el slot de EIP-1967 y cambia de versión sin
> perder la cuenta. Antes verás cómo se rompe un proxy que guarda la implementación en el
> slot 0, y en anvil leerás los slots del proxy con `cast storage`.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 01](../../1-teoria/01-proxies-y-delegatecall.md) y
[Teoría 02](../../1-teoria/02-storage-layout.md) leídas.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Counter.sol` | `CounterV1` (`count`, `increment`, `version`) y `CounterV2`, que añade `decrement`. Ya están completos |
| `src/NaiveProxy.sol` | Un proxy que guarda la implementación en el slot 0. Ya está completo: es el ejemplo de lo que no se hace |
| `src/Proxy.sol` | Tu proxy: slots de EIP-1967, `fallback` y `upgradeTo`. Aquí trabajas |
| `test/Proxy.t.sol` | Los tests de cada paso. No lo modifiques |

Los contadores no tienen constructor ni saben que hay un proxy: son contratos normales. El
test los usa a través del proxy con `CounterV1(address(proxy))`: la dirección del proxy, vista
con la interfaz del contador.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-15-contratos_actualizables/2-practicas/ejercicio-01-proxy-a-mano/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5667)` y `(2018)`.

**Verifica**: `3 tests passed, 9 failed, 0 skipped (12 total tests)`. Pasan los tres
`test_Given_`. Lee el primero, `test_Given_NaiveProxyBreaksOnFirstWrite`: tras un
`increment` a través de `NaiveProxy`, su `implementation` vale la dirección de `CounterV1`
más 1, y la siguiente llamada revierte con `AddressEmptyCode`, porque en esa dirección no hay
código. `count` y `implementation` comparten el slot 0 del proxy (teoría 02).

## Paso 1: Los slots de EIP-1967

**Por qué**: la implementación tiene que vivir en un slot que ninguna implementación use. EIP-1967
fija uno: `keccak256("eip1967.proxy.implementation") - 1`, un número de 256 bits que ningún
compilador asigna a una variable. `StorageSlot` lee y escribe un slot elegido a mano.

**Abre** `src/Proxy.sol`. En `_implementation`, borra el `revert` y descomenta:

```solidity
return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
```

Y en `_setImplementation`, descomenta:

```solidity
StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
```

**Verifica**: `4 tests passed, 8 failed`. `test_Step1_ImplementationInEip1967Slot` lee el
slot con `vm.load` y encuentra `CounterV1`. `test_Given_SlotZeroIsFree` sigue en verde: el
slot 0 queda para la implementación.

## Paso 2: Reenviar con `delegatecall`

**Por qué**: el proxy no tiene `increment` ni `count`. Una llamada a una función que un
contrato no tiene llega a su `fallback`. Ahí el proxy ejecuta el código de la implementación
con `delegatecall`: sobre el storage del proxy, con el `msg.sender` de quien llamó (teoría
01). `Address.functionDelegateCall` devuelve lo que devolvió la implementación o, si revirtió,
revierte con el mismo error.

En el `fallback`, borra el `revert` y descomenta:

```solidity
return Address.functionDelegateCall(_implementation(), msg.data);
```

**Verifica**: `7 tests passed, 5 failed`. Tres de los que pasan:

- `test_Step2_StateLivesInTheProxy`: tras dos `increment`, el slot 0 del proxy vale 2 y el
  `count` de `CounterV1`, llamado directamente, sigue en 0.
- `test_Step2_MsgSenderIsTheCaller`: el evento lleva a `alice`, no al proxy.
- `test_Step2_RevertWhen_FunctionIsNotInImplementation`: `decrement` no existe en V1, y la
  implementación revierte sin datos: `FailedCall`.

## Paso 3: Actualizar

**Por qué**: actualizar es escribir otra dirección en el slot de la implementación. Quien
puede hacerlo controla todo el código que se ejecuta sobre el estado del proxy, así que solo el
administrador (quien desplegó el proxy, guardado en el slot de administrador de EIP-1967).

En `upgradeTo`, borra el `revert` y descomenta:

```solidity
if (msg.sender != StorageSlot.getAddressSlot(ADMIN_SLOT).value) revert NotAdmin(msg.sender);
_setImplementation(newImplementation);
```

**Verifica**:

```bash
forge test --deny warnings
```

`12 tests passed, 0 failed, 0 skipped (12 total tests)`, sin warnings.
`test_Step3_UpgradeKeepsTheState`: tres `increment` en V1, `upgradeTo(v2)`, y el proxy dice
`version() == 2` con `count() == 3`. La misma dirección, el mismo estado y otro código.

`upgradeTo` está en el proxy, no en la implementación. Si un día una implementación tuviera
una función con el mismo selector, nadie podría llamarla: la del proxy gana siempre. Es el
choque de selectores de la teoría 04, que los proxies de OpenZeppelin resuelven de dos maneras.

## Paso 4: En anvil

**Por qué**: ver con `cast` dónde está cada dato: el estado en el proxy, el código en la
implementación.

Este paso no tiene código. La cuenta 0 despliega las dos versiones y el proxy:

```bash
anvil --silent &
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1)
forge create src/Counter.sol:CounterV1 --private-key "$PK0" --broadcast
forge create src/Counter.sol:CounterV2 --private-key "$PK0" --broadcast
forge create src/Proxy.sol:Proxy --private-key "$PK0" --broadcast --constructor-args 0x5FbDB2315678afecb367f032d93F642f64180aa3
P=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

`CounterV1` queda en `0x5FbD…`, `CounterV2` en `0xe7f1…` y el proxy en `0x9fE4…`. La cuenta
1 cuenta dos veces a través del proxy:

```bash
cast send $P "increment()" --private-key "$PK1" --json | jq -c '[.status, .to, (.logs[0].address)]'
cast send $P "increment()" --private-key "$PK1"
cast call $P "count()(uint256)"
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "count()(uint256)"
```

```
["0x1","0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0","0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0"]
2
0
```

La transacción va al proxy y el evento también sale del proxy, aunque el código que lo emitió
es de `CounterV1`. Ahora lee tres slots del proxy: el 0, el de la implementación y el del
administrador.

```bash
cast storage $P 0
cast storage $P 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
cast storage $P 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
```

```
0x0000000000000000000000000000000000000000000000000000000000000002
0x0000000000000000000000005fbdb2315678afecb367f032d93f642f64180aa3
0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266
```

El 2 de `count`, la dirección de `CounterV1` y la cuenta 0. Así encuentra un explorador de
bloques la implementación de cualquier proxy EIP-1967: leyendo ese slot. Prueba `decrement`
en V1, después la actualización desde la cuenta 1 y desde la 0:

```bash
cast call $P "decrement()"
cast send $P "upgradeTo(address)" 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 --private-key "$PK1"
cast send $P "upgradeTo(address)" 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 --private-key "$PK0" --json | jq -c '[.status, (.logs | length)]'
cast call $P "version()(uint256)"
cast call $P "count()(uint256)"
cast send $P "decrement()" --private-key "$PK1"
cast call $P "count()(uint256)"
```

```
Error: execution reverted: FailedCall
Error: ... custom error 0x17a84242: ...: NotAdmin(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
["0x1",1]
2
2
1
```

**Verifica**: tras la actualización, la misma dirección `0x9fE4…` responde `version() = 2`, la
cuenta sigue en 2 y `decrement`, que antes no existía, la baja a 1. El único evento de la
actualización es `Upgraded`.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 12 tests.
- Explicas por qué `NaiveProxy` se rompe en el primer `increment`.
- Explicas dónde está `count` y dónde está el código de `increment`.
- Explicas por qué el evento de `increment` sale de la dirección del proxy.
- Explicas qué podría hacer quien consiguiera llamar a `upgradeTo` sin ser administrador.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — UUPS y transparent](../../1-teoria/04-uups-y-transparent.md) | **Ejercicio 01 — Proxy a mano** | [Ejercicio 02 — Initializers y transparent →](../ejercicio-02-initializers-y-transparent/README.md) |
