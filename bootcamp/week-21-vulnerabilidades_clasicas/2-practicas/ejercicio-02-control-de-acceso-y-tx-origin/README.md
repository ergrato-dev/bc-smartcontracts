# Ejercicio 02 — Control de acceso y `tx.origin`

> Al terminar habrás robado una cartera que confía en `tx.origin` con un contrato cebo, la
> habrás corregido con `msg.sender`, y habrás cerrado los tres agujeros de control de acceso de
> una tesorería detrás de un proxy: un `initialize` repetible, una implementación sin cerrar y
> una función sin comprobación.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 02 — Control de acceso y `tx.origin`](../../1-teoria/02-control-de-acceso-y-tx-origin.md)
leída.

## Contexto

Proyecto Foundry. Alice es la dueña legítima de todo; Mallory, la atacante.

| Archivo | Qué es |
| ------- | ------ |
| `src/OriginWallet.sol` | Cartera que autoriza con `tx.origin`. **No la arregles** |
| `src/Phisher.sol` | El cebo de Mallory. Paso 1 |
| `src/Wallet.sol` | La cartera corregida. Paso 2 |
| `src/Treasury.sol` | Tesorería para un proxy ERC-1967. Pasos 3, 4 y 5 |
| `test/AccessControl.t.sol` | Los tests. **No lo modifiques** |

Los tests usan `vm.prank(alice, alice)`: el segundo argumento fija `tx.origin`, igual que si
Alice hubiera firmado la transacción. Con un solo argumento, `tx.origin` sería la cuenta por
defecto de Foundry y la cartera vulnerable no caería.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-21-vulnerabilidades_clasicas/2-practicas/ejercicio-02-control-de-acceso-y-tx-origin/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `1 passed; 6 failed`. `test_Paso5_OwnerSweeps` ya pasa: que la dueña barra su
tesorería funciona desde el principio; lo que falta es impedir que lo haga otro. Tres tests
fallan con `next call did not revert as expected`: esperan que Mallory sea rechazada y no lo es.

## Paso 1: El cebo

**Por qué**: Alice cree que reclama un premio y firma una transacción a `claimPrize`. Dentro,
el cebo llama a la cartera. Para la cartera, `msg.sender` es el cebo, pero `tx.origin` sigue
siendo Alice, que firmó. La comprobación pasa.

```solidity
WALLET.withdraw(THIEF, address(WALLET).balance);
```

**Abre** `src/Phisher.sol`, borra el `revert` de `claimPrize` y descomenta su línea. Ejecuta
`forge test`.

**Verifica**: `2 passed; 5 failed`. `test_Paso1_PhisherDrainsOriginWallet` en verde: Mallory
tiene los 10 ETH de Alice, que solo llamó a un contrato que parecía inofensivo.

## Paso 2: `msg.sender`, no `tx.origin`

**Por qué**: `msg.sender` es quien hace **esta** llamada. Si Alice llama directamente, es Alice;
si llama a través del cebo, es el cebo, y no tiene permiso.

```solidity
if (msg.sender != OWNER) revert NotOwner(msg.sender);
```

**Abre** `src/Wallet.sol`, borra el `revert` de `withdraw` y descomenta su línea.

**Verifica**: `4 passed; 3 failed`. En verde:

- `test_Paso2_OwnerWithdraws`: Alice retira 4 ETH llamando ella misma.
- `test_Paso2_RevertWhen_PhisherCallsWallet`: el cebo revierte con
  `NotOwner(0x3a9f41A27B1F5C1b9635F8ef7678575b241d660d)`, la dirección del propio cebo. Los
  10 ETH no se mueven.

## Paso 3: `initialize` una sola vez

**Por qué**: un contrato detrás de un proxy no tiene constructor útil: el constructor se ejecuta
en la implementación, no en el proxy (semana 15). Lo sustituye `initialize`, que es una función
`external` normal. Sin nada más, cualquiera puede llamarla cuando quiera y nombrarse dueño.
Eso es lo que hace Mallory en `test_Paso3_RevertWhen_InitializeTwice`.

El modificador `initializer` de OpenZeppelin la deja ejecutarse una vez; la segunda revierte con
`InvalidInitialization()`.

**Abre** `src/Treasury.sol` y descomenta la línea `//> initializer` de `initialize`.

**Verifica**: `5 passed; 2 failed`. El test despliega el proxy con la llamada a `initialize`
dentro (el segundo argumento de `ERC1967Proxy`): queda inicializado en la misma transacción que
lo crea, sin un hueco en el que alguien se adelante. El intento de Mallory revierte.

## Paso 4: Cerrar la implementación

**Por qué**: la implementación es un contrato desplegado como cualquier otro, con su propio
storage. Nadie la ha inicializado, así que Mallory puede llamar a `initialize` **en ella** y ser
su dueña. En 2021, eso dejó los proxies UUPS de OpenZeppelin a un paso de quedarse sin código:
la dueña de la implementación podía actualizarla a un contrato que hiciera `selfdestruct`. Hoy
`UUPSUpgradeable` solo deja actualizar a través del proxy y, desde EIP-6780, `selfdestruct` ya
no borra el código de un contrato antiguo, pero la regla sigue: una implementación con dueño
es un contrato con dueño, y lo que ese dueño pueda hacer en ella lo hace Mallory.

`_disableInitializers()` en el constructor marca la implementación como ya inicializada.

**Abre** `src/Treasury.sol` y descomenta la línea del constructor.

**Verifica**: `6 passed; 1 failed`. `test_Paso4_RevertWhen_InitializeImplementation` en verde:
`initialize` sobre la implementación da `InvalidInitialization()` y su `owner` sigue en
`address(0)`.

## Paso 5: La comprobación que falta

**Por qué**: el fallo de control de acceso más frecuente no tiene truco: una función que mueve
valor y no comprueba quién llama. `sweep` envía todo el ETH a la dirección que le pases.

```solidity
if (msg.sender != owner) revert NotOwner(msg.sender);
```

**Abre** `src/Treasury.sol` y descomenta la línea de `sweep`.

**Verifica**: `7 passed; 0 failed`. Mallory recibe `NotOwner(mallory)` y los 5 ETH siguen en la
tesorería. Comprueba que no queda ningún warning:

```bash
forge test --deny warnings
```

Y pasa el linter de Foundry por la cartera vulnerable:

```bash
forge lint src/OriginWallet.sol
```

El comentario `forge-lint: disable-next-line(tx-origin)` lo silencia. Bórralo y vuelve a
ejecutarlo: verás `` warning[tx-origin]: `tx.origin` is used for authorization ``. El linter lo
detecta solo; la semana 23 va de herramientas que buscan esto en todo un proyecto.

## Para pensar

- ¿Hay algún uso de `tx.origin` que no sea autorizar? Piensa en `require(tx.origin == msg.sender)`:
  ¿qué intenta impedir y por qué la account abstraction de la semana 32 lo rompe?
- Si `initialize` se llamara en una transacción aparte, después de desplegar el proxy, ¿qué
  podría hacer alguien que vigila el mempool?
- Haz una lista de las funciones de tu protocolo que mueven valor o cambian a quién se obedece.
  ¿Todas comprueban quién llama?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Reentrancy](../ejercicio-01-reentrancy/README.md) | **Ejercicio 02 — Control de acceso y `tx.origin`** | [Ejercicio 03 — DoS y aritmética →](../ejercicio-03-dos-y-aritmetica/README.md) |
