# Ejercicio 02 — Front-running y MEV

> Al terminar habrás hecho un sándwich alrededor del swap de otra cuenta, lo habrás frustrado
> con un mínimo a recibir y un plazo, y habrás convertido un acertijo que cualquiera copia de la
> mempool en uno de commit-reveal.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 03 — Front-running y MEV](../../1-teoria/03-front-running-y-mev.md)
leída.

## Contexto

Proyecto Foundry. El pool es el del ejercicio 01, con `quote` (lo que daría un swap ahora) y
dos parámetros más en `swap`: `minAmountOut` y `deadline`. En los tests, el pool tiene
1 000 000 USD y 1000 GOV, Alice quiere cambiar 100 000 USD por GOV, y el atacante tiene
500 000 USD.

Un test no tiene mempool: **el orden de las llamadas es el orden del bloque**. Cuando el test
llama a `frontRun` antes que al swap de Alice, está simulando que el constructor del bloque puso
la transacción del atacante delante.

| Archivo | Qué es |
| ------- | ------ |
| `src/Token.sol` | ERC-20 de prueba. Hecho |
| `src/Pool.sol` | El pool. Pasos 2 y 3 |
| `src/Sandwicher.sol` | El atacante del sándwich. Paso 1 |
| `src/VulnerablePuzzle.sol` | Un acertijo que paga 1 ETH a la primera respuesta buena. **No lo arregles** |
| `src/CommitRevealPuzzle.sol` | El acertijo en dos fases. Pasos 4 y 5 |
| `test/FrontRunning.t.sol` | Los tests. **No lo modifiques** |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-22-vulnerabilidades_economicas/2-practicas/ejercicio-02-front-running-y-mev/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `2 passed; 7 failed`. Ya pasan dos:

- `test_Paso2_SwapWithinSlippage`: sin nadie en medio, un swap da lo que dijo `quote`.
- `test_FrontRunnerStealsVulnerablePuzzle`: Mallory ve en la mempool `solve("rollup")` de Alice,
  envía lo mismo antes y cobra el 1 ETH; la de Alice revierte con `AlreadySolved`. No hay nada
  que resolver: es el ataque contra el que defiendes en los pasos 4 y 5.

`test_Paso3_RevertWhen_Expired` falla con `next call did not revert as expected`: el pool todavía
no mira el plazo.

## Paso 1: El sándwich

**Por qué**: el atacante necesita dos transacciones, una justo antes del swap de Alice y otra
justo después. La primera compra GOV y sube el precio que pagará Alice; la segunda vende el GOV
al precio que Alice ha subido todavía más. No pone mínimo ni plazo: va en el mismo bloque.

```solidity
uint256 amount = USD.balanceOf(address(this));
USD.forceApprove(address(POOL), amount);
// Va en la misma tanda que la víctima: no necesita mínimo ni plazo.
POOL.swap(USD, amount, 0, type(uint256).max);
```

```solidity
uint256 amount = GOV.balanceOf(address(this));
GOV.forceApprove(address(POOL), amount);
POOL.swap(GOV, amount, 0, type(uint256).max);
```

**Abre** `src/Sandwicher.sol`, borra los dos `revert` y descomenta las líneas de `frontRun` y
`backRun`.

**Verifica**: `3 passed; 6 failed`. `test_Paso1_SandwichProfits` en verde: sola, Alice habría
recibido 90,909... GOV; con el sándwich recibe **41,666...**, y el atacante pasa de 500 000 a
**556 521,739...** USD. `test_Paso2_RevertWhen_Sandwiched` falla con `next call did not revert as
expected`: el pool acepta el precio que sea.

## Paso 2: Un mínimo a recibir

**Por qué**: Alice calcula `minAmountOut` al firmar, fuera de la cadena, con el precio que ve
y su tolerancia: en el test, `quote` menos un 1 %. Si el swap va a dar menos, revierte. El
atacante solo puede mover el precio dentro de ese 1 %, y un sándwich tan fino no le paga.

```solidity
if (amountOut < minAmountOut) revert InsufficientOutput(amountOut, minAmountOut);
```

**Abre** `src/Pool.sol` y descomenta la línea del paso 2 en `swap`.

**Verifica**: `4 passed; 5 failed`. `test_Paso2_RevertWhen_Sandwiched` en verde: el swap de
Alice revierte con `InsufficientOutput(41666666666666666666, 89999999999999999999)`. El atacante
vende igual, pero sin nadie en medio recupera 499 999,999... USD: 500 wei menos de lo que puso,
lo que se pierde al redondear sus dos swaps.

## Paso 3: Un plazo

**Por qué**: una transacción con poca propina puede quedarse en la mempool horas. Cuando entra,
el precio ya no es el que viste, y `minAmountOut` solo te protege si lo calculaste con margen
para todo ese tiempo. `deadline` dice hasta cuándo vale la orden.

```solidity
// Un validador mueve el timestamp unos segundos: con plazos de minutos da igual.
// forge-lint: disable-next-line(block-timestamp)
if (block.timestamp > deadline) revert Expired(deadline);
```

**Abre** `src/Pool.sol` y descomenta las líneas del paso 3, al principio de `swap`.

**Verifica**: `5 passed; 4 failed`. `test_Paso3_RevertWhen_Expired` en verde: un swap con 5
minutos de plazo que entra a los 10 revierte con `Expired(plazo)`.

## Paso 4: El compromiso

**Por qué**: `VulnerablePuzzle` pierde porque la respuesta viaja en claro. En `CommitRevealPuzzle`
primero se envía solo un hash: el de tu dirección, tu respuesta y un salt secreto
(`hashCommitment`). Se guarda con el número de bloque en que llegó.

```solidity
commitmentOf[msg.sender] = commitment;
committedAt[msg.sender] = block.number;
```

**Abre** `src/CommitRevealPuzzle.sol`, borra el `revert` de `commit` y descomenta sus líneas.

**Verifica**: `6 passed; 3 failed`. `test_Paso4_Commit` en verde. Los tres del paso 5 fallan con
`TODO: Paso 5`.

## Paso 5: La revelación

**Por qué**: al revelar, el contrato recalcula el hash con `msg.sender` y exige que el
compromiso sea de un bloque anterior. Las comprobaciones van antes de pagar, y el pago al final
(checks-effects-interactions, semana 21).

```solidity
if (solved) revert AlreadySolved();
if (commitmentOf[msg.sender] != hashCommitment(msg.sender, answer, salt)) revert WrongCommitment();
if (block.number <= committedAt[msg.sender]) revert RevealTooEarly();
if (keccak256(bytes(answer)) != ANSWER_HASH) revert WrongAnswer();
solved = true;
(bool ok,) = msg.sender.call{value: REWARD}("");
if (!ok) revert TransferFailed();
```

**Abre** `src/CommitRevealPuzzle.sol`, borra el `revert` de `reveal` y descomenta sus líneas.

**Verifica**: `9 passed`. En verde:

- `test_Paso5_RevealPays`: revelar en el mismo bloque da `RevealTooEarly`; en el siguiente,
  Alice cobra 1 ETH.
- `test_Paso5_RevertWhen_FrontRunnerCopiesCommit`: Mallory copia el compromiso de Alice y
  después su revelación, y recibe `WrongCommitment`: el hash lleva la dirección de Alice.
- `test_Paso5_RevertWhen_FrontRunnerCopiesReveal`: Mallory ve la revelación de Alice, se
  compromete y revela en el mismo bloque, y recibe `RevealTooEarly`. Alice cobra después.

Para terminar, sin warnings:

```bash
forge test --deny warnings
```

## Para pensar

- El atacante del paso 1 tiene 500 000 USD. ¿Ganaría más o menos con 5 000 000? Prueba a cambiar
  el `mint` del `setUp` en una copia del test.
- Si Alice pone un 5 % de tolerancia en vez de un 1 %, ¿cuánto puede sacarle como mucho un
  sándwich?
- En el commit-reveal, ¿qué pasa si nadie revela nunca la respuesta buena? ¿Y si Alice olvida su
  salt?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Oráculo y flash loan](../ejercicio-01-oraculo-y-flash-loan/README.md) | **Ejercicio 02 — Front-running y MEV** | [Ejercicio 03 — Redondeo →](../ejercicio-03-redondeo/README.md) |
