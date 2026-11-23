# Ejercicio 03 — Permit

> Al terminar tendrás una tienda que cobra en puntos de dos maneras: con `approve` y `buy`
> (dos transacciones) y con un permit firmado y `buyWithPermit` (una). La compra con permit
> resiste a quien envía antes tu firma. En anvil firmarás el permit con `cast`.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 04](../../1-teoria/04-permit-erc2612.md) leída y el
[ejercicio 02](../ejercicio-02-votos-con-eip712/README.md) terminado.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/PointsToken.sol` | Un ERC-20 con `ERC20Permit`. Ya está completo: léelo |
| `src/Shop.sol` | La tienda: `PRICE`, `purchases`, `buy`, `buyWithPermit` y `_buy`. Aquí trabajas |
| `test/Shop.t.sol` | Los tests de cada paso. No lo modifiques |

`PointsToken` pasa el mismo nombre a `ERC20` y a `ERC20Permit`: el `name` del token es el
`name` del dominio EIP-712, y así una wallet sabe montar el permit leyendo el token. El test
`_permit` firma el struct `Permit` con el `DOMAIN_SEPARATOR()` del token.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-14-firmas_eip712_y_permit/2-practicas/ejercicio-03-permit/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5667)` y `(2018)`.

**Verifica**: `2 tests passed, 8 failed, 0 skipped (10 total tests)`. Pasan los dos
`test_Inherited_`: el token ya acepta permits. En `test_Inherited_PermitSetsAllowance`,
`mallory` envía el permit de `buyer` y la allowance queda puesta: quien envía no importa,
importa quien firma.

## Paso 1: Cobrar con la allowance

**Por qué**: `_buy` es el cobro común a las dos compras. Apunta la compra y cobra con
`safeTransferFrom` (semana 11), que gasta la allowance de la tienda y revierte si no llega.
Si revierte, la compra apuntada se deshace con todo lo demás.

**Abre** `src/Shop.sol` y, en `_buy`, borra el `revert` y descomenta:

```solidity
purchases[buyer]++;
emit Purchased(buyer, PRICE);
TOKEN.safeTransferFrom(buyer, address(this), PRICE);
```

**Verifica**: `4 tests passed, 6 failed`. `test_Step1_BuyAfterApprove` es el camino de dos
transacciones: `approve` y `buy`. Sin `approve`, `ERC20InsufficientAllowance(shop, 0, price)`.

## Paso 2: Comprar con permit

**Por qué**: el permit sustituye al `approve`. `owner` es `msg.sender`: solo quien firmó puede
gastar su permit aquí. El `try ... {} catch {}` ignora un permit que falla, porque puede
fallar sin culpa de nadie: si alguien vio la firma en el mempool y la envió antes al token,
el nonce ya está gastado y la allowance ya está puesta (teoría 04). `_buy` decide: con
allowance, cobra; sin ella, revierte.

En `buyWithPermit`, borra el `revert` y descomenta:

```solidity
try TOKEN.permit(msg.sender, address(this), PRICE, deadline, v, r, s) {} catch {}
_buy(msg.sender);
```

**Verifica**:

```bash
forge test --deny warnings
```

`10 tests passed, 0 failed, 0 skipped (10 total tests)`, sin warnings. Fíjate en que los
cuatro `RevertWhen` del paso 2 esperan el mismo error, `ERC20InsufficientAllowance(shop, 0,
price)`: un permit falso, caducado, repetido o de otra persona no da allowance, y el cobro
revierte.

Ahora quita el `try` para ver el ataque: deja la línea como
`TOKEN.permit(msg.sender, address(this), PRICE, deadline, v, r, s);` y ejecuta
`forge test --match-test FrontRun`:

```
[FAIL: ERC2612InvalidSigner(0xf50e113A02C9f058740a228Bd19F18bAC00EB14e, 0x0fF93eDfa7FB7Ad5E962E4C0EdB9207C03a0fe02)] test_Step2_FrontRunPermitDoesNotBlockTheBuy() (gas: 167598)
```

`mallory` gastó el nonce antes, y el permit de `buyer` revierte arrastrando la compra.
Vuelve a poner el `try`.

## Paso 3: En anvil

**Por qué**: firmar un permit como lo haría una wallet y comprar en una transacción.

Este paso no tiene código. La cuenta 0 despliega el token (recibe 1000 puntos) y la tienda,
y da 200 puntos a la cuenta 2:

```bash
anvil --silent &
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK2=$(cast wallet private-key "$M" 2)
A2=$(cast wallet address "$PK2")
forge create src/PointsToken.sol:PointsToken --private-key "$PK0" --broadcast --constructor-args 1000ether
T=0x5FbDB2315678afecb367f032d93F642f64180aa3
forge create src/Shop.sol:Shop --private-key "$PK0" --broadcast --constructor-args $T
SHOP=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
cast send $T "transfer(address,uint256)" $A2 200ether --private-key "$PK0" --json | jq -r .status
cast call $T "nonces(address)(uint256)" $A2
```

`0x1` y `0`. El permit de la cuenta 2 para la tienda, por 50 puntos (`50 ether` en
unidades de 18 decimales), en `permit.json`. `value` va entre comillas: es más grande que
los enteros que JSON garantiza.

```json
{
  "types": {
    "EIP712Domain": [
      {"name": "name", "type": "string"},
      {"name": "version", "type": "string"},
      {"name": "chainId", "type": "uint256"},
      {"name": "verifyingContract", "type": "address"}
    ],
    "Permit": [
      {"name": "owner", "type": "address"},
      {"name": "spender", "type": "address"},
      {"name": "value", "type": "uint256"},
      {"name": "nonce", "type": "uint256"},
      {"name": "deadline", "type": "uint256"}
    ]
  },
  "primaryType": "Permit",
  "domain": {"name": "Club Points", "version": "1", "chainId": 31337, "verifyingContract": "0x5FbDB2315678afecb367f032d93F642f64180aa3"},
  "message": {
    "owner": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
    "spender": "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
    "value": "50000000000000000000",
    "nonce": 0,
    "deadline": 2000000000
  }
}
```

Firma, parte la firma en `r`, `s` y `v`, y compra en una sola transacción:

```bash
SIG=$(cast wallet sign --private-key "$PK2" --data --from-file permit.json)
R=0x${SIG:2:64}; S=0x${SIG:66:64}; V=$((16#${SIG:130:2})); echo "r=$R s=$S v=$V"
cast send $SHOP "buyWithPermit(uint256,uint8,bytes32,bytes32)" 2000000000 $V $R $S --private-key "$PK2" --json | jq -c '[.status, (.logs | length)]'
cast call $SHOP "purchases(address)(uint256)" $A2
cast call $T "balanceOf(address)(uint256)" $A2
cast call $T "nonces(address)(uint256)" $A2
```

```
r=0x40d05337abcdb306f1e618c102b347d174d46ed026a0e8900a1d3dc03636c16b s=0x33ee7305c363e43c65f25f9ccabee4d54ea413cdfe09e60fc155280859bb6978 v=27
["0x1",3]
1
150000000000000000000 [1.5e20]
1
```

Una transacción con tres eventos: `Approval` (el permit), `Purchased` y `Transfer`. Ahora
repite la compra con la misma firma, y después envía la firma directamente al token desde
la cuenta 0:

```bash
cast send $SHOP "buyWithPermit(uint256,uint8,bytes32,bytes32)" 2000000000 $V $R $S --private-key "$PK2"
cast send $T "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)" $A2 $SHOP 50ether 2000000000 $V $R $S --private-key "$PK0"
```

```
Error: ... custom error 0xfb8f41b2: 000000000000000000000000e7f1725e7734ce288f8367e1bb143e90bb3f0512000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002b5e3af16b1880000, ...
Error: ... custom error 0x4b800e46: ...: ERC2612InvalidSigner(0x3c18126fDc2A502344Df76741B0e4d029B44092b, 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)
```

**Verifica**: `cast sig "ERC20InsufficientAllowance(address,uint256,uint256)"` da
`0xfb8f41b2`. La tienda ignoró el permit repetido y el cobro no encontró allowance: shop, `0`
y `0x2b5e3af16b1880000` (50 puntos). El token, llamado directamente, sí revierte: con el
nonce en 1, la firma recupera otra dirección.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 10 tests.
- Explicas qué transacción ahorra `buyWithPermit` frente a `buy`.
- Explicas por qué el `try` no deja comprar con un permit falso.
- Explicas por qué `buyWithPermit` usa `msg.sender` como `owner`.
- Explicas qué tendría que comprobar una persona antes de firmar un permit en una web.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Votos con EIP-712](../ejercicio-02-votos-con-eip712/README.md) | **Ejercicio 03 — Permit** | [Proyecto — Órdenes firmadas →](../../3-proyecto/README.md) |
