# Ejercicio 03 — CREATE y CREATE2

> Al terminar tendrás una fábrica que despliega una caja fuerte por cliente, sabrás su
> dirección antes de que exista, impedirás que otro la ocupe, y habrás enviado ETH a una
> caja que aún no estaba desplegada.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 05](../../1-teoria/05-create-y-create2.md) leída y
[ejercicio 02](../ejercicio-02-delegatecall-y-try-catch/README.md) terminado.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Vault.sol` | Una caja fuerte: recibe ETH y `withdraw()` se lo envía todo a su dueño. **Terminada: no la cambies** |
| `src/VaultFactory.sol` | La fábrica: `create`, `saltOf`, `predict` y `create2`. Aquí trabajas |
| `test/VaultFactory.t.sol` | Un test por paso (el paso 4 tiene cuatro). No lo modifiques |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-10-llamadas_entre_contratos/2-practicas/ejercicio-03-create-y-create2/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5667)` y `(2018)`, los de las funciones que solo revierten.

**Verifica**: `0 tests passed, 7 failed, 0 skipped (7 total tests)`, cada uno con su
`TODO`.

## Paso 1: Desplegar con `new`

**Por qué**: `new Vault(owner)` usa `CREATE`. La dirección depende de la fábrica y de su
nonce, que sube con cada contrato que crea. Es predecible, pero solo si sabes cuántos
contratos habrá creado antes.

**Abre** `src/VaultFactory.sol`, en `create`:

```solidity
return new Vault(msg.sender);
```

**Verifica**: `1 tests passed, 6 failed`. `test_Step1_Create` comprueba que la primera
caja está en `vm.computeCreateAddress(factory, 1)` y la segunda en la del nonce 2: un
contrato empieza a contar en 1.

## Paso 2: Un salt por cuenta

**Por qué**: si la fábrica usara tal cual el salt que eligen los usuarios, cualquiera podría
ver tu transacción pendiente y desplegar antes con tu mismo salt (teoría 05). Mezclando la
cuenta en el salt, el de alice y el de bob nunca coinciden.

```solidity
return keccak256(abi.encode(owner, salt));
```

`abi.encode`, no `abi.encodePacked`: con tipos de tamaño fijo daría lo mismo, pero
`abi.encode` es la opción que nunca colisiona (teoría 01).

**Verifica**: `2 tests passed, 5 failed`.

## Paso 3: Predecir

**Por qué**: la fórmula de `CREATE2` usa la fábrica, el salt y el hash del código de
creación, que incluye los argumentos del constructor. Por eso `predict` recibe el dueño:
con otro dueño, otra dirección.

```solidity
bytes32 initCodeHash = keccak256(bytes.concat(type(Vault).creationCode, abi.encode(owner)));
bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), saltOf(owner, salt), initCodeHash));
return address(uint160(uint256(hash)));
```

**Verifica**: `3 tests passed, 4 failed`. `test_Step3_Predict` compara con
`vm.computeCreate2Address`, la misma fórmula escrita en forge-std.

## Paso 4: Desplegar con `CREATE2`

**Por qué**: el despliegue tiene que usar exactamente el salt y el código de `predict`, o
la caja acabará en otra dirección. Y si la dirección ya está ocupada, `CREATE2` falla sin
datos y gastando todo el gas: mejor comprobarlo antes y revertir con un error que diga qué
pasó.

```solidity
address predicted = predict(msg.sender, salt);
if (predicted.code.length > 0) revert AlreadyDeployed(predicted);
return new Vault{salt: saltOf(msg.sender, salt)}(msg.sender);
```

**Verifica**:

```bash
forge test --deny warnings
```

`7 tests passed, 0 failed, 0 skipped (7 total tests)`, sin warnings. Los cuatro tests del
paso:

| Test | Qué comprueba |
| ---- | ------------- |
| `test_Step4_Create2` | La caja está donde dijo `predict` y su dueño es alice |
| `test_Step4_RevertWhen_SaltReused` | El mismo salt dos veces revierte con `AlreadyDeployed` |
| `test_Step4_SameSaltOtherAccount` | Bob usa el salt de alice y obtiene otra caja, suya |
| `test_Step4_FundsArriveBeforeDeploy` | ETH enviado a la dirección antes del despliegue llega a alice al retirar |

## Paso 5: ETH a una caja que aún no existe, en anvil

**Por qué**: el último test es la razón de ser de `CREATE2`. Una dirección se puede usar
(recibir ETH, apuntarla en otro contrato) antes de que tenga código. Hazlo en anvil, sin
`vm.deal`: con un pago de verdad desde otra cuenta.

Este paso no tiene código. Arranca anvil y despliega la fábrica desde la cuenta 0:

```bash
anvil --silent &
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1); PK2=$(cast wallet private-key "$M" 2)
forge create src/VaultFactory.sol:VaultFactory --private-key "$PK0" --broadcast
F=0x5FbDB2315678afecb367f032d93F642f64180aa3
ALICE=$(cast wallet address "$PK1")
SALT=$(cast keccak "caja-1")
V=$(cast call $F "predict(address,bytes32)(address)" $ALICE $SALT)
echo $V
```

```
0x38a74867Fd5937f7757FB684F52D947C4c4D32d5
```

La cuenta 2 le envía 0,5 ether a esa dirección, que todavía no tiene código:

```bash
cast send $V --value 0.5ether --private-key "$PK2"
cast code $V
cast balance $V --ether
```

Recibo con `status 1 (success)`, `0x` (sin código) y `0.500000000000000000`. Ahora alice
despliega su caja y retira:

```bash
cast send $F "create2(bytes32)" $SALT --private-key "$PK1"
cast call $V "OWNER()(address)"
cast send $V "withdraw()" --private-key "$PK1"
cast balance $V --ether
```

`OWNER()` responde `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` (alice), y la caja queda a
`0.000000000000000000`: los 0,5 ether pasaron a alice, menos el gas de sus transacciones.

**Verifica**: repite el `create2` de alice:

```bash
cast send $F "create2(bytes32)" $SALT --private-key "$PK1"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x29ab51bf: 00000000000000000000000038a74867fd5937f7757fb684f52d947c4c4d32d5, data: "0x29ab51bf00000000000000000000000038a74867fd5937f7757fb684f52d947c4c4d32d5": AlreadyDeployed(0x38a74867Fd5937f7757FB684F52D947C4c4D32d5)
```

El error propio, con la dirección ocupada. `cast` le pone nombre porque encuentra el error
en los artefactos del proyecto (`out/`).

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 7 tests.
- Explicas qué entra en la fórmula de `CREATE2` y por qué `predict` necesita al dueño.
- Explicas qué ataque evita `saltOf`.
- Explicas por qué el ETH enviado antes del despliegue no se perdió, y qué habría pasado
  si la fábrica hubiera desplegado la caja con otro dueño.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — delegatecall y try/catch](../ejercicio-02-delegatecall-y-try-catch/README.md) | **Ejercicio 03 — CREATE y CREATE2** | [Proyecto — Registro conectado →](../../3-proyecto/README.md) |
