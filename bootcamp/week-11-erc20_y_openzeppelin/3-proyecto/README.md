# Proyecto — Token de fidelidad

> Undécima capa del protocolo de tu dominio: los puntos de la semana 10 pasan a ser un
> token ERC-20. Cada alta da tokens a quien registra, los tokens se pueden transferir y
> mostrar en una wallet, y treinta de ellos pagan un alta sin ETH.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados y tu proyecto de la
semana 10 en `main`.

## Capa que se añade y por qué ahora

Los puntos de la semana 10 eran un número dentro de otro contrato: nadie podía enviarlos,
verlos en una wallet ni gastarlos. Con un ERC-20 sí. Esta semana:

- **`LoyaltyToken`**, el token de tu dominio, hecho con OpenZeppelin: `ERC20`,
  `ERC20Burnable` y `ERC20Capped`. Es el nuevo hook: en cada `onItemRegistered` emite
  `REWARD` (10 tokens) para quien registró. Solo el registro puede emitir.
- **El registro despliega su token** en el constructor, con `new` (semana 10). Así
  `REGISTRY` es `msg.sender` en el constructor del token, sin argumentos que puedan ir mal,
  y el token queda en `LOYALTY`.
- **`registerWithPoints(label)`**: un alta pagada con `POINTS_PRICE` (30 tokens) en vez de
  ETH. El registro los quema con `burnFrom`, que gasta el permiso que le diste con
  `approve`.
- **El tope**: `MAX_SUPPLY` es un millón de tokens. Alcanzado, la emisión revierte dentro
  del hook, el registro lo apunta en `HookFailed` y el alta sigue (semana 10).

En la semana 12 llegan los tokens no fungibles (ERC-721): un certificado propio para cada recurso.

**El dominio te lo asigna el instructor.** Usa los nombres y la tasa de tu semana 10, y dale
al token un nombre y un símbolo de tu dominio.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-11
   ```

2. Copia el starter entero, con su `.gitignore`, en una carpeta `week-11/` (ajusta la ruta a
   donde clonaste el bootcamp). Después trae tus pruebas de la semana 09 y el
   `.gas-snapshot` de la 10:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-11-erc20_y_openzeppelin/3-proyecto/starter week-11
   cp week-10/test/RegistryFuzz.t.sol week-10/test/RegistryFork.t.sol week-11/test/
   cp week-10/.gas-snapshot week-11/
   ```

3. En `week-11/src/Registry.sol`, pon los nombres y la tasa de tu dominio. En
   `week-11/src/LoyaltyToken.sol`, el nombre y el símbolo del token (primer `// TODO:`).
   El resto de `src/` es tu semana 10: si cambiaste algo allí, cópialo también.

4. Entra al contenedor y mira el rojo:

   ```bash
   cd week-11
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   forge test
   ```

**Verifica**: `63 tests passed, 6 failed, 1 skipped (70 total tests)`. Fallan los dos tests
del token en `RegistryHook.t.sol`, tres de los que ponen el token como hook, y el `setUp()`
de `RegistryLoyalty.t.sol`: sin `supportsInterface`, `setHook` lo rechaza con
`InvalidHook`, y forge cuenta los 10 tests de ese archivo como un solo fallo. Al arreglarlo,
el total sube a 79.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml`, `.gitignore` | Con el remapping de OpenZeppelin. No los cambies |
| `src/LoyaltyToken.sol` | El token, con las constantes, `REGISTRY`, el error y `_update` ya escritos, y sus `// TODO:` |
| `src/Registry.sol` | Tu registro de la semana 10, que ya despliega `LOYALTY` en el constructor; `registerWithPoints` por completar |
| `src/` (resto) | `IRegistry`, `Owned`, `Openable`, `LabelLib`, `IERC165` e `IRegistrationHook`, sin cambios |
| `test/Registry.t.sol`, `test/RegistryMulticall.t.sol` | Los de la semana 10. **No los modifiques** |
| `test/RegistryHook.t.sol` | Los 11 de la semana 10, con el token en lugar de los puntos. **No lo modifiques** |
| `test/RegistryLoyalty.t.sol` | 10 tests del token y de `registerWithPoints`. **No lo modifiques** |

`RegistrationPoints.sol` ya no está: lo sustituye el token.

## Requisitos

1. **`LoyaltyToken`**: nombre y símbolo de tu dominio. `onItemRegistered` revierte con
   `NotRegistry(msg.sender)` si no llama el registro y, si no, emite `REWARD` para
   `registrant`. `supportsInterface` responde `true` para `IRegistrationHook` e `IERC165`, y
   `false` para el resto.
2. **`registerWithPoints(label)`**: con `whenOpen`, `RegistryFull(CAPACITY)` si no hay sitio
   y, antes de registrar, `LOYALTY.burnFrom(msg.sender, POINTS_PRICE)`. Después, como
   `register`: `_register` y `_notifyHook`. No es `payable`.
3. **Sin permiso no hay alta**: sin `approve`, `registerWithPoints` revierte con el
   `ERC20InsufficientAllowance` de OpenZeppelin; sin saldo, con `ERC20InsufficientBalance`.
   No escribes esas comprobaciones: llegan con `burnFrom`.
4. **`.gas-snapshot` actualizado** y `forge snapshot --fuzz-seed 1 --check` en verde.
5. **Desplegado en anvil** desde la cuenta de tu `INDEX`: el registro, su token como hook,
   tres altas pagadas con ETH y una con tokens. El test de fork pasa contra ese despliegue.

## Cómo verificar

```bash
forge test
```

**Verifica**: `78 tests passed, 0 failed, 1 skipped (79 total tests)`, sin warnings
(`forge test --deny warnings`). Fíjate en `test_CapReachedDoesNotBlockRegistry`: lleva el
suministro al tope con `deal(..., true)` (teoría 04) y comprueba que el alta sigue, con
`HookFailed(1, ERC20ExceededCap(...))` en los logs y 0 tokens para alice.

### Lo que cuesta la capa nueva

```bash
forge snapshot --fuzz-seed 1 --diff
```

Esta vez un alta no cuesta más (`test_RegisterStoresItem` sigue en unos 248 500): `LOYALTY`
es `immutable` y no se lee del storage. Lo que sube es **desplegar** el registro, porque
ahora despliega también el token. Los tests que crean su propio registro lo muestran:

```
↑ RegistryTest::test_OwnerAndCapacityAreSetAtDeploy() (gas: 2655069 → 4047476 | 1392407 52.443%)
```

Tus números serán otros. Después regenera y comprueba:

```bash
forge snapshot --fuzz-seed 1
forge snapshot --fuzz-seed 1 --check
```

### En anvil, y sobre su fork

Con `anvil --silent &` recién arrancado y la clave de tu `INDEX` (aquí `3`, capacidad `50`
y tasa `0.01 ether`, los de los ejemplos), despliega el registro:

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 3)
ME=$(cast wallet address "$PK")
forge create src/Registry.sol:Registry --private-key "$PK" --broadcast --constructor-args 50
REGISTRY=0x057ef64E23666F000b34aE31332854aCBd1c8544   # tu "Deployed to"
LOYALTY=$(cast call $REGISTRY "LOYALTY()(address)")
echo $LOYALTY
cast compute-address $REGISTRY --nonce 1
```

```
0x3b3112c4376d037822DECFf3Fe6CD30E1E726517
0x3b3112c4376d037822DECFf3Fe6CD30E1E726517
```

El token es el primer contrato que creó el registro: nonce 1 (semana 10). Ponlo como hook y
registra tres recursos pagando ETH:

```bash
cast send $REGISTRY "setHook(address)" $LOYALTY --private-key "$PK"
cast send $REGISTRY "registerBatch(string[])" "[north,south,east]" --value 0.03ether --private-key "$PK"
cast call $LOYALTY "balanceOf(address)(uint256)" $ME
```

Dos recibos con `status 1 (success)` y `30000000000000000000 [3e19]`: 30 tokens. Intenta
pagar un alta con ellos sin aprobar:

```bash
cast send $REGISTRY "registerWithPoints(string)" west --private-key "$PK"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0xfb8f41b2: ..., data: "0xfb8f41b2...": ERC20InsufficientAllowance(0x057ef64E23666F000b34aE31332854aCBd1c8544, 0, 30000000000000000000 [3e19])
```

El spender es el registro, con permiso 0. `cast` pone nombre al error porque está en los
artefactos de `out/` (OpenZeppelin se compila con tu proyecto). Aprueba y repite:

```bash
cast send $LOYALTY "approve(address,uint256)" $REGISTRY 30ether --private-key "$PK"
cast send $REGISTRY "registerWithPoints(string)" west --private-key "$PK"
cast call $LOYALTY "balanceOf(address)(uint256)" $ME
cast call $LOYALTY "totalSupply()(uint256)"
cast balance $REGISTRY --ether
```

Dos recibos con `status 1 (success)`, `10000000000000000000 [1e19]` dos veces y
`0.030000000000000000`: se quemaron 30 tokens, el alta nueva dio 10, y el registro no cobró
ETH por ella. `30ether` en `cast` vale 30 tokens porque el token tiene 18 decimales.

Y el test de fork, sin cambios, contra este despliegue:

```bash
FORK_URL=http://127.0.0.1:8545 REGISTRY="$REGISTRY" forge test --match-path test/RegistryFork.t.sol
```

`[PASS] test_Fork_RegistersOnACopy()`.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna:

| Dominio | El token | Qué paga `registerWithPoints` |
| ------- | -------- | ----------------------------- |
| Biblioteca | `Reader Points` (`RDP`) por cada libro donado | Donar un libro sin pagar la tasa |
| Tienda en línea | `Seller Credits` (`SLC`) por cada producto publicado | Publicar un producto gratis |
| Cine | `Screen Tokens` (`SCR`) por cada sala registrada | Registrar una sala más |

## Criterios de calidad (no automatizables)

- Sabes explicar por qué el token confía en `REGISTRY` y por qué fijarlo con `msg.sender`
  en el constructor es más seguro que pasarlo como argumento.
- Sabes explicar por qué `burnFrom` va **antes** de `_register`, y por qué esa llamada
  externa no es un riesgo de reentrancy aquí (el token es tuyo y no llama a nadie).
- Sabes explicar los límites que asumes: con el tope alcanzado ya no se ganan tokens, y
  quien envía la transacción puede darle poco gas para que el hook falle (semana 10).
- Sabes qué funciones públicas heredó tu token (`forge inspect LoyaltyToken methods`) y
  qué permite `burnFrom` a quien tenga un permiso.
- Sin `TODO` restantes, y el nombre y el símbolo del token son de tu dominio.

## Entrega

```bash
git add week-11
git commit -m "feat(week-11): add loyalty token and pay registrations with points"
git push -u origin week-11
```

Abre un pull request `week-11` → `main` en tu repositorio. En la descripción pega la salida
de `forge test`, la línea de `--diff` de un test que despliega el registro, y los saldos
que leíste en anvil.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Allowance y SafeERC20](../2-practicas/ejercicio-03-allowance-y-safeerc20/README.md) | **Proyecto — Token de fidelidad** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
