# Ejercicio 03 — Enviar ETH

> Al terminar habrás recibido depósitos, devuelto ETH con `call` comprobando que llegó,
> resistido un ataque de reentrada con checks-effects-interactions y comprobado la
> solvencia sin fiarte del saldo.

**Duración estimada**: 2 h 30 min
**Prerrequisitos**: [Ejercicio 02](../ejercicio-02-recibir-ether/README.md) terminado;
[Teorías 04 y 05](../../1-teoria/04-enviar-ether.md) leídas.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Vault.sol` | Una caja de ahorro: el mapping `balanceOf`, el total `totalDeposits`, dos eventos y cuatro errores. Aquí trabajas |
| `test/Vault.t.sol` | Cuatro tests, uno por paso, y dos contratos de ayuda. **No lo modifiques** |

Los dos contratos de ayuda del test:

- `Rejector`: no tiene `receive` ni `fallback`, así que rechaza todo ETH. Deposita y luego
  intenta retirar.
- `Reentrant`: un atacante. Deposita 1 ETH y llama a `withdrawAll`; cuando recibe el ETH,
  su `receive` vuelve a llamar a `withdrawAll` mientras a la caja le quede al menos 1 ETH.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-07-eventos_y_ether/2-practicas/ejercicio-03-enviar-ether/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con `Warning (2018)` y `Warning (5667)`.

**Verifica**: cuatro `FAIL`, todos con `TODO: Paso 1`: todos los tests depositan primero.

## Paso 1: Depósito

**Por qué**: la caja apunta cuánto es de cada cuenta. Esa contabilidad, y no el saldo del
contrato, dice a quién se le debe qué (teoría 05).

**Abre** `src/Vault.sol`:

```solidity
function deposit() external payable {
    if (msg.value == 0) revert ZeroAmount();
    balanceOf[msg.sender] += msg.value;
    totalDeposits += msg.value;
    emit Deposited(msg.sender, msg.value);
}
```

**Verifica**: `[PASS] test_Step1_Deposit()`.

## Paso 2: Retiro con `call`

**Por qué**: `call` funciona con cualquier destino, pero no revierte si falla. Las
comprobaciones van primero, después el saldo y el evento (effects) y el envío al final
(interactions).

```solidity
function withdraw(uint256 amount) external {
    uint256 available = balanceOf[msg.sender];
    if (amount > available) revert InsufficientBalance(available, amount);
    balanceOf[msg.sender] = available - amount;
    totalDeposits -= amount;
    emit Withdrawn(msg.sender, amount);
    (bool ok,) = payable(msg.sender).call{value: amount}("");
    if (!ok) revert TransferFailed(msg.sender, amount);
}
```

**Verifica**: `[PASS] test_Step2_Withdraw()`. El `Rejector` intenta retirar, el envío
falla, la función revierte con `TransferFailed` y su saldo en la caja sigue en 1 ETH: no
pierde nada.

Rompe a propósito: cambia las dos últimas líneas por solo
`payable(msg.sender).call{value: amount}("");` y ejecuta `forge test --match-test test_Step2`:

```
Warning (9302): Return value of low-level calls not used.
  --> src/Vault.sol:38:9:
```

```
[FAIL: next call did not revert as expected] test_Step2_Withdraw() (gas: 519159)
```

El retiro del `Rejector` ya no revierte: la caja le descuenta 1 ETH que nunca le llegó.
Ese ETH se queda en el contrato sin que nadie lo tenga apuntado. Vuelve a comprobar `ok`.

## Paso 3: Retirar todo, a prueba de reentrada

**Por qué**: el envío le pasa el control al destino. Si el saldo sigue intacto mientras
envías, el destino puede volver a entrar y cobrar otra vez (teoría 04).

```solidity
function withdrawAll() external {
    uint256 amount = balanceOf[msg.sender];
    if (amount == 0) revert NothingToWithdraw();
    balanceOf[msg.sender] = 0;
    totalDeposits -= amount;
    emit Withdrawn(msg.sender, amount);
    (bool ok,) = payable(msg.sender).call{value: amount}("");
    if (!ok) revert TransferFailed(msg.sender, amount);
}
```

**Verifica**: `[PASS] test_Step3_WithdrawAllResistsReentrancy()`. Bob tiene 5 ETH en la
caja. El atacante deposita 1 y retira; al volver a entrar, su saldo ya es 0, la segunda
llamada revierte con `NothingToWithdraw`, su `receive` falla y todo el ataque revierte con
`TransferFailed`. La caja sigue con los 5 ETH de Bob.

Rompe a propósito: mueve las dos líneas de effects (`balanceOf[...] = 0` y
`totalDeposits -= amount`) al final, después del `if (!ok)`. Ejecuta
`forge test --match-test test_Step3`:

```
[FAIL: next call did not revert as expected] test_Step3_WithdrawAllResistsReentrancy() (gas: 453444)
```

El ataque salió bien. Midiendo el saldo del atacante después, tiene
`6000000000000000000` wei: su ETH y los 5 de Bob. Nada revierte por el camino: `= 0` se
puede repetir sin error. Vuelve al orden CEI.

## Paso 4: Solvencia

**Por qué**: a un contrato le puede llegar ETH sin pasar por `deposit` (teoría 05). La
comprobación correcta es "tengo al menos lo que debo", no "tengo exactamente lo que debo".

```solidity
function isSolvent() external view returns (bool) {
    return address(this).balance >= totalDeposits;
}
```

**Verifica**: `forge test` termina con
`4 tests passed, 0 failed, 0 skipped (4 total tests)` y sin warnings. El test fuerza el
saldo de la caja a 3 ETH con `vm.deal` (sin llamar a ninguna función) y la caja sigue
siendo solvente, con `totalDeposits` en 1 ETH.

## ✅ Criterios de éxito

- `forge test` pasa los 4 tests sin warnings.
- Explicas qué pasa con el ETH del `Rejector` si no compruebas `ok`.
- Explicas paso a paso cómo el atacante se lleva 6 ETH con el orden equivocado y por qué
  con CEI no puede.
- Explicas por qué `isSolvent` usa `>=` y no `==`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Recibir ETH](../ejercicio-02-recibir-ether/README.md) | **Ejercicio 03 — Enviar ETH** | [Proyecto — Registro con tasas y eventos →](../../3-proyecto/README.md) |
