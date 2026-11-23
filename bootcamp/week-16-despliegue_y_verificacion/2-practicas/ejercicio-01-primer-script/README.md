# Ejercicio 01 — Primer script

> Al terminar habrás escrito un script de despliegue con dos transacciones, lo habrás probado
> con `forge test` y lo habrás simulado y emitido contra anvil.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 01 — forge script](../../1-teoria/01-forge-script.md) leída.

## Contexto

Proyecto Foundry con una carpeta nueva, `script/`. Resolver un paso es borrar la línea
`revert("TODO: Paso N");`, si la tiene, y quitar el `//> ` de las líneas del paso.

| Archivo | Qué es |
| ------- | ------ |
| `src/Box.sol` | Una caja con un número que solo su dueño (`OWNER`, immutable) cambia con `store` |
| `script/DeployBox.s.sol` | El script: `run()` y `deploy(initial)`. Aquí trabajas |
| `test/DeployBox.t.sol` | Seis tests que ejecutan el script. **No lo modifiques** |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-16-despliegue_y_verificacion/2-practicas/ejercicio-01-primer-script/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 tests passed, 6 failed`. Cinco fallan con `TODO: Paso 1` y uno con
`TODO: Paso 4`: `deploy` revierte antes de hacer nada.

Al compilar, el linter avisa de `missing-zero-check` en el constructor de `Box`: no comprueba
que `owner` no sea `address(0)`. Aquí el dueño siempre es quien firma el script, así que no
llega a pasar; en un contrato de verdad, añadirías la comprobación.

## Paso 1: Desplegar entre startBroadcast y stopBroadcast

**Por qué**: lo que va entre las dos cheatcodes es lo único que se convierte en transacciones.
El dueño de la Box es quien firma, y `vm.readCallers()` lo da tanto en un script como en un
test.

```solidity
        vm.startBroadcast();
        (, address signer,) = vm.readCallers();
        box = new Box(signer);
        // (el paso 2 va aquí)
        vm.stopBroadcast();
```

**Abre** `script/DeployBox.s.sol`: borra `revert("TODO: Paso 1");` y descomenta las cuatro
líneas del paso, incluido el `vm.stopBroadcast()` del final.

**Verifica**: `forge test` da `2 tests passed, 4 failed`. Pasan `test_DeploysBox` y
`test_OwnerIsTheSigner`: la Box existe y su dueño es `DEFAULT_SENDER`, no el contrato del
script. Fallan:

- `test_StoresInitialValue` con `0 != 5`: todavía nadie llama a `store`.
- `test_StoreIsSignedByTheOwner` con `3 != 4`: el nonce de quien firma solo subió uno.
- `test_RevertWhen_InitialIsZero` con `next call did not revert as expected`.
- `test_RunUsesDefaultValue` con `TODO: Paso 4`.

**Prueba**: cambia `signer` por `msg.sender` en `new Box(...)` y vuelve a ejecutar
`test_OwnerIsTheSigner`. Falla: en un test, el `msg.sender` de `deploy` es el contrato de test,
no quien firma. Deja `signer`.

## Paso 2: Una segunda transacción

**Por qué**: un despliegue real rara vez es un solo `new`. Después de crear, se configura: aquí,
el número inicial. Como va antes de `vm.stopBroadcast()`, es otra transacción firmada por la
misma cuenta, y la Box acepta el `store` porque quien llama es su dueño.

```solidity
        box.store(initial);
```

**Abre** `script/DeployBox.s.sol` y descomenta la línea del paso 2.

**Verifica**: `4 tests passed, 2 failed`. `test_StoreIsSignedByTheOwner` comprueba que el nonce
de `DEFAULT_SENDER` sube 2: una creación y una llamada.

## Paso 3: Rechazar la configuración mala antes de emitir

**Por qué**: un 0 dejaría una Box inútil en la cadena, y lo habrías pagado. Comprobado antes de
`vm.startBroadcast()`, el script revierte en la simulación y no envía nada.

```solidity
        if (initial == 0) revert ZeroInitialValue();
```

**Abre** `script/DeployBox.s.sol` y descomenta la línea del paso 3, al principio de `deploy`.

**Verifica**: `5 tests passed, 1 failed`. Solo queda `test_RunUsesDefaultValue`.

## Paso 4: Leer la configuración del entorno

**Por qué**: `run()` es lo que ejecuta `forge script`. Leyendo una variable de entorno, el mismo
script despliega con otro número sin tocar el código.

```solidity
        return deploy(vm.envOr("INITIAL_VALUE", uint256(1)));
```

**Abre** `script/DeployBox.s.sol`: en `run()`, borra `revert("TODO: Paso 4");` y descomenta la
línea.

**Verifica**: `forge test --deny warnings` da `6 tests passed, 0 failed`.

## Paso 5: Simular y emitir en anvil

**Por qué**: hasta aquí, el script solo corrió dentro de tests. Ahora contra un nodo, primero
sin enviar nada.

En el contenedor, arranca anvil y toma la clave de la cuenta 3:

```bash
anvil --silent &
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 3)
forge script script/DeployBox.s.sol --rpc-url http://127.0.0.1:8545 --private-key "$PK"
```

**Verifica**: `SIMULATION COMPLETE`, `Estimated total gas used for script: 311011` y la Box en
`0x057ef64E23666F000b34aE31332854aCBd1c8544`. `cast nonce 0x90F79bf6EB2c4f870365E785982E1f101E93b906`
sigue en `0`.

Ahora emite, con otro número:

```bash
INITIAL_VALUE=7 forge script script/DeployBox.s.sol --rpc-url http://127.0.0.1:8545 --private-key "$PK" --broadcast
cast call 0x057ef64E23666F000b34aE31332854aCBd1c8544 "value()(uint256)"
cast nonce 0x90F79bf6EB2c4f870365E785982E1f101E93b906
```

**Verifica**: `ONCHAIN EXECUTION COMPLETE & SUCCESSFUL`, `7` y `2`. Por último, el script que
falla:

```bash
INITIAL_VALUE=0 forge script script/DeployBox.s.sol --rpc-url http://127.0.0.1:8545 --private-key "$PK" --broadcast
```

**Verifica**: `Error: script failed: ZeroInitialValue()`, y el nonce sigue en `2`.

## Qué aprendiste

- Un script es un contrato: `run()` es la entrada y `vm.startBroadcast()`/`vm.stopBroadcast()`
  marcan lo que se emite.
- `vm.readCallers()` da quien firma en un script y en un test; `msg.sender`, no.
- Lo que puede fallar se comprueba antes de emitir.
- Simular primero: sin `--broadcast` no se envía nada.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Verificación](../../1-teoria/04-verificacion.md) | **Ejercicio 01 — Primer script** | [Ejercicio 02 — Keystore y broadcast →](../ejercicio-02-keystore-y-broadcast/README.md) |
