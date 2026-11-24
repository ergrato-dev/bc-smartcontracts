# Ejercicio 01 — Una cuenta para el EntryPoint

> Al terminar habrás escrito una cuenta de ERC-4337 que el EntryPoint de mainnet acepta: valida la
> firma de su dueño sin revertir, paga su gas, solo deja validar al EntryPoint y solo deja ejecutar
> al EntryPoint o al dueño. Y una fábrica que la despliega en su primera operación.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 01 — Cuentas y UserOperations](../../1-teoria/01-cuentas-y-user-operations.md)
y [Teoría 02 — Cuentas, fábricas y firmas](../../1-teoria/02-cuentas-fabricas-y-firmas.md) leídas.

## Contexto

Proyecto Foundry. El EntryPoint es el de verdad: `EntryPoint` v0.8.0 de eth-infinitism, que la
imagen trae en `/opt/lib/account-abstraction` desde esta semana. Cada test lo despliega y envía las
operaciones como un bundler: `vm.prank(bundler, bundler)` y `handleOps`.

| Archivo | Qué es |
| ------- | ------ |
| `src/SimpleWallet.sol` | La cuenta: tu trabajo, pasos 1 a 4 |
| `src/WalletFactory.sol` | La fábrica con CREATE2: tu trabajo, paso 5 |
| `test/SimpleWallet.t.sol` | Los tests de cada paso y uno de comportamiento. No lo cambies |
| `foundry.toml` | El remapping `@account-abstraction/contracts/` y los warnings del código de eth-infinitism |

En el `setUp`, `owner` es el dueño de una `SimpleWallet` con 1 ETH, y `Counter` es lo que la
cuenta llama: cada operación hace `execute(counter, 0, increment())`.

## Paso 0: Entrar y ver el rojo

Esta semana la imagen cambia: si no la has reconstruido, hazlo antes (`docker build -t
bc-smartcontracts-dev docker` desde la raíz del repo).

```bash
cd bootcamp/week-32-account_abstraction/2-practicas/ejercicio-01-una-cuenta-para-el-entrypoint/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `1 tests passed, 11 failed`. Solo pasa `test_OwnerExecutesDirectly`. Los que pasan
por el EntryPoint fallan con el `revert("TODO: Paso 1")` envuelto en un error del EntryPoint:

```text
[FAIL: TODO: Paso 1] test_Paso1_OwnerSignatureIsValid() (gas: 91031)
[FAIL: FailedOpWithRevert(0, "AA23 reverted", 0x08c379a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000c544f444f3a205061736f20310000000000000000000000000000000000000000)] test_Paso2_HandleOpsRunsTheCall() (gas: 89590)
```

`AA23 reverted` es "la cuenta revirtió al validar"; los bytes de detrás son tu `Error("TODO: Paso 1")`
en ABI: el selector `0x08c379a0`, la posición, la longitud (`0c`, doce bytes) y el texto
(`544f444f3a205061736f2031`).

## Paso 1: La firma

**Por qué**: el EntryPoint pasa a la cuenta el `userOpHash`, el hash EIP-712 de la operación, y la
firma. La cuenta tiene que devolver `0` si la firmó el dueño y `1` si no, sin revertir: ni con
una firma de otro ni con tres bytes que no son una firma.

**Abre** `src/SimpleWallet.sol` y resuelve `_validateSignature`:

```solidity
(address signer, ECDSA.RecoverError err,) = ECDSA.tryRecover(userOpHash, signature);
if (err != ECDSA.RecoverError.NoError || signer != owner) return SIG_VALIDATION_FAILED;
return SIG_VALIDATION_SUCCESS;
```

**Verifica**: `4 tests passed, 8 failed`. Los tres del paso 1 pasan. Los que envían la operación
fallan ahora un poco más allá:

```text
[FAIL: FailedOp(0, "AA21 didn't pay prefund")] test_Paso2_HandleOpsRunsTheCall() (gas: 93621)
```

La firma vale, pero la cuenta no ha pagado.

## Paso 2: El prefund

**Por qué**: antes de ejecutar, el EntryPoint necesita tener el gas máximo de la operación. Le
dice a la cuenta cuánto le falta (`missingAccountFunds`) y comprueba después que llegó. Lo que
sobre se queda como depósito de la cuenta en el EntryPoint.

**Resuelve** `_payPrefund`: borra la línea marcada con `// <- Paso 2` y descomenta:

```solidity
if (missingAccountFunds > 0) {
    (bool ok,) = payable(msg.sender).call{value: missingAccountFunds}("");
    (ok); // si falla, el EntryPoint lo detecta: el depósito no llega
}
```

**Verifica**: `8 tests passed, 4 failed`. La cuenta ya funciona: el contador sube, el bundler
cobra y la misma operación enviada otra vez da `AA25 invalid account nonce`. Una firma de otro da
`AA24 signature error`. Pero cualquiera puede llamar a `validateUserOp`:

```text
[FAIL: next call did not revert as expected] test_Paso3_RevertWhen_StrangerCallsValidate() (gas: 61956)
```

## Paso 3: Solo el EntryPoint valida

**Por qué**: `validateUserOp` manda ETH a quien la llama. Si cualquiera puede llamarla, el atacante
la llama con `missingAccountFunds` igual al saldo de la cuenta y se lo lleva, sin firma: la firma
mala solo cambia lo que se devuelve, no lo que se paga.

**Descomenta** la primera línea de `validateUserOp`, bajo `// PASO 3`:

```solidity
if (msg.sender != address(entryPoint)) revert NotEntryPoint(msg.sender);
```

**Verifica**: `9 tests passed, 3 failed`.

## Paso 4: Quién ejecuta

**Por qué**: el EntryPoint llama a `execute` solo después de validar la firma. Si `execute` está
abierto, la firma no protege nada: cualquiera llama directamente.

**Descomenta** la línea bajo `// PASO 4` en `execute`:

```solidity
if (msg.sender != address(entryPoint) && msg.sender != owner) revert NotAllowed(msg.sender);
```

**Verifica**: `10 tests passed, 2 failed`. El dueño puede seguir llamando a `execute` desde su
EOA, pagando el gas él: la cuenta no le quita nada.

## Paso 5: La fábrica

**Por qué**: la cuenta tiene que poder recibir ETH antes de existir, y su primera operación la
despliega. La dirección se calcula con CREATE2: fábrica, sal y hash del código de creación con
sus argumentos (teoría 02).

**Abre** `src/WalletFactory.sol` y resuelve `getAddress`:

```solidity
bytes32 initCodeHash =
    keccak256(abi.encodePacked(type(SimpleWallet).creationCode, abi.encode(entryPoint, owner)));
return Create2.computeAddress(bytes32(salt), initCodeHash);
```

`Create2.computeAddress` sin tercer argumento usa `address(this)`, la fábrica.

**Verifica**: `12 tests passed, 0 failed`. Con `forge test --deny warnings`, sin warnings.
`test_Paso5_TheFirstOperationDeploysTheWallet` manda 1 ETH a la dirección prevista y envía una
operación con `initCode`: el EntryPoint llama a la fábrica a través del SenderCreator, comprueba
que la cuenta quedó en `sender` y ejecuta la llamada en la misma operación.

## Para pensar

- En el paso 2, si la cuenta no tuviera ETH, ¿qué error daría el EntryPoint? ¿Quién paga el gas
  de esa transacción fallida?
- El test de la fábrica sube `verificationGasLimit` a 1 000 000. ¿Por qué? ¿Qué error da con
  600 000?
- La cuenta guarda el EntryPoint como `immutable`. ¿Qué tendrías que hacer para pasar a la v0.9?
- Si la fábrica recibiera el dueño en `initialize` y no en el constructor, ¿cómo robarías una
  cuenta que alguien ya ha financiado?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — EIP-7702](../../1-teoria/04-eip-7702.md) | **Ejercicio 01 — Una cuenta para el EntryPoint** | [Ejercicio 02 — Un paymaster →](../ejercicio-02-un-paymaster/README.md) |
