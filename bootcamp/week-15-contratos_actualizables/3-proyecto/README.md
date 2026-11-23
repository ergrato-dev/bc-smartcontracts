# Proyecto — Registro actualizable

> Decimoquinta capa del protocolo de tu dominio: el registro pasa a vivir detrás de un proxy
> UUPS. La dirección que usan tus miembros ya no cambia, y una versión 2 llega por
> actualización sin perder los recursos, los puntos ni los certificados.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados y tu proyecto de la
semana 14 en `main`.

## Capa que se añade y por qué ahora

Hasta la semana 14, corregir un fallo del registro exigía desplegar otro y pedir a todos que
usaran la dirección nueva. Los recursos, los puntos y los certificados se quedaban en el
viejo. Esta semana:

- **El registro es UUPS**: hereda de las bases upgradeable de OpenZeppelin
  (`AccessControlUpgradeable`, `PausableUpgradeable`, `EIP712Upgradeable`, `NoncesUpgradeable`
  y `UUPSUpgradeable`) y se usa a través de un `ERC1967Proxy`.
- **El constructor pasa a `initialize`**, que el proxy llama al desplegarse, y la
  implementación queda cerrada con `_disableInitializers()`.
- **La capacidad, el token y el certificado pasan de `immutable` a storage**: una variable
  `immutable` vive en el código de la implementación, y el proxy no la ve (teoría 03). Sus
  nombres pasan a minúsculas: `capacity()`, `loyalty()` y `certificate()`.
- **El token y el certificado se despliegan antes que el proxy**, con la dirección que tendrá
  el proxy. Más abajo verás por qué.
- **Solo `DEFAULT_ADMIN_ROLE` actualiza**: tras el traspaso de la semana 13, el timelock. Una
  actualización espera su plazo, como cualquier otro cambio de configuración.
- **`RegistryV2`**: como mucho `maxPerAccount` altas por cuenta, en una variable nueva al
  final del storage, inicializada con `reinitializer(2)` al actualizar.

En la semana 16 desplegarás todo esto en una testnet pública con `forge script`.

**El dominio te lo asigna el instructor.** Usa los nombres, la tasa y la colección de tus
semanas anteriores.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-15
   ```

2. Copia el starter entero, con su `.gitignore`, en una carpeta `week-15/` (ajusta la ruta a
   donde clonaste el bootcamp). Después trae tus pruebas de fuzzing y de fork y el
   `.gas-snapshot` de la semana 14:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-15-contratos_actualizables/3-proyecto/starter week-15
   cp week-14/test/RegistryFuzz.t.sol week-14/test/RegistryFork.t.sol week-15/test/
   cp week-14/.gas-snapshot week-15/
   ```

3. Pon los nombres de tu dominio: en `week-15/src/Registry.sol`, los del registro y la tasa;
   en `week-15/src/LoyaltyToken.sol` y `week-15/src/Certificate.sol`, el nombre y el símbolo
   del token y de la colección.

4. Adapta tu `RegistryFuzz.t.sol` al proxy, como ya están los demás tests: importa
   `DeployRegistry`, hereda de él y despliega con `deployRegistry`:

   ```solidity
   import {DeployRegistry} from "./DeployRegistry.sol";

   contract RegistryFuzzTest is Test, DeployRegistry {
       // ...
       registry = deployRegistry(capacity); // antes: new Registry(capacity)
   ```

   Si usaba `CAPACITY()`, `LOYALTY()` o `CERTIFICATE()`, pasa a `capacity()`, `loyalty()` y
   `certificate()`. `RegistryFork.t.sol` no cambia: usa la dirección que le das.

5. Entra al contenedor y mira el rojo:

   ```bash
   cd week-15
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   forge test
   ```

**Verifica**: `117 tests passed, 21 failed, 1 skipped (139 total tests)`. Fallan:

- 12 de los 15 de `RegistryUpgrade.t.sol`: la mayoría con `TODO: _authorizeUpgrade`, y
  `test_ImplementationIsClosed`, `test_V2ImplementationIsClosed` y
  `test_RevertWhen_TokenPointsToAnotherRegistry` con `next call did not revert as expected`.
- 8 de los 14 de `RegistrySig.t.sol`, con `InvalidSigner` o con el nombre del dominio vacío:
  sin `__EIP712_init`, el dominio EIP-712 no tiene nombre y ninguna firma coincide.
- `test_UpgradeOnlyThroughTheTimelock`, en `RegistryTimelock.t.sol`.

Si ves `114 passed, 24 failed`, te faltan los nombres del paso 3.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml`, `.gitignore` | Con los remappings de OpenZeppelin y de OpenZeppelin Upgradeable. No los cambies |
| `src/Registry.sol` | Tu registro de la semana 14, ya con las bases upgradeable, `capacity`, `loyalty` y `certificate` en storage, `initialize`, `version()`, `WrongRegistry` y sus `// TODO:` |
| `src/RegistryV2.sol` | La versión 2: `maxPerAccount`, `TooManyItems`, `initializeV2` y el `_register` que limita, con sus `// TODO:` |
| `src/LoyaltyToken.sol`, `src/Certificate.sol` | Tu token y tu colección, sin los nombres. Su constructor recibe la dirección del registro, en vez de tomar `msg.sender` |
| `src/` (resto) | `IRegistry`, `LabelLib`, `IERC165` e `IRegistrationHook`, sin cambios |
| `test/DeployRegistry.sol` | `deployRegistry(capacity)` y `deployRegistryFrom(deployer, capacity)`: despliegan la implementación, el token, el certificado y el proxy |
| `test/` de la semana 14 | Los mismos tests, desplegando con `deployRegistry`. **No los modifiques** |
| `test/RegistryUpgrade.t.sol` | 15 tests del proxy, de quién actualiza y de la actualización a V2. **No lo modifiques** |

En `Registry.sol`, `_idsOf` pasa de `private` a `internal` para que V2 lo lea, y `_register`
es `virtual` para que V2 lo amplíe.

## Requisitos

1. **La implementación está cerrada**: el constructor llama a `_disableInitializers()`.
2. **`initialize(capacity, token, nft)`**, con `initializer`, comprueba que la capacidad es
   mayor que 0 y que el token y el certificado tienen este proxy como registro
   (`WrongRegistry`). Llama a `__AccessControl_init`, `__Pausable_init`,
   `__EIP712_init(PROTOCOL_NAME, "1")` y `__Nonces_init`, y da `DEFAULT_ADMIN_ROLE` a
   `msg.sender`.
3. **`_authorizeUpgrade` exige `DEFAULT_ADMIN_ROLE`.**
4. **`RegistryV2.initializeV2(max)`**, con `reinitializer(2)`, rechaza `max == 0`
   (`InvalidAmount`) y lo guarda en `maxPerAccount`.
5. **`RegistryV2._register`** revierte con `TooManyItems(registrant, maxPerAccount)` si
   `registrant` ya tiene `maxPerAccount` altas. Así aplica a todas las altas: con ETH, en
   lote, con firma y con puntos.
6. **El layout de V2 solo añade al final**: compruébalo con `forge inspect` (más abajo).
7. **Tus propiedades de fuzzing siguen siendo ciertas**, `.gas-snapshot` actualizado y
   `forge snapshot --fuzz-seed 1 --check` en verde.
8. **Desplegado en anvil** desde la cuenta de tu `INDEX`, a través del proxy: un alta en V1, la
   actualización a V2 y el límite de V2 en acción. El test de fork pasa contra el proxy.

## Por qué el token y el certificado van antes

En la semana 14, el constructor del registro creaba el token y el certificado con `new`. En
`initialize` no se puede hacer lo mismo, por dos motivos:

- **El tamaño.** El bytecode de un constructor no cuenta para el límite de 24 KiB (EIP-170):
  solo el código que queda desplegado. Pero `initialize` es una función normal, y el código de
  un `new` dentro de ella lleva entero el bytecode del contrato que crea. Con `new` en
  `initialize`, `forge build --sizes` da esto:

  ```
  | Registry           | 44,225           | 44,728            | -19,649            | 4,424               |
  ```

  44 KiB, casi el doble del límite: anvil y cualquier red rechazarían el despliegue. Con el
  token y el certificado fuera:

  ```
  | Registry           | 22,014           | 22,517            | 2,562              | 26,635              |
  ```

- **Quién despliega.** El token y el certificado guardan como registro a quien los despliega.
  Creados desde la implementación, su registro sería la implementación y no el proxy.

Así que se despliegan antes, con la dirección del proxy en su constructor. Esa dirección se
conoce antes de que exista: la de un contrato creado con `CREATE` sale de quien lo despliega y
de su nonce (semana 02, `cast compute-address`). Si despliegas la implementación, el token, el
certificado y el proxy en este orden, el proxy tiene el nonce del token más 2. Si te equivocas
de nonce, `initialize` lo detecta: el token apunta a otra dirección, y el proxy revierte con
`WrongRegistry` al desplegarse. `DeployRegistry.sol` hace lo mismo en los tests con
`vm.computeCreateAddress`.

## Cómo verificar

```bash
forge test
```

**Verifica**: `138 tests passed, 0 failed, 1 skipped (139 total tests)`, sin warnings
(`forge test --deny warnings`). Fíjate en `test_UpgradeKeepsItemsPointsAndCertificates`:
tras actualizar, el recurso, el saldo de puntos, el certificado, el rol de administrador y las
tasas siguen en el mismo proxy.

Al compilar con `forge build`, el linter avisa de tres `reentrancy-events` nuevos, en
`withdrawFees`, `setHook` y `removeHook`:

```
warning[reentrancy-events]: event emitted after an external call; reentrancy can reorder or fabricate logs that off-chain consumers rely on
```

No hay ninguna llamada externa nueva: `onlyRole` de `AccessControlUpgradeable` lee los roles
de su slot de ERC-7201 con `assembly`, y el linter lo toma por una llamada. Se silencian las
tres líneas diciendo por qué:

```solidity
        // `onlyRole` lee los roles de su slot de ERC-7201 con assembly y el linter lo toma por una llamada.
        // forge-lint: disable-next-line(reentrancy-events)
        emit FeesWithdrawn(to, amount);
```

Los dos avisos de reentrada de `registerWithPoints`, los de la semana 13, siguen igual.

### El layout de V2

```bash
diff <(forge inspect Registry storageLayout --json | jq -r '.storage[] | "\(.slot) \(.label)"') \
     <(forge inspect RegistryV2 storageLayout --json | jq -r '.storage[] | "\(.slot) \(.label)"')
```

```
8a9
> 8 maxPerAccount
```

**Verifica**: la única diferencia es una línea nueva, `maxPerAccount` en el slot 8, detrás de
`hook` (slot 7). Si `diff` mostrara una línea cambiada (`<` y `>` en el mismo slot), V2 leería
mal el estado de V1.

### Lo que cuesta la capa nueva

```bash
forge snapshot --fuzz-seed 1 --diff
```

```
↑ RegistryTest::test_RegisterStoresItem() (gas: 299451 → 313806 | 14355 4.794%)
↑ RegistryTest::test_AdminAndCapacityAreSetAtDeploy() (gas: 8501673 → 9803588 | 1301915 15.314%)
```

Un alta cuesta unos 14.000 de gas más. Cada llamada pasa por el proxy, que lee el slot de la
implementación y hace un `delegatecall` a otra dirección. Además, la capacidad, el token y el
certificado ya no son `immutable` (gratis, en el código) sino storage, y cada uno cuesta un
`SLOAD`. Desplegar también sube: son cuatro contratos en vez de uno. Es el precio de poder
actualizar. Tus números serán otros. Después regenera y comprueba:

```bash
forge snapshot --fuzz-seed 1
forge snapshot --fuzz-seed 1 --check
```

### En anvil: desplegar detrás del proxy

Con `anvil --silent &` recién arrancado, la clave de tu `INDEX` (aquí `3`, capacidad `50` y
tasa `0.01 ether`, los de los ejemplos) y la cuenta `5` como miembro. Para ir al grano, aquí
tú sigues de administrador; en tu protocolo de verdad, la actualización pasaría por el
timelock de la semana 13.

`--json` va antes que `--constructor-args`: todo lo que sigue a `--constructor-args` se toma
como argumento del constructor.

```bash
M="test test test test test test test test test test test junk"
PK=$(cast wallet private-key "$M" 3); ME=$(cast wallet address "$PK")
PK5=$(cast wallet private-key "$M" 5); MEMBER=$(cast wallet address "$PK5")
IMPL=$(forge create src/Registry.sol:Registry --private-key "$PK" --broadcast --json | jq -r .deployedTo); echo $IMPL
PROXY=$(cast compute-address $ME --nonce $(( $(cast nonce $ME) + 2 ))); echo $PROXY
LOYALTY=$(forge create src/LoyaltyToken.sol:LoyaltyToken --private-key "$PK" --broadcast --json --constructor-args $PROXY | jq -r .deployedTo)
CERT=$(forge create src/Certificate.sol:Certificate --private-key "$PK" --broadcast --json --constructor-args $PROXY | jq -r .deployedTo)
INIT=$(cast calldata "initialize(uint256,address,address)" 50 $LOYALTY $CERT)
forge create /opt/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy \
  --private-key "$PK" --broadcast --json --constructor-args $IMPL $INIT | jq -r .deployedTo
REGISTRY=$PROXY
```

```
0x057ef64E23666F000b34aE31332854aCBd1c8544
0xCba6b9A951749B8735C603e7fFC5151849248772
0xCba6b9A951749B8735C603e7fFC5151849248772
```

La implementación, la dirección predicha y la del proxy desplegado: las dos últimas
coinciden. El registro es el proxy, `0xCba6…`. La implementación, `0x057e…`, es la dirección
que tenía el registro de la semana 14 con la misma cuenta. Ahora pon el hook, y el miembro
registra en V1:

```bash
cast call $REGISTRY "version()(uint256)"
cast call $REGISTRY "capacity()(uint256)"
cast send $REGISTRY "setHook(address)" $LOYALTY --private-key "$PK" --json | jq -r .status
cast send $REGISTRY "register(string)" first --value 0.01ether --private-key "$PK5" --json | jq -r .status
cast storage $REGISTRY 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
```

```
1
50
0x1
0x1
0x000000000000000000000000057ef64e23666f000b34ae31332854acbd1c8544
```

### En anvil: actualizar a V2

Despliega `RegistryV2` y actualiza con un máximo de 2 altas por cuenta. Primero lo intenta el
miembro:

```bash
V2=$(forge create src/RegistryV2.sol:RegistryV2 --private-key "$PK" --broadcast --json | jq -r .deployedTo); echo $V2
INIT2=$(cast calldata "initializeV2(uint256)" 2)
cast send $REGISTRY "upgradeToAndCall(address,bytes)" $V2 $INIT2 --private-key "$PK5"
cast send $REGISTRY "upgradeToAndCall(address,bytes)" $V2 $INIT2 --private-key "$PK" --json | jq -c '[.status, (.logs | length)]'
cast storage $REGISTRY 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
```

```
0xcf27F781841484d5CF7e155b44954D7224caF1dD
Error: ... custom error 0xe2517d3f: 0000000000000000000000009965507d1a55bcc2695c58ba16fb37d819b0a4dc0000000000000000000000000000000000000000000000000000000000000000, ...
["0x1",2]
0x000000000000000000000000cf27f781841484d5cf7e155b44954d7224caf1dd
```

`0xe2517d3f` es `AccessControlUnauthorizedAccount`: el miembro y el rol `0x00…00`,
`DEFAULT_ADMIN_ROLE`. Tu actualización emite `Upgraded` e `Initialized(2)`, y el slot de la
implementación apunta a V2. Comprueba que todo sigue:

```bash
cast call $REGISTRY "version()(uint256)"
cast call $REGISTRY "maxPerAccount()(uint256)"
cast call $REGISTRY "count()(uint256)"
cast call $CERT "ownerOf(uint256)(address)" 1
cast call $LOYALTY "balanceOf(address)(uint256)" $MEMBER
```

```
2
2
1
0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc
10000000000000000000 [1e19]
```

El miembro registra una segunda vez (cabe) y una tercera (no cabe). Después intenta
inicializar la implementación de V2 directamente:

```bash
cast send $REGISTRY "register(string)" second --value 0.01ether --private-key "$PK5" --json | jq -r .status
cast send $REGISTRY "register(string)" third --value 0.01ether --private-key "$PK5"
cast sig "TooManyItems(address,uint256)"
cast send $V2 "initializeV2(uint256)" 9 --private-key "$PK5"
```

```
0x1
Error: ... custom error 0x5e9543f3: 0000000000000000000000009965507d1a55bcc2695c58ba16fb37d819b0a4dc0000000000000000000000000000000000000000000000000000000000000002, ...
0x5e9543f3
Error: ... custom error 0xf92ee8a9, data: "0xf92ee8a9": InvalidInitialization
```

**Verifica**: el test de fork, sin cambios, contra el proxy:

```bash
FORK_URL=http://127.0.0.1:8545 REGISTRY="$REGISTRY" forge test --match-path test/RegistryFork.t.sol
```

`[PASS] test_Fork_RegistersOnACopy()`. El test no sabe que hay un proxy: usa la dirección
de siempre.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna:

| Dominio | Qué trae la V2 | Por qué por actualización y no con otro despliegue |
| ------- | -------------- | -------------------------------------------------- |
| Biblioteca | Como mucho 3 préstamos especiales por socio | Los socios y sus carnés (certificados) siguen en la misma dirección |
| Tienda en línea | Como mucho 5 catálogos por vendedor | Los vendedores ya enlazaron la dirección del registro en su web |
| Cine | Como mucho 4 butacas por espectador en un estreno | Las reservas pagadas y los puntos de fidelidad no se pierden |

## Criterios de calidad (no automatizables)

- Sabes explicar por qué la capacidad no puede seguir siendo `immutable`.
- Sabes explicar por qué el token y el certificado se despliegan antes que el proxy.
- Sabes explicar qué pasaría si `initialize` se llamara en una transacción aparte.
- Sabes explicar por qué `maxPerAccount` va en `RegistryV2` y no delante de `count`.
- Sabes explicar quién puede actualizar tu registro tras el traspaso al timelock, y cuánto
  tarda.
- Sin `TODO` restantes, y los nombres son de tu dominio.

## Entrega

```bash
git add week-15
git commit -m "feat(week-15): make the registry upgradeable with UUPS"
git push -u origin week-15
```

Abre un pull request `week-15` → `main` en tu repositorio. En la descripción pega la salida
de `forge test`, el `diff` del layout, el slot de la implementación antes y después de la
actualización y el error `TooManyItems` de la tercera alta.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — UUPS y storage layout](../2-practicas/ejercicio-03-uups-y-storage-layout/README.md) | **Proyecto — Registro actualizable** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
