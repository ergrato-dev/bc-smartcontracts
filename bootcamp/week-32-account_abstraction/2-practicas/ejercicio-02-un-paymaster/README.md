# Ejercicio 02 — Un paymaster

> Al terminar habrás escrito un paymaster que paga el gas de una cuenta sin ETH, pero solo para
> llamar a un contrato, con un tope por operación, un presupuesto por cuenta y una fecha de fin.
> Cada regla tiene su test, y cada test rompe solo esa regla.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 03 — Paymasters](../../1-teoria/03-paymasters.md) leída y el
[ejercicio 01](../ejercicio-01-una-cuenta-para-el-entrypoint/README.md) en verde.

## Contexto

Proyecto Foundry. `SponsorPaymaster` hereda de `BasePaymaster` de eth-infinitism, que ya comprueba
que solo llama el EntryPoint y trae `deposit`, `withdrawTo` y `addStake`. Lo que decide a quién
paga es tuyo.

| Archivo | Qué es |
| ------- | ------ |
| `src/SponsorPaymaster.sol` | El paymaster: tu trabajo, pasos 1 a 5 |
| `src/SimpleWallet.sol` | La cuenta del ejercicio 01, resuelta |
| `src/Counter.sol` | El contrato que se patrocina |
| `test/SponsorPaymaster.t.sol` | Los tests de cada paso y uno de comportamiento. No lo cambies |

En el `setUp`, el paymaster tiene 1 ETH de depósito en el EntryPoint, un presupuesto de
0,001 ETH por cuenta y un plazo hasta el instante 2 000 000 000. La cuenta tiene 0 ETH: si el
paymaster no paga, nadie paga. Cada operación lleva
`paymasterAndData = abi.encodePacked(address(paymaster), uint128(100_000), uint128(50_000))`.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-32-account_abstraction/2-practicas/ejercicio-02-un-paymaster/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `1 tests passed, 9 failed`. Solo pasa `test_RevertWhen_StrangerCallsValidate`, que
comprueba `BasePaymaster`. Todo lo demás para en la validación del paymaster:

```text
[FAIL: FailedOpWithRevert(0, "AA33 reverted", 0x08c379a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000c544f444f3a205061736f20310000000000000000000000000000000000000000)] test_Paso1_TheWalletPaysNothing() (gas: 133038)
```

`AA33` es `AA23` para el paymaster: revirtió al validar.

## Paso 1: Qué se patrocina

**Por qué**: el paymaster paga lo que la cuenta llame. Tiene que leer `callData` y aceptar solo
`SimpleWallet.execute(target, 0, ...)`: el selector, el destino y el valor. Con uno solo de los
tres, el atacante encuentra otra forma de gastar el depósito.

**Abre** `src/SponsorPaymaster.sol` y resuelve `_checkCall`:

```solidity
if (callData.length < 4 || bytes4(callData[:4]) != SimpleWallet.execute.selector) revert NotSponsored();
(address to, uint256 value,) = abi.decode(callData[4:], (address, uint256, bytes));
if (to != target || value != 0) revert NotSponsored();
```

**Verifica**: `5 tests passed, 5 failed`. La cuenta sin ETH llama al contador, y lo que bajó el
depósito es lo que cobró el bundler. Pero el paymaster acepta cualquier límite de gas:

```text
[FAIL: next call did not revert as expected] test_Paso2_RevertWhen_GasLimitsAreHuge() (gas: 189496)
```

## Paso 2: El tope por operación

**Por qué**: los límites de gas los elige quien firma la operación. `maxCost` es lo peor que puede
costar: la suma de los cinco límites de gas por `maxFeePerGas`. Con diez millones de gas de
llamada, una operación cuesta lo que cien.

**Descomenta** la línea bajo `// PASO 2`:

```solidity
if (maxCost > MAX_COST) revert TooExpensive(maxCost);
```

**Verifica**: `6 tests passed, 4 failed`.

## Paso 3: Lo que costó

**Por qué**: en la validación solo se sabe lo peor; lo real se sabe después. El EntryPoint llama a
`_postOp` con `actualGasCost` y con el `context` que devolvió la validación: la cuenta.

**Resuelve** `_postOp`: borra la línea marcada con `// <- Paso 3` y descomenta:

```solidity
address account = abi.decode(context, (address));
spentBy[account] += actualGasCost;
```

**Verifica**: `7 tests passed, 3 failed`. `test_Paso3_PostOpRecordsTheRealCost` comprueba que lo
apuntado es mayor que 0 y menor que lo que cobró el bundler: `actualGasCost` no incluye el gas del
propio `postOp` (teoría 03).

## Paso 4: El presupuesto

**Por qué**: apuntar no basta; hay que dejar de pagar. La comprobación va en la validación, y con
`maxCost`: lo gastado más lo que esta operación podría costar.

**Descomenta** las dos líneas bajo `// PASO 4`:

```solidity
uint256 spent = spentBy[userOp.sender];
if (spent + maxCost > budget) revert OverBudget(userOp.sender, spent, maxCost);
```

**Verifica**: `8 tests passed, 2 failed`. El test envía operaciones hasta que la siguiente no cabe
en el presupuesto y espera `OverBudget` con los números exactos.

## Paso 5: La fecha de fin

**Por qué**: el patrocinio acaba el día 2 000 000 000. El paymaster no puede leer
`block.timestamp` en la validación (ERC-7562): devuelve el plazo en `validationData` y lo
comprueba el EntryPoint.

**Resuelve** el final de `_validatePaymasterUserOp`: borra la línea marcada con `// <- Paso 5` y
descomenta:

```solidity
validationData = _packValidationData(false, validUntil, 0);
```

**Verifica**: `10 tests passed, 0 failed`. Con `forge test --deny warnings`, sin warnings. Pasado
el plazo, el EntryPoint responde `AA32 paymaster expired or not due`.

## Para pensar

- La cuenta del atacante no tiene ETH ni puntos. ¿Cuántas cuentas puede crear para vaciar el
  depósito con este paymaster? ¿Qué regla haría falta para que crear cuentas cueste algo?
- Si el presupuesto se comprobara en `_postOp` en lugar de en la validación, ¿qué pasaría con la
  operación que se pasa? ¿Quién pagaría su gas?
- `postOp` apunta menos de lo que se cobra. ¿Cuánto se pasa una cuenta de su presupuesto como
  mucho?
- `spentBy` es storage del paymaster. ¿Qué pedirá un bundler de verdad a este paymaster antes de
  aceptar sus operaciones?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Una cuenta para el EntryPoint](../ejercicio-01-una-cuenta-para-el-entrypoint/README.md) | **Ejercicio 02 — Un paymaster** | [Ejercicio 03 — Una EOA con código →](../ejercicio-03-una-eoa-con-codigo/README.md) |
