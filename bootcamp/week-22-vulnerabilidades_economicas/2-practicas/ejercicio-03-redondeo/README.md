# Ejercicio 03 — Redondeo

> Al terminar tendrás una bóveda que redondea cada conversión a su favor, habrás visto cómo el
> primer depositante se queda con parte del depósito de otro, y la habrás defendido con
> participaciones virtuales.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 04 — Redondeo](../../1-teoria/04-redondeo.md) leída.

## Contexto

Proyecto Foundry. `Vault` guarda un token y reparte participaciones proporcionales a lo
depositado. Tiene tres conversiones: tokens a participaciones al depositar, participaciones a
tokens al quemarlas (`redeem`), y cuántas participaciones cuesta sacar una cantidad exacta de
tokens (`withdraw`). Todas usan los totales que da `_totals`; `VirtualVault` hereda de `Vault`
y solo cambia esa función.

En los tests, Alice y Mallory empiezan con 100 000 tokens cada una.

| Archivo | Qué es |
| ------- | ------ |
| `src/Token.sol` | ERC-20 de prueba. Hecho |
| `src/Vault.sol` | La bóveda. Pasos 1, 2 y 3 |
| `src/VirtualVault.sol` | La bóveda con participaciones virtuales. Paso 4 |
| `test/Rounding.t.sol` | Los tests. **No lo modifiques** |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-22-vulnerabilidades_economicas/2-practicas/ejercicio-03-redondeo/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 passed; 7 failed`, todos con `TODO: Paso 1`: sin conversiones no se puede ni
depositar.

## Paso 1: Las conversiones

**Por qué**: un depósito da `tokens × participaciones / totalTokens`. Hay que multiplicar antes
de dividir: `assets / total * shares` da 0 en cuanto `assets` es menor que `total`. `mulDiv`
lo hace sin desbordar y, sin cuarto argumento, redondea hacia abajo: quien deposita recibe como
mucho lo que pagó, y quien quema participaciones saca como mucho lo que valen. La bóveda vacía
da una participación por token.

```solidity
(uint256 shares, uint256 total) = _totals();
if (shares == 0) return assets;
return Math.mulDiv(assets, shares, total);
```

```solidity
(uint256 supply, uint256 total) = _totals();
if (supply == 0) return shares;
return Math.mulDiv(shares, total, supply);
```

**Abre** `src/Vault.sol`, borra los `revert` de `convertToShares` y `convertToAssets` y
descomenta sus líneas.

**Verifica**: `2 passed; 5 failed`. En verde:

- `test_Paso1_Conversions`: Alice deposita 100 y la bóveda gana otros 100. 50 tokens dan 25
  participaciones, y 25 participaciones valen 50 tokens. 1 token vale media participación, que
  se redondea a **0**; 1 participación vale 2 tokens.
- `test_Paso3_ZeroSharesIsNotEnough`: ya pasa, y es el ataque de la teoría 04. Mallory deposita
  1 wei, dona 10 000 tokens, Alice deposita 15 000 y recibe **1** participación (1,49...).
  Mallory quema la suya y saca 12 500: 2500 eran de Alice. El paso 3 no lo arregla; el 4, sí.

## Paso 2: Lo que paga quien retira

**Por qué**: `withdraw(assets)` saca una cantidad exacta de tokens y quema las participaciones
que cuesta. Si se redondea hacia abajo, sacar 1 token cuando vale media participación cuesta 0:
cualquiera sin participaciones sacaría tokens gratis, uno a uno. Lo que se cobra se redondea
hacia arriba.

```solidity
(uint256 shares, uint256 total) = _totals();
if (shares == 0) return assets;
return Math.mulDiv(assets, shares, total, Math.Rounding.Ceil);
```

**Abre** `src/Vault.sol`, borra el `revert` de `previewWithdraw` y descomenta sus líneas.

**Verifica**: `4 passed; 3 failed`. En verde:

- `test_Paso2_PreviewWithdraw`: sacar 50 tokens cuesta 25 participaciones, y sacar 1 cuesta 1.
- `test_Paso2_RevertWhen_WithdrawingForFree`: Mallory, sin participaciones, intenta sacar 1
  token y recibe `InsufficientShares(0, 1)`.

## Paso 3: Ningún depósito a cambio de nada

**Por qué**: con 10 000 tokens donados, un depósito de 10 000 da
`10 000e18 × 1 / (10 000e18 + 1) = 0,99...` participaciones: 0. Alice pagaría y no recibiría
nada, y todo sería de Mallory. Un depósito que da 0 participaciones tiene que revertir.

```solidity
if (shares == 0) revert ZeroShares();
```

**Abre** `src/Vault.sol` y descomenta la línea del paso 3 en `deposit`.

**Verifica**: `5 passed; 2 failed`. `test_Paso3_RevertWhen_DepositGivesNoShares` en verde: el
depósito de Alice revierte con `ZeroShares`. Pero `test_Paso3_ZeroSharesIsNotEnough` sigue en
verde: con 15 000, Alice recibe 1 participación y pierde 2500. Revertir con 0 solo cierra el
caso extremo.

## Paso 4: Participaciones virtuales

**Por qué**: el ataque funciona porque Mallory es dueña del 100 % de una bóveda casi vacía y
puede fijar cuánto vale una participación. Si la proporción se calcula como si siempre hubiera
1000 participaciones y 1 token más que no son de nadie, el primer depósito de 1 wei da 1000
participaciones, y la donación de Mallory se reparte también con las 1000 virtuales.

```solidity
return (totalShares + VIRTUAL_SHARES, totalAssets() + 1);
```

**Abre** `src/VirtualVault.sol`, borra el `revert` de `_totals` y descomenta su línea.

**Verifica**: `7 passed`. En verde:

- `test_Paso4_VirtualSharesMakeAttackLose`: el mismo ataque contra `VirtualVault`. Mallory
  recibe 1000 participaciones por su wei, dona 10 000, Alice deposita 15 000 y recibe 2999.
  Mallory quema las suyas y saca **5001,0002...**: pierde casi 5000. Alice saca
  **14 997,9995...**: pierde un 0,013 %. El resto se queda en la bóveda, de las participaciones
  virtuales.
- `test_Paso4_VirtualVaultNormalUse`: sin ataque, 100 tokens dan `100e21` participaciones (1000
  por token) y se recuperan los 100 exactos.

Para terminar, sin warnings:

```bash
forge test --deny warnings
```

## Para pensar

- `VirtualVault` da 1000 participaciones por token. ¿Qué pasa con el ataque si
  `VIRTUAL_SHARES` es 1? ¿Y si es `1e6`? Cambia la constante en una copia y mira cuánto saca
  Mallory.
- La donación de Mallory se queda en parte en la bóveda. ¿Quién se beneficia de ella cuando
  alguien deposita después?
- Si `totalAssets` sumara solo los depósitos y retiradas (contabilidad interna) en vez de leer
  `balanceOf`, ¿haría falta alguna de las otras defensas?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Front-running y MEV](../ejercicio-02-front-running-y-mev/README.md) | **Ejercicio 03 — Redondeo** | [Proyecto — Ataques económicos a tu protocolo →](../../3-proyecto/README.md) |
