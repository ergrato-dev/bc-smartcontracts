# Teoría 03 — Pausable y parada de emergencia

## 🎯 Objetivos

- Explicar para qué sirve pausar un contrato y qué no resuelve.
- Usar `Pausable` de OpenZeppelin: `whenNotPaused`, `whenPaused`, `_pause` y `_unpause`.
- Decidir qué funciones se pausan y cuáles nunca, con un ejemplo en anvil.
- Repartir la pausa entre un guardián que para y un administrador que reanuda.

---

## 1. Qué problema resuelve

Un contrato desplegado no se puede parar ni corregir: su código es el que es. Si
alguien encuentra un fallo y empieza a robar, cada bloque que pasa es dinero perdido. Una
**parada de emergencia** (*circuit breaker*) es un interruptor dentro del contrato que
bloquea las funciones peligrosas mientras el equipo decide qué hacer.

Ya hiciste uno: `Openable`, de la semana 08, con `whenOpen` y `setOpen`. `Pausable` de
OpenZeppelin es lo mismo, con dos modificadores, dos eventos y dos errores estándar, y sin
decidir quién lo mueve: eso lo pones tú, con `Ownable` o con roles.

Pausar no arregla el fallo. Da tiempo: para avisar, para mover los fondos que aún no se han
perdido, o para desplegar una versión nueva (semana 15).

## 2. Cómo funciona

| Pieza | Qué hace |
| ----- | -------- |
| `paused()` | `true` si el contrato está en pausa. Empieza en `false` |
| `whenNotPaused` | Revierte con `EnforcedPause()` si está en pausa |
| `whenPaused` | Revierte con `ExpectedPause()` si **no** está en pausa |
| `_pause()` | `internal`, con `whenNotPaused`. Pone la pausa y emite `Paused(account)` |
| `_unpause()` | `internal`, con `whenPaused`. La quita y emite `Unpaused(account)` |

`_pause` y `_unpause` son `internal` a propósito: `Pausable` no sabe quién puede pausar. El
contrato hijo escribe `pause()` y `unpause()` con el control de acceso que quiera. Si no lo
hace, nadie puede pausar.

## 3. Cómo se escribe

En `src/Pool.sol`, una caja donde cada cuenta deposita y retira su ETH. Un guardián pausa;
solo el administrador reanuda:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract Pool is AccessControl, Pausable {
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    mapping(address => uint256) public balanceOf;

    error InsufficientBalance(uint256 balance, uint256 needed);
    error TransferFailed();

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function deposit() external payable whenNotPaused {
        balanceOf[msg.sender] += msg.value;
    }

    // Sin whenNotPaused: salir del contrato no se bloquea nunca.
    function withdraw(uint256 amount) external {
        uint256 balance = balanceOf[msg.sender];
        if (balance < amount) revert InsufficientBalance(balance, amount);
        balanceOf[msg.sender] = balance - amount;
        (bool ok,) = msg.sender.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }

    function pause() external onlyRole(GUARDIAN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
```

`withdraw` sigue el orden de la semana 07: comprueba, apunta y después envía.

### En anvil

**Dónde**: en el contenedor, en la carpeta del proyecto, con `anvil --silent &` recién
arrancado. La cuenta 0 administra, la 1 es la guardiana y la 2 deposita:

```bash
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1); PK2=$(cast wallet private-key "$M" 2)
A1=$(cast wallet address "$PK1"); A2=$(cast wallet address "$PK2")
forge create src/Pool.sol:Pool --private-key "$PK0" --broadcast
P=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast send $P "grantRole(bytes32,address)" $(cast keccak GUARDIAN_ROLE) $A1 --private-key "$PK0" --json | jq -r .status
cast send $P "deposit()" --value 1ether --private-key "$PK2" --json | jq -r .status
cast send $P "pause()" --private-key "$PK1" --json | jq -c '[.status, .logs[0].topics, .logs[0].data]'
cast call $P "paused()(bool)"
```

```
0x1
0x1
["0x1",["0x62e78cea01bee320cd4e420270b5ea74000d11b0c9f74754ebdbfc544b05a258"],"0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8"]
true
```

`Paused` no indexa nada: la cuenta que pausó va en `data`, no en un topic. Con la pausa
puesta, depositar revierte, pero retirar funciona:

```bash
cast send $P "deposit()" --value 1ether --private-key "$PK2"
cast send $P "withdraw(uint256)" 0.4ether --private-key "$PK2" --json | jq -r .status
cast call $P "balanceOf(address)(uint256)" $A2
```

```
Error: ... custom error 0xd93c0665: ...: EnforcedPause
0x1
600000000000000000 [6e17]
```

### Quién reanuda

La guardiana no puede reanudar, y pausar dos veces revierte. La cuenta 0 reanuda, y
reanudar otra vez también revierte:

```bash
cast send $P "unpause()" --private-key "$PK1"
cast send $P "pause()" --private-key "$PK1"
cast send $P "unpause()" --private-key "$PK0" --json | jq -c '[.status, .logs[0].topics[0], .logs[0].data]'
cast send $P "unpause()" --private-key "$PK0"
```

```
Error: ... custom error 0xe2517d3f: ...: AccessControlUnauthorizedAccount(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 0x0000000000000000000000000000000000000000000000000000000000000000)
Error: ... custom error 0xd93c0665: ...: EnforcedPause
["0x1","0x5db9ee0a495bf2e6ff9c91a7834c1ba4fdd244a5e8aa4e537bd38aeae4b073aa","0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266"]
Error: ... custom error 0x8dfc202b: ...: ExpectedPause
```

El reparto es asimétrico a propósito. Pausar tiene que ser rápido: la guardiana puede ser
una cuenta que vigila el contrato a todas horas. Reanudar es decir "el peligro pasó", y esa
decisión la toma el administrador.

## 4. Antipatrones y riesgos

**Pausar las salidas.** Si `withdraw` llevara `whenNotPaused`, la pausa dejaría los fondos de
los usuarios dentro del contrato hasta que el administrador quisiera. Una pausa que bloquea
las salidas convierte al administrador en el dueño del dinero. Pausa las entradas y las
operaciones nuevas, no la salida de lo que ya es de cada uno. Hay excepciones (un fallo en el
propio `withdraw`), y entonces el contrato debe decirlo con claridad.

**Creer que la pausa protege todo.** Solo bloquea las funciones con `whenNotPaused`. Una
función nueva sin el modificador sigue abierta. Revisa la lista cada vez que añades una.

**Un guardián que se vuelve atacante.** Si roban la clave de la guardiana, el atacante no
puede robar fondos, pero puede pausar una y otra vez. Como no puede reanudar, el
administrador reanuda y le quita el rol con `revokeRole`. Un guardián que también reanudara
no tendría ese freno.

**La pausa llega tarde.** La transacción que pausa entra en un bloque como cualquier otra.
Una transacción del atacante que entre antes, en el mismo bloque o en uno anterior, se
ejecuta. La pausa limita el daño, no lo evita.

**Pausa sin final.** Un contrato que puede quedarse en pausa para siempre pide a los
usuarios que se fíen del administrador. Algunos protocolos limitan cuánto puede durar una
pausa, o la quitan sola pasado un plazo.

**Un contrato pausado que hace pausar a otros.** Si tu contrato llama a otro que está en
pausa, tu llamada revierte con `EnforcedPause` del otro (semana 10). Una pausa se propaga a
quien depende del contrato.

## 5. Trucos

- `cast call $P "paused()(bool)"` es la primera comprobación cuando todo revierte de golpe.
- `forge inspect Pool errors` lista los errores del contrato, también los heredados, con su
  selector: `d93c0665` es `EnforcedPause()`.
- En un test, `vm.expectRevert(Pausable.EnforcedPause.selector)` comprueba la pausa sin
  argumentos.
- `cast logs --from-block 0 --address $P "Paused(address)"` lista cuándo y quién pausó.

## ✅ Checklist

- [ ] Explico qué resuelve una parada de emergencia y qué no.
- [ ] Uso `whenNotPaused`, `_pause` y `_unpause`, y escribo `pause()` con control de acceso.
- [ ] Distingo `EnforcedPause` de `ExpectedPause`.
- [ ] Explico por qué las salidas de fondos no se pausan.
- [ ] Reparto la pausa entre un guardián que para y un administrador que reanuda.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — AccessControl y roles](02-accesscontrol-y-roles.md) | **Teoría 03 — Pausable y parada de emergencia** | [Teoría 04 — Timelock y multisig →](04-timelock-y-multisig.md) |
