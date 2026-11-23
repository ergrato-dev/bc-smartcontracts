# Proyecto — Despliegue en Sepolia

> Decimosexta capa del protocolo de tu dominio: el despliegue deja de ser una lista de comandos y
> pasa a dos scripts probados. Con ellos lo ensayas en anvil, lo despliegas en Sepolia firmando
> con tu keystore, lo verificas y lo actualizas a V2. Desde hoy, tu protocolo tiene una
> dirección pública que cualquiera puede leer.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados, tu proyecto de la semana 15 en
`main` y una cuenta `sepolia-dev` en un keystore montado fuera del contenedor (teoría 02).

## Capa que se añade y por qué ahora

En la semana 15 desplegaste el registro con cinco comandos en un orden que no admitía errores.
Esta semana:

- **`script/DeployProtocol.s.sol`** despliega la implementación, el token, el certificado y el
  `ERC1967Proxy`, y conecta el token como hook. Cinco transacciones, en un comando.
- **`script/UpgradeToV2.s.sol`** despliega `RegistryV2` y actualiza el proxy con
  `initializeV2`, en una transacción.
- **Los dos scripts tienen tests** (`test/DeployProtocol.t.sol`, `test/UpgradeToV2.t.sol`), que
  los ejecutan como en una red.
- **`foundry.toml`** gana los alias `anvil` y `sepolia` y la clave de Etherscan, leídas de
  `.env`, y llega a las bibliotecas por `lib`, un enlace a `/opt/lib` (teoría 04).
- **En Sepolia**: el protocolo desplegado y verificado, una alta de verdad, el test de fork
  contra él y la actualización a V2. El registro de la ejecución
  (`broadcast/.../11155111/run-latest.json`) va a tu repositorio.

Quien firma queda como administrador del registro. En Sepolia es tu cuenta `sepolia-dev`; el
traspaso al timelock de la semana 13 sería el paso siguiente en una red de verdad.

**El dominio te lo asigna el instructor.** Usa los nombres, la tasa y la colección de tus
semanas anteriores.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-16
   ```

2. Copia el starter entero, con `.gitignore`, `.env.example` y el enlace `lib`, en una carpeta
   `week-16/`. Después trae tus pruebas de fuzzing y de fork y el `.gas-snapshot` de la
   semana 15:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-16-despliegue_y_verificacion/3-proyecto/starter week-16
   cp week-15/test/RegistryFuzz.t.sol week-15/test/RegistryFork.t.sol week-16/test/
   cp week-15/.gas-snapshot week-16/
   ls -l week-16/lib
   ```

   **Verifica**: `lib -> /opt/lib`. Fuera del contenedor el enlace no lleva a ningún sitio; dentro,
   a las bibliotecas de la imagen.

3. Pon los nombres de tu dominio, como en la semana 15: en `src/Registry.sol`, los del registro
   y la tasa; en `src/LoyaltyToken.sol` y `src/Certificate.sol`, el nombre y el símbolo.

4. Crea tu `.env` desde la plantilla. Si tienes clave de Etherscan, ponla; si no, deja la línea
   vacía y verificarás en Sourcify:

   ```bash
   cp week-16/.env.example week-16/.env
   ```

5. Entra al contenedor, con tus keystores montados, y mira el rojo:

   ```bash
   cd week-16
   docker run --rm -it -v "$PWD":/workspace \
     -v "$HOME/.foundry/keystores":/home/ubuntu/.foundry/keystores bc-smartcontracts-dev
   forge test
   ```

**Verifica**: `138 tests passed, 2 failed, 1 skipped (141 total tests)`. Fallan los `setUp()` de
`DeployProtocol.t.sol` y `UpgradeToV2.t.sol`, con `TODO: deploy`: los 14 tests de los scripts
no llegan a ejecutarse. Si ves `135 passed, 5 failed`, te faltan los nombres del paso 3.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml`, `.gitignore`, `.env.example`, `lib` | La configuración con los alias de red, el enlace a las bibliotecas y lo que git ignora. No los cambies |
| `src/` | Tu protocolo de la semana 15, resuelto y sin los nombres del dominio |
| `script/DeployProtocol.s.sol` | El script de despliegue, con `Deployment` y los `// TODO:` de `run` y `deploy` |
| `script/UpgradeToV2.s.sol` | El script de actualización, con `run` hecho y el `// TODO:` de `upgrade` |
| `test/DeployProtocol.t.sol` | 9 tests del despliegue. **No lo modifiques** |
| `test/UpgradeToV2.t.sol` | 5 tests de la actualización. **No lo modifiques** |
| `test/` (resto) | Los tests de la semana 15, sin cambios, con `test/DeployRegistry.sol` |

El `.gitignore` ignora `broadcast/*/31337/` y las simulaciones, pero **no** los registros de
Sepolia: esos se versionan.

## Requisitos

1. **`DeployProtocol.run()`** despliega con la capacidad de `CAPACITY`, 50 por defecto.
2. **`DeployProtocol.deploy(capacity)`** emite, en este orden, la implementación, el token y el
   certificado (con la dirección predicha del proxy), el `ERC1967Proxy` con `initialize`, y
   `setHook` con el token. Quien firma, con `vm.readCallers()`.
3. **`UpgradeToV2.upgrade(registry, max)`** emite `new RegistryV2()` y `upgradeToAndCall` con
   `initializeV2(max)`.
4. **Tests en verde**: `forge test --deny warnings` pasa 152 y salta el de fork;
   `.gas-snapshot` actualizado y `forge snapshot --fuzz-seed 1 --check` en verde.
5. **Ensayo en anvil** con un keystore: despliegue, una alta, el test de fork y la actualización.
6. **Desplegado en Sepolia** con `sepolia-dev`, simulado antes de emitir.
7. **Los cuatro contratos verificados** (implementación, token, certificado y proxy), y la
   implementación V2 tras actualizar. Sourcify los da como `exact_match`.
8. **Una alta real en Sepolia** y el test de fork en verde contra tu proxy de Sepolia.
9. **`broadcast/DeployProtocol.s.sol/11155111/run-latest.json`** y el de `UpgradeToV2` en el
   commit.

## Cómo verificar

```bash
forge test --deny warnings
```

**Verifica**: `152 tests passed, 0 failed, 1 skipped (153 total tests)`. Después regenera y
comprueba el snapshot: los tests nuevos entran, y los de la semana 15 apenas cambian (el
bytecode lleva otras rutas en sus metadatos, ahora `lib/...`):

```bash
forge snapshot --fuzz-seed 1
forge snapshot --fuzz-seed 1 --check
```

Al compilar siguen los avisos del linter de la semana 15 (los de reentrada); los scripts no
añaden ninguno nuevo.

### Ensayo en anvil

Con `anvil --silent &` en marcha. Importa la cuenta de tu `INDEX` (aquí la 3) en un keystore de
pruebas, y despliega:

```bash
M="test test test test test test test test test test test junk"
cast wallet import anvil-3 --private-key $(cast wallet private-key "$M" 3)
forge script script/DeployProtocol.s.sol --rpc-url anvil --account anvil-3 --broadcast
```

```
== Return ==
0: struct DeployProtocol.Deployment Deployment({ implementation: 0x057ef64E23666F000b34aE31332854aCBd1c8544, loyalty: 0x261D8c5e9742e6f7f1076Fa1F560894524e19cad, certificate: 0xCE3478A9E0167a6Bc5716DC39DbbbfAc38F27623, registry: 0xCba6b9A951749B8735C603e7fFC5151849248772 })

Estimated total gas used for script: 12567367

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
```

Las mismas direcciones que en la semana 15 con la misma cuenta: el script hace lo mismo que
hacías a mano. Saca el proxy del registro de la ejecución (la cuarta transacción), registra con
la cuenta 5 y pasa el test de fork:

```bash
J=broadcast/DeployProtocol.s.sol/31337/run-latest.json
jq -r '.transactions[] | "\(.transactionType) \(.contractName) \(.function // "")"' $J
REGISTRY=$(cast to-check-sum-address $(jq -r '.transactions[3].contractAddress' $J))
cast send $REGISTRY "register(string)" first --value 0.01ether \
  --private-key $(cast wallet private-key "$M" 5) --rpc-url anvil
FORK_URL=anvil REGISTRY=$REGISTRY forge test --match-path test/RegistryFork.t.sol
```

```
CREATE Registry
CREATE LoyaltyToken
CREATE Certificate
CREATE ERC1967Proxy
CALL ERC1967Proxy
```

**Verifica**: `[PASS] test_Fork_RegistersOnACopy()`. La quinta transacción es `setHook`, sobre
el proxy. `FORK_URL=anvil` usa el alias de `foundry.toml`. Sin el alta, el test falla con
`assertion failed: 0 <= 0`: comprueba que el registro ya tiene altas.

Ahora la actualización, dos veces:

```bash
REGISTRY=$REGISTRY forge script script/UpgradeToV2.s.sol --rpc-url anvil --account anvil-3 --broadcast
cast call $REGISTRY "version()(uint256)" --rpc-url anvil
cast call $REGISTRY "maxPerAccount()(uint256)" --rpc-url anvil
REGISTRY=$REGISTRY forge script script/UpgradeToV2.s.sol --rpc-url anvil --account anvil-3 --broadcast
```

**Verifica**: `ONCHAIN EXECUTION COMPLETE & SUCCESSFUL`, `2` y `3` (el valor por defecto de
`MAX_PER_ACCOUNT`). La segunda vez, la simulación para con
`Error: script failed: InvalidInitialization()`: `initializeV2` ya se ejecutó y nada se envía.

### En Sepolia: preparar

Desde aquí, todo va contra Sepolia: `--rpc-url sepolia` y `--account sepolia-dev`. Comprueba la
red y tu saldo, y pide ETH a un faucet (teoría 03) si hace falta:

```bash
cast chain-id --rpc-url sepolia
ME=$(cast wallet address --account sepolia-dev); echo $ME
cast balance $ME --ether --rpc-url sepolia
```

**Verifica**: `11155111` y un saldo mayor que cero. Con 0,05 ETH de Sepolia te sobra.

### En Sepolia: simular, desplegar y verificar

Primero sin `--broadcast`. Lee el gas estimado y `Estimated amount required`: debe caber en tu
saldo.

```bash
forge script script/DeployProtocol.s.sol --rpc-url sepolia --account sepolia-dev
```

Después, de verdad. Con clave de Etherscan, `--verify`; sin ella, añade `--verifier sourcify`:

```bash
forge script script/DeployProtocol.s.sol --rpc-url sepolia --account sepolia-dev \
  --broadcast --slow --verify --verifier sourcify
```

Tarda un par de minutos: cinco transacciones, cada una en su bloque, y después la verificación
de los cuatro contratos. Si la verificación se corta, la parte emitida ya está hecha: verifica
lo que falte con `forge verify-contract` (teoría 04), sin volver a desplegar.

**Verifica** cada dirección en Sourcify. Las cuatro creaciones están en el registro:

```bash
J=broadcast/DeployProtocol.s.sol/11155111/run-latest.json
for a in $(jq -r '.transactions[] | select(.transactionType == "CREATE") | .contractAddress' $J); do
  curl -s https://sourcify.dev/server/v2/contract/11155111/$a | jq -r '"\(.address) \(.match)"'
done
```

Cuatro líneas terminadas en `exact_match`. Abre el proxy en
`https://sepolia.etherscan.io/address/<proxy>`: en la pestaña *Contract* debe aparecer el código.
Si Etherscan no detecta el proxy, usa *More options → Is this a proxy?*, y tendrás *Read as
Proxy* con las funciones de tu registro.

### En Sepolia: usarlo

Una alta de verdad, con tu tasa, y el test de fork contra Sepolia:

```bash
REGISTRY=$(cast to-check-sum-address $(jq -r '.transactions[3].contractAddress' $J)); echo $REGISTRY
cast send $REGISTRY "register(string)" first --value 0.01ether --account sepolia-dev --rpc-url sepolia
cast call $REGISTRY "count()(uint256)" --rpc-url sepolia
FORK_URL=sepolia REGISTRY=$REGISTRY forge test --match-path test/RegistryFork.t.sol
```

**Verifica**: `1` y `[PASS] test_Fork_RegistersOnACopy()`. El test copia el estado de Sepolia en
local, registra allí y no envía nada a Sepolia.

### En Sepolia: actualizar a V2

```bash
REGISTRY=$REGISTRY forge script script/UpgradeToV2.s.sol --rpc-url sepolia --account sepolia-dev
REGISTRY=$REGISTRY forge script script/UpgradeToV2.s.sol --rpc-url sepolia --account sepolia-dev \
  --broadcast --slow --verify --verifier sourcify
cast call $REGISTRY "version()(uint256)" --rpc-url sepolia
cast call $REGISTRY "count()(uint256)" --rpc-url sepolia
```

**Verifica**: `2` y `1`: la versión nueva, con el alta de antes. La implementación V2 sale en
Sourcify como `exact_match` (es la primera creación de
`broadcast/UpgradeToV2.s.sol/11155111/run-latest.json`).

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna:

| Dominio | `CAPACITY` en Sepolia | Primera alta real | Quién usará la dirección pública |
| ------- | --------------------- | ----------------- | -------------------------------- |
| Biblioteca | 200 socios | El primer socio, con su carné | La web de préstamos de la semana 17 |
| Tienda en línea | 50 vendedores | Un vendedor de prueba | El panel de vendedores y el indexador de pedidos |
| Cine | 120 butacas | Una reserva para el estreno | La taquilla web y el indexador de la semana 19 |

## Criterios de calidad (no automatizables)

- Sabes explicar por qué el script usa `vm.readCallers()` y no `msg.sender`.
- Sabes explicar qué pasa si alguien envía una transacción desde tu cuenta entre la
  implementación y el proxy.
- Sabes explicar por qué simulas contra Sepolia aunque ya funcionara en anvil.
- Sabes explicar dónde está tu clave privada y qué hace falta para usarla.
- Sabes explicar por qué el proyecto usa `lib` y no `/opt/lib`.
- Ninguna clave, contraseña ni URL con clave de API en el repositorio: `git status` no muestra
  `.env` y `cache/` no está en el commit.
- Sin `TODO` restantes, y los nombres son de tu dominio.

## Entrega

```bash
git add week-16
git status --short week-16 | grep -E '\.env$|cache/' && echo "¡Para! Hay secretos en el commit"
git commit -m "feat(week-16): deploy and verify the protocol on Sepolia with forge script"
git push -u origin week-16
```

Abre un pull request `week-16` → `main` en tu repositorio. En la descripción pega la salida de
`forge test`, la dirección del proxy en Sepolia con su enlace a Etherscan, las cinco líneas de
Sourcify (las cuatro del despliegue y la de V2) y la salida del test de fork contra Sepolia.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Verificación por dentro](../2-practicas/ejercicio-03-verificacion-por-dentro/README.md) | **Proyecto — Despliegue en Sepolia** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
