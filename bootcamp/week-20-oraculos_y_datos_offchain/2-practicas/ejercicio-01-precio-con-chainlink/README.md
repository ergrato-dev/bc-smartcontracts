# Ejercicio 01 — Precio con Chainlink

> Al terminar tendrás una taquilla que vende en ETH entradas de 25 dólares: lee el precio
> ETH/USD de un price feed, lo rechaza si es imposible o antiguo, convierte dólares a wei y wei a
> dólares redondeando a favor de la taquilla, y devuelve el cambio a quien paga de más.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 01](../../1-teoria/01-el-problema-del-oraculo.md) y
[Teoría 02 — Price feeds](../../1-teoria/02-price-feeds.md) leídas.

## Contexto

Proyecto Foundry, como los de la fase 3. Los tests usan `MockV3Aggregator`, el feed falso de
Chainlink, con 8 decimales y 3000 dólares al empezar, y una antigüedad máxima de 1 hora.

| Archivo | Qué es |
| ------- | ------ |
| `src/PriceConsumer.sol` | La taquilla y los cinco pasos. Aquí trabajas |
| `test/PriceConsumer.t.sol` | Los tests. **No lo modifiques** |
| `foundry.toml` | Con el remapping `@chainlink/contracts/` a la copia de la imagen |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-20-oraculos_y_datos_offchain/2-practicas/ejercicio-01-precio-con-chainlink/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 passed; 8 failed`. Cada test falla con el `TODO` del paso que necesita. Los dos
del paso 5 dicen `TODO: Paso 3`: `buy` llama a `usdToWei`, que todavía no existe.

## Paso 1: El precio tal cual

**Por qué**: antes de comprobar nada, ver qué devuelve un feed y cómo se desestructura una tupla
de cinco valores.

```solidity
(, int256 answer,,,) = FEED.latestRoundData();
return answer;
```

Cada coma sin nombre descarta un campo: te quedas solo con el segundo.

**Abre** `src/PriceConsumer.sol`, borra el `revert` de `rawPrice` y descomenta sus líneas.
Ejecuta `forge test`.

**Verifica**: `1 passed; 7 failed`, con `test_Paso1_RawPrice` en verde. El test cambia el
precio a `-1` y `rawPrice` lo devuelve sin quejarse: por eso hace falta el paso 2.

## Paso 2: Un precio en el que confiar

**Por qué**: un precio 0, negativo o de hace horas cobraría mal. Mejor no vender.

```solidity
(, int256 answer,, uint256 updatedAt,) = FEED.latestRoundData();
if (answer <= 0) revert InvalidPrice(answer);
if (block.timestamp - updatedAt > MAX_AGE) revert StalePrice(updatedAt);
return uint256(answer);
```

**Verifica**: `4 passed; 4 failed`. Los tres tests del paso 2 en verde:

- `test_Paso2_Price`: 3000 dólares, y todavía vale justo al cumplir 1 hora.
- `test_Paso2_RevertWhen_PriceNotPositive`: `InvalidPrice(0)` e `InvalidPrice(-5)`.
- `test_Paso2_RevertWhen_Stale`: un segundo después de la hora, `StalePrice(1750000000)`, la
  hora de la última ronda.

## Paso 3: Dólares a wei

**Por qué**: la taquilla cobra en ETH. La cuenta usa los decimales que dice el feed y redondea
hacia arriba: cobrar un wei de menos en cada venta es regalarlo.

```solidity
return Math.mulDiv(usdAmount, 10 ** FEED.decimals(), price(), Math.Rounding.Ceil);
```

`usdAmount` tiene 18 decimales y el precio, los del feed: el resultado sale en wei (teoría 02).
Llamar a `price()` y no a `latestRoundData` directamente hace que la conversión herede sus
comprobaciones.

**Verifica**: `5 passed; 3 failed`. `test_Paso3_UsdToWei`: 30 dólares son `0.01 ether`; 25
dólares, `8333333333333334` wei (el 4 final es el redondeo); con un feed de 18 decimales a 2000
dólares, 30 dólares son `0.015 ether`. Prueba a quitar `, Math.Rounding.Ceil`: el test falla con
`assertion failed: 8333333333333333 != 8333333333333334`, y cuando hagas el paso 4, también su
ida y vuelta (`24999999999999999000 < 25000000000000000000`): la taquilla cobraría menos de 25
dólares. Déjalo como estaba.

## Paso 4: Wei a dólares

**Por qué**: para enseñar en dólares lo que hay en la taquilla. Al revés que al cobrar, se
redondea hacia abajo: nunca se promete más de lo que hay.

```solidity
return Math.mulDiv(weiAmount, price(), 10 ** FEED.decimals());
```

Sin cuarto argumento, `mulDiv` redondea hacia abajo.

**Verifica**: `6 passed; 2 failed`. `test_Paso4_WeiToUsd`: 1 ETH son 3000 dólares; cobrar 25
dólares y convertirlos de vuelta nunca da menos de 25; a 3333,33333333 dólares, 1 wei vale
`3333` (en unidades de 10⁻¹⁸ dólares) y no 3333,33.

## Paso 5: Vender y devolver el cambio

**Por qué**: si `buy` exigiera el importe exacto, una ronda nueva del feed entre que tu página
calcula el precio y la transacción entra en un bloque haría revertir la compra. Aceptar de más y
devolver el resto lo evita.

```solidity
uint256 required = usdToWei(PRICE_USD);
if (msg.value < required) revert InsufficientPayment(required, msg.value);
emit TicketSold(msg.sender, required);
uint256 change = msg.value - required;
if (change > 0) {
    (bool ok,) = msg.sender.call{value: change}("");
    if (!ok) revert RefundFailed();
}
```

El evento y todas las cuentas van **antes** de enviar el cambio (comprobaciones, efectos,
interacciones, semana 07). La taquilla no guarda nada por comprador, así que no hay estado que
una reentrada pueda pisar.

**Verifica**: `8 passed; 0 failed`. `test_Paso5_Buy` paga 0,01 ETH y recibe el cambio: la
taquilla se queda exactamente con `usdToWei(25e18)`. `test_Paso5_RevertWhen_InsufficientOrStale`:
un wei de menos da `InsufficientPayment`, y con el precio de hace 2 horas, `StalePrice`.

## Qué aprendiste

- Un contrato lee un price feed con `latestRoundData` y se queda con `answer` y `updatedAt`.
- Un precio no positivo o antiguo se rechaza: mejor no operar que operar mal.
- Las conversiones leen `decimals()` y redondean a favor del contrato con `Math.mulDiv`.
- Con un precio que cambia, aceptar de más y devolver el cambio evita reverts innecesarios.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — IPFS y metadatos](../../1-teoria/04-ipfs-y-metadatos.md) | **Ejercicio 01 — Precio con Chainlink** | [Ejercicio 02 — Sorteo con VRF →](../ejercicio-02-sorteo-con-vrf/README.md) |
