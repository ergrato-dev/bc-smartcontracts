# Ejercicio 03 — Llamadas en assembly

> Al terminar habrás revertido con un custom error codificado a mano, leído un saldo con
> `staticcall` rechazando lo que no es un token, reenviado una llamada con su error tal cual,
> llamado copiando solo unos bytes de la returndata y desplegado con `create2` detectando cuándo
> falla.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 03 — Llamadas, errores y despliegues](../../1-teoria/03-llamadas-errores-y-despliegues.md)
leída y el [ejercicio 02](../ejercicio-02-memoria-y-storage-en-assembly/README.md) en verde.

## Contexto

Proyecto Foundry. `AsmCaller` habla con otros contratos desde assembly, y cada forma es un paso.

| Archivo | Qué es |
| ------- | ------ |
| `src/AsmCaller.sol` | El contrato: tu trabajo, pasos 1 a 5 |
| `test/Targets.sol` | Los contratos a los que llama: un token mínimo, uno que no devuelve nada, uno que revierte, un destino (`Target`) y un constructor que falla. No lo cambies |
| `test/AsmCaller.t.sol` | Los tests. No lo cambies |

Los selectores de los errores ya están en el código, como números. Los sacas tú con `cast sig`
si quieres comprobarlos:

| Error o función | `cast sig` |
| --------------- | ---------- |
| `NotOwner(address)` | `0x245aecd3` |
| `BadToken(address)` | `0x732d20af` |
| `DeployFailed()` | `0xb4f54111` |
| `balanceOf(address)` | `0x70a08231` |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-28-yul_e_inline_assembly/2-practicas/ejercicio-03-llamadas-en-assembly/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 tests passed, 11 failed`, cada uno con su `TODO: Paso N`.

## Paso 1: Un custom error a mano

**Por qué**: `revert NotOwner(msg.sender)` de Solidity devuelve 36 bytes: el selector y la
dirección codificada en una palabra. En assembly los escribes en el scratch space y revierte con
`revert(0, 0x24)`. `OWNER` es `immutable`: el bloque no ve variables de estado por nombre, así que
`checkOwner` la copia antes a la variable local `owner`.

**Abre** `src/AsmCaller.sol` y resuelve `checkOwner`:

```solidity
assembly ("memory-safe") {
    if iszero(eq(caller(), owner)) {
        mstore(0, shl(224, 0x245aecd3)) // NotOwner(address)
        mstore(4, caller())
        revert(0, 0x24)
    }
}
```

`caller()` es `msg.sender`.

**Verifica**: `3 tests passed, 8 failed`. Los dos del paso 1 y `test_Paso3_OnlyOwnerForwards`:
`forward` llama a `checkOwner` antes de su `TODO`, así que un extraño ya recibe `NotOwner`.

## Paso 2: Leer un saldo con `staticcall`

**Por qué**: la calldata de `balanceOf(account)` son 36 bytes, y caben en el scratch space.
`staticcall` copia como mucho 32 bytes de respuesta a `0x00`. Pero `ok == 1` no basta: una cuenta
sin código y un contrato que acaba sin devolver nada también dan `ok == 1`, con `returndatasize()`
a 0. Solo es un saldo si llegaron 32 bytes o más.

**Abre** `src/AsmCaller.sol` y resuelve `balanceOf`:

```solidity
assembly ("memory-safe") {
    mstore(0, shl(224, 0x70a08231)) // balanceOf(address)
    mstore(4, account)
    let ok := staticcall(gas(), token, 0, 0x24, 0, 0x20)
    if iszero(and(ok, gt(returndatasize(), 0x1f))) {
        mstore(0, shl(224, 0x732d20af)) // BadToken(address)
        mstore(4, token)
        revert(0, 0x24)
    }
    amount := mload(0)
}
```

**Verifica**: `5 tests passed, 6 failed`. `test_Paso2_RejectsWhatIsNotAToken` prueba tres "tokens"
que no lo son: una cuenta sin código, `SilentToken` y `RevertingToken`.

Cambia la condición por `if iszero(ok)` y vuelve a ejecutar. El test falla con
`next call did not revert as expected`: con la cuenta sin código, `balanceOf` devolvió lo que
quedaba en `0x00`. Deshaz el cambio.

## Paso 3: Reenviar una llamada y su error

**Por qué**: `forward` hace la llamada que le pidan. Si el destino revierte, revierte con **los
mismos bytes**, sin decodificarlos ni envolverlos. Si sale bien, devuelve la returndata como un
`bytes memory`. Las dos cosas usan memoria libre, no el scratch space: tanto la calldata como la
respuesta pueden pasar de 64 bytes.

**Abre** `src/AsmCaller.sol` y resuelve `forward`:

```solidity
assembly ("memory-safe") {
    let ptr := mload(0x40)
    calldatacopy(ptr, data.offset, data.length)
    let ok := call(gas(), target, 0, ptr, data.length, 0, 0)
    let size := returndatasize()
    if iszero(ok) {
        returndatacopy(ptr, 0, size)
        revert(ptr, size)
    }
    result := ptr
    mstore(result, size)
    returndatacopy(add(result, 0x20), 0, size)
    mstore(0x40, add(add(result, 0x20), and(add(size, 0x1f), not(0x1f))))
}
```

La calldata se copia en `ptr` y, tras la llamada, la respuesta va al mismo sitio: la calldata ya
no hace falta. El puntero se mueve detrás de la respuesta, redondeado a palabras, porque Solidity
codifica `result` después, en la memoria libre.

**Verifica**: `7 tests passed, 4 failed`. `test_Paso3_ForwardBubblesError` espera exactamente
`Target.Nope(42)`. `testFuzz_Paso3_ForwardReturnsSameBytes` reenvía `echo` con datos de cualquier
longitud.

Borra la última línea, la que mueve el puntero, y ejecuta otra vez. El fuzz test falla: al
codificar `result` para devolverlo, Solidity escribe encima de él.

## Paso 4: Copiar como mucho `maxCopy` bytes

**Por qué**: es la defensa contra la return bomb de la teoría 03, y lo que harás en el proyecto.
La llamada no copia nada (`0, 0` al final); después copias `min(returndatasize(), maxCopy)`. Si
copiaras `maxCopy` sin mirar, una respuesta más corta haría revertir `returndatacopy`.

**Abre** `src/AsmCaller.sol` y resuelve `callCapped`:

```solidity
assembly ("memory-safe") {
    ok := call(gas(), target, 0, add(payload, 0x20), mload(payload), 0, 0)
    let size := returndatasize()
    if gt(size, maxCopy) { size := maxCopy }
    head := mload(0x40)
    mstore(head, size)
    returndatacopy(add(head, 0x20), 0, size)
    mstore(0x40, add(add(head, 0x20), and(add(size, 0x1f), not(0x1f))))
}
```

`payload` es la copia en memoria de `data` que hace la primera línea de la función, en Solidity:
`add(payload, 0x20)` son sus datos y `mload(payload)`, su longitud.

**Verifica**: `9 tests passed, 2 failed`. Ejecuta el test de gas con sus logs:

```bash
forge test --mt test_Paso4_BombCostsLittle -vv
```

```text
  gas copiando 4 bytes: 64235
  gas copiando 100 000 bytes: 286041
```

`Target.bomb(100_000)` revierte con 100 000 bytes. Copiar 4 cuesta lo que cuesta el destino;
copiarlos todos, más de cuatro veces más.

## Paso 5: `create2` y su dirección 0

**Por qué**: `create2` despliega `initCode` en una dirección que depende de este contrato, la sal
y el hash del código (semana 10). Si el constructor revierte o la dirección ya tiene un contrato,
`create2` no revierte: devuelve 0. Sin comprobarlo, `deploy` devolvería la dirección 0 como si
fuera un contrato.

**Abre** `src/AsmCaller.sol` y resuelve `deploy`:

```solidity
assembly ("memory-safe") {
    deployed := create2(0, add(initCode, 0x20), mload(initCode), salt)
    if iszero(deployed) {
        mstore(0, shl(224, 0xb4f54111)) // DeployFailed()
        revert(0, 4)
    }
}
```

**Verifica**: `11 tests passed, 0 failed`. `test_Paso5_DeployAtPredictedAddress` compara con
`vm.computeCreate2Address`. `test_Paso5_FailedDeployReverts` despliega dos veces con la misma sal
y una vez con `Unbuildable`, cuyo constructor revierte: las dos veces, `DeployFailed`.

Cambia `if iszero(deployed)` por `if 0` y ejecuta: `next call did not revert as expected`. Mira el
gas de ese test en la salida: más de mil millones. El choque de dirección gastó todo el gas que
tenía.

## Para pensar

- `checkOwner` compara `caller()` con `owner`. ¿Qué pasaría si `owner` tuviera bits sucios en sus
  12 bytes altos? ¿Puede tenerlos, viniendo de un `immutable`?
- `forward` acepta cualquier `target` y cualquier `data`, con todo el gas. Si el dueño fuera un
  contrato, ¿qué riesgos añade `forward`? ¿En qué se diferencia del `multicall` de tu registro?
- En el paso 4, el gas que gasta el destino al revertir lo paga quien llama a `callCapped`. ¿Cómo
  lo limitarías? ¿Qué hace el registro de tu proyecto con `HOOK_GAS`?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Memoria y storage en assembly](../ejercicio-02-memoria-y-storage-en-assembly/README.md) | **Ejercicio 03 — Llamadas en assembly** | [Proyecto — La llamada al hook en assembly →](../../3-proyecto/README.md) |
