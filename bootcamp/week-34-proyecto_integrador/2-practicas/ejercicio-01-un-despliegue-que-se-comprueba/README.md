# Ejercicio 01 — Un despliegue que se comprueba

> Al terminar tendrás el script de despliegue de una tienda que paga en puntos, con el traspaso a
> un timelock, y un segundo script que comprueba cualquier despliegue suyo solo con lecturas:
> quién administra, que nadie más tenga roles y que los contratos estén conectados entre sí.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 01 — El protocolo completo](../../1-teoria/01-el-protocolo-completo.md)
leída.

## Contexto

Proyecto Foundry con dos contratos y dos scripts:

| Archivo | Qué es |
| ------- | ------ |
| `src/Points.sol` | Un ERC-20 con `AccessControlEnumerable`: solo `MINTER_ROLE` acuña |
| `src/Shop.sol` | Una tienda `Ownable`: cada compra cuesta `price` y da 10 puntos |
| `script/Deploy.s.sol` | El despliegue en tres fases: `deployContracts`, `wire` (paso 1) y `handOver` (paso 2) |
| `script/CheckDeployment.s.sol` | Las comprobaciones: `_checkAdmins` (paso 3), `_checkNoOneElse` (paso 4) y `_checkWiring` (paso 5) |
| `test/Deployment.t.sol` | Los tests de cada paso. No lo cambies |

Los tests ejecutan los scripts como cualquier contrato: `new Deploy()` y una llamada. Dentro,
`vm.startBroadcast()` firma con el remitente por defecto de forge, `DEFAULT_SENDER`: es el
`deployer` de los tests. Para fabricar un despliegue malo, el test hace `vm.prank` como el
timelock y cambia un rol: así se cuela una cuenta de más sin tocar el script.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-34-proyecto_integrador/2-practicas/ejercicio-01-un-despliegue-que-se-comprueba/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `1 tests passed, 14 failed`. Solo pasa `test_Paso1_RevertWhen_NotWired`: sin el
paso 1, la tienda no puede acuñar y la compra revierte, que es lo que ese test espera. Lo
primero en rojo:

```text
[FAIL: TODO: Paso 1] test_Paso1_ShopMintsPoints() (gas: 4636906)
```

## Paso 1: Conectar los contratos

**Por qué**: desplegar no basta. La tienda llama a `points.mint`, y `Points` solo deja acuñar a
`MINTER_ROLE`. Sin esta llamada todo compila y se despliega, y la primera compra revierte.

**Abre** `script/Deploy.s.sol`, borra el `revert` de `wire` y descomenta:

```solidity
d.points.grantRole(d.points.MINTER_ROLE(), address(d.shop));
```

**Verifica**: `2 tests passed, 13 failed`. Ahora falla el traspaso:

```text
[FAIL: TODO: Paso 2] test_Paso2_TimelockOwnsEverything() (gas: 4637988)
```

## Paso 2: Traspasar al timelock

**Por qué**: al terminar la fase 1, quien firma es administrador de los puntos (los podría
acuñar sin comprar) y dueño de la tienda (podría retirar su ETH). Ninguna de las dos cosas le
toca a una clave: le tocan al timelock, que solo actúa tras su plazo. El orden importa: primero
el timelock recibe el rol y después quien firma renuncia. Al revés, los puntos se quedarían sin
administrador.

**Borra** el `revert` de `handOver` y descomenta:

```solidity
d.points.grantRole(d.points.DEFAULT_ADMIN_ROLE(), address(d.timelock));
d.points.renounceRole(d.points.DEFAULT_ADMIN_ROLE(), deployer);
d.shop.transferOwnership(address(d.timelock));
```

**Verifica**: `4 tests passed, 11 failed`. El despliegue ya es bueno, pero nada lo comprueba:
`CheckDeployment` aún no mira nada.

```text
[FAIL: Error != expected error: TODO: Paso 3 != DeployerStillAdmin(0x34A1D3fff3958843C43aD80F30b94c510645C316)] test_Paso3_RevertWhen_DeployerStillAdmin() (gas: 4920233)
```

## Paso 3: Quién administra

**Por qué**: es lo primero que mira un auditor: ¿quién puede cambiar las reglas después del
despliegue? Las comprobaciones son de las dos caras: que el timelock tenga el rol, y que quien
desplegó no lo tenga, ni en los puntos ni en el propio timelock. Un timelock con un
administrador aparte no protege nada: ese administrador se da a sí mismo el rol de proponer y
ejecutar.

**Abre** `script/CheckDeployment.s.sol`, borra el `revert` de `_checkAdmins` y descomenta:

```solidity
bytes32 admin = d.points.DEFAULT_ADMIN_ROLE();
if (!d.points.hasRole(admin, address(d.timelock))) revert NotAdmin(address(d.points), address(d.timelock));
if (d.points.hasRole(admin, deployer)) revert DeployerStillAdmin(address(d.points));
if (d.timelock.hasRole(d.timelock.DEFAULT_ADMIN_ROLE(), deployer)) revert DeployerStillAdmin(address(d.timelock));
```

**Verifica**: `7 tests passed, 8 failed`. Pasan los tres del paso 3. Pero una cuenta de más con
el rol de minter no la ve nadie:

```text
[FAIL: Error != expected error: TODO: Paso 4 != UnexpectedMembers(0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6, 2)] test_Paso4_RevertWhen_AnExtraMinter() (gas: 4941552)
```

## Paso 4: Nadie más

**Por qué**: `hasRole` solo responde por la cuenta que le preguntas. La cuenta que diste de
minter para probar en testnet, o la de un compañero, no la preguntas porque no te acuerdas de
ella. `AccessControlEnumerable` cuenta los miembros de cada rol: si hay uno y es el esperado, no
hay nadie más.

**Borra** el `revert` de `_checkNoOneElse` y descomenta:

```solidity
bytes32 admin = d.points.DEFAULT_ADMIN_ROLE();
bytes32 minter = d.points.MINTER_ROLE();
if (d.points.getRoleMemberCount(admin) != 1) revert UnexpectedMembers(admin, d.points.getRoleMemberCount(admin));
if (d.points.getRoleMemberCount(minter) != 1) revert UnexpectedMembers(minter, d.points.getRoleMemberCount(minter));
if (!d.points.hasRole(minter, address(d.shop))) revert NotMinter(address(d.shop));
```

El hash de `UnexpectedMembers` en la salida del paso anterior es `MINTER_ROLE`,
`keccak256("MINTER_ROLE")`; el de `DEFAULT_ADMIN_ROLE` es cero.

**Verifica**: `10 tests passed, 5 failed`. Falla hasta el despliegue bueno, porque `check` llega
a `_checkWiring`:

```text
[FAIL: TODO: Paso 5] test_Paso5_ChecksAGoodDeployment() (gas: 4835738)
```

## Paso 5: Las conexiones

**Por qué**: los roles pueden estar bien y el despliegue, mal: la tienda que el timelock posee
puede acuñar otros puntos (una dirección copiada de otra red), o el timelock puede esperar una
hora en vez de dos días. Son valores que pasaste al desplegar y que nadie más vuelve a mirar.

**Borra** el `revert` de `_checkWiring` y descomenta:

```solidity
if (d.shop.owner() != address(d.timelock)) revert WrongOwner(d.shop.owner());
if (address(d.shop.points()) != address(d.points)) revert WrongPoints(address(d.shop.points()));
if (d.timelock.getMinDelay() < MIN_DELAY) revert DelayTooShort(d.timelock.getMinDelay());
```

**Verifica**: `15 tests passed, 0 failed`. Con `forge test --deny warnings`, sin warnings.
`test_Paso5_RunDeploysAndChecks` ejecuta `run()`, el punto de entrada de `forge script`: despliega
y comprueba, y si la comprobación falla, el script revierte antes de emitir nada.

## Para pensar

- `Deploy.run()` comprueba en la simulación de `forge script`. ¿Qué cambia si la comprobas
  después, contra la red, con `CheckDeployment` y las direcciones de `broadcast/`? ¿Qué podría
  haber pasado entre la simulación y los bloques reales?
- `Points` usa `AccessControlEnumerable`. Si fuera `AccessControl`, ¿cómo sabrías que no hay un
  minter de más? (Pista: los eventos `RoleGranted` y `RoleRevoked`.)
- El proponente del timelock es `PROPOSER`. ¿Qué comprobarías de él? ¿Y si es una multifirma?
- Ninguna comprobación mira el ETH de la tienda ni el `totalSupply` de los puntos. ¿Cuándo
  tendría sentido, y por qué no en un despliegue recién hecho?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Entregar y mantener](../../1-teoria/04-entregar-y-mantener.md) | **Ejercicio 01 — Un despliegue que se comprueba** | [Ejercicio 02 — Auditar código ajeno →](../ejercicio-02-auditar-codigo-ajeno/README.md) |
