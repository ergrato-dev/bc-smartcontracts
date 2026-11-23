# Proyecto — Tasa en dólares con un oráculo

> Tu protocolo deja de cobrar una cantidad fija de ETH: con RegistryV3, la tasa de alta se fija
> en dólares y se convierte a ETH con el price feed ETH/USD de Chainlink, comprobado y
> redondeado a favor del protocolo. Llega por actualización: la dirección, los recursos y todo lo
> demás siguen donde estaban.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 19 en
`main`.

## Capa que se añade y por qué ahora

Desde la semana 07, tu alta cuesta `REGISTRATION_FEE`, 0,01 ETH. Lo que cuesta en dinero de
verdad depende del día: si el ETH se duplica, también tu tasa. Con un price feed, la tasa es
`usdFee` dólares y el contrato calcula los wei en cada alta.

Ahora es el momento porque tu protocolo ya está en Sepolia (semana 16), donde existe el feed
ETH/USD real, y se actualiza con el patrón de la semana 15. Es la última capa de la fase 4: la
semana 21 empieza a atacarla.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-20
   ```

2. Copia el starter en `week-20/` y pon encima tus contratos de la semana 19, sin tocar lo que
   trae el starter nuevo (`RegistryV3.sol`, `UpgradeToV3.s.sol`, `test/` y `foundry.toml`):

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-20-oraculos_y_datos_offchain/3-proyecto/starter week-20
   cp -r week-19/contracts/src week-19/contracts/script week-20/contracts/
   ls -l week-20/contracts/lib
   ```

   **Verifica**: `lib -> /opt/lib`. Si tenías tests propios en `week-19/contracts/test`, cópialos
   también.

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-20
   docker run --rm -it -p 8545:8545 -v "$PWD":/workspace bc-smartcontracts-dev
   bash test.sh
   ```

**Verifica**: no compila: tu `Registry` todavía no tiene `registrationFee()` y tu `RegistryV2`
no deja sobrescribir `version()`. Son los dos primeros requisitos.

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/Registry.sol`, `RegistryV2.sol` | Los del starter de la semana 19 con los dos cambios de los requisitos 1 y 2 hechos: tu referencia |
| `contracts/src/RegistryV3.sol` | **Tu trabajo**: tres funciones con `// TODO:` y su pista. Variables, eventos, errores, `initializeV3`, `setFeeConfig` y `version` están hechos |
| `contracts/script/UpgradeToV3.s.sol` | Despliega V3 y llama a `upgradeToAndCall` con `initializeV3`; al final lee `registrationFee()` para que un feed roto pare la simulación. Hecho |
| `contracts/test/RegistryV3.t.sol` | 8 tests: despliegan con tus scripts, actualizan a V2 y a V3 con un feed falso a 2500 dólares. **No los modifiques** |
| `contracts/foundry.toml` | Con el remapping `@chainlink/contracts/` y el optimizador (requisito 3) |
| `test.sh` | `forge test --deny warnings` en `contracts/` |

## Requisitos

| # | Dónde | Qué |
| - | ----- | --- |
| 1 | `Registry.sol` | `registrationFee()`, `public view virtual`, devuelve `REGISTRATION_FEE`. `register`, `registerBySig` y `registerBatch` cobran `registrationFee()` (por etiqueta en el lote), no la constante |
| 2 | `RegistryV2.sol` | `version()` pasa a `virtual override`, para que V3 la sobrescriba |
| 3 | `foundry.toml` | `optimizer = true` y `optimizer_runs = 200` (ver abajo) |
| 4 | `RegistryV3._setFeeConfig` | Feed distinto de `address(0)` (`ZeroAddress`), tasa y antigüedad mayores que 0 (`InvalidAmount`); guarda y emite `FeeConfigChanged` |
| 5 | `RegistryV3.ethUsdPrice` | El precio y los decimales del feed; `InvalidPrice` si no es positivo, `StalePrice` si tiene más de `maxPriceAge` |
| 6 | `RegistryV3.registrationFee` | `usdFee` dólares en wei, con `Math.mulDiv` y redondeo hacia arriba |

El cambio de los requisitos 1 y 2, tal como está en el `Registry.sol` del starter:

```solidity
/// @notice La tasa de un alta, en wei.
/// @dev Desde la semana 20, las altas leen la tasa de aquí y no de la constante:
///   RegistryV3 la sobrescribe para calcularla con un price feed.
function registrationFee() public view virtual returns (uint256) {
    return REGISTRATION_FEE;
}
```

```solidity
uint256 fee = registrationFee();
if (msg.value != fee) revert WrongFee(fee, msg.value);
```

Cambiar código de V1 no toca su storage: `registrationFee` es una función, no una variable. Lo
que ya está desplegado no cambia; el código nuevo llega con la implementación de V3.

### Por qué el optimizador

Sin él, tu RegistryV3 no se puede desplegar. Con el starter, `forge script` falla así:

```text
Error: `RegistryV3` is above the contract size limit (25851 > 24576).
```

La EVM no acepta código de más de 24 576 bytes (EIP-170). V3 hereda todo V1 y V2 y añade la
lectura del feed: se pasa. El optimizador de solc lo deja en 14 878. Los tests no lo detectan,
porque Foundry no aplica el límite en `forge test`: lo verías al desplegar.

Los tests que lo comprueban:

| Test | Qué mira |
| ---- | -------- |
| `test_Upgrade` | Versión 3, configuración del feed, y lo de V1 y V2 intacto (el alta de antes, `maxPerAccount`, el administrador) |
| `test_EthUsdPrice` | 2500 dólares con 8 decimales, y todavía válido justo a las 3 horas |
| `test_RevertWhen_PriceInvalidOrStale` | `InvalidPrice(0)`, `InvalidPrice(-1)` y un alta con el precio de hace 3 horas y 1 segundo |
| `test_RegistrationFee` | 0,01 ETH a 2500, 0,0125 a 2000 y 8333333333333334 wei a 3000 |
| `test_RegisterPaysFeedFee` | La tasa vieja da `WrongFee`, la del feed registra, el lote cobra una por etiqueta |
| `test_SetFeeConfig` | Solo el administrador; dirección 0 y ceros rechazados; evento; feed de 18 decimales |
| `test_RevertWhen_InitializeV3Twice` | `InvalidInitialization` |
| `test_RevertWhen_UpgradeWithBrokenFeed` | `UpgradeToV3` con un feed parado revierte con `StalePrice` |

## Cómo verificar

### Los tests

```bash
bash test.sh
```

**Verifica**: `8 passed; 0 failed`, y ningún warning en la compilación final. Mientras queden
`TODO` en V3, verás `[FAIL: TODO: _setFeeConfig] setUp()` y `0 passed; 1 failed`: el `setUp`
actualiza a V3 y `initializeV3` llama a `_setFeeConfig`, así que ningún test llega a empezar. Los
avisos `Unreachable code` en `Registry.sol` vienen de los `revert` de los `TODO` y desaparecen
al resolverlos.

### En anvil

En el contenedor del paso 3 de *Preparar la rama*, despliega el protocolo, actualiza a V2 y
despliega un feed falso a 2500 dólares (`250000000000`, con 8 decimales):

```bash
cd contracts
anvil --silent &
K0=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export ETHERSCAN_API_KEY=""
forge script script/DeployProtocol.s.sol --rpc-url anvil --broadcast --slow --private-key $K0 >/dev/null
export REGISTRY=$(jq -r '.transactions[] | select(.transactionType == "CREATE" and .contractName == "ERC1967Proxy") | .contractAddress' \
  broadcast/DeployProtocol.s.sol/31337/run-latest.json)
forge script script/UpgradeToV2.s.sol --rpc-url anvil --broadcast --slow --private-key $K0 >/dev/null
forge create lib/chainlink-contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol:MockV3Aggregator \
  --rpc-url anvil --broadcast --private-key $K0 --constructor-args 8 250000000000 | grep "Deployed to"
```

```text
Deployed to: 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853
```

Es la dirección con los contratos del starter en un anvil recién arrancado; con los tuyos puede
ser otra. Actualiza a V3 con ella:

```bash
export PRICE_FEED=0xa513E6E4b8f2a923D98304ec87F64353C4D5C853
forge script script/UpgradeToV3.s.sol --rpc-url anvil --broadcast --slow --private-key $K0 | grep ONCHAIN
cast call $REGISTRY "version()(uint256)" --rpc-url anvil
cast call $REGISTRY "registrationFee()(uint256)" --rpc-url anvil
```

```text
ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
3
10000000000000000 [1e16]
```

A 2500 dólares, 25 dólares son los mismos 0,01 ETH de antes. Sube el ETH a 3000 y da un alta con
la cuenta 1 de anvil, primero con la tasa vieja y después con la nueva:

```bash
K1=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
cast send $PRICE_FEED "updateAnswer(int256)" 300000000000 --private-key $K0 --rpc-url anvil >/dev/null
FEE=$(cast call $REGISTRY "registrationFee()(uint256)" --rpc-url anvil | cut -d' ' -f1)
echo $FEE
cast send $REGISTRY "register(string)" uno --value 0.01ether --private-key $K1 --rpc-url anvil
cast send $REGISTRY "register(string)" uno --value $FEE --private-key $K1 --rpc-url anvil | grep status
```

```text
8333333333333334
Error: ... WrongFee(8333333333333334 [8.333e15], 10000000000000000 [1e16])
status               1 (success)
```

Y deja pasar 3 horas sin rondas nuevas:

```bash
cast rpc evm_increaseTime 10801 --rpc-url anvil >/dev/null
cast rpc evm_mine --rpc-url anvil >/dev/null
cast send $REGISTRY "register(string)" dos --value $FEE --private-key $K1 --rpc-url anvil
```

```text
Error: ... StalePrice(<hora de la última ronda>, 10800 [1.08e4])
```

El protocolo deja de cobrar en vez de cobrar con un precio viejo.

### En Sepolia

Tu registro de la semana 16 está en Sepolia. Si todavía es V1, actualízalo antes a V2 con
`UpgradeToV2.s.sol`, como en la semana 15. Después, con el feed ETH/USD real (teoría 01):

```bash
export REGISTRY=<tu proxy en Sepolia> PRICE_FEED=0x694AA1769357215DE4FAC081bf1f309aDC325306
forge script script/UpgradeToV3.s.sol --rpc-url sepolia --account <tu keystore> --broadcast --verify
cast call $REGISTRY "registrationFee()(uint256)" --rpc-url sepolia
```

`USD_FEE` (25 dólares) y `MAX_PRICE_AGE` (3 horas) tienen valores por defecto en el script; ponlos
en el entorno si quieres otros. Si tu administrador es el timelock de la semana 13, la
actualización pasa por su propuesta y su plazo, como la de V2.

### Tu página

La página de la semana 18 lee `REGISTRATION_FEE` para el `value` del alta: con V3, esa constante
ya no es la tasa y el alta revierte con `WrongFee`. En `week-18/web`:

1. En `scripts/abi.sh`, cambia `../contracts` por `../../week-20/contracts` y `RegistryV2` por
   `RegistryV3`, y ejecuta `pnpm abi`.
2. En tus hooks, lee `registrationFee` donde leías `REGISTRATION_FEE`, justo antes de enviar el
   alta: un precio leído al cargar la página puede tener ya otra ronda encima.

## Ejemplos de adaptación

| Dominio | Tasa en dólares | Antigüedad máxima |
| ------- | --------------- | ----------------- |
| Biblioteca | 5 dólares por carné | 3 horas: el latido de 1 hora más margen para retrasos |
| Tienda en línea | 20 dólares por alta de vendedor | 3 horas |
| Cine | 8 dólares por butaca reservada | 1 hora y 5 minutos: la reserva se paga justo antes de la sesión y el precio debe ser del momento |

Los nombres de errores y eventos van en inglés y con tu dominio si los cambias; los comentarios,
en español.

## Criterios de calidad (no automatizables)

- Tu contrato guarda la dirección del **proxy** del feed, nunca la de su agregador.
- La antigüedad máxima está justificada en tu README con el latido del feed que usas.
- Ninguna conversión supone los decimales del feed: los lee.
- Cobrar redondea hacia arriba; nada en tu protocolo redondea a favor de quien paga.
- Tu README dice en qué confías: en la red de Chainlink y en quien puede cambiar el feed
  (`setFeeConfig`, tu administrador).
- Las tres variables de V3 van al final del storage, detrás de las de V2.

## Entrega

1. `bash test.sh` acaba en `8 passed; 0 failed`.
2. Tu README de `week-20/` dice qué feed usas en Sepolia, con qué `USD_FEE` y `MAX_PRICE_AGE`, y la
   dirección de la implementación V3 verificada.
3. Commit y pull request:

   ```bash
   git add week-20
   git commit -m "feat(week-20): add USD registration fee with Chainlink price feed"
   git push -u origin week-20
   ```

   Abre el pull request `week-20` → `main` y fusiónalo cuando esté en verde.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Metadatos en IPFS](../2-practicas/ejercicio-03-metadatos-en-ipfs/README.md) | **Proyecto — Tasa en dólares con un oráculo** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
