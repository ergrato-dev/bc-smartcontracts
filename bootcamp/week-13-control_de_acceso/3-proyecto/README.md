# Proyecto — Roles del protocolo

> Decimotercera capa del protocolo de tu dominio: el dueño único de la semana 08 se reparte
> en roles. Un guardián pausa las altas al instante, tesorería retira las tasas, y la
> configuración la cambia un timelock, con un plazo que cualquiera puede ver.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados y tu proyecto de la
semana 12 en `main`.

## Capa que se añade y por qué ahora

Desde la semana 08, una sola cuenta, `OWNER`, retira las tasas, cierra el registro y elige el
hook. Es `immutable`: no se puede cambiar, y quien robe su clave lo puede todo. Esta semana:

- **`Owned` y `Openable` desaparecen.** El registro hereda de `AccessControl` y `Pausable` de
  OpenZeppelin.
- **Tres roles con tareas distintas**:

  | Rol | Puede | Funciones |
  | --- | ----- | --------- |
  | `DEFAULT_ADMIN_ROLE` | Configurar, reanudar y dar o quitar roles | `setHook`, `removeHook`, `unpause`, `grantRole`, `revokeRole` |
  | `PAUSER_ROLE` | Parar las altas en una emergencia | `pause` |
  | `TREASURER_ROLE` | Retirar las tasas | `withdrawFees` |

- **Al desplegar, solo hay un administrador**: quien despliega. Los demás roles se dan
  después, a quien haga falta.
- **La pausa bloquea las altas** (`register`, `registerBatch`, `registerWithPoints`). Retirar
  un recurso y mover certificados siguen funcionando: son salidas (teoría 03).
- **En anvil, el administrador pasa a ser un `TimelockController`**: quien desplegó renuncia, y
  cambiar el hook o reanudar pasa por un plazo de una hora.

En la semana 14 llegan las firmas: órdenes firmadas fuera de la cadena que el registro
verifica con EIP-712.

**El dominio te lo asigna el instructor.** Usa los nombres, la tasa y la colección de tus
semanas anteriores.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-13
   ```

2. Copia el starter entero, con su `.gitignore`, en una carpeta `week-13/` (ajusta la ruta a
   donde clonaste el bootcamp). Después trae tus pruebas de la semana 09 y el
   `.gas-snapshot` de la 12:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-13-control_de_acceso/3-proyecto/starter week-13
   cp week-12/test/RegistryFuzz.t.sol week-12/test/RegistryFork.t.sol week-13/test/
   cp week-12/.gas-snapshot week-13/
   ```

3. Pon los nombres de tu dominio: en `week-13/src/Registry.sol`, los del registro y la tasa;
   en `week-13/src/LoyaltyToken.sol` y `week-13/src/Certificate.sol`, el nombre y el símbolo
   del token y de la colección. El resto de `src/` es tu semana 12: si cambiaste algo allí,
   cópialo también, salvo `Owned.sol` y `Openable.sol`, que ya no existen.

4. Entra al contenedor y mira el rojo:

   ```bash
   cd week-13
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   forge test
   ```

**Verifica**: `41 tests passed, 6 failed, 1 skipped (48 total tests)`. Faltan más de la mitad
de los tests: tres de los fallos son `setUp()`, que revierte con
`AccessControlUnauthorizedAccount(<el test>, 0x00…00)`. Los `setUp` de `Registry.t.sol`,
`RegistryRoles.t.sol` y `RegistryTimelock.t.sol` dan roles, y sin administrador nadie puede
darlos. Cuando un `setUp` falla, forge no ejecuta ningún test de ese archivo.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml`, `.gitignore` | Con el remapping de OpenZeppelin. No los cambies |
| `src/Registry.sol` | Tu registro de la semana 12, ya con `AccessControl`, `Pausable`, `PAUSER_ROLE`, `TREASURER_ROLE`, `pause` y `unpause`; sus `// TODO:` |
| `src/LoyaltyToken.sol`, `src/Certificate.sol` | Tu token y tu colección de las semanas 11 y 12, sin los nombres |
| `src/` (resto) | `IRegistry`, `LabelLib`, `IERC165` e `IRegistrationHook`, sin cambios |
| `test/Registry.t.sol`, `test/RegistryHook.t.sol`, `test/RegistryMulticall.t.sol`, `test/RegistryLoyalty.t.sol` | Los de la semana 12, adaptados: `NotOwner` pasa a ser `AccessControlUnauthorizedAccount`, `setOpen(false)` pasa a ser `pause()` y `RegistryClosed`, `EnforcedPause`. **No los modifiques** |
| `test/RegistryCertificate.t.sol` | El de la semana 12, sin cambios. **No lo modifiques** |
| `test/RegistryRoles.t.sol` | 10 tests de roles y pausa. **No lo modifiques** |
| `test/RegistryTimelock.t.sol` | 5 tests con un `TimelockController` como único administrador. **No lo modifiques** |

## Requisitos

1. **Un administrador al desplegar**: el constructor da `DEFAULT_ADMIN_ROLE` a
   `msg.sender` con `_grantRole`, y ningún rol más.
2. **`pause()`** (solo `PAUSER_ROLE`, ya en la cabecera) llama a `_pause()`. **`unpause()`**,
   solo `DEFAULT_ADMIN_ROLE`, llama a `_unpause()`. Quien pausa no reanuda (teoría 03).
3. **Cada función de dueño, con su rol**: `withdrawFees` con `onlyRole(TREASURER_ROLE)`;
   `setHook` y `removeHook` con `onlyRole(DEFAULT_ADMIN_ROLE)`.
4. **Las tres altas, con `whenNotPaused`**. `retire` no.
5. **`supportsInterface`** declara `IRegistry` además de lo que ya declara `AccessControl`
   (`super.supportsInterface`): `IAccessControl` e `IERC165`.
6. **Tus propiedades de fuzzing siguen siendo ciertas** (más abajo), `.gas-snapshot`
   actualizado y `forge snapshot --fuzz-seed 1 --check` en verde.
7. **Desplegado en anvil** desde la cuenta de tu `INDEX`, con un guardián, un timelock como
   único administrador y un cambio de hook que pasa por su plazo. El test de fork pasa contra
   ese despliegue.

## Por qué un `override` en `supportsInterface`

Hasta la semana 12, `supportsInterface` era tuya y `external pure`. `AccessControl` trae otra,
`public view virtual`, que responde por `IAccessControl` y por `IERC165`. Dos funciones con el
mismo nombre en la herencia no compilan sin `override`, y la tuya tiene que llamar a `super`
para no perder lo que responde la de OpenZeppelin:

```solidity
function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
    return interfaceId == type(IRegistry).interfaceId || super.supportsInterface(interfaceId);
}
```

Es el mismo patrón que `_update` en la semana 11. `IERC165` sigue importado: `_isHook` lo usa
para preguntar al hook.

## Cómo verificar

```bash
forge test
```

Con todo hecho, falla uno de tus fuzz tests:

```
[FAIL: AccessControlUnauthorizedAccount(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496, 0x3496e2e73c4d42b75d702e60d9e48102720b8691234415963a5a857b86425d07); counterexample: calldata=0x... args=[5207, 0x000000000000000000000000000000003F7286F4]] testFuzz_WithdrawSendsAllFees(uint256,address) (runs: 0, μ: 0, ~: 0)
```

`0x7FA9…1496` es el contrato de test, que despliega el registro. Hasta ahora era el `OWNER` y
podía retirar. Ahora solo es administrador, y `0x3496e2e7…` es `TREASURER_ROLE`. No es un
fallo del registro: es el mínimo privilegio funcionando. Tu test tiene que hacer lo mismo que
harías en anvil, darse el rol, en `setUp` y con un comentario:

```solidity
        registry = new Registry(10);
        // Semana 13: quien despliega solo es administrador. Para retirar las tasas en
        // testFuzz_WithdrawSendsAllFees, este contrato necesita TREASURER_ROLE.
        registry.grantRole(registry.TREASURER_ROLE(), address(this));
```

Y el linter avisa de algo que antes no veía:

```
warning[arbitrary-send-eth]: ETH is sent to a user-controlled destination; restrict the destination or the caller
```

en el `call` de `withdrawFees`. El linter de forge reconoce `onlyOwner` como restricción, pero
no `onlyRole`: para él, cualquiera elige `to`. Aquí solo llega `TREASURER_ROLE`, así que se
silencia esa línea diciendo por qué:

```solidity
        // Solo TREASURER_ROLE llega aquí. El linter reconoce `onlyOwner`, no `onlyRole`.
        // forge-lint: disable-next-line(arbitrary-send-eth)
        (bool ok,) = to.call{value: amount}("");
```

**Verifica**: `101 tests passed, 0 failed, 1 skipped (102 total tests)`, sin warnings
(`forge test --deny warnings`). Fíjate en `test_RetireAndTransferWhilePaused`: con el registro
en pausa, la dueña retira un recurso y transfiere el certificado de otro.

### Lo que cuesta la capa nueva

```bash
forge snapshot --fuzz-seed 1 --diff
```

Las altas casi no cambian: `whenNotPaused` lee un `bool` como antes lo hacía `whenOpen`. Lo
que sube es lo que exige un rol:

```
↑ RegistryTest::test_RegisterStoresItem() (gas: 299333 → 299395 | 62 0.021%)
↑ RegistryTest::test_RevertWhen_NothingToWithdraw() (gas: 32685 → 35122 | 2437 7.456%)
```

`OWNER` era `immutable`: estaba en el código y compararlo no leía storage. `hasRole` lee una
tabla en storage, y la primera lectura de una posición en una transacción cuesta 2100 de
gas. Es el precio de poder cambiar quién tiene cada permiso. Tus números serán otros. Después
regenera y comprueba:

```bash
forge snapshot --fuzz-seed 1
forge snapshot --fuzz-seed 1 --check
```

### En anvil: el traspaso al timelock

Con `anvil --silent &` recién arrancado y la clave de tu `INDEX` (aquí `3`, capacidad `50`
y tasa `0.01 ether`, los de los ejemplos), y la cuenta siguiente como guardiana. Despliega el
registro y un timelock de una hora en el que solo tú propones:

```bash
M="test test test test test test test test test test test junk"
PK=$(cast wallet private-key "$M" 3); ME=$(cast wallet address "$PK")
PK4=$(cast wallet private-key "$M" 4); GUARD=$(cast wallet address "$PK4")
Z=0x0000000000000000000000000000000000000000; Z32=$(cast to-bytes32 0x00)
forge create src/Registry.sol:Registry --private-key "$PK" --broadcast --constructor-args 50
REGISTRY=0x057ef64E23666F000b34aE31332854aCBd1c8544   # tu "Deployed to"
forge create /opt/lib/openzeppelin-contracts/contracts/governance/TimelockController.sol:TimelockController \
  --private-key "$PK" --broadcast --constructor-args 3600 "[$ME]" "[$Z]" $Z
TL=0x261D8c5e9742e6f7f1076Fa1F560894524e19cad   # tu "Deployed to"
```

Reparte los roles, registra tres recursos y pasa la administración al timelock. El orden
importa: primero das el rol al timelock y después renuncias. Al revés, el registro se quedaría
sin administrador (teoría 02):

```bash
cast send $REGISTRY "grantRole(bytes32,address)" $(cast keccak PAUSER_ROLE) $GUARD --private-key "$PK"
cast send $REGISTRY "grantRole(bytes32,address)" $(cast keccak TREASURER_ROLE) $ME --private-key "$PK"
cast send $REGISTRY "registerBatch(string[])" "[north,south,east]" --value 0.03ether --private-key "$PK"
cast send $REGISTRY "grantRole(bytes32,address)" $Z32 $TL --private-key "$PK"
cast send $REGISTRY "renounceRole(bytes32,address)" $Z32 $ME --private-key "$PK"
cast call $REGISTRY "hasRole(bytes32,address)(bool)" $Z32 $ME
cast call $REGISTRY "hasRole(bytes32,address)(bool)" $Z32 $TL
```

`false` y `true`. Ahora intenta poner el hook de la semana 11 directamente, y después por el
timelock:

```bash
LOYALTY=$(cast call $REGISTRY "LOYALTY()(address)")
cast send $REGISTRY "setHook(address)" $LOYALTY --private-key "$PK"
DATA=$(cast calldata "setHook(address)" $LOYALTY)
cast send $TL "schedule(address,uint256,bytes,bytes32,bytes32,uint256)" $REGISTRY 0 $DATA $Z32 $Z32 3600 --private-key "$PK"
cast send $TL "execute(address,uint256,bytes,bytes32,bytes32)" $REGISTRY 0 $DATA $Z32 $Z32 --private-key "$PK"
```

```
Error: ... custom error 0xe2517d3f: ...: AccessControlUnauthorizedAccount(0x90F79bf6EB2c4f870365E785982E1f101E93b906, 0x0000000000000000000000000000000000000000000000000000000000000000)
Error: ... custom error 0x5ead8eb5: ...: TimelockUnexpectedOperationState(0xc2575e8d47c2e99bdd92e5b94c0faef5276c9f6ae75a7ddabd2597fb76f5c394, 0x0000000000000000000000000000000000000000000000000000000000000004)
```

Desplegaste el registro, pero ya no lo administras. Programar funciona, y ejecutar antes de
la hora no. Adelanta el reloj y ejecuta:

```bash
cast rpc evm_increaseTime 3600 >/dev/null; cast rpc evm_mine >/dev/null
cast send $TL "execute(address,uint256,bytes,bytes32,bytes32)" $REGISTRY 0 $DATA $Z32 $Z32 --private-key "$PK"
cast call $REGISTRY "hook()(address)"
echo $LOYALTY
```

```
0x3b3112c4376d037822DECFf3Fe6CD30E1E726517
0x3b3112c4376d037822DECFf3Fe6CD30E1E726517
```

### En anvil: la pausa

La guardiana pausa sin plazo. Registrar revierte, retirar un recurso no, y ella no puede
reanudar:

```bash
cast send $REGISTRY "pause()" --private-key "$PK4"
cast send $REGISTRY "register(string)" west --value 0.01ether --private-key "$PK"
cast send $REGISTRY "retire(uint256)" 3 --private-key "$PK"
cast send $REGISTRY "unpause()" --private-key "$PK4"
```

```
Error: ... custom error 0xd93c0665: ...: EnforcedPause
Error: ... custom error 0xe2517d3f: ...: AccessControlUnauthorizedAccount(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65, 0x0000000000000000000000000000000000000000000000000000000000000000)
```

(`pause` y `retire` dan `status 1`). Reanudar también pasa por el timelock:

```bash
UN=$(cast calldata "unpause()")
cast send $TL "schedule(address,uint256,bytes,bytes32,bytes32,uint256)" $REGISTRY 0 $UN $Z32 $Z32 3600 --private-key "$PK"
cast rpc evm_increaseTime 3600 >/dev/null; cast rpc evm_mine >/dev/null
cast send $TL "execute(address,uint256,bytes,bytes32,bytes32)" $REGISTRY 0 $UN $Z32 $Z32 --private-key "$PK"
cast call $REGISTRY "paused()(bool)"
cast send $REGISTRY "register(string)" west --value 0.01ether --private-key "$PK"
cast call $LOYALTY "balanceOf(address)(uint256)" $ME
cast send $REGISTRY "withdrawFees(address)" $ME --private-key "$PK4"
```

```
false
10000000000000000000 [1e19]
Error: ... custom error 0xe2517d3f: ...: AccessControlUnauthorizedAccount(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65, 0x3496e2e73c4d42b75d702e60d9e48102720b8691234415963a5a857b86425d07)
```

El alta de `west` ya avisa al hook: tienes 10 puntos, los de un alta (las tres primeras se
hicieron antes del hook). La guardiana no puede retirar las tasas; tú sí, con
`withdrawFees` y tu clave.

**Verifica**: la historia de roles del registro, con el rol (recortado), la cuenta y quién
lo dio o quitó:

```bash
cast logs --from-block 0 --address $REGISTRY "RoleGranted(bytes32 indexed,address indexed,address indexed)" --json \
  | jq -c '.[] | [.topics[1][0:10], .topics[2][26:], .topics[3][26:]]'
cast logs --from-block 0 --address $REGISTRY "RoleRevoked(bytes32 indexed,address indexed,address indexed)" --json \
  | jq -c '.[] | [.topics[1][0:10], .topics[2][26:], .topics[3][26:]]'
```

```
["0x00000000","90f79bf6eb2c4f870365e785982e1f101e93b906","90f79bf6eb2c4f870365e785982e1f101e93b906"]
["0x65d7a28e","15d34aaf54267db7d7c367839aaf71a00a2c6a65","90f79bf6eb2c4f870365e785982e1f101e93b906"]
["0x3496e2e7","90f79bf6eb2c4f870365e785982e1f101e93b906","90f79bf6eb2c4f870365e785982e1f101e93b906"]
["0x00000000","261d8c5e9742e6f7f1076fa1f560894524e19cad","90f79bf6eb2c4f870365e785982e1f101e93b906"]
["0x00000000","90f79bf6eb2c4f870365e785982e1f101e93b906","90f79bf6eb2c4f870365e785982e1f101e93b906"]
```

Administración para ti al desplegar, `PAUSER_ROLE` para la guardiana, `TREASURER_ROLE` para
ti, administración para el timelock, y tu renuncia. Cualquier usuario puede leer esto y
comprobar que nadie más que el timelock administra el registro.

Y el test de fork, sin cambios, contra este despliegue:

```bash
FORK_URL=http://127.0.0.1:8545 REGISTRY="$REGISTRY" forge test --match-path test/RegistryFork.t.sol
```

`[PASS] test_Fork_RegistersOnACopy()`.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna:

| Dominio | `PAUSER_ROLE` | `TREASURER_ROLE` | Qué pasa por el timelock |
| ------- | ------------- | ---------------- | ------------------------ |
| Biblioteca | Quien atiende el mostrador, si detecta altas falsas | La administración de la biblioteca | Cambiar el programa de puntos |
| Tienda en línea | El equipo de soporte de guardia | Contabilidad | Cambiar el contrato que reparte recompensas |
| Cine | La gerencia de cada sala | La central de la cadena | Reanudar las altas tras un incidente |

## Criterios de calidad (no automatizables)

- Sabes explicar por qué quien despliega no recibe `PAUSER_ROLE` ni `TREASURER_ROLE`.
- Sabes explicar por qué `pause` no pasa por el timelock y `unpause` sí.
- Sabes explicar por qué `retire` no lleva `whenNotPaused`.
- Sabes explicar qué pasa si renuncias al administrador antes de dárselo al timelock.
- Sabes explicar por qué el cambio en tu fuzz test no esconde un fallo del registro.
- Sin `TODO` restantes, y los nombres son de tu dominio.

## Entrega

```bash
git add week-13
git commit -m "feat(week-13): add protocol roles, pause and timelock admin"
git push -u origin week-13
```

Abre un pull request `week-13` → `main` en tu repositorio. En la descripción pega la salida
de `forge test`, la línea de `--diff` de `test_RevertWhen_NothingToWithdraw`, el error de
ejecutar antes del plazo y la historia de roles de `cast logs`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Multisig](../2-practicas/ejercicio-03-multisig/README.md) | **Proyecto — Roles del protocolo** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
