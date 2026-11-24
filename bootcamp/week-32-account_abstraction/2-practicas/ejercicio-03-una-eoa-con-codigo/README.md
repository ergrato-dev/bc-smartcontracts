# Ejercicio 03 — Una EOA con código

> Al terminar, alice, una EOA, habrá delegado con EIP-7702 en un contrato tuyo: hará tres llamadas
> en una transacción, firmará operaciones que envía y paga otro, y guardará su nonce en un slot
> donde no lo pisa lo que dejó una delegación anterior.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 04 — EIP-7702](../../1-teoria/04-eip-7702.md) leída. Sin EntryPoint:
este ejercicio es EIP-7702 solo.

## Contexto

Proyecto Foundry. Los tests delegan a alice con `vm.signAndAttachDelegation(contrato, clave)`:
alice firma la autorización y la siguiente llamada del test la lleva, como haría una transacción
de tipo 4. Desde ese momento, `BatchDelegate(payable(alice))` es alice con el código de
`BatchDelegate`.

| Archivo | Qué es |
| ------- | ------ |
| `src/BatchDelegate.sol` | El código para la EOA: tu trabajo, pasos 1 a 4 |
| `src/OldDelegate.sol` | Otro código en el que alice delegó antes: escribe en el slot 0 |
| `test/BatchDelegate.t.sol` | Los tests de cada paso y dos de la delegación. No lo cambies |

En el `setUp`, alice tiene 10 ETH. El lote de los tests llama dos veces a `Counter.increment` y
manda 1 ETH a bob.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-32-account_abstraction/2-practicas/ejercicio-03-una-eoa-con-codigo/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `2 tests passed, 9 failed`. Pasan los dos de la delegación:
`test_DelegationWritesTheDesignator` (el código de alice es `0xef0100` y la dirección del
contrato) y `test_DelegatingToZeroClearsTheCode`. Delegar no necesita que el contrato funcione:

```text
[FAIL: TODO: Paso 1] test_Paso1_AliceBatchesThreeCalls() (gas: 77495)
[FAIL: assertion failed: 42 != 0] test_Paso4_OldStorageDoesNotBreakTheNonce() (gas: 242222)
```

El segundo ya cuenta la historia del paso 4: la delegación anterior dejó un 42 en el slot 0, y
el starter guarda el nonce ahí.

## Paso 1: Varias llamadas en una

**Por qué**: es lo primero que gana una EOA con código: `approve` y la llamada, o tres pagos, en
una transacción y con una firma. Si una falla, fallan todas, con el error de la que falló.

**Abre** `src/BatchDelegate.sol` y resuelve `_executeBatch`:

```solidity
for (uint256 i; i < calls.length; i++) {
    (bool ok, bytes memory result) = calls[i].target.call{value: calls[i].value}(calls[i].data);
    if (!ok) {
        assembly ("memory-safe") {
            revert(add(result, 0x20), mload(result))
        }
    }
}
```

**Verifica**: `4 tests passed, 7 failed`. Pero bob también puede ejecutar lotes con el ETH de
alice:

```text
[FAIL: next call did not revert as expected] test_Paso2_RevertWhen_StrangerExecutes() (gas: 110700)
```

## Paso 2: Solo la EOA

**Por qué**: el contrato se ejecuta en la dirección de alice, así que alice llamándose a sí misma
es `msg.sender == address(this)`. No hace falta guardar un dueño: el dueño es la clave de alice.

**Descomenta** la línea bajo `// PASO 2` en `execute`:

```solidity
if (msg.sender != address(this)) revert Unauthorized(msg.sender);
```

**Verifica**: `5 tests passed, 6 failed`.

## Paso 3: Firmada por alice, enviada por otro

**Por qué**: si alice no tiene ETH para el gas (o no quiere gastarlo), firma el lote y un relayer
lo envía. La firma tiene que atar el lote a esta red (`block.chainid`), a esta cuenta
(`address(this)`), a un nonce que se gasta y a un plazo: sin cualquiera de los cuatro, la firma se
reutiliza.

**Resuelve** `executeWithSignature`:

```solidity
if (block.timestamp > deadline) revert Expired(deadline);
DelegateStorage storage $ = _storage();
bytes32 digest = MessageHashUtils.toEthSignedMessageHash(
    keccak256(abi.encode(block.chainid, address(this), $.nonce, deadline, calls))
);
(address signer, ECDSA.RecoverError err,) = ECDSA.tryRecover(digest, signature);
if (err != ECDSA.RecoverError.NoError || signer != address(this)) revert BadSignature();
$.nonce++;
_executeBatch(calls);
```

El nonce sube antes de ejecutar: si el lote llamara de vuelta a alice, la misma firma ya no
valdría (checks-effects-interactions, semana 7).

**Verifica**: `9 tests passed, 2 failed`. El relayer envía, alice solo pierde el ETH del lote, y
la misma firma no vale dos veces, ni en otra red, ni pasado el plazo. Quedan los del storage:

```text
[FAIL: assertion failed: 0 != 1] test_Paso4_TheNonceLivesInItsOwnSlot() (gas: 192248)
```

## Paso 4: El storage de la EOA

**Por qué**: el storage es el de alice, compartido con cualquier contrato en el que delegue. Con
`STORAGE_SLOT = 0`, el nonce de `BatchDelegate` es el `savedNumber` de `OldDelegate`. ERC-7201 da
a cada contrato su propio slot, calculado desde un nombre.

**Resuelve** la constante: borra la línea marcada con `// <- Paso 4` y descomenta la de debajo. El
valor sale de la fórmula del comentario; compruébalo en el contenedor:

```bash
h=$(cast keccak "bootcamp.BatchDelegate")
k=$(cast keccak $(cast abi-encode "f(uint256)" $(python3 -c "print($(cast to-dec $h) - 1)")))
python3 -c "print(hex(int('$k', 16) & ~0xff))"
```

```text
0xb65fc48599bdae15717ba796c47e752ea9327f57b6be417b75729fa3a8ce2900
```

**Verifica**: `11 tests passed, 0 failed`. Con `forge test --deny warnings`, sin warnings. El 42
sigue en el slot 0 de alice, y el nonce de `BatchDelegate` empieza en 0 en su slot.

## Para pensar

- Si `executeWithSignature` no metiera `address(this)` en el hash, ¿qué podría hacer bob con una
  firma de alice si bob también delega en `BatchDelegate`?
- alice delegó en `BatchDelegate`. ¿Puede alguien quitarle la delegación sin su clave? ¿Y puede
  alice seguir mandando transacciones normales?
- ¿Qué pasaría con un `initialize(address owner)` público en `BatchDelegate`?
- Un contrato antiguo protege una función con `require(tx.origin == msg.sender)`. ¿Sigue
  sabiendo que quien llama no es un contrato?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Un paymaster](../ejercicio-02-un-paymaster/README.md) | **Ejercicio 03 — Una EOA con código** | [Proyecto — Altas sin ETH →](../../3-proyecto/README.md) |
