# Proyecto — Ataques económicos a tu protocolo

> Sigues la auditoría de tu protocolo con las clases de esta semana: oráculos, flash loans,
> orden de las transacciones y redondeo. Tu registro aguanta casi todo, pero cobra la tasa
> exacta, y la tasa cambia con el precio: cualquier actualización del feed entre que tu página
> la pide y el alta entra en un bloque hace revertir el alta. Lo corriges devolviendo lo que
> sobra, compruebas que la devolución no abre una reentrancy, y añades el hallazgo H-02 al
> informe.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 21 en
`main`.

## Capa que se añade y por qué ahora

Desde la semana 20, tu registro cobra en ETH una tasa fijada en dólares, con el precio de un
feed. Esa es justo la superficie de esta semana: un precio que viene de fuera, transacciones
que esperan en la mempool mientras ese precio cambia, órdenes firmadas que cualquiera puede
enviar y una división que redondea.

La mayoría de esos riesgos ya están cerrados por decisiones de semanas anteriores, y esta semana
lo demuestras con tests: el precio sale de Chainlink y no de un pool (semana 20), la orden
firmada lleva el registrante dentro (semana 14) y la tasa redondea hacia arriba (semana 20). Uno
no estaba cerrado.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-22
   ```

2. Copia el starter en `week-22/` y pon encima tus contratos de la semana 21:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-22-vulnerabilidades_economicas/3-proyecto/starter week-22
   cp -r week-21/contracts/src week-21/contracts/script week-22/contracts/
   ls -l week-22/contracts/lib
   ```

   **Verifica**: `lib -> /opt/lib`. Tus `src/` y `script/` son los de la semana 21. Los tests
   y los atacantes de `test/` son los del starter: los de la semana 21 ya resueltos, más los
   nuevos. Si tenías tests o atacantes propios, cópialos también.

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-22
   docker run --rm -it -p 8545:8545 -v "$PWD":/workspace bc-smartcontracts-dev
   bash test.sh
   ```

**Verifica**: `RegistryV3Test` da `8 passed` y `ClassicAttacksTest`, `7 passed`.
`EconomicAttacksTest` da `4 passed; 5 failed`: cuatro fallan con `WrongFee` porque envían más
que la tasa y tu registro solo acepta la exacta, y `test_RevertWhen_RefundRejected` espera
`TransferFailed` y recibe `WrongFee`.

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/`, `contracts/script/` | Los de la solución de la semana 21: tu referencia. Tú usas los tuyos |
| `contracts/src/Registry.sol` | Con un `// TODO (semana 22)` en `register`: el requisito 1 |
| `contracts/test/attackers/RefundReentrant.sol` | **Tu trabajo**: el atacante de la devolución, con su `// TODO:` y su pista |
| `contracts/test/attackers/` (el resto) | Los atacantes de la semana 21, resueltos |
| `contracts/test/EconomicAttacks.t.sol` | 9 tests: despliegan con tus scripts, actualizan a V3 y atacan. **No los modifiques** |
| `contracts/test/ClassicAttacks.t.sol` | Los 7 tests de la semana 21 |
| `contracts/test/RegistryV3.t.sol` | Los 8 de la semana 20. `test_RegisterPaysFeedFee` baja ahora el precio a 2000 en vez de subirlo a 3000: con la corrección, pagar de más ya no revierte |
| `test.sh` | `forge test`, y después `forge build --deny warnings` |

## Requisitos

| # | Dónde | Qué |
| - | ----- | --- |
| 1 | Tu `Registry`: `register`, `registerBySig`, `registerBatch` | Aceptan `msg.value >= fee` y devuelven el exceso a `msg.sender` al final, después del hook. Si la devolución falla, revierten con `TransferFailed(msg.sender, exceso)` |
| 2 | `attackers/RefundReentrant.sol` | En `receive`, la primera vez, da de alta `"dos"` con todo lo recibido y guarda su id |
| 3 | `week-22/audit/README.md` | El informe de la semana 21, con la revisión económica y el hallazgo H-02 |

Los tests que lo comprueban:

| Test | Clase | Qué mira |
| ---- | ----- | -------- |
| `test_RevertWhen_ExactQuoteAfterPriceMove` | Orden de transacciones | El feed se actualiza antes del alta y la tasa exacta de antes revierte con `WrongFee`. Reproduce H-02: pasa antes y después de corregir |
| `test_PriceMoveWithinMarginKeepsRegister` | Orden de transacciones | Con un 1 % de margen, el alta se hace, cobra la tasa nueva y devuelve el resto |
| `test_RevertWhen_PriceMovesBeyondMargin` | Orden de transacciones | Si la tasa sube más que el margen, `WrongFee` |
| `test_BatchRefundsExcess` | Orden de transacciones | Un lote que envía 1 ETH paga tres tasas y recupera el resto |
| `test_BySigRefundsRelayer` | Orden de transacciones | En una orden firmada, el recurso es de quien firma y la devolución, de quien paga |
| `test_FrontRunSignedOrderKeepsSigner` | Front-running | Quien adelanta una orden firmada la ejecuta a nombre de quien firmó, y la del relayer revierte con `InvalidSigner` |
| `test_RefundReentrancyPaysEveryRegister` | Reentrancy | Un contrato que vuelve a entrar con la devolución paga las dos tasas enteras |
| `test_RevertWhen_RefundRejected` | DoS | Quien no acepta ETH no puede pagar de más, pero sí la tasa exacta |
| `testFuzz_FeeRoundsInFavorOfRegistry` | Redondeo | Para cualquier precio y tasa, `fee` wei valen al menos la tasa, y uno menos ya no |

### El hallazgo: la tasa exacta

Tu `register` hace esto desde que cobra en ETH:

```solidity
uint256 fee = registrationFee();
if (msg.value != fee) revert WrongFee(fee, msg.value);
```

Cuando la tasa era una constante, era lo correcto. Desde la semana 20, `registrationFee` sale
del feed, y el feed de Chainlink se actualiza cada vez que el precio se mueve más de un umbral
(en ETH/USD de mainnet, un 0,5 %) o pasa su tiempo máximo. Tu página de la semana 18 pide la
tasa, el usuario firma, y la transacción espera en la mempool unos segundos. Si en esos segundos
entra antes una actualización del feed, la tasa ya no es la que el usuario envió, y el alta
revierte con `WrongFee`: el usuario paga el gas de una transacción fallida y tiene que volver a
empezar. En un día de mercado agitado, puede pasarle varias veces seguidas.

Es lo mismo que el slippage de un swap (teoría 03): el precio que ves al firmar no es el que
encuentras al ejecutar, porque otra transacción, en este caso la del oráculo, entra antes. No
roba nada, pero impide usar el registro justo cuando el precio se mueve. Severidad **baja**.

La corrección es la del swap: aceptar un margen y devolver lo que sobre.

```solidity
uint256 fee = registrationFee();
if (msg.value < fee) revert WrongFee(fee, msg.value);
uint256 id = _register(msg.sender, label);
_notifyHook(id, msg.sender, label);
_refundExcess(fee);
return id;
```

```solidity
// Devuelve a quien paga lo que envió de más sobre `fee`. Va lo último, con el alta escrita
// y el hook avisado (checks-effects-interactions): si quien recibe vuelve a entrar, paga su
// propia tasa. Con la tasa exacta no llama a nadie.
function _refundExcess(uint256 fee) internal {
    uint256 excess = msg.value - fee;
    if (excess == 0) return;
    (bool ok,) = msg.sender.call{value: excess}("");
    if (!ok) revert TransferFailed(msg.sender, excess);
}
```

Lo mismo en `registerBySig` y en `registerBatch` (en el lote, `fee` ya es la tasa por el
número de etiquetas). La devolución es una llamada externa nueva: por eso va al final, y por eso
el requisito 2 intenta volver a entrar por ella. El ABI no cambia: tu página y tu indexador
siguen funcionando, y la página puede empezar a enviar la tasa con un margen.

`multicall` no es `payable`: dentro, `msg.value` es 0 y nadie puede usar un mismo ETH para dos
altas.

## Cómo verificar

### Los tests

```bash
bash test.sh
```

**Verifica**: `8 passed`, `7 passed` y `9 passed`, y ningún warning en la compilación final.

### En anvil: el hallazgo y su corrección

Como en la semana 21, despliega **antes** de corregir el requisito 1: si ya lo corregiste,
guarda tu `Registry.sol` aparte y vuelve un momento a la versión de la semana 21.

En el contenedor del paso 3 de *Preparar la rama*, despliega hasta V3:

```bash
cd contracts
anvil --silent &
K0=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
K1=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
export ETHERSCAN_API_KEY=""
forge script script/DeployProtocol.s.sol --rpc-url anvil --broadcast --slow --private-key $K0 >/dev/null
export REGISTRY=$(jq -r '.transactions[] | select(.transactionType == "CREATE" and .contractName == "ERC1967Proxy") | .contractAddress' \
  broadcast/DeployProtocol.s.sol/31337/run-latest.json)
forge script script/UpgradeToV2.s.sol --rpc-url anvil --broadcast --slow --private-key $K0 >/dev/null
export PRICE_FEED=$(forge create lib/chainlink-contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol:MockV3Aggregator \
  --rpc-url anvil --broadcast --private-key $K0 --constructor-args 8 250000000000 | grep "Deployed to" | cut -d' ' -f3)
forge script script/UpgradeToV3.s.sol --rpc-url anvil --broadcast --slow --private-key $K0 >/dev/null
```

Pide la tasa como hace tu página, deja que el feed se actualice (ETH baja de 2500 a 2490) y envía
el alta con la tasa que pediste:

```bash
QUOTE=$(cast call $REGISTRY "registrationFee()(uint256)" --rpc-url anvil | cut -d' ' -f1)
echo $QUOTE
cast send $PRICE_FEED "updateAnswer(int256)" 249000000000 --private-key $K0 --rpc-url anvil >/dev/null
cast send $REGISTRY "register(string)" uno --value $QUOTE --private-key $K1 --rpc-url anvil 2>&1 | grep -o "WrongFee.*"
```

```text
10000000000000000
WrongFee(10040160642570282 [1.004e16], 10000000000000000 [1e16])
```

Un 0,4 % de movimiento basta. Ahora corrige el registro (requisito 1), llévalo al proxy con el
`PatchV3` de la semana 21 y envía la misma tasa con un 1 % de margen:

```bash
forge script script/PatchV3.s.sol --rpc-url anvil --broadcast --slow --private-key $K0 | grep -A1 "== Return"
cast send $REGISTRY "register(string)" uno --value $((QUOTE * 101 / 100)) --private-key $K1 --rpc-url anvil >/dev/null
cast balance $REGISTRY --rpc-url anvil
```

```text
== Return ==
0: address 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e
10040160642570282
```

El registro se queda exactamente la tasa nueva; el resto del 1 % volvió a la cuenta 1. La
dirección de la implementación es la de los contratos del starter; con los tuyos puede ser otra.

### En Sepolia

Como en la semana 21: `PatchV3` con tu keystore y `--verify`, o la propuesta al timelock si tu
administrador es el de la semana 13. Apunta la dirección nueva en el informe.

## El informe de auditoría

Copia tu informe de la semana 21 a `week-22/audit/README.md` y añade dos cosas:

1. **Revisión económica**: para cada clase de la semana, dónde podría aparecer en tu protocolo,
   qué lo defiende y qué test lo prueba. Si una clase no aplica, di por qué.
2. **H-02**: la tasa exacta, con el mismo formato que H-01.

```markdown
## Revisión económica (semana 22)

| Clase | Dónde podría aparecer | Defensa | Test |
| ----- | --------------------- | ------- | ---- |
| Manipulación de oráculos | `registrationFee` usa un precio externo | Chainlink, no reservas de un pool; `InvalidPrice`, `StalePrice` | `test_RevertWhen_PriceInvalidOrStale` |
| Flash loans | ... | ... | ... |
| Front-running y MEV | `registerBySig`, `registerWithPermit`, la tasa que cambia | ... | `test_FrontRunSignedOrderKeepsSigner`, ... |
| Redondeo | `registrationFee`, `registerBatch` | ... | `testFuzz_FeeRoundsInFavorOfRegistry` |

## Hallazgos

| Id | Título | Severidad | Estado |
| -- | ------ | --------- | ------ |
| H-01 | Un hook puede encarecer cada alta con un motivo de revert enorme | Baja | Corregido |
| H-02 | Una actualización del feed hace revertir las altas ya enviadas | Baja | Corregido |
```

Para flash loans, piensa en qué se decide con un saldo del momento: `LoyaltyToken` no presta,
pero `withdrawFees` envía `address(this).balance` y los puntos se cuentan con `balanceOf`. ¿Puede
alguien ganar algo teniendo mucho de algo durante una transacción?

## Ejemplos de adaptación

| Dominio | Qué se puede adelantar | Qué cambia en tu revisión |
| ------- | ---------------------- | ------------------------- |
| Biblioteca | Nada que sea único: dos socios pueden tener el mismo nombre | Front-running: no aplica a las altas; sí a la tasa que cambia |
| Tienda en línea | El nombre de una tienda, si lo haces único | Un front-runner que ve tu alta en la mempool registra tu nombre antes: necesitarías commit-reveal |
| Cine | La butaca de una sesión | Quien ve tu reserva en la mempool reserva esa butaca antes: commit-reveal, o asignar butacas en orden |

Si en tu dominio algo es único (un nombre, una butaca, un número), escribe el test del
front-running que lo roba y di en el informe cómo lo defiendes o por qué lo aceptas.

## Criterios de calidad (no automatizables)

- La devolución va al final de cada función que la hace, después del hook.
- Cada clase de la revisión económica dice dónde **podría** aparecer, aunque no aparezca.
- H-02 explica por qué la severidad es baja: qué pierde el usuario y qué no.
- Si tu página de la semana 18 envía la tasa exacta, el informe lo dice y propone el margen.

## Entrega

1. `bash test.sh` acaba con `8 passed`, `7 passed` y `9 passed`, sin warnings.
2. `week-22/audit/README.md` con la revisión económica y H-02. Si llevaste el parche a Sepolia,
   la dirección de la implementación nueva.
3. Commit y pull request:

   ```bash
   git add week-22
   git commit -m "fix(week-22): refund fee excess and add economic attack tests"
   git push -u origin week-22
   ```

   Abre el pull request `week-22` → `main` y fusiónalo cuando esté en verde.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Redondeo](../2-practicas/ejercicio-03-redondeo/README.md) | **Proyecto — Ataques económicos a tu protocolo** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
