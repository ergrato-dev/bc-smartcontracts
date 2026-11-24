# Proyecto — Tu protocolo en una L2

> Tu registro funciona en L1 y lo gobierna una DAO. Esta semana lo despliegas también en una L2,
> donde un alta cuesta céntimos. Con dos cambios que L1 no necesitaba: el precio no vale mientras
> el secuenciador está caído, y el registro de la L2 lo administra la misma DAO de L1, por
> mensajes.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 32 en
`main`.

## Capa que se añade y por qué ahora

Hasta ahora todo tu protocolo vive en una cadena. En una L2 cada alta cuesta mucho menos gas en
ETH, y para un registro con muchas altas pequeñas eso cambia quién puede usarlo. Pero desplegar en
la L2 con los mismos scripts deja dos huecos:

- **El precio.** `RegistryV3` cobra en dólares con el feed ETH/USD (semana 20). En la L2, si el
  secuenciador se cae, el feed no se actualiza y el registro cobraría con un precio viejo
  (teoría 02).
- **El dueño.** En L1 el administrador es el timelock de la DAO (semana 31). En la L2 no hay
  Governor ni votos: si el administrador fuera quien despliega, la DAO no mandaría allí.

La capa de esta semana tiene tres piezas:

- **El feed.** `SequencerAwareFeed`: un `AggregatorV3Interface` delante del feed de Chainlink que
  revierte con el secuenciador caído o recién vuelto (ejercicio 01). `RegistryV3` no cambia:
  `setFeeConfig` acepta cualquier feed.
- **El ejecutor.** `L2Executor`: el administrador del registro de la L2. Solo ejecuta lo que le
  llega por el mensajero del rollup y envió el timelock de L1 (ejercicio 02).
- **El despliegue.** `DeployToL2.s.sol`: después de `DeployProtocol`, `UpgradeToV2` y
  `UpgradeToV3` en la L2, despliega el feed y el ejecutor y les pasa el registro, como
  `HandOverToDao` en L1.

Ahora es cuando tienes todo lo necesario: los scripts de la 16, el feed de la 20, el modelo de
amenazas de la 26, los mutantes de la 24 y la DAO de la 31, que pasa a gobernar dos cadenas.

Tres decisiones de diseño:

- **La DAO se queda en L1.** Los votos están en el vault de L1. Un mensaje de L1 a la L2 tarda
  minutos; uno de vuelta, siete días (teoría 04). Gobernar desde L1 es lo rápido.
- **Un feed envoltorio y no un `RegistryV4`.** Actualizar el registro de la L2 sería otra
  implementación, otro mapa de storage y otra revisión. El envoltorio se pone con una llamada a
  `setFeeConfig`, y la DAO puede quitarlo con otra.
- **El guardián conserva la pausa.** Una propuesta tarda la votación más dos días de timelock.
  Para un incidente en la L2, el guardián pausa sin esperar a nadie.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-33
   ```

2. Copia el starter en `week-33/` y pon encima tus contratos, tus pruebas, tu gas guardado y tu
   informe de la semana 32:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-33-l2_y_cross_chain/3-proyecto/starter week-33
   cp -r week-32/contracts/src week-32/contracts/script week-32/contracts/snapshots week-33/contracts/
   cp -r week-32/contracts/test/invariant week-32/contracts/test/formal week-32/contracts/test/audit week-32/contracts/test/evm week-32/contracts/test/asm week-32/contracts/test/gas week-32/contracts/test/defi week-32/contracts/test/dao week-32/contracts/test/aa week-33/contracts/test/
   cp week-32/detectors/unpaused_register.py week-33/detectors/
   cp -r week-32/audit week-33/
   ls -l week-33/contracts/lib week-33/contracts/src/SequencerAwareFeed.sol week-33/contracts/src/L2Executor.sol week-33/contracts/script/DeployToL2.s.sol
   ```

   **Verifica**: `lib -> /opt/lib`, y los tres archivos nuevos existen: son los del starter, porque
   tu semana 32 no los tenía.

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-33
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   cd contracts
   forge test --mc OnL2Test
   ```

**Verifica**: `1 tests passed, 8 failed`. El registro de la L2 sigue con el feed de siempre y con
quien despliega como administrador:

```text
[FAIL: el registro lee el feed del secuenciador: 0x3D7Ebc40AF7092E3F1C81F2e996cbA5Cae2090d7 != 0xcae746B46013Bf4D43B8E2B9e98F9DBE2461532A] test_RegistersOnL2WhileTheSequencerIsUp() (gas: 433343)
[FAIL: assertion failed] test_HandOverLeavesOnlyTheExecutor() (gas: 28030)
```

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/`, `contracts/script/`, `contracts/test/` (salvo `l2/`) | Los de la solución de la semana 32: tu referencia. Tú usas los tuyos |
| `contracts/src/SequencerAwareFeed.sol` | El feed envoltorio, con la comprobación en su `// TODO (semana 33)` |
| `contracts/src/L2Executor.sol` | El ejecutor, con las dos comprobaciones en su `// TODO (semana 33)` |
| `contracts/src/ICrossDomainMessenger.sol` | La interfaz del mensajero del ejercicio 02 |
| `contracts/script/DeployToL2.s.sol` | El final del despliegue en la L2, con el traspaso en su `// TODO (semana 33)` |
| `contracts/test/l2/OnL2.t.sol` | Los nueve tests de la L2. **No los modifiques** |
| `contracts/test/l2/MockMessenger.sol` | Los dos mensajeros y el rollup en uno: `sendMessage` guarda y `relay` entrega |
| `contracts/foundry.toml`, `contracts/.env.example` | Los de la semana 32 con `op_sepolia` en `[rpc_endpoints]` y `[etherscan]`: úsalos tal cual |
| `mutants.sh` | Los treinta y tres mutantes de la semana 32 y cinco nuevos, de la L2. **No lo modifiques** |
| `test.sh`, `check-report.sh` | Los de la semana 32 |
| `detectors/` | El detector de la semana 23; pon encima el tuyo |

El `setUp` de `OnL2.t.sol` despliega dos veces en el mismo EVM. "L1": tus scripts de la semana 32
hasta `HandOverToDao`, y alice con los votos. "L2": `DeployProtocol`, `UpgradeToV2` y `UpgradeToV3`
con otro feed de precios, y al final `DeployToL2` con el timelock de L1 como `l1Dao`. El feed de
disponibilidad es un `MockV3Aggregator`: 0 en marcha, 1 caído.

## El despliegue en la L2

**Abre** `contracts/script/DeployToL2.s.sol` y resuelve el `TODO`:

```solidity
registry.setFeeConfig(l2.feed, registry.usdFee(), registry.maxPriceAge());
registry.grantRole(registry.DEFAULT_ADMIN_ROLE(), address(l2.executor));
registry.grantRole(registry.PAUSER_ROLE(), guardian);
registry.renounceRole(registry.DEFAULT_ADMIN_ROLE(), deployer);
```

Y borra la línea `(deployer, guardian);`, que solo evitaba los avisos de variables sin usar. El
orden importa: `setFeeConfig` es del administrador, y quien firma lo es hasta la última línea.

**Verifica**: `forge test --mc OnL2Test` da `5 tests passed, 4 failed`. El registro lee el feed
nuevo y solo el ejecutor lo administra, pero ni el feed ni el ejecutor comprueban nada:

```text
[FAIL: next call did not revert as expected] test_RevertWhen_TheSequencerIsDown() (gas: 165128)
[FAIL: next call did not revert as expected] test_RevertWhen_StrangerCallsTheExecutor() (gas: 63882)
```

El segundo es grave: con el ejecutor como administrador y sin comprobaciones, cualquiera
administra el registro de la L2.

## El feed del secuenciador

**Abre** `contracts/src/SequencerAwareFeed.sol` y escribe `_checkSequencer` con los pasos 3 y 4
del ejercicio 01:

```solidity
// forge-lint: disable-next-item(unused-return, block-timestamp)
function _checkSequencer() internal view {
    // Del feed de disponibilidad solo importan el estado y desde cuándo.
    // slither-disable-next-line unused-return
    (, int256 status, uint256 statusSince,,) = sequencerUptimeFeed.latestRoundData();
    if (status != 0) revert SequencerDown();
    // Unos segundos de un validador no cambian un plazo de una hora.
    // slither-disable-next-line timestamp
    if (block.timestamp - statusSince <= GRACE_PERIOD) revert GracePeriodNotOver(statusSince);
}
```

Los comentarios de `forge-lint` y de Slither justifican los dos avisos, como en
`RegistryV3.ethUsdPrice`: sin ellos, `test.sh` para en el análisis estático.

**Verifica**: `7 tests passed, 2 failed`. Las altas con puntos siguen con el secuenciador caído
(`test_PointsRegistrationsGoOnWhileDown`): no leen el precio.

## El ejecutor

**Abre** `contracts/src/L2Executor.sol` y pon en `execute`, antes del `emit`, las dos
comprobaciones del ejercicio 02:

```solidity
if (msg.sender != address(messenger)) revert NotMessenger(msg.sender);
address remoteSender = messenger.xDomainMessageSender();
if (remoteSender != l1Dao) revert NotL1Dao(remoteSender);
```

**Verifica**:

```bash
forge test --mc OnL2Test
```

`9 tests passed`. Y `forge test`, `79 tests passed, 0 failed`: los 70 de la semana 32 y los nueve
de esta. `test_DaoChangesTheL2FeeFromL1` recorre el camino entero: alice propone en L1, vota, la
propuesta espera los dos días del timelock, el timelock envía el mensaje, el rollup lo entrega y
la tasa de la L2 pasa a 30 dólares.

## El informe

**Abre** `week-33/audit/README.md` y añade la L2:

- En **Resumen**, que el protocolo vive en dos cadenas y qué dos dependencias nuevas trae: el
  secuenciador y el mensajero.
- En **Alcance**, `SequencerAwareFeed`, `L2Executor` y `DeployToL2.s.sol` (los roles que deja son
  una defensa). El mensajero y el puente del rollup, fuera, como el EntryPoint.
- En **Actores**, el secuenciador, cualquier remitente de L1 y el ejecutor. En **Activos**, el
  registro de la L2. En **Fronteras de confianza**, L1 → L2 por el mensajero y secuenciador →
  feed.
- En **Amenazas**, cinco filas nuevas:

  | Id | Amenaza | Defensa | Prueba |
  | -- | ------- | ------- | ------ |
  | T-25 | El secuenciador se cae y el registro cobra con un precio viejo | `SequencerAwareFeed` revierte con el feed de disponibilidad en 1 | `test_RevertWhen_TheSequencerIsDown` |
  | T-26 | El secuenciador acaba de volver y el precio aún no refleja el mercado | Plazo de gracia de una hora | `test_RevertWhen_TheSequencerJustCameBack` |
  | T-27 | Alguien administra el registro de la L2 sin la DAO | Solo el ejecutor es admin y comprueba mensajero y remitente | `test_HandOverLeavesOnlyTheExecutor`, `test_RevertWhen_StrangerCallsTheExecutor`, `test_RevertWhen_AnotherL1SenderMessagesTheExecutor` |
  | T-28 | Un incidente en la L2 espera a la DAO de L1 | El guardián pausa en la L2 | `test_GuardianPausesTheL2WithoutWaiting` |
  | T-29 | El secuenciador retrasa o reordena las altas de la L2 | Ninguna: riesgo aceptado | — |

- Una sección `## El protocolo en L2 (semana 33)`, antes de `## Hallazgos`, con: cómo se despliega
  en la L2, el feed y por qué un envoltorio, el camino de una propuesta de L1 a la L2 y cuánto
  tarda, qué prueba cada test, qué mutante mata cada uno, y lo que no hiciste.

T-29 es un riesgo aceptado, y el informe tiene que decir por qué: qué ofrece la L2 que elijas para
forzar una transacción por L1, cuánto tarda, y qué pierde un usuario de tu dominio si su alta
llega horas tarde.

## Cómo verificar

```bash
cd /workspace
bash test.sh
```

Tarda unos minutos: Medusa y los mutantes son lo más lento. Al final:

```text
✅ precio con el secuenciador caído: muerto
✅ sin plazo de gracia: muerto
✅ cualquiera llama al ejecutor: muerto
✅ obedece a cualquier remitente de L1: muerto
✅ quien despliega sigue de admin en L2: muerto
```

y el código de salida es 0. Por el camino, `check-report.sh` dice `✅ informe: secciones, commit,
hallazgos, gas y N pruebas citadas`, con tu N; `forge test`, `79 tests passed`; Halmos,
`Symbolic test result: 5 passed`; Slither, `0 result(s) found`; Medusa, `13 test(s) passed`; y
los treinta y ocho mutantes, muertos.

## En una testnet L2 (opcional)

Si tienes ETH de OP Sepolia (de un faucet o por el puente de Sepolia), el despliegue es el de la
semana 16 con otra red. Copia `.env.example` a `.env` y rellena tu clave de Etherscan. Busca en la
[página de Chainlink](https://docs.chain.link/data-feeds/l2-sequencer-feeds) el feed de
disponibilidad de OP Sepolia y, en la de los
[price feeds](https://docs.chain.link/data-feeds/price-feeds/addresses), el ETH/USD. Después, en
orden: `DeployProtocol`, `UpgradeToV2` y `UpgradeToV3` con `PRICE_FEED` de la L2, y por último:

```bash
REGISTRY=0x... L1_DAO=<tu timelock de Sepolia> SEQUENCER_UPTIME_FEED=0x... \
  forge script script/DeployToL2.s.sol --rpc-url op_sepolia --account sepolia-dev --broadcast --verify
```

Sin `L2_MESSENGER`, el script usa `0x4200000000000000000000000000000000000007`, el mensajero de
todas las cadenas del OP Stack. Guarda en el informe las direcciones de `broadcast/`.

## Ejemplos de adaptación

| Dominio | Qué gana en la L2 | Qué cambia la DAO desde L1 |
| ------- | ----------------- | -------------------------- |
| Biblioteca | Préstamos de céntimos para socios que piden muchos libros | La tasa por préstamo de la L2 |
| Tienda en línea | Pedidos pequeños cuyo gas en L1 costaría más que el pedido | La tasa y la pausa durante una incidencia |
| Cine | Reservas de butaca en el momento, sin esperar a un bloque de L1 | La tasa de reserva y el feed de precios |

En los tres, el feed, el ejecutor y el script son los mismos: cambian la tasa, el plazo de gracia
que tu dominio aguanta sin altas con ETH y la L2 que elijas.

## Criterios de calidad (no automatizables)

- Ninguna cuenta administra el registro de la L2 salvo el ejecutor, y el ejecutor solo obedece al
  timelock de L1.
- Cada comprobación del feed y del ejecutor tiene un test que rompe solo esa comprobación.
- El informe dice cuánto tarda una propuesta en llegar a la L2 y qué hace el guardián mientras.
- T-29 dice por qué se acepta, con los plazos de la L2 que elegiste.
- Ningún test del starter ni ningún mutante modificado para que pase.

## Entrega

1. Comprueba que `week-33/` no tiene `out/`, `cache/` ni `crytic-export/`, que sí tiene
   `contracts/snapshots/RegisterGasTest.json` y que no tiene `.env`.
2. Haz commit y sube la rama:

   ```bash
   git add week-33
   git commit -m "feat(week-33): deploy the protocol to an L2 governed from L1"
   git push -u origin week-33
   ```

3. Abre un pull request `week-33` → `main` y pega en la descripción la salida final de
   `bash test.sh`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Un puente de tokens](../2-practicas/ejercicio-03-un-puente-de-tokens/README.md) | **Proyecto — Tu protocolo en una L2** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
