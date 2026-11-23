# Ejercicio 01 — Reentrancy

> Al terminar habrás vaciado un banco con dos ataques de reentrancy, el de una función y el
> que salta entre funciones, y lo habrás corregido de dos formas que se suman: ordenar el
> código con checks-effects-interactions y poner un cerrojo `nonReentrant`.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 01 — Reentrancy](../../1-teoria/01-reentrancy.md) leída.

## Contexto

Proyecto Foundry. Hay dos bancos con la misma interfaz: `VulnerableBank`, roto a propósito, y
`Bank`, que corriges tú. En los tests, Alice tiene 10 ETH depositados en cada banco y Mallory,
la atacante, empieza con 1 ETH.

| Archivo | Qué es |
| ------- | ------ |
| `src/VulnerableBank.sol` | El blanco: envía el ETH antes de poner el saldo a cero. **No lo arregles** |
| `src/Attacker.sol` | El atacante de una sola función. Pasos 1 y 2 |
| `src/CrossAttacker.sol` | El atacante entre funciones. Paso 4 |
| `src/Bank.sol` | El banco corregido. Pasos 3 y 5 |
| `test/Reentrancy.t.sol` | Los tests. **No lo modifiques** |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-21-vulnerabilidades_clasicas/2-practicas/ejercicio-01-reentrancy/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 passed; 7 failed`. Casi todos fallan con un `TODO`; el del paso 4 falla con
`assertion failed: 0 != 1000000000000000000`, porque su atacante todavía no hace nada.

## Paso 1: Depositar y retirar

**Por qué**: un ataque empieza como un uso normal. El atacante tiene que tener saldo en el banco
para que `withdraw` le envíe algo; ese envío es la puerta por la que vuelve a entrar.

```solidity
stake = msg.value;
BANK.deposit{value: msg.value}();
BANK.withdraw();
```

**Abre** `src/Attacker.sol`, borra el `revert` de `attack` y descomenta sus líneas. Ejecuta
`forge test`.

**Verifica**: `1 passed; 6 failed`, con `test_Paso1_AttackDepositsAndWithdraws` en verde. El
atacante recupera su 1 ETH y nada más: `receive` solo acepta el ETH.
`test_Paso2_DrainsVulnerableBank` dice ahora `1000000000000000000 != 11000000000000000000`:
Mallory tiene 1 ETH y el test espera 11.

## Paso 2: Volver a entrar

**Por qué**: cuando `withdraw` envía el ETH, la EVM ejecuta el `receive` del atacante **antes**
de volver al banco. En ese momento `balanceOf[attacker]` sigue valiendo 1 ETH, así que otra
llamada a `withdraw` vuelve a pagar. Se repite mientras al banco le quede al menos lo depositado.

```solidity
if (address(BANK).balance >= stake) BANK.withdraw();
```

**Abre** `src/Attacker.sol` y descomenta la línea de `receive`.

**Verifica**: `2 passed; 5 failed`. `test_Paso2_DrainsVulnerableBank` en verde: once llamadas
anidadas a `withdraw`, Mallory se lleva 11 ETH, el banco se queda en 0 y aun así
`balanceOf(alice)` dice 10 ETH. El banco debe un dinero que ya no tiene.

## Paso 3: Checks, effects, interactions

**Por qué**: el fallo es el orden. Si el saldo se pone a 0 **antes** de enviar, la segunda
entrada encuentra 0, revierte con `NothingToWithdraw` y el envío entero falla.

```solidity
uint256 amount = balanceOf[msg.sender];
if (amount == 0) revert NothingToWithdraw();
balanceOf[msg.sender] = 0;
(bool ok,) = msg.sender.call{value: amount}("");
if (!ok) revert TransferFailed();
```

**Abre** `src/Bank.sol`, borra el `revert` de `withdraw` y descomenta sus cinco líneas. Deja
para el paso 5 la línea `//> nonReentrant`.

**Verifica**: `5 passed; 2 failed`. En verde:

- `test_Paso3_Withdraw`: Alice retira sus 10 ETH, y una segunda vez da `NothingToWithdraw`.
- `test_Paso3_RevertWhen_ReentrantWithdraw`: el mismo `Attacker` contra `Bank` revierte con
  `TransferFailed`. La entrada anidada revierte, el `receive` del atacante revierte con ella, el
  `call` devuelve `false` y el banco deshace todo. Los 10 ETH de Alice siguen ahí.
- `test_Paso3_CrossFunctionGetsNothingFromBank`: contra `Bank`, el atacante del paso 4 recupera
  su 1 ETH y nada más. Lo entenderás en el paso 4.

## Paso 4: Reentrancy entre funciones

**Por qué**: `VulnerableBank.transfer` no envía ETH, pero lee el mismo saldo que `withdraw`
todavía no ha puesto a 0. El atacante no necesita volver a entrar en `withdraw`: mientras cobra,
pasa su saldo a un cómplice. Al acabar, `withdraw` lo pone a 0, pero el cómplice ya tiene 1 ETH
apuntado que nadie depositó.

```solidity
uint256 balance = BANK.balanceOf(address(this));
if (balance > 0) BANK.transfer(ACCOMPLICE, balance);
```

**Abre** `src/CrossAttacker.sol` y descomenta las dos líneas de `receive`.

**Verifica**: `6 passed; 1 failed`. `test_Paso4_CrossFunctionDrainsVulnerableBank` en verde: el
cómplice retira 1 ETH, el atacante tenía otro y el banco se queda con 9 de los 10 de Alice.
Contra `Bank` el mismo atacante no saca nada (test del paso 3): cuando recibe, su saldo ya es 0.

## Paso 5: El cerrojo

**Por qué**: checks-effects-interactions basta aquí, pero depende de que **cada** función que
toca saldos esté bien ordenada, hoy y en cada cambio futuro. `nonReentrant` cierra la puerta
aunque alguien se equivoque: mientras una función con el modificador se ejecuta, cualquier otra
con él revierte con `ReentrancyGuardReentrantCall()`.

`Bank` hereda `ReentrancyGuardTransient` de OpenZeppelin, que guarda el cerrojo en transient
storage (teoría 01).

**Abre** `src/Bank.sol` y descomenta las dos líneas `//> nonReentrant`, la de `transfer` y la
de `withdraw`.

**Verifica**: `7 passed; 0 failed`. `test_Paso5_GuardBlocksReentry` usa una sonda que, al cobrar
de `withdraw`, llama a `transfer` y guarda el error. Antes de este paso guardaba
`0xcf479181...01`, que es `InsufficientBalance(0, 1)`: `transfer` entraba y miraba el saldo.
Ahora guarda `0x3ee5aeb5`, `ReentrancyGuardReentrantCall()`: ni siquiera entra.

Comprueba también que no queda ningún warning:

```bash
forge test --deny warnings
```

## Para pensar

- ¿Por qué el paso 3 ya protege contra el ataque del paso 4, si `transfer` no se ha tocado?
- `deposit` no lleva `nonReentrant`. ¿Puede un atacante sacar algo volviendo a entrar en él?
- Si `Bank` guardara un `totalDeposits` y otro contrato lo leyera para dar un precio, ¿qué
  vería ese contrato si lo consulta desde el `receive` del atacante con el banco vulnerable?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Aritmética y `unchecked`](../../1-teoria/04-aritmetica-y-unchecked.md) | **Ejercicio 01 — Reentrancy** | [Ejercicio 02 — Control de acceso y `tx.origin` →](../ejercicio-02-control-de-acceso-y-tx-origin/README.md) |
