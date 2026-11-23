# Ejercicio 01 — Cupones firmados

> Al terminar tendrás un contrato de cupones: el emisor firma "50 puntos para esta cuenta"
> con `cast`, sin gastar gas, y cualquiera canjea el cupón. Y verás en anvil que el mismo
> cupón no se canjea dos veces ni con otra cantidad.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 01](../../1-teoria/01-ecdsa-y-ecrecover.md) y
[Teoría 02](../../1-teoria/02-eip191-y-replay.md) leídas.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Coupons.sol` | El contrato: `ISSUER`, `points`, `used`, `couponHash` y `redeem`. Aquí trabajas |
| `test/Coupons.t.sol` | Los tests de cada paso. No lo modifiques |

Los tests firman como `cast wallet sign`: prefijo EIP-191 con longitud `32` sobre el hash del
cupón, y `vm.sign` con la clave del emisor. `test_Step2_RevertWhen_SignatureIsMalleated`
fabrica la firma gemela de la teoría 01.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-14-firmas_eip712_y_permit/2-practicas/ejercicio-01-cupones-firmados/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5740)`, `(5667)`, `(2072)` y `(2018)`: código detrás de un `revert`,
parámetros y una variable sin usar todavía.

**Verifica**: `0 tests passed, 11 failed, 0 skipped (11 total tests)`. Todos llaman a
`couponHash`, que aún revierte con `TODO: Paso 1`.

## Paso 1: El hash del cupón

**Por qué**: el hash es lo que firma el emisor y lo que el contrato rehará. Lleva los datos
del cupón (`to`, `amount`, `id`) y dos piezas contra el replay: la dirección del contrato
(otro despliegue, otro hash) y la red (`block.chainid`). `id` distingue dos cupones de la
misma cantidad para la misma cuenta. `abi.encode` da 32 bytes a cada campo (teoría 02).

**Abre** `src/Coupons.sol` y, en `couponHash`, borra el `revert` y descomenta:

```solidity
return keccak256(abi.encode(address(this), block.chainid, to, amount, id));
```

**Verifica**: `2 tests passed, 9 failed`. `test_Step1_HashDependsOnContractAndChain`
despliega otro `Coupons` y cambia de red con `vm.chainId(1)`: en los dos casos el hash es
otro.

## Paso 2: Recuperar el firmante

**Por qué**: el emisor firmó con el prefijo EIP-191, así que el contrato rehace ese hash con
`MessageHashUtils.toEthSignedMessageHash` y saca el firmante con `ECDSA.recover`, que
revierte con firmas rotas o maleables. Lo recuperado se compara con `ISSUER`: si otro firmó,
o el cupón cambió, sale otra dirección.

En `redeem`, borra el `revert` del paso 2 y descomenta sus líneas:

```solidity
address signer = ECDSA.recover(MessageHashUtils.toEthSignedMessageHash(hash), signature);
if (signer != ISSUER) revert InvalidSigner(signer);
points[to] += amount;
emit Redeemed(hash, to, amount);
```

Los puntos van a `to`, no a `msg.sender`: quien envía el cupón (el relayer) no se queda nada.

**Verifica**: `9 tests passed, 2 failed`. Mira tres de los que pasan:

- `test_Step2_RevertWhen_AmountIsChanged`: con `5000` en vez de `50`, el hash cambia y
  `InvalidSigner` lleva una dirección de nadie.
- `test_Step2_RevertWhen_SignatureIsMalleated`: `ecrecover` acepta la firma gemela;
  `ECDSA.recover` revierte con `ECDSAInvalidSignatureS`.
- `test_Step2_RevertWhen_ReplayedInOtherDeployment`: el cupón de un contrato no vale en otro.

Fallan los del paso 3: el mismo cupón se canjea dos veces.

## Paso 3: Una sola vez

**Por qué**: la firma es pública en cuanto se canjea: cualquiera la copia de la transacción y
la envía otra vez. Se marca el hash como usado **antes** de sumar los puntos (teoría 02). Se
marca el hash del cupón, no la firma, porque la firma es maleable (teoría 01).

Descomenta las dos líneas del paso 3, al principio de `redeem`:

```solidity
if (used[hash]) revert CouponUsed(hash);
used[hash] = true;
```

**Verifica**:

```bash
forge test --deny warnings
```

`11 tests passed, 0 failed, 0 skipped (11 total tests)`, sin warnings.

## Paso 4: En anvil

**Por qué**: ver el ciclo completo con cuentas reales: la cuenta 0 emite y firma, la 1 hace
de relayer y paga el gas, y la 2 recibe los puntos sin enviar nada.

Este paso no tiene código. Arranca anvil, despliega con la cuenta 0 como emisora y pide al
contrato el hash del cupón 1, de 50 puntos para la cuenta 2:

```bash
anvil --silent &
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1)
A0=$(cast wallet address "$PK0"); A2=$(cast wallet address $(cast wallet private-key "$M" 2))
forge create src/Coupons.sol:Coupons --private-key "$PK0" --broadcast --constructor-args $A0
C=0x5FbDB2315678afecb367f032d93F642f64180aa3
H=$(cast call $C "couponHash(address,uint256,uint256)(bytes32)" $A2 50 1); echo $H
SIG=$(cast wallet sign --private-key "$PK0" $H); echo $SIG
cast wallet verify --address $A0 $H $SIG
```

```
0xcd1e4947ee51ca6eaae8b50cb68f641c9bb1f06eaa5ade6b5bff61cad5fddd21
0xa7ca1abaec72ba2290f57baa9883e8b55969db4bd77330ea97ed1cb894f126ab39931ebce210bf582af6c3aa052c8dd39f59563bfb860dee6715a8e26b15bfa51c
Validation succeeded. Address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 signed this message.
```

Firmar no envió ninguna transacción. Ahora la cuenta 1 canjea el cupón para la 2:

```bash
cast send $C "redeem(address,uint256,uint256,bytes)" $A2 50 1 $SIG --private-key "$PK1" --json | jq -c '[.status, .from]'
cast call $C "points(address)(uint256)" $A2
```

```
["0x1","0x70997970c51812dc3a010c7d01b50e0d17dc79c8"]
50
```

La transacción es de la cuenta 1 (`0x7099…`); los puntos, de la 2. Prueba los tres ataques:
el mismo cupón otra vez, el cupón con otra cantidad y un cupón firmado por la cuenta 1:

```bash
cast send $C "redeem(address,uint256,uint256,bytes)" $A2 50 1 $SIG --private-key "$PK1"
cast send $C "redeem(address,uint256,uint256,bytes)" $A2 5000 1 $SIG --private-key "$PK1"
SIG2=$(cast wallet sign --private-key "$PK1" $(cast call $C "couponHash(address,uint256,uint256)(bytes32)" $A2 50 2))
cast send $C "redeem(address,uint256,uint256,bytes)" $A2 50 2 $SIG2 --private-key "$PK1"
```

```
Error: ... custom error 0xb5cf5f05: cd1e4947ee51ca6eaae8b50cb68f641c9bb1f06eaa5ade6b5bff61cad5fddd21, ...
Error: ... custom error 0xbf18af43: ...: InvalidSigner(0xf3AC469362253067ADE5F0959EB074603c67e510)
Error: ... custom error 0xbf18af43: ...: InvalidSigner(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
```

El primero, cast no lo nombra. Búscalo por su selector:

```bash
cast sig "CouponUsed(bytes32)"
```

```
0xb5cf5f05
```

**Verifica**: los tres errores tienen sentido. `CouponUsed` lleva el hash del cupón 1. Con
`5000`, el hash es otro y `0xf3AC…` no es nadie. El cupón 2 lo firmó la cuenta 1, que no es la
emisora: `InvalidSigner` lleva su dirección.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 11 tests.
- Explicas qué pasaría si `couponHash` no incluyera `address(this)` y el emisor tuviera dos
  tiendas.
- Explicas por qué los puntos van a `to` y no a `msg.sender`.
- Explicas por qué se marca el hash y no la firma.
- Explicas qué le haría falta al cupón para caducar.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Permit (ERC-2612)](../../1-teoria/04-permit-erc2612.md) | **Ejercicio 01 — Cupones firmados** | [Ejercicio 02 — Votos con EIP-712 →](../ejercicio-02-votos-con-eip712/README.md) |
