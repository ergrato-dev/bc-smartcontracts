# Ejercicio 02 — Initializers y transparent

> Al terminar tendrás un club detrás de un `TransparentUpgradeableProxy` de OpenZeppelin: el
> dueño y el nombre se fijan con `initialize`, la implementación queda cerrada para que nadie
> se haga dueño de ella, y la versión 2 trae un máximo de miembros que se inicializa al
> actualizar. En anvil desplegarás el proxy y lo actualizarás a través de su `ProxyAdmin`.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 03](../../1-teoria/03-initializers.md) y
[Teoría 04](../../1-teoria/04-uups-y-transparent.md) leídas y el
[ejercicio 01](../ejercicio-01-proxy-a-mano/README.md) terminado.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Club.sol` | `ClubV1` (`name`, `members`, `isMember`, `join`, `rename`) y `ClubV2`, con `maxMembers`. Aquí trabajas |
| `test/Club.t.sol` | Los tests de cada paso. No lo modifiques |

`ClubV1` hereda de `Initializable` y de `OwnableUpgradeable`, que vienen de
`@openzeppelin/contracts-upgradeable/`: la versión de OpenZeppelin para contratos detrás de un
proxy, con `__Ownable_init` en vez de constructor. El proxy y su `ProxyAdmin` vienen de
`@openzeppelin/contracts/`. El `setUp` crea el proxy con
`new TransparentUpgradeableProxy(v1, owner, initData)`: `initData` es la llamada a
`initialize`, que el proxy ejecuta en su constructor.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-15-contratos_actualizables/2-practicas/ejercicio-02-initializers-y-transparent/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila sin warnings: solc no avisa de los parámetros sin usar de `initialize`.

**Verifica**: `6 tests passed, 6 failed, 0 skipped (12 total tests)`. Pasan los cuatro
`test_Given_`:

- `test_Given_ProxyAdminBelongsToOwner`: el proxy creó un `ProxyAdmin` cuyo dueño es `owner`.
- `test_Given_ProxyAdminCannotUseTheClub`: si el `ProxyAdmin` llama a `members()`, el proxy
  revierte con `ProxyDeniedAdminAccess`. Esa es la regla del proxy transparent (teoría 04).
- `test_Given_RevertWhen_InitializedTwice`: el modificador `initializer` ya impide llamar
  otra vez a `initialize`, aunque esté vacío.
- `test_Given_RevertWhen_NotOwnerUpgrades`: solo el dueño del `ProxyAdmin` actualiza.

Pasan también dos `RevertWhen` de los pasos 1 y 3, que protegen el dueño vacío y el modificador
`reinitializer`. Con el dueño en `address(0)`, nadie puede cambiar el nombre: es un club sin
dueño.

## Paso 1: `initialize`

**Por qué**: el proxy no ejecuta el constructor de la implementación: un constructor corre
una vez, al desplegar, sobre el storage de la implementación (teoría 03). Lo que haría el
constructor va a `initialize`, que el proxy llama con `delegatecall` sobre su storage.
`__Ownable_init` es el constructor de `Ownable` convertido en función.

**Abre** `src/Club.sol` y, en `initialize`, descomenta:

```solidity
__Ownable_init(initialOwner);
name = clubName;
```

**Verifica**: `8 tests passed, 4 failed`. `test_Step1_ProxyIsInitialized`: el proxy tiene
dueño y nombre.

## Paso 2: Cerrar la implementación

**Por qué**: la implementación es un contrato normal, desplegado en su propia dirección, y su
`initialize` es `external`: cualquiera puede llamarlo sobre ella y hacerse su dueño. Aquí no
gana nada con eso, pero en una implementación con `selfdestruct` o con `upgradeToAndCall`
(teoría 04) un dueño ajeno puede romperla. `_disableInitializers()` en el constructor marca la
implementación como inicializada para siempre.

En el constructor, descomenta:

```solidity
_disableInitializers();
```

**Verifica**: `10 tests passed, 2 failed`. `test_Step2_ImplementationIsClosedOnDeploy` ve el
evento `Initialized(type(uint64).max)` al desplegar: la versión más alta, que ningún
`reinitializer` puede superar.

## Paso 3: V2 con `reinitializer`

**Por qué**: `maxMembers` es nueva, así que nadie la ha inicializado y vale 0. El proxy ya está
inicializado, así que `initializer` no vale: `reinitializer(2)` deja inicializar una vez la
versión 2. `ProxyAdmin.upgradeAndCall` cambia la implementación y llama a `initializeV2` en la
misma transacción.

En `initializeV2`, descomenta:

```solidity
maxMembers = newMaxMembers;
```

**Verifica**:

```bash
forge test --deny warnings
```

`12 tests passed, 0 failed, 0 skipped (12 total tests)`, sin warnings.
`test_Step3_UpgradeKeepsMembersAndSetsMax`: tras la actualización, `alice` sigue siendo
miembro, el nombre y el dueño siguen, y `maxMembers` vale 2. `maxMembers` va al final del
storage, detrás de las variables de V1 (teoría 02).

## Paso 4: En anvil

**Por qué**: desplegar un proxy transparent con `cast` y ver las dos cuentas que lo controlan:
el `ProxyAdmin` (un contrato) y su dueño (tu cuenta).

Este paso no tiene código. La cuenta 0 despliega las dos versiones y el proxy, con ella misma
como dueña del club y del `ProxyAdmin`. El tercer argumento del proxy es la llamada a
`initialize`, codificada con `cast calldata`:

```bash
anvil --silent &
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1); PK2=$(cast wallet private-key "$M" 2)
A0=$(cast wallet address "$PK0")
forge create src/Club.sol:ClubV1 --private-key "$PK0" --broadcast
forge create src/Club.sol:ClubV2 --private-key "$PK0" --broadcast
INIT=$(cast calldata "initialize(address,string)" $A0 Chess)
forge create /opt/lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy \
  --private-key "$PK0" --broadcast --constructor-args 0x5FbDB2315678afecb367f032d93F642f64180aa3 $A0 $INIT
P=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
cast call $P "name()(string)"
cast call $P "owner()(address)"
```

```
"Chess"
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

El `ProxyAdmin` no tiene dirección conocida: la lees del slot de administrador del proxy.

```bash
ADMIN=$(cast parse-bytes32-address $(cast storage $P 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)); echo $ADMIN
cast call $ADMIN "owner()(address)"
cast call $P "members()(uint256)" --from $ADMIN
```

```
0x75537828f2ce51be7289709686A69CbFDbB714F1
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Error: ... custom error 0xd2b576ec ...
```

`cast sig "ProxyDeniedAdminAccess()"` da `0xd2b576ec`: el `ProxyAdmin` no puede usar el club.
La cuenta 0, que es su dueña, sí, porque para el proxy es una cuenta más. Ahora la cuenta 2
intenta hacerse dueña de la implementación, y la cuenta 1 se une al club:

```bash
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "initialize(address,string)" $(cast wallet address "$PK2") Mine --private-key "$PK2"
cast send $P "join()" --private-key "$PK1" --json | jq -c '[.status]'
```

```
Error: ... custom error 0xf92ee8a9, data: "0xf92ee8a9": InvalidInitialization
["0x1"]
```

La cuenta 0 actualiza a V2 con un máximo de 1 miembro, a través del `ProxyAdmin`:

```bash
cast send $ADMIN "upgradeAndCall(address,address,bytes)" $P 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 $(cast calldata "initializeV2(uint256)" 1) --private-key "$PK0" --json | jq -c '[.status, (.logs | length)]'
cast call $P "maxMembers()(uint256)"
cast call $P "members()(uint256)"
cast call $P "name()(string)"
cast send $P "join()" --private-key "$PK2"
cast send $P "initializeV2(uint256)" 100 --private-key "$PK0"
```

```
["0x1",2]
1
1
"Chess"
Error: ... custom error 0xc11ac767: , data: "0xc11ac7670000000000000000000000000000000000000000000000000000000000000001"
Error: ... custom error 0xf92ee8a9, data: "0xf92ee8a9": InvalidInitialization
```

**Verifica**: la actualización emitió dos eventos, `Upgraded` e `Initialized(2)`. El miembro de
V1 sigue ahí, la cuenta 2 no cabe (`cast sig "ClubFull(uint256)"` da `0xc11ac767`, con el máximo
1) y `initializeV2` no se repite.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 12 tests.
- Explicas por qué el club no tiene dueño si `initialize` está vacío, aunque el proxy lo llamara.
- Explicas qué pasaría si el proxy se desplegara sin `initData` y `initialize` se llamara en
  otra transacción.
- Explicas por qué `_disableInitializers` va en el constructor y no en `initialize`.
- Explicas por qué el `ProxyAdmin` no puede llamar a `members()` y la cuenta 0 sí.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Proxy a mano](../ejercicio-01-proxy-a-mano/README.md) | **Ejercicio 02 — Initializers y transparent** | [Ejercicio 03 — UUPS y storage layout →](../ejercicio-03-uups-y-storage-layout/README.md) |
