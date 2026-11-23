# Ejercicio 03 — Multisig

> Al terminar tendrás una cuenta compartida "2 de 3": uno de sus dueños propone una llamada,
> los dueños la confirman uno a uno, y cuando hay dos confirmaciones se ejecuta. En los tests
> es la dueña de otro contrato; en anvil, envía ETH.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 04](../../1-teoria/04-timelock-y-multisig.md) leída y
[ejercicio 02](../ejercicio-02-pausa-y-dueno-en-dos-pasos/README.md) terminado.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/MultiSig.sol` | El multisig: dueños, umbral, `submit`, `confirm` y `execute`. Aquí trabajas |
| `test/Config.sol` | Un contrato `Ownable` con una tasa. En los tests, su dueño es el multisig. No lo modifiques |
| `test/MultiSig.t.sol` | Los tests de cada paso. No lo modifiques |

Cada propuesta es una llamada: `target`, `value` (ETH) y `data` (selector y argumentos,
semana 10). Su id es su posición en el array `proposals`. `confirmed[id][dueño]` apunta quién
confirmó cada una. `_proposal(id)` ya está escrita: devuelve la propuesta como `storage`, o
revierte con `ProposalNotFound`.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-13-control_de_acceso/2-practicas/ejercicio-03-multisig/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5667)` y `(2018)`.

**Verifica**: `1 tests passed, 13 failed, 0 skipped (14 total tests)`. Solo pasa
`test_Step2_RevertWhen_StrangerSubmits`, por `onlyOwner`. Sin el paso 1 nadie es dueño: hasta
Ana recibe `NotOwner`.

## Paso 1: Dueños y umbral

**Por qué**: el multisig no se puede reconfigurar después de desplegar, así que el
constructor es la única oportunidad de rechazar una configuración rota. Un umbral de 0
dejaría ejecutar sin confirmaciones; uno mayor que el número de dueños, nunca. Un dueño
repetido contaría dos veces en la lista, aunque solo pueda confirmar una vez: un "2 de 2" con
Ana repetida sería un "1 de 1".

**Abre** `src/MultiSig.sol` y, en el constructor, descomenta:

```solidity
if (threshold == 0 || threshold > initialOwners.length) {
    revert InvalidThreshold(threshold, initialOwners.length);
}
for (uint256 i = 0; i < initialOwners.length; i++) {
    address owner = initialOwners[i];
    // Un dueño inválido invalida el despliegue entero, a propósito.
    // forge-lint: disable-next-line(require-revert-in-loop)
    if (owner == address(0) || isOwner[owner]) revert InvalidOwner(owner);
    isOwner[owner] = true;
}
```

El linter de forge avisa de un `revert` dentro de un bucle: en una función que procesa una
lista suele ser mejor saltarse el elemento malo. Aquí no, y el comentario lo dice.

**Verifica**: `5 tests passed, 9 failed`.

## Paso 2: Proponer

**Por qué**: proponer no ejecuta nada, solo guarda la llamada y la publica en un evento, para
que los demás dueños la lean antes de confirmar.

```solidity
id = proposals.length;
proposals.push(Proposal({target: target, value: value, data: data, confirmations: 0, executed: false}));
emit Submitted(id, msg.sender, target, value, data);
```

**Verifica**: `6 tests passed, 8 failed`.

## Paso 3: Confirmar

**Por qué**: cada dueño cuenta una vez. Sin `confirmed[id][msg.sender]`, un solo dueño
podría confirmar dos veces y alcanzar el umbral solo. `proposal` es una referencia
`storage` (semana 06): `confirmations++` cambia la propuesta guardada, no una copia.

```solidity
Proposal storage proposal = _proposal(id);
if (proposal.executed) revert AlreadyExecuted(id);
if (confirmed[id][msg.sender]) revert AlreadyConfirmed(id, msg.sender);
confirmed[id][msg.sender] = true;
proposal.confirmations++;
emit Confirmed(id, msg.sender);
```

**Verifica**: `9 tests passed, 5 failed`.

## Paso 4: Ejecutar

**Por qué**: `executed = true` va **antes** de la llamada. Si el destino llamara de vuelta a
`execute` con el mismo id, ya constaría como ejecutada (semana 07). Si la llamada falla, todo
revierte, también la marca, y el motivo sube dentro de `CallFailed` (semana 10).

```solidity
Proposal storage proposal = _proposal(id);
if (proposal.executed) revert AlreadyExecuted(id);
if (proposal.confirmations < THRESHOLD) {
    revert NotEnoughConfirmations(id, proposal.confirmations, THRESHOLD);
}
proposal.executed = true;
emit Executed(id);
// El destino lo eligió un dueño y lo confirmaron THRESHOLD: no es de cualquiera.
// forge-lint: disable-next-line(arbitrary-send-eth)
(bool ok, bytes memory reason) = proposal.target.call{value: proposal.value}(proposal.data);
if (!ok) revert CallFailed(id, reason);
```

Las dos líneas de comentario ya están en el starter: el linter avisa de que se envía ETH a un
destino que elige quien llama, y aquí ese destino lo aprobaron dos dueños.

**Verifica**:

```bash
forge test --deny warnings
```

`14 tests passed, 0 failed, 0 skipped (14 total tests)`, sin warnings.
`test_Step4_ExecuteChangesConfig` cambia la tasa de `Config`, cuyo dueño es el multisig, y
`test_Step4_RevertWhen_CallFails` intenta cambiar la de otro `Config` y recibe
`CallFailed(0, OwnableUnauthorizedAccount(multisig))`.

## Paso 5: En anvil

**Por qué**: ver una propuesta pasar por todos sus estados con tres cuentas reales.

Este paso no tiene código. Arranca anvil y despliega un "2 de 3" con las cuentas 0, 1 y 2.
La cuenta 0 le envía 1 ETH (el `receive` lo acepta):

```bash
anvil --silent &
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1); PK2=$(cast wallet private-key "$M" 2); PK3=$(cast wallet private-key "$M" 3)
A0=$(cast wallet address "$PK0"); A1=$(cast wallet address "$PK1"); A2=$(cast wallet address "$PK2"); A3=$(cast wallet address "$PK3")
forge create src/MultiSig.sol:MultiSig --private-key "$PK0" --broadcast --constructor-args "[$A0,$A1,$A2]" 2
W=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast send $W --value 1ether --private-key "$PK0" --json | jq -r .status
```

La cuenta 3 no es dueña. La 0 propone enviarle 0,5 ETH (sin `data`: es un envío) y confirma:

```bash
cast send $W "submit(address,uint256,bytes)" $A3 0.5ether 0x --private-key "$PK3"
cast send $W "submit(address,uint256,bytes)" $A3 0.5ether 0x --private-key "$PK0" --json | jq -r .status
cast call $W "proposals(uint256)(address,uint256,bytes,uint256,bool)" 0
cast send $W "confirm(uint256)" 0 --private-key "$PK0" --json | jq -r .status
cast send $W "execute(uint256)" 0 --private-key "$PK0"
cast send $W "confirm(uint256)" 0 --private-key "$PK0"
```

```
Error: ... custom error 0x245aecd3: ...: NotOwner(0x90F79bf6EB2c4f870365E785982E1f101E93b906)
0x1
0x90F79bf6EB2c4f870365E785982E1f101E93b906
500000000000000000 [5e17]
0x
0
false
0x1
Error: ... custom error 0xb8aef845: ...: NotEnoughConfirmations(0, 1, 2)
Error: ... custom error 0x8f68cf72: ...: AlreadyConfirmed(0, 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
```

Con una confirmación no basta, y la misma cuenta no puede confirmar dos veces. Confirma la
cuenta 1 y ejecuta la 2:

```bash
cast send $W "confirm(uint256)" 0 --private-key "$PK1" --json | jq -r .status
cast send $W "execute(uint256)" 0 --private-key "$PK2" --json | jq -c '[.status, [.logs[].topics[0]]]'
cast balance $A3 --ether
cast balance $W --ether
```

```
0x1
["0x1",["0xbcf6a68a2f901be4a23a41b53acd7697893a7e34def4e28acba584da75283b67"]]
10000.500000000000000000
0.500000000000000000
```

**Verifica**: `cast call $W "proposals(uint256)(address,uint256,bytes,uint256,bool)" 0`
termina en `2` y `true`: dos confirmaciones y ejecutada. Volver a ejecutarla revierte con
`AlreadyExecuted(0)`.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 14 tests.
- Explicas qué pasaría con un dueño repetido y con un umbral de 0.
- Explicas por qué `executed = true` va antes de la llamada.
- Explicas qué umbral elegirías para tres dueños y por qué no "1 de 3" ni "3 de 3".
- Explicas qué no puede hacer este multisig: cambiar sus dueños, quitar una confirmación.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Pausa y dueño en dos pasos](../ejercicio-02-pausa-y-dueno-en-dos-pasos/README.md) | **Ejercicio 03 — Multisig** | [Proyecto — Roles del protocolo →](../../3-proyecto/README.md) |
