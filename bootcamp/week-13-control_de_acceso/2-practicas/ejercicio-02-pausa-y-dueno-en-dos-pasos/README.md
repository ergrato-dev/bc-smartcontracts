# Ejercicio 02 — Pausa y dueño en dos pasos

> Al terminar tendrás una caja de ETH que su dueño pausa en una emergencia sin atrapar el
> dinero de nadie, que cambia de dueño en dos pasos y que no se puede quedar sin dueño.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 01](../../1-teoria/01-ownable-y-ownable2step.md) y
[teoría 03](../../1-teoria/03-pausable-y-parada-de-emergencia.md) leídas, y
[ejercicio 01](../ejercicio-01-roles-con-accesscontrol/README.md) terminado.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Vault.sol` | La caja: `Ownable2Step` y `Pausable`, con `pause`, `deposit`, `withdraw` y la renuncia desactivada. Aquí trabajas |
| `test/Vault.t.sol` | Los tests de cada paso. No lo modifiques |

`Vault` hereda de `Ownable2Step`, que hereda de `Ownable`: por eso el constructor llama a
`Ownable(msg.sender)`. Las funciones de la propiedad (`transferOwnership`,
`acceptOwnership`, `pendingOwner`) vienen heredadas y ya funcionan.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-13-control_de_acceso/2-practicas/ejercicio-02-pausa-y-dueno-en-dos-pasos/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5667)` y `(2018)`.

**Verifica**: `3 tests passed, 8 failed, 0 skipped (11 total tests)`. Pasan
`test_Step1_RevertWhen_StrangerPauses` (por `onlyOwner`) y los dos `test_Inherited_*` de la
transferencia en dos pasos.

## Paso 1: Pausar y reanudar

**Por qué**: `_pause` y `_unpause` son `internal`: `Pausable` no decide quién pausa
(teoría 03). Aquí lo decide `onlyOwner`. Con una sola cuenta no hay reparto entre guardián y
administrador: el dueño hace las dos cosas.

**Abre** `src/Vault.sol`, en `pause` y en `unpause`, borra el `revert` y descomenta la línea:

```solidity
_pause();
```

```solidity
_unpause();
```

**Verifica**: `5 tests passed, 6 failed`. `test_Step1_RevertWhen_DepositWhilePaused` ya pasa
aunque `deposit` no tenga cuerpo: `whenNotPaused` revierte con `EnforcedPause` antes de
entrar.

## Paso 2: Depositar

**Por qué**: depositar es una entrada de dinero nueva. Es lo que se para en una emergencia:
si la caja tiene un fallo, que no entre más dinero.

```solidity
if (msg.value == 0) revert ZeroAmount();
balanceOf[msg.sender] += msg.value;
emit Deposited(msg.sender, msg.value);
```

**Verifica**: `7 tests passed, 4 failed`.

## Paso 3: Retirar

**Por qué**: `withdraw` no lleva `whenNotPaused`. Si lo llevara, el dueño podría dejar el
dinero de todos dentro mientras quisiera (teoría 03). Se apunta antes de enviar, como en la
semana 07.

```solidity
uint256 balance = balanceOf[msg.sender];
if (balance < amount) revert InsufficientBalance(balance, amount);
balanceOf[msg.sender] = balance - amount;
emit Withdrawn(msg.sender, amount);
(bool ok,) = msg.sender.call{value: amount}("");
if (!ok) revert TransferFailed();
```

**Verifica**: `10 tests passed, 1 failed`. `test_Step3_WithdrawWhilePaused` pausa y retira
todo. Falla `test_Step4_RevertWhen_Renounce`: `next call did not revert as expected`, porque
el dueño todavía puede renunciar.

## Paso 4: Sin renuncia

**Por qué**: si el dueño renunciara con la caja en pausa, nadie podría reanudarla nunca, y
los depósitos quedarían cerrados para siempre (teoría 01). La función heredada se sobrescribe
para que siempre revierta. Puede ser `pure` porque no lee nada: una función que sobrescribe
puede prometer más que la original, no menos.

**Descomenta** las tres líneas del final:

```solidity
function renounceOwnership() public pure override {
    revert RenounceDisabled();
}
```

**Verifica**:

```bash
forge test --deny warnings
```

`11 tests passed, 0 failed, 0 skipped (11 total tests)`, sin warnings.

## Paso 5: En anvil

**Por qué**: ver la propiedad cambiar en dos pasos y una pausa que deja salir.

Este paso no tiene código. Arranca anvil y despliega con la cuenta 0. La cuenta 2 deposita
y la propiedad pasa a la cuenta 1:

```bash
anvil --silent &
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1); PK2=$(cast wallet private-key "$M" 2)
A1=$(cast wallet address "$PK1")
forge create src/Vault.sol:Vault --private-key "$PK0" --broadcast
V=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast send $V "deposit()" --value 1ether --private-key "$PK2" --json | jq -r .status
cast send $V "transferOwnership(address)" $A1 --private-key "$PK0" --json | jq -r .status
cast call $V "owner()(address)"
cast call $V "pendingOwner()(address)"
cast send $V "acceptOwnership()" --private-key "$PK1" --json | jq -r .status
```

```
0x1
0x1
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
0x1
```

Hasta que la cuenta 1 acepta, la dueña sigue siendo la 0. Ahora la antigua dueña intenta
pausar, pausa la nueva, y la cuenta 2 intenta depositar y retira:

```bash
cast send $V "pause()" --private-key "$PK0"
cast send $V "pause()" --private-key "$PK1" --json | jq -r .status
cast send $V "deposit()" --value 1ether --private-key "$PK2"
cast send $V "withdraw(uint256)" 1ether --private-key "$PK2" --json | jq -c '[.status, .logs[0].topics[0], .logs[0].data]'
cast balance $V
```

```
Error: ... custom error 0x118cdaa7: ...: OwnableUnauthorizedAccount(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
0x1
Error: ... custom error 0xd93c0665: ...: EnforcedPause
["0x1","0x7084f5476618d8e60b11ef0d7d3f06914655adb8793e28ff7f018d4c76d505d5","0x0000000000000000000000000000000000000000000000000de0b6b3a7640000"]
0
```

**Verifica**: la nueva dueña no puede renunciar:

```bash
cast send $V "renounceOwnership()" --private-key "$PK1"
cast call $V "owner()(address)"
```

```
Error: ... custom error 0x89051165: ...: RenounceDisabled
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 11 tests.
- Explicas por qué `withdraw` no lleva `whenNotPaused`.
- Explicas qué pasaría si `transferOwnership` fuera la de `Ownable` y la dirección estuviera
  mal escrita.
- Explicas por qué esta caja desactiva `renounceOwnership` y en qué contrato tendría sentido
  dejarla.
- Explicas qué cambiarías para que pausar y reanudar fueran de cuentas distintas.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Roles con AccessControl](../ejercicio-01-roles-con-accesscontrol/README.md) | **Ejercicio 02 — Pausa y dueño en dos pasos** | [Ejercicio 03 — Multisig →](../ejercicio-03-multisig/README.md) |
