# Teoría 01 — Cheatcodes

## 🎯 Objetivos

- Explicar qué es un cheatcode y por qué un test de Solidity los necesita.
- Saber qué estado tiene cada test y de dónde sale (`setUp`).
- Fijar quién llama (`prank`, `startPrank`, `hoax`), cuánto ETH tiene (`deal`) y qué hora y
  qué bloque son (`warp`, `skip`, `roll`).
- Leer una traza con `-vvvv` y escribir en ella con `console.log`.

---

## 1. Qué problema resuelve

Hasta la semana 08 los tests venían escritos y usaban una "plantilla" mínima: `vm.prank`,
`vm.expectRevert`, `vm.deal` y `vm.expectEmit`. Esta semana los escribes tú, y para eso
necesitas entender qué es ese `vm`.

Un contrato decide según cosas que en una red real no controlas: quién firma la
transacción (`msg.sender`), cuánto ETH envía (`msg.value`), el saldo de cada cuenta y la
hora del bloque (`block.timestamp`). Una regla como "solo una vez al día" no se puede probar
esperando un día. Hace falta un test que **mande** sobre esas cosas.

Un **cheatcode** (*truco*) es una función que no existe en Ethereum: la ofrece la EVM de
forge solo durante los tests. Se llama como a un contrato, en la dirección fija
`0x7109709ECfa91a80626fF3989D68f67F5b1DD12D`, que son los últimos 20 bytes de
`keccak256("hevm cheat code")`:

```bash
cast keccak "hevm cheat code"
```

```
0x885cb69240a935d632d79c317109709ecfa91a80626ff3989d68f67f5b1dd12d
```

`forge-std` envuelve esa dirección en la variable `vm` de tipo `Vm`, que heredas con
`contract MiTest is Test`. Además, `Test` trae ayudantes escritos en Solidity sobre esos
cheatcodes (`hoax`, `skip`, `makeAddr`, `bound`...): se llaman sin `vm.` delante.

## 2. El contrato de los ejemplos

Crea `src/Faucet.sol` en un proyecto Foundry (el de la plantilla del bootcamp te sirve). Un
**grifo** (*faucet*) regala 0,1 ether a quien lo pide, como mucho una vez al día:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Faucet {
    uint256 public constant AMOUNT = 0.1 ether;
    uint256 public constant COOLDOWN = 1 days;

    mapping(address => uint256) public lastDrip;

    event Dripped(address indexed to, uint256 amount);

    error TooSoon(uint256 nextDrip);
    error Empty();

    receive() external payable {}

    function drip() external {
        uint256 next = lastDrip[msg.sender] + COOLDOWN;
        if (lastDrip[msg.sender] != 0 && block.timestamp < next) revert TooSoon(next);
        if (address(this).balance < AMOUNT) revert Empty();
        lastDrip[msg.sender] = block.timestamp;
        emit Dripped(msg.sender, AMOUNT);
        (bool ok,) = msg.sender.call{value: AMOUNT}("");
        require(ok, "transfer failed");
    }
}
```

Las cuatro teorías siguientes lo prueban. Todo lo que sigue va en `test/Faucet.t.sol`.

## 3. Cómo funciona un test

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test, console} from "forge-std/Test.sol";
import {Faucet} from "../src/Faucet.sol";

contract FaucetTest is Test {
    Faucet faucet;
    address alice = makeAddr("alice");

    function setUp() public {
        faucet = new Faucet();
        vm.deal(address(faucet), 1 ether);
    }

    function test_Drip() public {
        vm.prank(alice);
        faucet.drip();
        assertEq(alice.balance, 0.1 ether);
        assertEq(address(faucet).balance, 0.9 ether);
    }

    function test_StateIsFreshInEachTest() public view {
        assertEq(alice.balance, 0);
        assertEq(address(faucet).balance, 1 ether);
    }
}
```

Lo que hace `forge test` con este archivo:

1. Despliega `FaucetTest` en una cadena local en memoria. El contrato de test es un
   contrato más, con su dirección y su storage.
2. Por cada función que empieza por `test`: parte del estado recién desplegado, ejecuta
   `setUp()` y después el test. **Cada test empieza de cero**: lo que hizo `test_Drip` no
   lo ve `test_StateIsFreshInEachTest`, que pasa aunque se ejecute después.
3. Un test falla si revierte (un `assert` que no se cumple también revierte). Si no, pasa.

Por eso el orden de los tests no importa y no hay que "limpiar" al acabar.

`makeAddr("alice")` crea una dirección a partir de un nombre (es el hash de ese nombre) y
la **etiqueta**: en las trazas aparece `alice` en vez de 40 dígitos hexadecimales. Para
etiquetar una dirección que ya tienes, `vm.label(address(faucet), "Faucet")`.

## 4. Quién llama: `prank`, `startPrank` y `hoax`

Dentro de un test, `msg.sender` es el contrato de test. Para que llame otra cuenta:

| Cheatcode | Qué hace |
| --------- | -------- |
| `vm.prank(a)` | La **siguiente** llamada sale de `a` |
| `vm.startPrank(a)` … `vm.stopPrank()` | **Todas** las llamadas entre medias salen de `a` |
| `vm.deal(a, x)` | Fija el saldo de `a` en `x` wei (no lo suma: lo sustituye) |
| `hoax(a, x)` | `deal(a, x)` + `prank(a)` en una línea. Sin `x`, le da 2¹²⁸ wei |

```solidity
function test_RevertWhen_DripTwiceTheSameDay() public {
    vm.startPrank(alice);
    faucet.drip();
    skip(1 days - 1);
    vm.expectRevert(abi.encodeWithSelector(Faucet.TooSoon.selector, 1 + 1 days));
    faucet.drip();
    skip(1);
    faucet.drip();
    vm.stopPrank();
    assertEq(alice.balance, 0.2 ether);
}
```

Los tres `drip` salen de alice. `vm.expectRevert` no cuenta como llamada: no gasta el prank.

## 5. Qué hora es: `warp`, `skip` y `roll`

En el test, `block.timestamp` y `block.number` valen `1` al empezar. Para moverlos:

| Cheatcode | Qué hace |
| --------- | -------- |
| `vm.warp(t)` | `block.timestamp = t` |
| `skip(s)` / `rewind(s)` | Suma o resta `s` segundos a `block.timestamp` |
| `vm.roll(n)` | `block.number = n` |

En el test de la sección 4, el primer `drip` es en el segundo `1`, así que el siguiente se
permite en `1 + 1 days`. Con `skip(1 days - 1)` falta un segundo: revierte con
`TooSoon(86401)`. Con `skip(1)` más, se cumple.

Para ver los valores, `console.log` escribe en la salida del test:

```solidity
function test_Clock() public {
    console.log("timestamp", block.timestamp, "block", block.number);
    vm.warp(1_700_000_000);
    vm.roll(100);
    console.log("timestamp", block.timestamp, "block", block.number);
}
```

```bash
forge test --match-test test_Clock -vv
```

```
Logs:
  timestamp 1 block 1
  timestamp 1700000000 block 100
```

`warp` y `roll` son independientes: mover uno no mueve el otro. En una red real cada bloque
avanza los dos (unos 12 segundos por bloque en Ethereum); si tu contrato usa los dos,
muévelos a la vez.

## 6. Leer una traza

Con `-vv` ves los `console.log`; con `-vvv`, la traza de los tests que fallan; con `-vvvv`,
la de todos. Una **traza** (*trace*) es el árbol de llamadas que hizo el test, con el gas
de cada una entre corchetes:

```bash
forge test --match-test test_Drip -vvvv
```

```
Traces:
  [63627] FaucetTest::test_Drip()
    ├─ [0] VM::prank(alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6])
    │   └─ ← [Return]
    ├─ [52625] Faucet::drip()
    │   ├─ emit Dripped(to: alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], amount: 100000000000000000 [1e17])
    │   ├─ [0] alice::receive{value: 100000000000000000}()
    │   │   └─ ← [Stop]
    │   └─ ← [Stop]
    └─ ← [Stop]
```

Se lee de arriba abajo: el prank, la llamada a `drip`, el evento que emitió y el envío de
ETH a alice. Las etiquetas (`alice`, `Faucet`) vienen de `makeAddr` y del nombre del
contrato. Cuando un test falla y no sabes por qué, la traza es lo primero que miras.

## 7. Antipatrones y riesgos

- **Gastar el prank sin querer.** `vm.prank` vale para la siguiente llamada, sea cual sea,
  también una de solo lectura:

  ```solidity
  // ❌ El prank lo gasta lastDrip; drip lo llama el contrato de test
  function test_PrankIsSpentByTheFirstCall() public {
      vm.prank(alice);
      faucet.lastDrip(alice);
      faucet.drip();
  }
  ```

  ```
  [FAIL: transfer failed] test_PrankIsSpentByTheFirstCall() (gas: 71659)
  ```

  El contrato de test no tiene `receive`, así que rechaza el ETH. El fallo no dice nada del
  prank: lo descubres en la traza. Lee el estado antes del prank, o usa `startPrank`.
- **Olvidar `stopPrank`.** Todo lo que sigue sale de la otra cuenta, también tus
  comprobaciones de "solo el dueño".
- **Confiar en los valores por defecto.** Con `block.timestamp = 1` y saldos a 0, un error
  que solo aparece con fechas reales o cuentas con saldo pasa inadvertido. El proyecto de la
  semana lo demuestra con un fallo que los 44 tests de ejemplo no ven.
- **Creer que en la red funciona igual.** Un cheatcode cambia las reglas en el test; en una
  red real nadie puede hacerse pasar por otra cuenta sin su clave privada. Si tu test solo
  pasa con un `prank` que en la realidad no podría ocurrir, prueba algo imposible.

## 8. Trucos

- `--match-test`, `--match-contract` y `--match-path` filtran qué tests se ejecutan.
- `forge test --rerun` repite solo los que fallaron la última vez.
- Nombra los tests como el bootcamp: `test_Algo`, `test_RevertWhen_Condicion` y, desde la
  teoría 03, `testFuzz_Algo`.
- `vm.deal` sustituye el saldo. Para sumar, `vm.deal(a, a.balance + x)`.

## ✅ Checklist

- [ ] Explico qué es `vm` y por qué en una red real no existe.
- [ ] Sé que cada test parte del estado que deja `setUp`.
- [ ] Uso `prank`, `startPrank`, `hoax`, `deal`, `warp`, `skip` y `roll`.
- [ ] Leo una traza con `-vvvv` y encuentro qué cuenta hizo cada llamada.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 09 — Testing con Foundry](../README.md) | **Teoría 01 — Cheatcodes** | [Teoría 02 — Reverts, eventos y llamadas →](02-reverts-eventos-y-llamadas.md) |
