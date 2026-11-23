# Teoría 01 — Manipulación de oráculos

## 🎯 Objetivos

- Explicar qué es un pool de producto constante y por qué su precio cambia con cada swap.
- Distinguir un precio al contado (spot), un precio medio en el tiempo (TWAP) y un price feed, y
  decir cuánto cuesta mover cada uno.
- Reconocer en un contrato un precio que sale de algo que cualquiera puede mover en la misma
  transacción.
- Leer un precio de Chainlink con sus comprobaciones y llevarlo a 18 decimales.

## 1. Qué problema resuelve

La semana 21 atacó el código: un orden mal puesto, un permiso que falta, un bucle sin límite.
Esta semana ataca la **economía** del contrato. El código hace exactamente lo que dice, sin un
solo fallo de programación, y aun así alguien gana dinero que no debería, porque el contrato se
fía de un precio, de un orden de transacciones o de un redondeo que el atacante controla. Son
las **vulnerabilidades económicas**, y en DeFi (finanzas descentralizadas: préstamos, cambios
de tokens y depósitos que funcionan con contratos, sin un banco en medio) se han llevado más
dinero que cualquier otra clase.

La primera es la más directa. En la semana 20 tu registro calculó su tasa con un **oráculo**: un
contrato que trae a la cadena un dato de fuera, como el precio ETH/USD. Usaste Chainlink, que
lo calcula fuera de la cadena con varios nodos. Pero muchos protocolos tienen la tentación de
algo más simple: leer el precio de un **exchange descentralizado** (DEX) que ya está en la
cadena. Es gratis, está siempre al día y no depende de nadie. Y se puede comprar.

En octubre de 2022, un atacante de Mango Markets compró en pocos minutos el token MNGO en los
mercados de los que el protocolo leía el precio, lo multiplicó varias veces y pidió prestado
contra sus MNGO, a ese precio, más de 100 millones de dólares en otros tokens. Ninguna línea de
código falló.

## 2. Cómo funciona

### Un pool de producto constante

Un **pool de liquidez** es un contrato que guarda dos tokens y cambia uno por otro. Quien
deposita los dos tokens es un **proveedor de liquidez**, y lo que hay de cada token son sus
**reservas**. Un **swap** es un cambio: metes una cantidad de un token y sacas del otro.

¿Cuánto sacas? La fórmula más usada, la de Uniswap v2, es la de **producto constante**: el
producto de las dos reservas no puede bajar con un swap.

```text
reserveUsd × reserveGov = k
```

En el ejercicio 01 el pool empieza con 1 000 000 USD y 1000 GOV, así que `k` es 10⁹. El
**precio al contado** (spot price) es lo que vale un GOV según las reservas de ahora:
`1 000 000 / 1000 = 1000` USD.

Si alguien mete 1 000 000 USD, la reserva de USD pasa a 2 000 000 y, para que `k` siga igual, la
de GOV tiene que bajar a 500: el pool le da 500 GOV. El precio al contado pasa a ser
`2 000 000 / 500 = 4000` USD. Un solo swap ha multiplicado el precio por cuatro.

Eso no es un fallo del pool: es como funciona. El precio de un pool lo fija quien compra y
vende en él, y se recupera cuando otros aprovechan la diferencia con otros mercados
(**arbitraje**). Pero eso tarda al menos una transacción, y el atacante solo necesita que el
precio esté mal durante la suya. La semana 30 construye el pool entero, con comisiones y
proveedores; para esta semana basta la fórmula.

### Anatomía del ataque

El blanco del ejercicio 01 es `SpotLender`, un prestamista que acepta GOV como **colateral**
(garantía que se queda si no devuelves) y presta hasta el 80 % de lo que vale, en USD. El valor
lo calcula con el precio al contado del pool. El ataque tiene tres pasos, todos en la misma
transacción:

1. **Mover el precio.** Comprar 500 GOV con 1 000 000 USD: el precio sube de 1000 a 4000.
2. **Usar el precio.** Dejar los 500 GOV de colateral: para `SpotLender` valen
   `500 × 4000 = 2 000 000` USD, y presta el 80 %: 1 600 000 USD.
3. **Quedarse la diferencia.** Gastó 1 000 000 y se lleva 1 600 000. El prestamista tiene
   500 GOV que, a precio justo, valen 500 000: una deuda de 1 600 000 que nadie va a pagar.

El paso 1 necesita un millón. La teoría 02 explica cómo conseguirlo sin tenerlo.

### El mismo ataque, hacia abajo

Subir el precio sirve para pedir más de lo que vale el colateral. Bajarlo sirve para otra cosa.
Los prestamistas de verdad tienen **liquidaciones**: si el colateral de una deuda baja tanto que
ya no la cubre, cualquiera puede pagar esa deuda y quedarse el colateral con un descuento, para
que el prestamista no pierda. Es la defensa del prestamista contra un precio que cae.

Con un precio al contado, el atacante vende GOV en el pool, el precio se hunde, las deudas
honradas de otros usuarios parecen sin cubrir y él mismo las liquida, cobrando el descuento.
Después compra GOV de vuelta y el precio vuelve a su sitio. Las víctimas no son el protocolo,
sino sus usuarios, que pierden el colateral sin que el mercado real se haya movido.

La lección es la misma en las dos direcciones: un precio que se puede mover dentro de la
transacción que lo usa no es un precio, es un parámetro que elige el atacante.

### Tres tipos de precio

| Precio | De dónde sale | Cuánto cuesta moverlo |
| ------ | ------------- | --------------------- |
| Al contado | Las reservas de un pool ahora | Un swap en la misma transacción; con un flash loan, casi nada |
| TWAP | La media de los precios de un pool durante un tiempo | Mantener el precio movido varios bloques, contra los arbitrajistas |
| Price feed | Varios nodos fuera de la cadena, con muchos mercados | Mover el precio en muchos mercados a la vez, o corromper a los nodos |

Un **TWAP** (time-weighted average price, precio medio ponderado por tiempo) guarda cada bloque
el precio acumulado y calcula la media de, por ejemplo, los últimos 30 minutos. Para moverlo
mucho hay que sostener el precio falso durante muchos bloques, pagando a cada arbitrajista que
lo corrige. Es caro en un pool grande y barato en uno pequeño: un TWAP no protege un token con
poca liquidez.

El **price feed** de Chainlink de la semana 20 agrega precios de muchos mercados fuera de la
cadena y los publica firmados por varios nodos. Nadie lo mueve con un swap. A cambio trae los
riesgos que ya viste: que se pare (`StalePrice`) o que dé un valor imposible (`InvalidPrice`).
En una L2 hay uno más, que el **secuenciador** (quien ordena las transacciones de la L2) se
caiga; la semana 33 lo trata.

## 3. Cómo se escribe

El prestamista vulnerable del ejercicio 01 (`src/SpotLender.sol`) lee el precio del pool:

```solidity
function price() public view override returns (uint256) {
    return POOL.spotPrice();
}
```

Y el pool lo calcula con sus reservas (`src/Pool.sol`, paso 1 del ejercicio):

```solidity
function spotPrice() public view returns (uint256) {
    return reserveUsd * 1e18 / reserveGov;
}
```

La versión corregida (`src/FeedLender.sol`, paso 4) lee el price feed con las dos
comprobaciones de la semana 20 y pasa sus 8 decimales a los 18 de los tokens:

```solidity
function price() public view override returns (uint256) {
    // forge-lint: disable-next-line(unused-return)
    (, int256 answer,, uint256 updatedAt,) = FEED.latestRoundData();
    if (answer <= 0) revert InvalidPrice(answer);
    // forge-lint: disable-next-line(block-timestamp)
    if (block.timestamp - updatedAt > MAX_PRICE_AGE) revert StalePrice(updatedAt);
    // `answer` ya es positivo: la conversión no cambia su valor.
    // forge-lint: disable-next-line(unsafe-typecast)
    return uint256(answer) * 10 ** (18 - FEED.decimals());
}
```

En el ejercicio, con el atacante terminado, el test del ataque lo comprueba con números:

```bash
forge test --mt test_Paso2_FlashLoanDrainsSpotLender
```

```text
[PASS] test_Paso2_FlashLoanDrainsSpotLender() (gas: 1305746)
```

El mismo atacante contra `FeedLender` recibe 400 000 USD por sus 500 GOV (500 × 1000 × 0,8), no
llega a devolver el préstamo y toda la transacción revierte.

## 4. Antipatrones y riesgos

- **Precio de las reservas de un pool.** `reserveA / reserveB`, `getReserves()` o
  `slot0` de Uniswap v3 son precios al contado. Si un contrato decide algo con ellos (cuánto
  prestar, cuántos tokens dar, cuándo liquidar), quien los mueve decide por él.
- **`balanceOf(address(this))` como contabilidad.** Si el precio o la proporción salen del saldo
  del contrato, cualquiera los cambia enviándole tokens sin llamar a ninguna función (una
  **donación**). La teoría 04 lo ataca en una bóveda.
- **Precio de un token de liquidez calculado a mano.** El valor de las participaciones de un
  pool sumando sus reservas a precio al contado se manipula igual que el precio.
- **Un TWAP corto o de un pool pequeño.** Una media de pocos bloques, o de un pool con poca
  liquidez, cuesta poco de mover.
- **Una sola fuente sin comprobaciones.** Un feed sin mirar `updatedAt` ni el signo de `answer`
  falla en silencio el día que se para.
- **Mezclar decimales.** El feed ETH/USD da 8 decimales; casi todos los tokens, 18. Olvidar la
  conversión da un precio 10¹⁰ veces menor.

## 5. Trucos

- Al revisar un contrato, busca de dónde sale cada número que decide un pago: si sale de una
  llamada a otro contrato, pregúntate quién puede cambiar su respuesta y cuánto le cuesta.
- Un test de manipulación necesita solo tres líneas: mover el precio, usarlo, comprobar quién
  gana. Si no sabes si un precio es manipulable, escribe ese test.
- Si tienes que usar un pool, usa su TWAP con un plazo largo y compáralo con otra fuente; si
  difieren demasiado, no operes.

## ✅ Checklist

- [ ] Calculo a mano cómo cambia el precio de un pool de producto constante tras un swap.
- [ ] Sé por qué un precio al contado se mueve en una transacción y un TWAP no.
- [ ] Reconozco un precio que sale de reservas o de `balanceOf`.
- [ ] Leo un price feed con sus comprobaciones y lo llevo a 18 decimales.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 22 — Vulnerabilidades económicas](../README.md) | **Teoría 01 — Manipulación de oráculos** | [Teoría 02 — Flash loans →](02-flash-loans.md) |
