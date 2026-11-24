# Ejercicio 02 — Handlers

> Al terminar habrás visto una invariante pasar sin probar nada, habrás escrito el handler que la
> hace útil, con cuentas, entradas acotadas y variables fantasma, y habrás encontrado con él un
> fallo que solo aparece cuando el vault tiene rendimiento.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 03 — Handlers](../../1-teoria/03-handlers.md) leída y el
[ejercicio 01](../ejercicio-01-invariantes/README.md) terminado.

## Contexto

`Vault` es la bóveda de la semana 22: depositas un token y recibes participaciones; retiras
participaciones y recibes tu parte de los tokens. Si alguien manda tokens al vault sin depositar
(un rendimiento), cada participación vale más. Sus tres tests unitarios pasan, todos con precio
1:1.

| Archivo | Qué es |
| ------- | ------ |
| `src/Vault.sol` | El vault. Paso 4 |
| `src/Token.sol` | ERC-20 de prueba: cualquiera acuña. Hecho |
| `test/Vault.t.sol` | Tres tests unitarios, en verde. **No lo modifiques** |
| `test/VaultHandler.sol` | El handler. Pasos 2, 3 y 5 |
| `test/VaultInvariants.t.sol` | Dos contratos de invariantes: sin handler y con él. Pasos 1, 2, 3 y 5 |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-24-fuzzing_de_invariantes/2-practicas/ejercicio-02-handlers/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `VaultTest` pasa, `3 passed`. `VaultOpenTest` falla con `TODO: Paso 1` y
`VaultInvariantsTest`, en `setUp`, con `TODO: Paso 2`.

## Paso 1: Una invariante sin handler

**Por qué**: sin rendimiento, cada participación vale un token, así que nunca hay más
participaciones que tokens. `VaultOpenTest` pone el vault como objetivo directo, como el
ejercicio 01.

```solidity
assertLe(vault.totalShares(), vault.totalAssets());
```

**Abre** `test/VaultInvariants.t.sol` y, en `invariant_SharesBackedByAssets`, borra el `revert` y
descomenta la línea.

**Verifica**: `forge test --mc VaultOpenTest` pasa, y mira la tabla:

```text
[PASS] invariant_SharesBackedByAssets() (runs: 256, calls: 128000, reverts: 128000)
| Vault    | deposit  | 63806 | 63806   | 0        |
| Vault    | withdraw | 64194 | 64194   | 0        |
```

Todas las llamadas revierten. Las cuentas del fuzzer no tienen tokens ni han dado allowance: el
vault no sale nunca del estado inicial. Verde, y no ha probado nada.

## Paso 2: El handler

**Por qué**: el handler hace lo que el fuzzer no sabe hacer. Elige una de tres cuentas, le da
tokens, aprueba al vault y deposita una cantidad con sentido. Para retirar, acota las
participaciones a las que tiene la cuenta. El fuzzer llama solo al handler.

```solidity
function deposit(uint256 actorSeed, uint256 assets) external {
    address actor = actors[actorSeed % actors.length];
    assets = bound(assets, 1, 1_000_000e18);
    // Con rendimiento, un depósito muy pequeño daría 0 participaciones y el vault lo
    // rechaza: el handler no lo intenta.
    uint256 supply = vault.totalShares();
    if (supply != 0 && assets * supply / vault.totalAssets() == 0) return;
    token.mint(actor, assets);
    vm.startPrank(actor);
    token.approve(address(vault), assets);
    vault.deposit(assets);
    vm.stopPrank();
    // ...
}
```

**Abre** `test/VaultHandler.sol` y descomenta las líneas del paso 2 en `deposit` y en `withdraw`
(no las del paso 5). Después, en `VaultInvariants.t.sol`, en el `setUp` de `VaultInvariantsTest`,
borra el `revert` y descomenta `targetContract(address(handler))`.

**Verifica**: compila, y `VaultInvariantsTest` ya no falla en `setUp`: fallan sus dos invariantes,
con su `TODO`.

## Paso 3: Rendimiento y la suma de participaciones

**Por qué**: `totalShares` es la suma de las participaciones de todos. Con solo tres cuentas, esa
suma se puede calcular. Y hace falta una acción que no es de ningún usuario: tokens que llegan al
vault sin depósito. Sin ella, el precio siempre es 1.

```solidity
function addYield(uint256 assets) external {
    assets = bound(assets, 1, 100_000e18);
    token.mint(address(vault), assets);
}
```

```solidity
function invariant_SharesAddUp() public view {
    uint256 sum;
    for (uint256 i = 0; i < handler.actorCount(); i++) {
        sum += vault.sharesOf(handler.actors(i));
    }
    assertEq(sum, vault.totalShares());
}
```

**Abre** `VaultHandler.sol` y descomenta las dos líneas del paso 3 en `addYield`. En
`VaultInvariants.t.sol`, en `invariant_SharesAddUp`, borra el `revert` y descomenta el cuerpo.

**Verifica**: `invariant_SharesAddUp` falla, con una secuencia de unas cuatro llamadas:

```text
[FAIL: assertion failed: 1839503193972906336940995 != 1827302886870147413019674] invariant_SharesAddUp
	[Sequence] (original: 19, shrunk: 4)
		... calldata=deposit(uint256,uint256) args=[1, 100000000000000000000000 [1e23]]
		... calldata=addYield(uint256) args=[1000000000000000000000000 [1e24]]
		... calldata=deposit(uint256,uint256) args=[21838953708549868168146491371012655290136 [2.183e40], ...]
		... calldata=withdraw(uint256,uint256) args=[1000000000000000000000000 [1e24], 1000000000000000000000000 [1e24]]
```

Depósito, rendimiento, otro depósito y una retirada: la suma de participaciones queda por
**encima** de `totalShares`. Los argumentos son los del fuzzer antes del `bound`.

## Paso 4: Se queman participaciones, no tokens

**Por qué**: `withdraw` resta de `sharesOf` las participaciones, y de `totalShares`... los tokens
que paga. Con precio 1 son el mismo número, y los tests unitarios no lo ven. Con rendimiento, una
retirada quema de `totalShares` más de lo que debe, y las participaciones de los demás pasan a
valer más que su parte.

```solidity
totalShares -= shares;
```

**Abre** `src/Vault.sol` y, en `withdraw`, sustituye la línea `// <- Paso 4` por la de debajo.

**Verifica**: `[PASS] invariant_SharesAddUp`, y en la tabla del handler, 0 reverts en las tres
acciones.

## Paso 5: Variables fantasma

**Por qué**: los tokens del vault tienen que ser lo depositado, más el rendimiento, menos lo
retirado. El vault no guarda esos tres números; el handler sí puede contarlos, cada uno después
de que su acción salga bien.

```solidity
ghostDeposited += assets;   // al final de deposit
ghostWithdrawn += assets;   // al final de withdraw
ghostYield += assets;       // al final de addYield
```

```solidity
function invariant_AssetsAccounted() public view {
    assertEq(vault.totalAssets(), handler.ghostDeposited() + handler.ghostYield() - handler.ghostWithdrawn());
}
```

**Abre** `VaultHandler.sol` y descomenta las tres líneas del paso 5. En `VaultInvariants.t.sol`, en
`invariant_AssetsAccounted`, borra el `revert` y descomenta la línea.

**Verifica**: `forge test` sin error. Las dos invariantes de `VaultInvariantsTest` en verde, con 0
reverts:

```text
 VaultInvariantsTest invariants (runs: 256, calls: 128000, reverts: 0)
```

## Para pensar

- En el paso 3, ¿por qué hace falta `addYield`? Quítala del handler con `excludeSelector` o
  comentándola, deshaz el paso 4 y mira si `invariant_SharesAddUp` sigue encontrando el fallo.
- Sin `targetContract(address(handler))` en el `setUp`, ¿qué invariante falla y por qué, si el
  vault está bien? (Pista: la teoría 02.)
- `deposit` se salta los depósitos que darían 0 participaciones. ¿Qué cambiarías para que el
  handler compruebe también que el vault los rechaza?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Invariantes](../ejercicio-01-invariantes/README.md) | **Ejercicio 02 — Handlers** | [Ejercicio 03 — Medusa →](../ejercicio-03-medusa/README.md) |
