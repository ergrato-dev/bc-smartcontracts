# Ejercicio 01 — Un contrato en varias cadenas

> Al terminar tendrás un contrato de vales firmados que se despliega en la misma dirección en L1 y
> en una L2 sin que un vale valga en las dos, y un lector de precios que no se fía del feed
> mientras el secuenciador de la L2 está caído o acaba de volver.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 02 — Desplegar en una L2](../../1-teoria/02-desplegar-en-una-l2.md)
leída.

## Contexto

Proyecto Foundry. Las dos cadenas viven en un solo EVM de pruebas: `vm.chainId` cambia
`block.chainid`, y `vm.snapshotState`/`vm.revertToState` deshacen un despliegue para repetirlo
"en la otra cadena". L1 es la cadena 1 y la L2, la 10 (OP Mainnet).

| Archivo | Qué es |
| ------- | ------ |
| `src/Vouchers.sol` | Vales EIP-712 de puntos: el paso 1 |
| `src/CrossChainAddress.sol` | Desplegar con la fábrica CREATE2 de Nick y predecir la dirección: el paso 2 |
| `src/L2PriceReader.sol` | El precio ETH/USD con el feed del secuenciador: pasos 3 y 4 |
| `test/MultiChain.t.sol` | Los tests de cada paso. No lo cambies |

El emisor de los vales firma con la clave `0xA11CE`. El feed de disponibilidad y el de precios
son `MockV3Aggregator` de Chainlink (semana 20): `updateAnswer(1)` simula que el secuenciador se
cae y `updateAnswer(0)`, que vuelve; en los dos casos `startedAt` pasa a ser `block.timestamp`.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-33-l2_y_cross_chain/2-practicas/ejercicio-01-un-contrato-en-varias-cadenas/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `4 tests passed, 7 failed`. El primero en rojo es el del paso 1:

```text
[FAIL: next call did not revert as expected] test_Paso1_RevertWhen_ReplayedAfterAChainSplit() (gas: 887415)
```

Los vales firmados para la cadena del despliegue ya funcionan. Lo que falla es que siguen
funcionando cuando la cadena cambia.

## Paso 1: El dominio con la cadena de ahora

**Por qué**: `Vouchers` guarda en `DEPLOY_CHAIN` la cadena en la que se desplegó y la mete en el
dominio EIP-712. Si la cadena se divide y la copia toma otro chain id, el contrato y su storage
siguen ahí, con el mismo `DEPLOY_CHAIN`: cada vale se canjea una vez en cada copia. El dominio
tiene que llevar la cadena en la que se canjea.

**Abre** `src/Vouchers.sol`. Borra las dos líneas que acaban en `// <- Paso 1` (la declaración de
`DEPLOY_CHAIN` y el `return` que la usa) y descomenta la de debajo de `// PASO 1`:

```solidity
return keccak256(abi.encode(DOMAIN_TYPEHASH, NAME_HASH, VERSION_HASH, block.chainid, address(this)));
```

**Verifica**: `5 tests passed, 6 failed`. Ahora rojo `TODO: Paso 2`:

```text
[FAIL: TODO: Paso 2] test_Paso2_SameAddressOnTwoChains() (gas: 1531350)
```

## Paso 2: La misma dirección en las dos cadenas

**Por qué**: con `new Vouchers(issuer)`, la dirección depende de tu nonce, que en cada cadena es
otro. Con CREATE2 desde la fábrica de Nick, depende solo de la fábrica, la sal y el código de
creación. `deploy` ya llama a la fábrica; falta `predict`, que da la dirección sin desplegar, para
que el emisor pueda firmar vales del contrato de la L2 antes de que exista.

**Abre** `src/CrossChainAddress.sol`, borra el `revert` y descomenta:

```solidity
bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), CREATE2_FACTORY, salt, keccak256(initCode)));
return address(uint160(uint256(hash)));
```

Es la fórmula de CREATE2 de la semana 10 con la fábrica como creador. `initCode` es
`type(Vouchers).creationCode` más los argumentos del constructor codificados: otro emisor, otra
dirección.

**Verifica**: `8 tests passed, 3 failed`. Pasan los tres del paso 2:

- `test_Paso2_SameAddressOnTwoChains`: el mismo contrato, en la cadena 1 y en la 10, en la misma
  dirección, que es la que dice `predict`.
- `test_Paso2_OtherArgumentsOtherAddress`: otro emisor u otra sal, otra dirección.
- `test_Paso2_RevertWhen_ReplayedOnTheTwinContract`: el gemelo de la L2 rechaza el vale firmado
  para L1. Misma dirección, mismo emisor y nonce sin usar: solo el chain id lo para. Sin el paso 1,
  este test fallaría.

## Paso 3: El secuenciador caído

**Por qué**: si el secuenciador de la L2 se cae, el feed ETH/USD se queda con su último precio y
`MAX_PRICE_AGE` no lo detecta hasta pasadas tres horas. El feed de disponibilidad sí lo sabe al
momento: su respuesta pasa a 1.

**Abre** `src/L2PriceReader.sol`. Borra la línea `(status, statusSince); // <- Paso 3` (solo
estaba para que el compilador no avise de variables sin usar) y descomenta la de `// PASO 3`:

```solidity
if (status != 0) revert SequencerDown();
```

**Verifica**: `9 tests passed, 2 failed`. Pero si el secuenciador acaba de volver, el precio pasa:

```text
[FAIL: next call did not revert as expected] test_Paso4_RevertWhen_SequencerJustCameBack() (gas: 357251)
```

## Paso 4: El plazo de gracia

**Por qué**: cuando el secuenciador vuelve, entran de golpe las transacciones que esperaban, y
quien pudo forzar las suyas por L1 durante la caída ya tiene ventaja. `startedAt` del feed de
disponibilidad dice desde cuándo está en marcha: hasta que pase `GRACE_PERIOD`, nada.

**Descomenta** la línea de `// PASO 4`:

```solidity
if (block.timestamp - statusSince <= GRACE_PERIOD) revert GracePeriodNotOver(statusSince);
```

`<=` y no `<`: `test_Paso4_RevertWhen_GracePeriodEndsThisSecond` lee justo cuando se cumple la
hora, y aún revierte.

**Verifica**: `11 tests passed, 0 failed`. Con `forge test --deny warnings`, sin warnings.

## Para pensar

- `EIP712` de OpenZeppelin guarda el separador al desplegar y lo recalcula solo si
  `block.chainid` cambió. ¿Por qué es mejor que calcularlo siempre? ¿Y que guardarlo siempre?
- Con la fábrica de Nick, ¿puede alguien desplegar `Vouchers` en una cadena donde tú no lo has
  hecho, en la dirección que tus usuarios esperan? ¿Con qué emisor?
- Si el feed de disponibilidad de Chainlink devolviera `startedAt = 0` (no inicializado), ¿qué
  haría tu paso 4?
- Una hora de gracia es la cifra del ejemplo de Chainlink. ¿Qué miras para elegirla en tu
  protocolo?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Mensajes entre cadenas](../../1-teoria/04-mensajes-entre-cadenas.md) | **Ejercicio 01 — Un contrato en varias cadenas** | [Ejercicio 02 — Mensajes entre cadenas →](../ejercicio-02-mensajes-entre-cadenas/README.md) |
