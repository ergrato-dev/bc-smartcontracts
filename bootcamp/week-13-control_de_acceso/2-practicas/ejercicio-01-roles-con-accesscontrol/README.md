# Ejercicio 01 — Roles con AccessControl

> Al terminar tendrás un tablón de anuncios con tres niveles: el administrador nombra
> moderadores, los moderadores nombran editores y retiran anuncios, y los editores publican.
> Y verás en anvil que el administrador ya no puede nombrar editores directamente.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 02](../../1-teoria/02-accesscontrol-y-roles.md) leída.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Bulletin.sol` | El tablón: `MODERATOR_ROLE`, `EDITOR_ROLE`, `publish` y `remove`. Aquí trabajas |
| `test/Bulletin.t.sol` | Los tests de cada paso. No lo modifiques |

`publish` y `remove` ya llevan su `onlyRole` en la cabecera: tú escribes el cuerpo. El
constructor recibe el administrador como parámetro, en vez de usar `msg.sender`: así se
puede desplegar con un multisig como administrador (teoría 04).

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-13-control_de_acceso/2-practicas/ejercicio-01-roles-con-accesscontrol/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5667)` y `(2018)`.

**Verifica**: `3 tests passed, 8 failed, 0 skipped (11 total tests)`. Pasan los dos que
llaman sin rol (`onlyRole` ya funciona) y `test_Inherited_SupportsInterface`.

## Paso 1: El primer administrador y la jerarquía

**Por qué**: nadie tiene ningún rol al desplegar. Sin un `_grantRole` en el constructor,
nadie podría dar roles nunca (teoría 02). `_setRoleAdmin(EDITOR_ROLE, MODERATOR_ROLE)`
cambia quién administra a los editores: dejan de depender de `DEFAULT_ADMIN_ROLE` y pasan a
depender de los moderadores, que son quienes trabajan con ellos.

**Abre** `src/Bulletin.sol` y, en el constructor, descomenta:

```solidity
_grantRole(DEFAULT_ADMIN_ROLE, admin);
_setRoleAdmin(EDITOR_ROLE, MODERATOR_ROLE);
```

**Verifica**: `7 tests passed, 4 failed`. Mira `test_Step1_RevertWhen_AdminGrantsEditor`:
el administrador recibe `AccessControlUnauthorizedAccount(admin, MODERATOR_ROLE)` al dar
`EDITOR_ROLE`. Administrar todo el contrato no es administrar cada rol: para nombrar un
editor, el administrador tendría que hacerse moderador primero.

## Paso 2: Publicar

**Por qué**: el rol ya está comprobado al entrar, así que el cuerpo solo valida el texto y
guarda el anuncio. `nextId++` devuelve el valor actual y después suma: el primer anuncio es
el 1, y un anuncio con `author == address(0)` es uno que no existe.

```solidity
if (bytes(text).length == 0) revert EmptyText();
id = nextId++;
posts[id] = Post(msg.sender, text);
emit Published(id, msg.sender, text);
```

**Verifica**: `9 tests passed, 2 failed`.

## Paso 3: Retirar

**Por qué**: retirar es tarea de moderación. `delete` pone el anuncio a cero (semana 06), y
el evento deja escrito quién lo retiró.

```solidity
if (posts[id].author == address(0)) revert PostNotFound(id);
delete posts[id];
emit Removed(id, msg.sender);
```

**Verifica**:

```bash
forge test --deny warnings
```

`11 tests passed, 0 failed, 0 skipped (11 total tests)`, sin warnings.

## Paso 4: En anvil

**Por qué**: ver la jerarquía con cuentas reales y leer en los logs quién nombró a quién.

Este paso no tiene código. Arranca anvil y despliega con la cuenta 0 como administradora.
La 1 será moderadora y la 2, editora:

```bash
anvil --silent &
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1); PK2=$(cast wallet private-key "$M" 2)
A0=$(cast wallet address "$PK0"); A1=$(cast wallet address "$PK1"); A2=$(cast wallet address "$PK2")
forge create src/Bulletin.sol:Bulletin --private-key "$PK0" --broadcast --constructor-args $A0
B=0x5FbDB2315678afecb367f032d93F642f64180aa3
MOD=$(cast keccak MODERATOR_ROLE); ED=$(cast keccak EDITOR_ROLE)
cast send $B "grantRole(bytes32,address)" $ED $A2 --private-key "$PK0"
cast send $B "grantRole(bytes32,address)" $MOD $A1 --private-key "$PK0" --json | jq -r .status
cast send $B "grantRole(bytes32,address)" $ED $A2 --private-key "$PK1" --json | jq -r .status
```

```
Error: ... custom error 0xe2517d3f: ...: AccessControlUnauthorizedAccount(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 0x71f3d55856e4058ed06ee057d79ada615f65cdf5f9ee88181b914225088f834f)
0x1
0x1
```

La administradora no puede nombrar a la editora (`0x71f3d558…` es `MODERATOR_ROLE`, el rol
que le falta). Nombra a la moderadora, y la moderadora nombra a la editora. Ahora publica,
retira y renuncia:

```bash
cast send $B "publish(string)" "Reunion el lunes" --private-key "$PK2" --json | jq -c '[.status, .logs[0].topics]'
cast call $B "posts(uint256)(address,string)" 1
cast send $B "remove(uint256)" 1 --private-key "$PK1" --json | jq -r .status
cast call $B "posts(uint256)(address,string)" 1
cast send $B "renounceRole(bytes32,address)" $ED $A2 --private-key "$PK2" --json | jq -r .status
cast send $B "publish(string)" "otra" --private-key "$PK2"
```

```
["0x1",["0x88a4ee6a45575a394458cdf3270feffdada072897cd64a73ce4361d259bb594f","0x0000000000000000000000000000000000000000000000000000000000000001","0x0000000000000000000000003c44cdddb6a900fa2b585dd299e03d12fa4293bc"]]
0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
"Reunion el lunes"
0x1
0x0000000000000000000000000000000000000000
""
0x1
Error: ... custom error 0xe2517d3f: ...: AccessControlUnauthorizedAccount(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, 0x21d1167972f621f75904fb065136bc8b53c7ba1c60ccd3a7758fbee465851e9c)
```

**Verifica**: la historia de nombramientos, con el rol (recortado), quién lo recibió y quién
lo dio:

```bash
cast logs --from-block 0 --address $B "RoleGranted(bytes32 indexed,address indexed,address indexed)" --json \
  | jq -c '.[] | [.topics[1][0:10], .topics[2][26:], .topics[3][26:]]'
```

```
["0x00000000","f39fd6e51aad88f6f4ce6ab8827279cfffb92266","f39fd6e51aad88f6f4ce6ab8827279cfffb92266"]
["0x71f3d558","70997970c51812dc3a010c7d01b50e0d17dc79c8","f39fd6e51aad88f6f4ce6ab8827279cfffb92266"]
["0x21d11679","3c44cdddb6a900fa2b585dd299e03d12fa4293bc","70997970c51812dc3a010c7d01b50e0d17dc79c8"]
```

El primero es el `_grantRole` del constructor: la cuenta 0 se dio `DEFAULT_ADMIN_ROLE` al
desplegar. Después, la 0 nombró a la 1 moderadora, y la 1 nombró a la 2 editora.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 11 tests.
- Explicas qué pasaría si borraras el `_grantRole` del constructor.
- Explicas por qué la administradora no puede nombrar editores y qué tendría que hacer.
- Explicas qué puede hacer un atacante con la clave de una editora, y qué no.
- Explicas por qué una moderadora puede hacerse editora a sí misma.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Timelock y multisig](../../1-teoria/04-timelock-y-multisig.md) | **Ejercicio 01 — Roles con AccessControl** | [Ejercicio 02 — Pausa y dueño en dos pasos →](../ejercicio-02-pausa-y-dueno-en-dos-pasos/README.md) |
