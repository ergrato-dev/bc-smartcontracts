# Teoría 01 — forge script

## 🎯 Objetivos

- Explicar por qué un despliegue de varios pasos se escribe como un script y no como una lista
  de comandos.
- Escribir un script de Foundry: `Script`, `run()`, `vm.startBroadcast()` y `vm.stopBroadcast()`.
- Distinguir las tres fases de `forge script`: ejecutar, simular contra la red y emitir.
- Leer el registro que deja cada ejecución en `broadcast/`.
- Probar un script con `forge test` antes de lanzarlo contra una red.

---

## 1. Qué problema resuelve

En la semana 15 desplegaste el registro con cinco `forge create` y un `cast send`, a mano y en
un orden preciso: la implementación, la dirección predicha del proxy, el token, el certificado,
el proxy y el hook. En anvil, un error se arregla reiniciando la cadena. En una red pública no:
cada transacción enviada queda para siempre y cuesta gas, y un paso olvidado deja el protocolo
a medias, con contratos que apuntan a direcciones que no existen.

Un **script de despliegue** convierte esa lista en un programa. En Foundry se escribe en
Solidity, como los tests, y `forge script` lo ejecuta. Ganas cuatro cosas:

- **Repetible**: el mismo comando despliega igual en anvil, en Sepolia o en una L2.
- **Probado**: un test puede ejecutar el script y comprobar lo que deja (ejercicio 01).
- **Simulado**: antes de enviar nada, `forge script` ejecuta todo contra el estado real de la
  red. Si un paso revierte, no se envía ninguno.
- **Registrado**: cada ejecución deja un JSON con las transacciones, las direcciones y los
  recibos.

## 2. Cómo funciona

Un script es un contrato que hereda de `Script` (de forge-std) con una función `run()`. Lo que
haces dentro de `run()` se ejecuta en una EVM local, como un test. La diferencia está en dos
cheatcodes:

- **`vm.startBroadcast()`**: a partir de aquí, cada llamada a otro contrato y cada `new` que
  haga el script se anota como una transacción que hay que enviar. La firma la cuenta que le
  pases a `forge script`.
- **`vm.stopBroadcast()`**: deja de anotar.

**Emitir** (*broadcast*) es enviar esas transacciones a la red. Lo que va fuera del par (leer
variables de entorno, calcular, comprobar) se ejecuta en la simulación, pero nunca llega a la
red.

![forge script ejecuta run() en una EVM local y anota las transacciones de startBroadcast; con --rpc-url las repite sobre el estado real y pide la estimación de gas; si algo revierte se para sin enviar; con --broadcast firma, envía, espera los recibos y escribe run-latest.json](../0-assets/01-simular-y-emitir.svg)

Según las opciones que le des, `forge script` llega más o menos lejos:

| Comando | Qué hace |
| ------- | -------- |
| `forge script S.s.sol` | Fase 1: ejecuta `run()` en memoria, sin red |
| `forge script S.s.sol --rpc-url <red>` | Fases 1 y 2: simula sobre la red y estima el gas |
| `forge script S.s.sol --rpc-url <red> --account <cuenta> --broadcast` | Las tres: firma y envía |

Sin `--broadcast` nunca se envía nada: es la forma segura de ensayar.

## 3. Cómo se escribe

El script del ejercicio 01. **Dónde**: `script/DeployBox.s.sol`, en una carpeta `script/` al
lado de `src/` y `test/` (la extensión `.s.sol` es la convención de Foundry para scripts):

```solidity
import {Script} from "forge-std/Script.sol";
import {Box} from "../src/Box.sol";

contract DeployBox is Script {
    error ZeroInitialValue();

    function run() external returns (Box) {
        return deploy(vm.envOr("INITIAL_VALUE", uint256(1)));
    }

    function deploy(uint256 initial) public returns (Box box) {
        if (initial == 0) revert ZeroInitialValue();

        vm.startBroadcast();
        (, address signer,) = vm.readCallers();
        box = new Box(signer);
        box.store(initial);
        vm.stopBroadcast();
    }
}
```

- `vm.envOr("INITIAL_VALUE", uint256(1))` lee la variable de entorno `INITIAL_VALUE`, o 1 si no
  existe. Así el mismo script sirve con otra configuración sin tocar el código.
- La comprobación de `initial` va **antes** de `vm.startBroadcast()`: un valor malo para el
  script en la simulación, sin una sola transacción.
- `vm.readCallers()` devuelve, entre otras cosas, quién es el `msg.sender` de lo que se emite:
  la cuenta que firma. En la sección 5 verás por qué no se usa `msg.sender` sin más.
- `new Box(signer)` y `box.store(initial)` son dos transacciones: una creación y una llamada.

### Ejecutar sin red

**Dónde**: en el contenedor, en la carpeta del proyecto.

```bash
forge script script/DeployBox.s.sol
```

```
Script ran successfully.
Gas used: 296089

== Return ==
0: contract Box 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496

If you wish to simulate on-chain transactions pass a RPC URL.
```

Solo la fase 1, en una cadena vacía que desaparece al terminar. Sirve para ver que `run()` no
revierte.

### Simular contra anvil

Con `anvil --silent &` en marcha y la clave de la cuenta 3 de anvil en `PK` (en la teoría 02 la
cambiarás por un keystore):

```bash
forge script script/DeployBox.s.sol --rpc-url http://127.0.0.1:8545 --private-key "$PK"
```

```
== Return ==
0: contract Box 0x057ef64E23666F000b34aE31332854aCBd1c8544

Chain 31337

Estimated max fee per gas: 2.000000001 gwei
Estimated base fee per gas: 1 gwei
Estimated max priority fee per gas: 0.000000001 gwei

Estimated total gas used for script: 311011

Estimated amount required: 0.000622022000311011 ETH

SIMULATION COMPLETE. To broadcast these transactions, add --broadcast and wallet configuration(s) to the previous command. See forge script --help for more.

Transactions saved to: /workspace/broadcast/DeployBox.s.sol/31337/dry-run/run-latest.json
```

Ahora la dirección es la real: la que sale de la cuenta 3 y su nonce en anvil (semana 02). Y
`forge script` te dice cuánto gas y cuánto ETH necesitas antes de gastar nada. La estimación
lleva un margen: por defecto, un 30 % más de lo que mide (`--gas-estimate-multiplier`).

### Emitir

El mismo comando con `--broadcast`:

```bash
forge script script/DeployBox.s.sol --rpc-url http://127.0.0.1:8545 --private-key "$PK" --broadcast
```

```
ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /workspace/broadcast/DeployBox.s.sol/31337/run-latest.json
```

`cast nonce` de la cuenta 3 pasa de 0 a 2: dos transacciones enviadas.

### El registro de la ejecución

Cada ejecución escribe `broadcast/<script>/<chain id>/run-latest.json` (y una copia con la hora,
`run-<timestamp>.json`). Una simulación, en la subcarpeta `dry-run/`. Lo lees con `jq`:

```bash
jq -r '.transactions[] | "\(.transactionType) \(.function // .contractName)"' \
  broadcast/DeployBox.s.sol/31337/run-latest.json
jq -r '.transactions[0].contractAddress' broadcast/DeployBox.s.sol/31337/run-latest.json
```

```
CREATE Box
CALL store(uint256)
0x057ef64e23666f000b34ae31332854acbd1c8544
```

En `transactions` está lo que se envió (tipo, contrato, función, argumentos y la transacción
completa); en `receipts`, los recibos (estado, gas usado, bloque). Es la fuente de las
direcciones de tu despliegue: el frontend de la semana 17 las leerá de aquí.

### Un script que falla

```bash
INITIAL_VALUE=0 forge script script/DeployBox.s.sol --rpc-url http://127.0.0.1:8545 --private-key "$PK" --broadcast
```

```
    └─ ← [Revert] ZeroInitialValue()

Error: script failed: ZeroInitialValue()
```

Aunque lleva `--broadcast`, no se envía nada: la simulación revirtió antes.

## 4. Probar el script

Un script es un contrato: un test puede crearlo y llamar a sus funciones. **Dónde**:
`test/DeployBox.t.sol`:

```solidity
function test_OwnerIsTheSigner() public {
    Box box = new DeployBox().deploy(5);
    assertEq(box.OWNER(), DEFAULT_SENDER);
}
```

Dentro de un test, `vm.startBroadcast()` sin argumentos firma con **`DEFAULT_SENDER`**, el
remitente por defecto de Foundry (`0x1804c8AB…`), una constante que forge-std da a tests y
scripts. Por eso el script separa `run()` (lee el entorno) de `deploy(initial)` (hace el
trabajo): el test llama a `deploy` con los valores que quiere.

## 5. Antipatrones y riesgos

- ❌ **Usar `msg.sender` como quien firma.** En `forge script`, el `msg.sender` de `run()` es la
  cuenta que firma. Pero en un test es el contrato de test (`0x7FA9…`), y el dueño de la Box
  sería un contrato que no puede llamar a `store`. `vm.readCallers()` da quien firma en los dos
  casos.
- ❌ **Comprobar después de emitir.** Una comprobación tras `vm.stopBroadcast()` se ejecuta,
  pero si falla, las transacciones ya van camino de la red. Lo que pueda fallar se comprueba
  antes de `vm.startBroadcast()`.
- ❌ **Emitir sin simular.** Lanza siempre el comando sin `--broadcast` primero, contra la red
  de verdad: te dice el gas, el ETH y si algo revierte. `--skip-simulation` se salta la fase
  2: no lo uses.
- ❌ **Emitir sin decir con qué cuenta.** Con `--broadcast` y sin cuenta, `forge script` se
  niega: `Error: You seem to be using Foundry's default sender. Be sure to set your own --sender.`
  `DEFAULT_SENDER` es una dirección de la que nadie tiene la clave.
- ❌ **Confiar en el orden de nonces ajenos.** Si otra transacción de tu cuenta entra en medio
  (otro script, una wallet), las direcciones predichas con el nonce cambian. Un despliegue,
  una cuenta, un script a la vez.

## 6. Trucos

- `forge script ... -vvvv` muestra la traza de cada llamada, como en los tests.
- Si la ejecución se corta a medias (el nodo cae, se acaba el ETH), `--resume` reenvía solo lo
  que falta, leyendo `run-latest.json`.
- `--slow` espera el recibo de cada transacción antes de enviar la siguiente. En una red
  pública, úsalo: evita que una transacción llegue antes que la anterior.
- El script puede devolver valores (`returns (Box)`): aparecen en `== Return ==` y en el campo
  `returns` del JSON.

## ✅ Checklist

- [ ] Explico qué se emite y qué no en un script: lo que va entre `startBroadcast` y
      `stopBroadcast`.
- [ ] Distingo lo que hace `forge script` sin red, con `--rpc-url` y con `--broadcast`.
- [ ] Sé dónde queda el registro de una ejecución y saco de él una dirección con `jq`.
- [ ] Explico por qué el script usa `vm.readCallers()` y no `msg.sender`.
- [ ] Sé probar un script con `forge test`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 16 — Despliegue y verificación](../README.md) | **Teoría 01 — forge script** | [Teoría 02 — Claves y keystores →](02-claves-y-keystores.md) |
