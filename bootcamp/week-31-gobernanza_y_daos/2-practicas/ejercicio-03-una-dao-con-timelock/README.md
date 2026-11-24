# Ejercicio 03 — Una DAO con timelock

> Al terminar habrás montado una DAO completa en un solo constructor: un timelock que espera dos
> días, un Governor que es el único que le propone, un guardián que puede cancelar, una tesorería
> que solo mueve el timelock y ninguna cuenta con poder de administrador. Y habrás visto que un
> millón de votos prestados no cuentan.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 03 — El timelock de la DAO](../../1-teoria/03-el-timelock-de-la-dao.md)
y [Teoría 04 — Ataques a la gobernanza](../../1-teoria/04-ataques-a-la-gobernanza.md) leídas, y el
[ejercicio 02](../ejercicio-02-un-governor/README.md) en verde.

## Contexto

Proyecto Foundry. El Governor ya está escrito: es el del ejercicio 02 con el recuento de
OpenZeppelin y `GovernorTimelockControl`. Tu trabajo es el constructor de `DaoDeployer`, que
despliega el timelock, el Governor y la tesorería y reparte los roles.

| Archivo | Qué es |
| ------- | ------ |
| `src/DaoDeployer.sol` | El montaje de la DAO: tu trabajo, pasos 1 a 5 |
| `src/DaoGovernor.sol` | El Governor con timelock (teoría 02) |
| `src/GovToken.sol` | El token del ejercicio 02 con flash loans de ERC-3156 (`ERC20FlashMint`) |
| `src/Treasury.sol` | La tesorería del ejercicio 02 |
| `test/Dao.t.sol` | Los tests y `FlashVoter`, que vota con un millón de tokens prestados. No lo cambies |

En el `setUp`, el test despliega el token y `new DaoDeployer(token, guardian)`. `alice` tiene
400 000 tokens y `bob` 300 000, delegados, y la tesorería tiene 10 ETH. La propuesta de los tests
paga 1 ETH a `dave`.

Los pasos 2 a 5 añaden líneas a un constructor: no llevan `revert`, porque el `setUp` no podría
desplegar. Resolver es descomentar.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-31-gobernanza_y_daos/2-practicas/ejercicio-03-una-dao-con-timelock/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `2 tests passed, 6 failed`. Pasan dos tests de comportamiento:

- `test_FlashLoanVotesCountZero`: `FlashVoter` pide prestado un millón de tokens, delega en sí
  mismo y vota en la misma transacción. Tiene un millón de votos durante el préstamo, y cuentan 0:
  el Governor lee la foto (teoría 04).
- `test_RevertWhen_SchedulingWithoutTheGovernor`: `alice` no puede programar nada en el timelock
  directamente.

El resto falla. Poner en cola, porque el Governor no tiene ningún rol en el timelock:

```text
[FAIL: assertion failed: 0 != 172800] test_Paso1_TimelockWaitsTwoDays() (gas: 10999)
[FAIL: AccessControlUnauthorizedAccount(0x8d2C17FAd02B7bb64139109c6533b7C2b9CADb81, 0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1)] test_Paso2_ApprovedProposalsGoToTheQueue() (gas: 364641)
```

`0x8d2C...` es el Governor y `0xb09a...`, `keccak256("PROPOSER_ROLE")`.

## Paso 1: El timelock

**Por qué**: el starter crea un timelock con plazo 0 y sin ejecutores: lo aprobado pasaría al
instante, y nadie lo podría ejecutar. El plazo son dos días (`MIN_DELAY`), y el ejecutor es
`address(0)`: cualquiera ejecuta lo que ya esperó. `DaoDeployer` es el administrador mientras
dura el constructor, para repartir los roles.

**Abre** `src/DaoDeployer.sol`, borra la línea que acaba en `// <- Paso 1` y descomenta las de
debajo:

```solidity
address[] memory anyone = new address[](1);
timelock = new TimelockController(MIN_DELAY, none, anyone, address(this));
```

Un `address[]` de longitud 1 recién creado tiene `address(0)` dentro.

**Verifica**: `3 tests passed, 5 failed`. `getMinDelay` es 172 800 segundos, y `address(0)` tiene
`EXECUTOR_ROLE`.

## Paso 2: El Governor propone

**Por qué**: `queue` del Governor llama a `timelock.scheduleBatch`, que exige `PROPOSER_ROLE`. Es
el error del paso 0. El Governor también necesita `CANCELLER_ROLE`: `GovernorTimelockControl`
cancela en el timelock cuando se cancela una propuesta en cola.

**Abre** `src/DaoDeployer.sol` y descomenta las líneas del paso 2:

```solidity
timelock.grantRole(timelock.PROPOSER_ROLE(), address(governor));
timelock.grantRole(timelock.CANCELLER_ROLE(), address(governor));
```

**Verifica**: `4 tests passed, 4 failed`. La propuesta aprobada queda `Queued`, la operación está
pendiente en el timelock y la `eta` es la hora de la cola más dos días.

## Paso 3: El guardián

**Por qué**: durante los dos días, alguien tiene que poder parar una propuesta que sea un ataque
(teoría 04). El guardián cancela la operación en el timelock, sin votar, y el Governor lo ve: la
propuesta pasa a `Canceled`.

**Abre** `src/DaoDeployer.sol` y descomenta la línea del paso 3:

```solidity
timelock.grantRole(timelock.CANCELLER_ROLE(), guardian);
```

**Verifica**: `5 tests passed, 3 failed`. Ahora falla la ejecución:

```text
[FAIL: OwnableUnauthorizedAccount(0xffD4505B3452Dc22f8473616d50503bA9E1710Ac)] test_Paso4_ExecutionPaysAfterTheDelay() (gas: 596173)
```

## Paso 4: La tesorería es del timelock

**Por qué**: quien llama a `pay` al ejecutar es el timelock (`0xffD4...`), y la tesorería sigue
siendo de `DaoDeployer`. Lo que gobierna la DAO tiene que ser del timelock (teoría 03).

**Abre** `src/DaoDeployer.sol` y descomenta la línea del paso 4:

```solidity
treasury.transferOwnership(address(timelock));
```

**Verifica**: `6 tests passed, 2 failed`. Un segundo antes de la `eta`, ejecutar revierte con
`TimelockUnexpectedOperationState`; en la `eta`, `dave` (que no tiene votos) ejecuta y cobra.

## Paso 5: Nadie administra el timelock

**Por qué**: `DaoDeployer` sigue con `DEFAULT_ADMIN_ROLE` en el timelock. No tiene funciones para
usarlo, pero un contrato de despliegue que sí las tuviera (o una cuenta) podría darse
`PROPOSER_ROLE` y programar sin votar. Al renunciar, solo el timelock se administra a sí mismo:
los roles los cambia una propuesta.

**Abre** `src/DaoDeployer.sol` y descomenta la línea del paso 5:

```solidity
timelock.renounceRole(timelock.DEFAULT_ADMIN_ROLE(), address(this));
```

**Verifica**: `8 tests passed, 0 failed`. `DaoDeployer` ya no puede dar roles
(`AccessControlUnauthorizedAccount`), y en `test_Paso5_RolesOnlyChangeByProposal` la DAO le quita
el rol al guardián con una propuesta al propio timelock: propuesta, votos, cola, dos días y
ejecución.

## Para pensar

- El guardián puede cancelar cualquier operación. ¿Qué pasa si cancela todas? ¿Cómo se lo quita la
  DAO, si la propuesta que lo quita también pasa por la cola que él puede cancelar?
- `FlashVoter` no pudo votar con votos prestados en un instante. ¿Qué tendría que hacer para que sus
  votos contaran en la foto, y cuánto le costaría con un mercado de préstamos?
- `DaoDeployer` hace todo en una transacción. Si lo hicieras con cinco transacciones desde una
  cuenta, ¿qué podría pasar entre la primera y la última? ¿Qué test lo detectaría?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Un Governor](../ejercicio-02-un-governor/README.md) | **Ejercicio 03 — Una DAO con timelock** | [Proyecto — La DAO del protocolo →](../../3-proyecto/README.md) |
