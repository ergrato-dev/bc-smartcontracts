# Ejercicio 01 — Cheatcodes

> Al terminar habrás escrito tests que deciden quién llama, cuánto ETH tiene y qué hora es,
> y que exigen un revert, un evento y un envío de ETH concretos.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teorías 01 y 02](../../1-teoria/01-cheatcodes.md) leídas.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/TimeVault.sol` | Una hucha con candado de tiempo: cada cuenta deposita ETH y no puede sacarlo hasta 7 días después de su último depósito. **Terminado: no lo cambies** |
| `test/TimeVault.t.sol` | Cinco tests, uno por paso, con el cuerpo por escribir. Aquí trabajas |

Esta semana el trabajo está en los tests. Cada test lleva un `revert("TODO: Paso N");` y,
debajo, el código comentado con `//> `. En cada paso borras el `revert` y quitas el `//> `
de las líneas del test, como en las semanas anteriores con los contratos. Escríbelas tú
mirando el bloque del README en vez de solo descomentarlas: se aprende más.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-09-testing_con_foundry/2-practicas/ejercicio-01-cheatcodes/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con cinco `Warning (2018): Function state mutability can be restricted to pure`:
un test que solo revierte no lee nada. Desaparecen al escribir los tests.

**Verifica**: cinco `FAIL`, cada uno con el `TODO` de su paso, y
`0 tests passed, 5 failed, 0 skipped (5 total tests)`.

## Paso 1: Depositar desde otra cuenta con `hoax`

**Por qué**: `deposit` guarda el saldo de `msg.sender`. Si llama el contrato de test, pruebas
la cuenta del test; quieres una cuenta de usuario, con ETH para pagar. `hoax(alice, 5 ether)`
le da 5 ether a alice y hace que la siguiente llamada salga de ella.

**Abre** `test/TimeVault.t.sol`, en `test_Step1_Deposit`:

```solidity
hoax(alice, 5 ether);
vault.deposit{value: 1 ether}();
assertEq(vault.balanceOf(alice), 1 ether);
assertEq(alice.balance, 4 ether);
assertEq(vault.unlockAt(alice), block.timestamp + 7 days);
```

**Verifica**: `forge test --match-test test_Step1` da `[PASS] test_Step1_Deposit()`.
`alice.balance` bajó de 5 a 4 ether: el ETH salió de su saldo, no del aire.

## Paso 2: Varias llamadas seguidas con `startPrank`

**Por qué**: `vm.prank` vale para una llamada. Para dos depósitos de bob, o repites el
prank o abres un bloque con `startPrank` y lo cierras con `stopPrank`. La última
comprobación demuestra que nada salió de la cuenta del test.

```solidity
vm.deal(bob, 3 ether);
vm.startPrank(bob);
vault.deposit{value: 1 ether}();
vault.deposit{value: 2 ether}();
vm.stopPrank();
assertEq(vault.balanceOf(bob), 3 ether);
assertEq(vault.balanceOf(address(this)), 0);
```

**Verifica**: `[PASS] test_Step2_SeveralCalls()`. Prueba a quitar `vm.startPrank(bob);`:

```
[FAIL: assertion failed: 0 != 3000000000000000000] test_Step2_SeveralCalls() (gas: 130812)
```

Los depósitos salieron del contrato de test, que forge crea con mucho ETH, así que no
fallaron: los 3 ether quedaron a nombre del test y bob tiene 0. Sin los `assertEq` el test
habría pasado. Vuelve a poner la línea.

## Paso 3: Mover el reloj con `vm.warp`

**Por qué**: la regla "no antes de 7 días" tiene dos lados: un segundo antes revierte con
`StillLocked(unlockAt)`; justo en `unlockAt`, funciona. Un test que solo prueba "mucho
después" no sabe si el límite está en el segundo correcto.

```solidity
hoax(alice, 1 ether);
vault.deposit{value: 1 ether}();
uint256 until = vault.unlockAt(alice);

vm.warp(until - 1);
vm.prank(alice);
vm.expectRevert(abi.encodeWithSelector(TimeVault.StillLocked.selector, until));
vault.withdraw();

vm.warp(until);
vm.prank(alice);
vault.withdraw();
assertEq(alice.balance, 1 ether);
```

**Verifica**: `[PASS] test_Step3_Time()`. Cambia el segundo `vm.warp(until)` por
`vm.warp(until - 1)` y ejecuta `forge test --match-test test_Step3`:

```
[FAIL: StillLocked(604801 [6.048e5])] test_Step3_Time() (gas: 155368)
```

`604801` es `1 + 7 days`: el depósito fue en el segundo 1. Vuelve a `vm.warp(until)`.

## Paso 4: Comprobar eventos

**Por qué**: un evento no deja estado que leer con `assertEq`. `vm.expectEmit` comprueba
uno entero contra un molde. `vm.recordLogs` te deja revisar los campos uno a uno, incluido
el `indexed`, que viaja como topic de 32 bytes. `skip(7 days)` suma 7 días al reloj.

```solidity
vm.deal(alice, 1 ether);
vm.expectEmit(address(vault));
emit TimeVault.Deposited(alice, 1 ether, block.timestamp + 7 days);
vm.prank(alice);
vault.deposit{value: 1 ether}();

skip(7 days);
vm.recordLogs();
vm.prank(alice);
vault.withdraw();
Vm.Log[] memory logs = vm.getRecordedLogs();
assertEq(logs.length, 1);
assertEq(logs[0].emitter, address(vault));
assertEq(logs[0].topics[0], TimeVault.Withdrawn.selector);
assertEq(logs[0].topics[1], bytes32(uint256(uint160(alice))));
assertEq(abi.decode(logs[0].data, (uint256)), 1 ether);
```

`topics[1]` es la dirección de alice convertida a 32 bytes: `uint160` (20 bytes),
`uint256` (rellena con ceros a la izquierda) y `bytes32`. `amount` no es `indexed`, así
que va en `data` y se lee con `abi.decode`.

**Verifica**: `[PASS] test_Step4_Events()`. Cambia `7 days` por `6 days` en el `emit` del
test:

```
[FAIL: Deposited param mismatch at unlockAt: expected=518401 [5.184e5], got=604801 [6.048e5]] test_Step4_Events() (gas: 89075)
```

Forge te dice qué campo no coincide. Vuelve a `7 days`.

## Paso 5: Exigir el envío con `vm.expectCall`

**Por qué**: que el saldo de alice suba no dice cómo. `vm.expectCall(alice, 2 ether, "")`
exige que, durante `withdraw`, la hucha llame a alice con 2 ether y datos vacíos: un envío
de ETH.

```solidity
hoax(alice, 2 ether);
vault.deposit{value: 2 ether}();
skip(7 days);
vm.expectCall(alice, 2 ether, "");
vm.prank(alice);
vault.withdraw();
```

**Verifica**: `forge test` termina con `5 tests passed, 0 failed, 0 skipped (5 total
tests)` y sin warnings. Cambia `2 ether` por `1 ether` en el `expectCall`:

```
[FAIL: expected call to 0x328809Bc894f92807417D2dAD6b7C998c1aFdac6 with data 0x, value 1000000000000000000 to be called 1 time, but was called 0 times] test_Step5_ExpectCall() (gas: 126503)
```

`0x3288…dac6` es alice (`makeAddr("alice")`). Vuelve a `2 ether` y mira la traza:

```bash
forge test --match-test test_Step5 -vvvv
```

Entre las líneas verás `emit Withdrawn(account: alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], amount: 2000000000000000000 [2e18])`
y `alice::receive{value: 2000000000000000000}()`: el evento y el envío que comprobaste.

## ✅ Criterios de éxito

- `forge test` pasa los 5 tests sin warnings.
- Explicas qué diferencia hay entre `prank`, `startPrank` y `hoax`.
- Explicas por qué el paso 3 prueba `until - 1` y `until`, y no "dentro de un mes".
- Sabes cómo viaja un parámetro `indexed` en un log y cómo leerlo con `recordLogs`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 05 — Gas y cobertura](../../1-teoria/05-gas-y-cobertura.md) | **Ejercicio 01 — Cheatcodes** | [Ejercicio 02 — Fuzz testing →](../ejercicio-02-fuzz/README.md) |
