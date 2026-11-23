# Ejercicio 02 — Fuzz testing

> Al terminar habrás escrito cuatro fuzz tests, habrás visto al fuzzer encontrar un overflow
> que ningún ejemplo a mano buscaba y sabrás decidir qué entradas tienen sentido.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 03](../../1-teoria/03-fuzz-testing.md) leída y
[ejercicio 01](../ejercicio-01-cheatcodes/README.md) terminado.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/FeeSplitter.sol` | Reparte un importe en comisión y resto. La comisión va en **puntos básicos** (*basis points*, bps): 1 bp = 0,01 %, así que 250 bps = 2,5 % y 10 000 bps = 100 %. `pay()` cobra un pago, guarda la comisión para el dueño y devuelve el resto. **Terminado: no lo cambies** |
| `test/FeeSplitter.t.sol` | Cuatro fuzz tests por escribir. Aquí trabajas |

Igual que en el ejercicio 01: borra el `revert("TODO: Paso N");` de cada test y escribe las
líneas marcadas con `//> `.

`split(amount, bps)` calcula `fee = amount * bps / 10_000` y `rest = amount - fee`. La
división entera redondea hacia abajo: con `amount = 1` y `bps = 250`, `fee` es `0`.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-09-testing_con_foundry/2-practicas/ejercicio-02-fuzz/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: cuatro `FAIL` con su `TODO`, y
`0 tests passed, 4 failed, 0 skipped (4 total tests)`. Cada uno trae un `counterexample`
aunque el fallo sea el `TODO`: el fuzzer informa de la primera entrada con la que el test
revirtió, sea por lo que sea.

## Paso 1: Las partes suman el importe

**Por qué**: la primera propiedad de un reparto es que no crea ni pierde dinero:
`fee + rest == amount`, para cualquier importe y cualquier comisión válida. Los bps por
encima de 10 000 no son válidos (los prueba el paso 3), así que se llevan al rango con
`bound`. El importe, de momento, sin acotar.

**Abre** `test/FeeSplitter.t.sol`, en `testFuzz_Step1_PartsAddUp`. Escribe todas las
líneas **menos** la de `amount = bound(...)`, que es del paso 2:

```solidity
bps = bound(bps, 0, MAX_BPS);
(uint256 fee, uint256 rest) = splitter.split(amount, bps);
assertEq(fee + rest, amount);
assertLe(fee, amount);
```

**Verifica**: con una semilla fija, para que veas lo mismo que aquí:

```bash
rm -rf cache/fuzz
forge test --match-test Step1 --fuzz-seed 1
```

El `rm` borra los fallos que forge guardó en el paso 0 (teoría 03). Sin él, forge probaría
primero la entrada con la que falló aquel `TODO`, y verías otro contraejemplo.

```
[FAIL: panic: arithmetic underflow or overflow (0x11); counterexample: calldata=0x20906450fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd000000000000000000018240ac1fe6dc1ef1c2e7cf06d53260ae90c4ee67ada4 args=[115792089237316195423570985008687907853269984665640564039457584007913129639933 [1.157e77], 144514264557126092423991874632701998002677218378493348 [1.445e53]]] testFuzz_Step1_PartsAddUp(uint256,uint256) (runs: 14, μ: 9451, ~: 9801)
```

El contraejemplo es el mismo con la misma semilla; las `runs` y el gas medio pueden variar
un poco entre ejecuciones.

El fallo no es tu test: es el contrato. `amount` es casi el máximo de `uint256` y
`amount * bps` se desborda antes de dividir. Con importes reales nunca pasa (no hay tanto
ETH), pero `split` es `public`: cualquiera puede llamarla con ese número.

Hay dos salidas: cambiar el contrato para que no multiplique antes de dividir, o decidir
que `split` solo se usa con importes que caben en un `uint128` y escribirlo en el test. Aquí
eliges la segunda, porque `pay()` solo la llama con `msg.value`. Esa decisión es un
supuesto del sistema y tiene que quedar escrita.

## Paso 2: Acotar el importe

**Por qué**: con `bound(amount, 0, type(uint128).max)`, `amount * bps` cabe siempre en 256
bits: 2¹²⁸ × 10⁴ está muy lejos de 2²⁵⁶. El test deja de mezclar dos preguntas ("¿reparte
bien?" y "¿qué pasa con números imposibles?").

Escribe ahora la línea que faltaba, debajo del `bound` de `bps`:

```solidity
amount = bound(amount, 0, type(uint128).max);
```

**Verifica**: `forge test --match-test Step1` da
`[PASS] testFuzz_Step1_PartsAddUp(uint256,uint256) (runs: 256, …)`. El fallo del paso 1
quedó guardado en `cache/fuzz/failures/FeeSplitterTest/testFuzz_Step1_PartsAddUp`; forge lo
probó primero y ahora pasa.

## Paso 3: El camino del error

**Por qué**: cada `revert` es una regla. "Más de 10 000 bps revierte con
`InvalidBps(bps)`" vale para cualquier valor de `10 001` al máximo. `bound` lleva la
entrada a ese rango sin descartar ninguna.

```solidity
bps = bound(bps, MAX_BPS + 1, type(uint256).max);
vm.expectRevert(abi.encodeWithSelector(FeeSplitter.InvalidBps.selector, bps));
splitter.split(1 ether, bps);
```

**Verifica**: `[PASS] testFuzz_Step3_RevertWhen_BpsTooHigh(uint256) (runs: 256, …)`.

## Paso 4: Una propiedad del redondeo, con más entradas

**Por qué**: "la comisión redondea hacia abajo" se puede escribir sin repetir la fórmula:
`fee * 10_000` nunca supera el valor exacto `amount * bps`, y se queda a menos de `10_000`
de él (lo que se pierde al redondear es menos de una unidad de `fee`).

Esta vez el tipo de los parámetros hace de límite: `uint128` para el importe y `uint16`
para los bps (de 0 a 65 535). Quedan los bps por encima de 10 000, que se descartan con
`vm.assume`. Se rechaza alrededor del 85 % de las entradas: es mucho, pero cada una es
barata y el fuzzer encuentra de sobra las que valen. Con un `uint256` sería al revés.

El comentario `/// forge-config: default.fuzz.runs = 1000`, que ya está encima del test,
sube las entradas de este test de 256 a 1000.

```solidity
vm.assume(bps <= MAX_BPS);
(uint256 fee,) = splitter.split(amount, bps);
uint256 exact = uint256(amount) * bps;
assertLe(fee * MAX_BPS, exact);
assertLt(exact - fee * MAX_BPS, MAX_BPS);
```

**Verifica**: `[PASS] testFuzz_Step4_FeeRoundsDown(uint128,uint16) (runs: 1000, …)`. Las
`runs: 1000` confirman la configuración.

## Paso 5: Cualquier cuenta puede pagar

**Por qué**: `pay()` envía ETH de vuelta a `msg.sender`. La propiedad: quien paga recupera
el resto y el dueño acumula la comisión, con cualquier cuenta y cualquier importe. Pero no
cualquier dirección es una cuenta que pueda pagar:

- `vm.assume(value > 0)`: un pago de 0 revierte con `ZeroAmount` (otra regla, otro test).
- `assumePayable(payer)`: descarta las direcciones que rechazarían el ETH de vuelta. Si el
  fuzzer eligiera una, fallaría el `require(ok)` y parecería un fallo del contrato cuando es
  del test.
- `assumeNotPrecompile(payer)`: descarta los **precompilados**, direcciones bajas
  (`0x01`, `0x02`…) donde la EVM tiene funciones propias, no cuentas.
- `payer != address(splitter)`: el contrato pagándose a sí mismo no es un caso real.

`uint96` como tipo de `value` limita a unos 79 000 millones de ether: de sobra.

```solidity
vm.assume(value > 0);
assumePayable(payer);
assumeNotPrecompile(payer);
vm.assume(payer != address(splitter));
vm.deal(payer, value);
uint256 before = payer.balance;
vm.prank(payer);
uint256 rest = splitter.pay{value: value}();
assertEq(payer.balance, before - value + rest);
assertEq(splitter.ownerFees() + rest, value);
```

**Verifica**: `forge test` termina con `4 tests passed, 0 failed, 0 skipped (4 total
tests)` y sin warnings.

## ✅ Criterios de éxito

- `forge test` pasa los 4 tests sin warnings.
- Explicas por qué el paso 1 falla y por qué acotar el importe es una decisión sobre el
  sistema, no un parche del test.
- Eliges entre `bound`, `vm.assume` y el tipo del parámetro, y justificas la elección en
  los pasos 2, 3 y 4.
- Explicas qué protege cada `assume` del paso 5.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Cheatcodes](../ejercicio-01-cheatcodes/README.md) | **Ejercicio 02 — Fuzz testing** | [Ejercicio 03 — Forks, gas y cobertura →](../ejercicio-03-forks-gas-y-cobertura/README.md) |
