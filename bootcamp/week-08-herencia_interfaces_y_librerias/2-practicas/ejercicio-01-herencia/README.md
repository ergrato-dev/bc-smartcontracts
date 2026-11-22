# Ejercicio 01 — Herencia

> Al terminar habrás usado modificadores y funciones heredados, sustituido una función del
> padre sin perder sus comprobaciones y comprobado en qué orden encadena Solidity a dos
> padres.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teorías 01 y 02](../../1-teoria/01-herencia.md) leídas.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Ticketing.sol` | Cuatro contratos: `Owned` (dueño), `Pausable` (pausa) y `Capped` (tope de entradas), los tres `abstract`, y `Ticketing`, la taquilla que hereda de `Pausable` y `Capped`. Aquí trabajas |
| `test/Ticketing.t.sol` | Cuatro tests, uno por paso. **No lo modifiques** |

La jerarquía es un rombo: `Pausable` y `Capped` heredan de `Owned`, y `Ticketing` de los
dos. `Owned` está una sola vez en la taquilla: un solo `owner`.

Los tests nombran cada error y cada evento por el contrato que lo declara:
`Owned.NotOwner`, `Capped.SoldOut`, `Pausable.PausedSet` (teoría 01).

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-08-herencia_interfaces_y_librerias/2-practicas/ejercicio-01-herencia/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con `Warning (5667)` y `Warning (2018)`: los parámetros que todavía no usas.

**Verifica**: cuatro `FAIL`, cada uno con el `TODO` de su paso.

## Paso 1: Pausar con un modificador heredado

**Por qué**: `Pausable` no declara `onlyOwner`; lo hereda de `Owned`. Usarlo es lo mismo
que si estuviera escrito ahí.

**Abre** `src/Ticketing.sol`, en `Pausable`:

```solidity
function setPaused(bool value) external onlyOwner {
    paused = value;
    emit PausedSet(value);
}
```

**Verifica**: `[PASS] test_Step1_OwnerPauses()`. El dueño pausa y queda el evento; alice
recibe `NotOwner(alice)`.

## Paso 2: Comprar con piezas de dos padres

**Por qué**: la taquilla junta lo de sus dos padres. `whenNotPaused` viene de `Pausable` y
`_take`, que es `internal`, de `Capped`. Desde fuera nadie puede llamar a `_take`; desde
un hijo, sí.

```solidity
function buy(uint256 amount) external whenNotPaused {
    _take(amount);
    ticketsOf[msg.sender] += amount;
    emit Bought(msg.sender, amount);
}
```

**Verifica**: `[PASS] test_Step2_Buy()`. Con un tope de 5, alice compra 3; otras 3 dan
`SoldOut(5)`; en pausa, `IsPaused()`.

## Paso 3: `override` con `super`

**Por qué**: `forge build` ya te avisa del problema, en `Owned`:

```
warning[missing-zero-check]: address parameter is used in a state write or value transfer without a zero-address check
   ╭▸ src/Ticketing.sol:28:32
```

Pasar la propiedad a `address(0)` deja la taquilla sin dueño para siempre. No tocas
`Owned`: la taquilla sustituye `transferOwnership` (que en `Owned` es `virtual`), comprueba
su regla y deja el resto a la versión de `Owned` con `super`, `onlyOwner` incluido.

```solidity
function transferOwnership(address newOwner) public override {
    if (newOwner == address(0)) revert ZeroAddress();
    super.transferOwnership(newOwner);
}
```

**Verifica**: `[PASS] test_Step3_TransferOwnership()`. `address(0)` da `ZeroAddress()`,
alice recibe `NotOwner(alice)` y el dueño pasa la propiedad a alice con el evento
`OwnershipTransferred`. El aviso de `forge build` sigue ahí: lo da sobre `Owned`, que no
ha cambiado, aunque la taquilla ya no use esa versión sin la comprobación.

Rompe a propósito: cambia la línea de `super` por lo mismo que hace `Owned`, escrito a
mano:

```solidity
emit OwnershipTransferred(owner, newOwner);
owner = newOwner;
```

`forge test --match-test test_Step3`:

```
[FAIL: next call did not revert as expected] test_Step3_TransferOwnership() (gas: 63630)
```

Alice se queda con la taquilla: copiaste el cuerpo de `Owned`, pero no su `onlyOwner`, que
iba en la firma. Vuelve a `super`.

## Paso 4: Dos padres con la misma función

**Por qué**: `Pausable` y `Capped` tienen su propio `layers` y los dos sustituyen el de
`Owned`. La taquilla tiene que escribir el suyo y nombrar a los dos con
`override(Pausable, Capped)`. Esa firma ya está en el starter: sin ella no compila
(`Error (6480)`, teoría 02).

```solidity
function layers() public pure override(Pausable, Capped) returns (string memory) {
    return string.concat("Ticketing > ", super.layers());
}
```

**Verifica**: `forge test` termina con
`4 tests passed, 0 failed, 0 skipped (4 total tests)` y sin warnings. `layers()` devuelve
`"Ticketing > Capped > Pausable > Owned"`: el último padre de la lista (`Capped`) es el
primer `super`, y el `super` de `Capped` es `Pausable`, aunque `Capped` no herede de él.

Rompe a propósito: cambia el orden a `contract Ticketing is Capped, Pausable` y ejecuta
`forge test --match-test test_Step4`:

```
[FAIL: assertion failed: Ticketing > Pausable > Capped > Owned != Ticketing > Capped > Pausable > Owned] test_Step4_Layers() (gas: 11627)
```

Mismos contratos, otra fila. Vuelve al orden original.

## ✅ Criterios de éxito

- `forge test` pasa los 4 tests sin warnings.
- Explicas por qué `_take` se puede llamar desde `Ticketing` y no desde fuera.
- Explicas por qué copiar el cuerpo del padre en vez de llamar a `super` deja que alice se
  quede con la taquilla.
- Escribes la fila de linealización de `Ticketing` con los dos órdenes de la lista `is`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 05 — Librerías](../../1-teoria/05-librerias.md) | **Ejercicio 01 — Herencia** | [Ejercicio 02 — Interfaces y contratos abstractos →](../ejercicio-02-interfaces/README.md) |
