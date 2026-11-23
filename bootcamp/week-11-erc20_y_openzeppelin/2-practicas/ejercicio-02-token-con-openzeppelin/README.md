# Ejercicio 02 — Token con OpenZeppelin

> Al terminar tendrás la moneda de un gremio hecha con OpenZeppelin: con tope de
> suministro, quema, emisión solo para el dueño y una regla propia en `_update`. Y sabrás
> listar todo lo que tu contrato expone sin haberlo escrito.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 03](../../1-teoria/03-openzeppelin-y-forge-install.md) leída y
[ejercicio 01](../ejercicio-01-erc20-a-mano/README.md) terminado.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml` | Con el remapping `@openzeppelin/contracts/` a la copia de la imagen. No lo cambies |
| `src/Owned.sol` | El dueño fijo de la semana 08, con `onlyOwner`. Terminado |
| `src/GuildCoin.sol` | La moneda: hereda `ERC20`, `ERC20Burnable`, `ERC20Capped` y `Owned`. Aquí trabajas |
| `test/GuildCoin.t.sol` | Tests de tus pasos (`test_Step*`) y de lo heredado (`test_Inherited_*`). No lo modifiques |

El `_update` ya está escrito, con `override(ERC20, ERC20Capped)` y `super`: sin él no
compila (error 6480, teoría 03).

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-11-erc20_y_openzeppelin/2-practicas/ejercicio-02-token-con-openzeppelin/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con dos warnings `(5667)` (parámetros sin usar) y un `(2018)`.

**Verifica**: `2 tests passed, 6 failed, 0 skipped (8 total tests)`. Ya pasan
`test_Step2_RevertWhen_StrangerMints` (`onlyOwner` revierte antes de llegar al `TODO`) y
`test_Inherited_RevertWhen_TransferToZero`: ese error lo pone OpenZeppelin, no tú.

## Paso 1: El suministro inicial

**Por qué**: el constructor de `ERC20` fija nombre y símbolo, y el de `ERC20Capped` el
tope, pero ninguno crea tokens. `_mint` es `internal`: solo tu contrato decide quién lo
llama. Aquí, una vez, al desplegar.

**Abre** `src/GuildCoin.sol`, en el constructor, y descomenta (en un constructor no hay
`revert("TODO")`: el comentario explica por qué):

```solidity
_mint(msg.sender, initialSupply);
```

**Verifica**: `5 tests passed, 3 failed`. Con saldo en el dueño pasan también
`test_Inherited_BurnLowersSupply` y `test_Inherited_BurnFromNeedsAllowance`.

## Paso 2: Emitir, solo el dueño

**Por qué**: el tope limita cuántos tokens puede haber, no quién los crea. Sin `onlyOwner`,
cualquiera emitiría hasta el tope (teoría 03).

```solidity
_mint(to, amount);
```

**Verifica**: `7 tests passed, 1 failed`. Pasa `test_Inherited_RevertWhen_CapExceeded`: con
1000 de partida, emitir 999 001 deja el suministro en 1 000 001, y `ERC20Capped` revierte
con `ERC20ExceededCap(1000001000000000000000000, 1000000000000000000000000)`. Tú no
escribiste esa comprobación; la hiciste llegar con `super`.

## Paso 3: Una regla propia

**Por qué**: unos tokens enviados a la dirección del propio token se pierden (teoría 01).
Como mint, burn y transfer pasan todos por `_update`, una línea allí lo impide en todos los
caminos, también en `transferFrom`.

**En** `_update`, descomenta, antes de `super`:

```solidity
if (to == address(this)) revert SelfTransfer();
```

Antes de `super`, porque así revierte sin mover nada; después también revertiría, pero
gastando más gas.

**Verifica**:

```bash
forge test --deny warnings
```

`8 tests passed, 0 failed, 0 skipped (8 total tests)`, sin warnings.

## Paso 4: Lo que heredaste

**Por qué**: escribiste tres líneas, pero tu contrato expone muchas más funciones. Cada una
es parte de tu contrato, aunque no la hayas escrito tú.

Este paso no tiene código:

```bash
forge inspect GuildCoin methods
```

```
╭---------------------------------------+------------╮
| Method                                | Identifier |
+====================================================+
| MAX_SUPPLY()                          | 32cb6b0c   |
|---------------------------------------+------------|
| OWNER()                               | 117803e3   |
|---------------------------------------+------------|
| allowance(address,address)            | dd62ed3e   |
|---------------------------------------+------------|
| approve(address,uint256)              | 095ea7b3   |
|---------------------------------------+------------|
| balanceOf(address)                    | 70a08231   |
|---------------------------------------+------------|
| burn(uint256)                         | 42966c68   |
|---------------------------------------+------------|
| burnFrom(address,uint256)             | 79cc6790   |
|---------------------------------------+------------|
| cap()                                 | 355274ea   |
...
```

Quince funciones: de ellas, tú escribiste `mint` y la constante `MAX_SUPPLY`. Las de
ERC-20 tienen los mismos selectores que tu `MiniToken` del ejercicio 01 (`transfer` es
`a9059cbb` en los dos): por eso una wallet maneja los dos igual.

**Verifica**: lee `test_Inherited_BurnFromNeedsAllowance`. Sin permiso, `burnFrom` revierte con
`ERC20InsufficientAllowance(shop, 0, 10 ether)`; con un `approve` de 10, la tienda quema 10
tokens del gremio y el permiso queda a 0. `burnFrom` gasta allowance igual que
`transferFrom`: lo usarás en el proyecto.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 8 tests.
- Explicas por qué `_update` necesita `override(ERC20, ERC20Capped)` y qué hace `super`.
- Explicas por qué la regla del paso 3 va en `_update` y no en `transfer`.
- Señalas en la salida de `forge inspect` qué funciones heredaste y qué permite cada una
  de `ERC20Burnable`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — ERC-20 a mano](../ejercicio-01-erc20-a-mano/README.md) | **Ejercicio 02 — Token con OpenZeppelin** | [Ejercicio 03 — Allowance y SafeERC20 →](../ejercicio-03-allowance-y-safeerc20/README.md) |
