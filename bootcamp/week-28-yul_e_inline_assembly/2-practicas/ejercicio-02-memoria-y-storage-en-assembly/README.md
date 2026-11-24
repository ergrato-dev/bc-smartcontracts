# Ejercicio 02 — Memoria y storage en assembly

> Al terminar habrás empaquetado dos valores en una palabra, calculado el slot de un mapping en
> el scratch space, apuntado un `struct` a su espacio de nombres ERC-7201, construido un array en
> memoria sin que Solidity lo pise y escrito un cerrojo contra reentrancy en transient storage.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 02 — Assembly dentro de Solidity](../../1-teoria/02-assembly-dentro-de-solidity.md)
leída y el [ejercicio 01](../ejercicio-01-yul-paso-a-paso/README.md) en verde.

## Contexto

Proyecto Foundry. `Ledger` es un libro de saldos en ETH con una configuración (dueño y tasa) en su
espacio de nombres. Cada pieza en assembly es un paso.

| Archivo | Qué es |
| ------- | ------ |
| `src/Ledger.sol` | El contrato: tu trabajo, pasos 1 a 5 |
| `test/Ledger.t.sol` | Los tests, con dos contratos de ayuda: `Reenterer`, que vuelve a entrar en `withdraw`, y `TwiceWithdrawer`, que retira dos veces en una misma llamada. No lo cambies |

`withdraw` envía el ETH **antes** de poner el saldo a cero, a propósito: es la reentrancy de la
semana 21. Lo único que la para es el cerrojo del paso 5.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-28-yul_e_inline_assembly/2-practicas/ejercicio-02-memoria-y-storage-en-assembly/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 tests passed, 6 failed`, cada uno con su `TODO: Paso N`.

## Paso 1: Empaquetar una palabra

**Por qué**: una dirección son 20 bytes y un `uint96`, 12: caben juntos en una palabra, como en un
slot empaquetado (semana 27). `abi.encodePacked(owner, amount)` pone la dirección primero, en los
bytes altos. Para eso hay que subirla 96 bits (12 bytes) con `shl` y juntarla con el importe con
`or`. Deshacerlo es bajar con `shr` y quedarse con los 12 bytes bajos con una máscara.

**Abre** `src/Ledger.sol` y resuelve `pack` y `unpack`:

```solidity
assembly {
    word := or(shl(96, owner), amount)
}
```

```solidity
assembly {
    owner := shr(96, word)
    amount := and(word, 0xffffffffffffffffffffffff)
}
```

La máscara tiene 24 cifras hexadecimales `f`: 12 bytes a uno. `shr(96, word)` ya deja los 12
bytes altos a cero, así que `owner` sale limpio.

**Verifica**: `1 tests passed, 5 failed`. `testFuzz_Paso1_PackLikeEncodePacked` compara con
`bytes32(abi.encodePacked(owner, amount))` y deshace la palabra.

## Paso 2: El slot de un mapping

**Por qué**: el valor de `balanceOf[account]` vive en `keccak256(abi.encode(account, slot))`
(semana 27). En assembly, esos 64 bytes se escriben en el scratch space (`0x00`-`0x3f`), que está
para esto, y se hashean ahí mismo. `balanceOf.slot` da el slot del mapping sin escribir el número.

**Abre** `src/Ledger.sol` y resuelve `balanceSlot`:

```solidity
assembly ("memory-safe") {
    mstore(0, account)
    mstore(0x20, balanceOf.slot)
    slot := keccak256(0, 0x40)
}
```

`balanceOfAsm`, ya escrita, lee ese slot con `sload`.

**Verifica**: `2 tests passed, 4 failed`. `testFuzz_Paso2_BalanceSlot` calcula el slot en Solidity,
lo lee con `vm.load` y compara con `balanceOf` y con `balanceOfAsm`.

## Paso 3: Un `struct` en su espacio de nombres

**Por qué**: `Config` no vive en los slots 0, 1, 2... sino en `CONFIG_LOCATION`, la raíz de su
espacio de nombres ERC-7201 (semana 15), que salió de:

```bash
cast index-erc7201 bootcamp.ledger.config
```

```text
0xdd5f1edd997c3883620047e02264e62911601722964f04716e490bb06f097900
```

Un puntero `storage` local es un número de slot, y en assembly se puede asignar.

**Abre** `src/Ledger.sol` y resuelve `_config`:

```solidity
assembly {
    $.slot := CONFIG_LOCATION
}
```

`initialize` y `config` ya usan `_config()` como un puntero normal.

**Verifica**: `3 tests passed, 3 failed`. `test_Paso3_ConfigInNamespace` lee el slot raíz con
`vm.load`: `owner` en los 20 bytes bajos y `fee` empaquetado encima, desde el byte 20. Y comprueba
que `initialize` no se puede llamar dos veces.

## Paso 4: Un array en memoria

**Por qué**: `_range(n)` construye en assembly un `uint256[] memory` con `0, 1, ..., n - 1`. En
memoria, un array es su longitud y, detrás, sus elementos, cada uno en una palabra. Se construye
en el puntero de memoria libre (`mload(0x40)`). Como Solidity lo devuelve después, el puntero
tiene que quedar **detrás** del array: si no, la siguiente reserva de Solidity lo pisa.

**Abre** `src/Ledger.sol` y resuelve `_range`:

```solidity
assembly ("memory-safe") {
    arr := mload(0x40)
    mstore(arr, n)
    for { let i := 0 } lt(i, n) { i := add(i, 1) } {
        mstore(add(add(arr, 0x20), shl(5, i)), i)
    }
    mstore(0x40, add(add(arr, 0x20), shl(5, n)))
}
```

El elemento `i` está en `arr + 32 + i * 32`. El array ocupa `32 + 32 * n` bytes: el puntero
nuevo es `arr + 32 + n * 32`.

**Verifica**: `4 tests passed, 2 failed`. `twoArrays` llama a `_range(n)` y, justo después,
reserva con Solidity otro array de `n` sietes. `testFuzz_Paso4_RangeSurvivesNextAllocation`
comprueba que los dos están intactos.

Ahora borra la última línea, `mstore(0x40, ...)`, y vuelve a ejecutar. El test falla con
`assertion failed: 7 != 0`: el array de sietes se escribió encima del tuyo. Es el diagrama de la
teoría 02. Deshaz el cambio.

## Paso 5: Un cerrojo en transient storage

**Por qué**: el cerrojo de reentrancy de la semana 21 guarda un 1 mientras la función se ejecuta
y lo vuelve a poner a 0 al acabar. En storage, eso son dos `SSTORE` por llamada. En transient
storage (`tstore`, `tload`), 100 de gas por acceso, y se borra solo al acabar la transacción.

Al acabar la **transacción**, no la llamada: si no lo quitas tú al final de `withdraw`, una
segunda llamada legítima en la misma transacción se encuentra el cerrojo puesto.

**Abre** `src/Ledger.sol` y resuelve el modificador `nonReentrant`. Tiene dos bloques, uno antes
de `_;` y otro después:

```solidity
assembly ("memory-safe") {
    if tload(LOCK_SLOT) {
        mstore(0, shl(224, 0xab143c06)) // Reentrancy()
        revert(0, 4)
    }
    tstore(LOCK_SLOT, 1)
}
_;
assembly ("memory-safe") {
    tstore(LOCK_SLOT, 0)
}
```

`LOCK_SLOT` es `keccak256("bootcamp.ledger.lock")`: un slot de transient que nadie más usa.
`0xab143c06` es `cast sig "Reentrancy()"`.

**Verifica**: `6 tests passed, 0 failed`.

- `test_Paso5_ReentrancyBlocked`: `Reenterer` deposita 1 ETH, retira y, al recibirlo, vuelve a
  llamar a `withdraw`. La segunda entrada revierte con `Reentrancy()`; el atacante se queda con
  su 1 ETH y los otros 5 siguen en el contrato.
- `test_Paso5_LockReleasedWithinSameTransaction`: `TwiceWithdrawer` deposita y retira dos veces
  en una sola llamada.

Quita `tstore(LOCK_SLOT, 0)` y vuelve a ejecutar: el segundo test falla con `Reentrancy()`. El
primero sigue en verde. Deshaz el cambio.

## Para pensar

- En el paso 1, `unpack` no limpia `owner` con una máscara. ¿Por qué no hace falta aquí y en qué
  caso haría falta?
- En el paso 2, `mstore(0x20, ...)` pisa la segunda palabra del scratch space. ¿Por qué no rompe
  nada? ¿Y si escribieras en `0x40`?
- El cerrojo del paso 5 está en `withdraw`, pero no en `deposit`. ¿Puede el atacante usar `deposit`
  desde su `receive` para algo? ¿Y si `deposit` también llamara a otro contrato?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Yul paso a paso](../ejercicio-01-yul-paso-a-paso/README.md) | **Ejercicio 02 — Memoria y storage en assembly** | [Ejercicio 03 — Llamadas en assembly →](../ejercicio-03-llamadas-en-assembly/README.md) |
