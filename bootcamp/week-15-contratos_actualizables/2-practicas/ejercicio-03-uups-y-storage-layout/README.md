# Ejercicio 03 — UUPS y storage layout

> Al terminar tendrás un tablón de notas UUPS detrás de un `ERC1967Proxy`: solo el dueño
> actualiza, la versión 2 guarda el autor de cada nota sin tocar las de la versión 1, y verás
> con `forge inspect` por qué una V2 que declara una variable antes que las de V1 corrompe el
> estado.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 02](../../1-teoria/02-storage-layout.md) y
[Teoría 04](../../1-teoria/04-uups-y-transparent.md) leídas y el
[ejercicio 02](../ejercicio-02-initializers-y-transparent/README.md) terminado.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Notes.sol` | `NotesV1` (`count`, `notes`, `post`, `_authorizeUpgrade`), `NotesV2` (añade `authorOf`) y `NotesV2Bad`, la V2 mal hecha. Aquí trabajas |
| `test/Notes.t.sol` | Los tests de cada paso. No lo modifiques |

`NotesV1` hereda de `UUPSUpgradeable`: la función `upgradeToAndCall` está en la
implementación, y el proxy es un `ERC1967Proxy` que solo reenvía. `UUPSUpgradeable` deja
`_authorizeUpgrade` sin escribir: cada contrato decide quién actualiza. El `setUp` despliega el
proxy y publica dos notas, de `alice` y de `bob`.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-15-contratos_actualizables/2-practicas/ejercicio-03-uups-y-storage-layout/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5740)`, `(5667)` y `(2018)`.

**Verifica**: `2 tests passed, 8 failed, 0 skipped (10 total tests)`. Pasan los dos
`test_Given_`:

- `test_Given_StateLivesInSequentialSlots`: `count` está en el slot 0 del proxy. El dueño no
  ocupa el slot 0 aunque `OwnableUpgradeable` vaya antes en la herencia: OpenZeppelin guarda sus
  variables en slots de ERC-7201 (teoría 02).
- `test_Given_RevertWhen_UpgradeIsCalledOnImplementation`: `upgradeToAndCall` llamado sobre la
  implementación, no sobre el proxy, revierte con `UUPSUnauthorizedCallContext`.

## Paso 1: `_authorizeUpgrade`

**Por qué**: `upgradeToAndCall` llama a `_authorizeUpgrade` antes de cambiar el slot de la
implementación. Si no revierte, la actualización sigue. Un `_authorizeUpgrade` vacío deja
que cualquiera cambie el código del tablón. `_checkOwner()` es lo que ejecuta el modificador
`onlyOwner`: revierte si quien llama no es el dueño.

**Abre** `src/Notes.sol` y, en `_authorizeUpgrade` de `NotesV1`, borra el `revert` y
descomenta:

```solidity
_checkOwner();
```

**Verifica**: `8 tests passed, 2 failed`. Cuatro de los que pasan:

- `test_Step1_OwnerUpgradesKeepingNotes`: tras la actualización, las dos notas siguen.
- `test_Step1_RevertWhen_ImplementationIsNotUups`: `PlainCounter` no tiene `proxiableUUID`, y
  `upgradeToAndCall` lo rechaza con `ERC1967InvalidImplementation`. Sin esa comprobación, el
  proxy apuntaría a un contrato sin `upgradeToAndCall` y no se podría actualizar nunca más.
- `test_Step1_BadLayoutCorruptsState`: con `NotesV2Bad`, `lastAuthor` lee el 2 de `count`
  como si fuera una dirección, `count` vale 0 y la nota 1 aparece vacía.
- `test_Step1_V2CanUpgradeAgain`: `NotesV2` hereda `_authorizeUpgrade` de V1, así que sigue
  siendo UUPS y puede volver a V1.

## Paso 2: V2

**Por qué**: `authorOf` es una variable nueva al final, en el slot 2. V1 no la conocía, así
que las notas anteriores no tienen autor (`address(0)`). `post` de V2 publica como V1 con
`super.post` y después apunta el autor.

En `post` de `NotesV2`, borra el `revert` y descomenta:

```solidity
id = super.post(text);
authorOf[id] = msg.sender;
```

**Verifica**:

```bash
forge test --deny warnings
```

`10 tests passed, 0 failed, 0 skipped (10 total tests)`, sin warnings.

## Paso 3: El layout con `forge inspect`

**Por qué**: antes de actualizar se compara el layout de la versión nueva con el de la
desplegada. `forge inspect` lo saca del compilador. La salida normal es una tabla muy ancha;
con `--json` y `jq` se ve en una línea por variable:

```bash
for c in NotesV1 NotesV2 NotesV2Bad; do
  echo "-- $c"
  forge inspect $c storageLayout --json | jq -r '.storage[] | "\(.slot) \(.label) \(.type)"'
done
```

```
-- NotesV1
0 count t_uint256
1 notes t_mapping(t_uint256,t_string_storage)
108904022758810753673719992590105913556127789646572562039383141376366747609600 openzeppelin.storage.Initializable._initialized erc7201(openzeppelin.storage.Initializable)::t_uint64
108904022758810753673719992590105913556127789646572562039383141376366747609600 openzeppelin.storage.Initializable._initializing erc7201(openzeppelin.storage.Initializable)::t_bool
65173360639460082030725920392146925864023520599682862633725751242436743107328 openzeppelin.storage.Ownable._owner erc7201(openzeppelin.storage.Ownable)::t_address
-- NotesV2
0 count t_uint256
1 notes t_mapping(t_uint256,t_string_storage)
2 authorOf t_mapping(t_uint256,t_address)
...
-- NotesV2Bad
0 lastAuthor t_address
1 count t_uint256
2 notes t_mapping(t_uint256,t_string_storage)
...
```

**Verifica**: `NotesV2` repite los slots 0 y 1 de V1 y añade el 2: compatible. `NotesV2Bad`
cambia el slot de `count` y de `notes`: incompatible. Las líneas de OpenZeppelin, con slots de
78 cifras, son iguales en las tres.

## Paso 4: En anvil

**Por qué**: desplegar un proxy UUPS y actualizarlo llamando al propio proxy.

Este paso no tiene código. La cuenta 0 despliega V1, V2 y el `ERC1967Proxy`, que llama a
`initialize` con ella como dueña. La cuenta 1 publica una nota:

```bash
anvil --silent &
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1)
A0=$(cast wallet address "$PK0")
forge create src/Notes.sol:NotesV1 --private-key "$PK0" --broadcast
forge create src/Notes.sol:NotesV2 --private-key "$PK0" --broadcast
forge create /opt/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy \
  --private-key "$PK0" --broadcast --constructor-args 0x5FbDB2315678afecb367f032d93F642f64180aa3 $(cast calldata "initialize(address)" $A0)
P=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
V2=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
cast send $P "post(string)" hello --private-key "$PK1"
cast storage $P 0
```

```
0x0000000000000000000000000000000000000000000000000000000000000001
```

La cuenta 1 intenta actualizar, y después la cuenta 0 actualiza a V2 sin llamada de
inicialización (`0x`, datos vacíos):

```bash
cast send $P "upgradeToAndCall(address,bytes)" $V2 0x --private-key "$PK1"
cast send $P "upgradeToAndCall(address,bytes)" $V2 0x --private-key "$PK0" --json | jq -c '[.status, (.logs | length)]'
cast call $P "version()(uint256)"
cast call $P "notes(uint256)(string)" 1
cast send $P "post(string)" again --private-key "$PK1"
cast call $P "authorOf(uint256)(address)" 1
cast call $P "authorOf(uint256)(address)" 2
```

```
Error: ... custom error 0x118cdaa7: ...: OwnableUnauthorizedAccount(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
["0x1",1]
2
"hello"
0x0000000000000000000000000000000000000000
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

La nota de V1 no tiene autor; la de V2, sí. Por último, pregunta `proxiableUUID` a la
implementación y al proxy:

```bash
cast call $V2 "proxiableUUID()(bytes32)"
cast call $P "proxiableUUID()(bytes32)"
```

```
0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
Error: ... custom error 0xe07c8dba, data: "0xe07c8dba"
```

**Verifica**: la implementación responde con el slot de EIP-1967: así demuestra que sabe
actualizarse. A través del proxy, la misma función revierte (`cast sig
"UUPSUnauthorizedCallContext()"` da `0xe07c8dba`). Por eso un proxy no se puede usar como
implementación de otro proxy.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 10 tests.
- Explicas qué pasaría con un `_authorizeUpgrade` vacío.
- Explicas por qué `upgradeToAndCall` comprueba `proxiableUUID` antes de actualizar.
- Lees en `forge inspect` si una V2 es compatible con la V1 desplegada.
- Explicas por qué el dueño no ocupa el slot 0 aunque `OwnableUpgradeable` vaya primero.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Initializers y transparent](../ejercicio-02-initializers-y-transparent/README.md) | **Ejercicio 03 — UUPS y storage layout** | [Proyecto — Registro actualizable →](../../3-proyecto/README.md) |
