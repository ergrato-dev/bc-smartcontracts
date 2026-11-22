# Ejercicio 02 — Interfaces y contratos abstractos

> Al terminar habrás escrito una plantilla abstracta con un hueco, dos fuentes de precios
> que lo rellenan, un conversor que funciona con cualquier fuente que cumpla una interfaz
> y la respuesta ERC-165 de las fuentes.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 01](../ejercicio-01-herencia/README.md) terminado;
[Teorías 03 y 04](../../1-teoria/03-contratos-abstractos.md) leídas.

## Contexto

Un contrato que acepta pagos en ETH pero pone precios en dólares necesita saber cuánto vale
1 ETH. Ese dato viene de fuera de la cadena, a través de una **fuente de precios**
(*price feed*): un contrato que guarda el precio. La semana 20 usa las de Chainlink; aquí
escribes las tuyas.

| Archivo | Qué es |
| ------- | ------ |
| `src/IPriceFeed.sol` | Dos interfaces: `IERC165` y `IPriceFeed` (`decimals` y `latestPrice`). Ya escritas |
| `src/Feeds.sol` | `BaseFeed`, la plantilla abstracta, y dos fuentes: `FixedFeed` (precio fijo) y `ManualFeed` (lo actualiza una cuenta). Aquí trabajas |
| `src/Converter.sol` | Convierte wei a dólares con la fuente que recibe al desplegarse. Aquí trabajas |
| `test/Converter.t.sol` | Cinco tests, uno por paso, y `HalfFeed`: una fuente que cumple `IPriceFeed` sin heredar de `BaseFeed`. **No lo modifiques** |

Los precios llevan 8 decimales, como los de Chainlink: 3000 dólares es `3000e8`
(`300000000000`). `3000e8` es notación científica de Solidity: 3000 × 10^8.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-08-herencia_interfaces_y_librerias/2-practicas/ejercicio-02-interfaces/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con `Warning (5667)` y `Warning (2018)`.

**Verifica**: cinco `FAIL`. Los de los pasos 1 y 2 con `TODO: Paso 1`: toda lectura de
precio pasa por la plantilla.

## Paso 1: La plantilla

**Por qué**: `BaseFeed` fija qué pasa al leer un precio, sea cual sea la fuente: pedírselo
a la hija con `_readPrice` (el hueco, sin cuerpo) y rechazar el 0. Un precio 0 haría que
cualquier cosa costara nada. `latestPrice` no es `virtual`: ninguna hija puede saltarse
la comprobación.

**Abre** `src/Feeds.sol`:

```solidity
function latestPrice() external view returns (uint256) {
    uint256 price = _readPrice();
    if (price == 0) revert InvalidPrice();
    return price;
}
```

**Verifica**: `[PASS] test_Step1_TemplateRejectsZero()`. Una `ManualFeed` recién
desplegada tiene el precio a 0, y leerlo da `InvalidPrice()`.

Rompe a propósito: borra la línea del `if` y ejecuta `forge test --match-test test_Step1`:

```
[FAIL: next call did not revert as expected] test_Step1_TemplateRejectsZero() (gas: 371852)
```

Una fuente sin inicializar dice que 1 ETH vale 0 dólares. Vuelve a poner la línea.

## Paso 2: Una fuente fija

**Por qué**: `FixedFeed` no escribe `latestPrice`; solo rellena el hueco. Todo lo demás lo
hereda.

```solidity
function _readPrice() internal view override returns (uint256) {
    return PRICE;
}
```

**Verifica**: `[PASS] test_Step2_FixedFeed()`.

Rompe a propósito: borra la función entera y ejecuta `forge build`:

```
Error (3656): Contract "FixedFeed" should be marked as abstract.
```

Sin el hueco relleno, `FixedFeed` sigue siendo abstracta y no se puede desplegar.
Vuelve a ponerla.

## Paso 3: Una fuente manual

**Por qué**: `ManualFeed` ya rellena el hueco con su variable `price`. Falta quién la
cambia: solo `UPDATER`. No compruebes el 0 al guardar: la plantilla lo comprueba al leer,
y así ninguna fuente puede olvidarlo.

```solidity
function setPrice(uint256 newPrice) external {
    if (msg.sender != UPDATER) revert NotUpdater(msg.sender);
    price = newPrice;
    emit PriceUpdated(newPrice);
}
```

**Verifica**: `[PASS] test_Step3_ManualFeed()`. El precio cambia con su evento, alice
recibe `NotUpdater(alice)`, y un precio 0 se guarda pero no se puede leer.

## Paso 4: Un conversor que no sabe qué fuente tiene

**Por qué**: `Converter` guarda la fuente como `IPriceFeed`, no como `FixedFeed` ni
`ManualFeed`. Le sirve cualquier contrato que cumpla la interfaz, incluido `HalfFeed`, que
no hereda de `BaseFeed`. Multiplica antes de dividir: al revés, cualquier importe menor que
1 ETH daría 0 (teoría 05).

**Abre** `src/Converter.sol`:

```solidity
function toUsd(uint256 weiAmount) external view returns (uint256) {
    return weiAmount * FEED.latestPrice() / 1 ether;
}
```

**Verifica**: `[PASS] test_Step4_ConverterWorksWithAnyFeed()`. Con `FixedFeed` a 3000
dólares, 2 ETH son `6000e8` y 0,5 ETH, `1500e8`; con `HalfFeed`, a 1500, 2 ETH son `3000e8`.

`HalfFeed` cumple la interfaz y `Converter` la acepta sin más. Pero `HalfFeed` no tiene la
comprobación del 0 de `BaseFeed`: la interfaz promete funciones, no reglas (teoría 04).

## Paso 5: ERC-165

**Por qué**: antes de aceptar una fuente, un contrato puede preguntarle si dice cumplir
`IPriceFeed`. El identificador de una interfaz es el XOR de sus selectores:

```bash
cast sig "decimals()"
cast sig "latestPrice()"
```

```
0x313ce567
0xa3e6ba94
```

`0x313ce567` XOR `0xa3e6ba94` = `0x92da5ff3`, que es `type(IPriceFeed).interfaceId`.
Vuelve a **abrir** `src/Feeds.sol`:

```solidity
function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return interfaceId == type(IPriceFeed).interfaceId || interfaceId == type(IERC165).interfaceId;
}
```

**Verifica**: `forge test` termina con
`5 tests passed, 0 failed, 0 skipped (5 total tests)` y sin warnings. Las dos fuentes
responden `true` para `IPriceFeed` y `IERC165` y `false` para `0xffffffff`, y lo
escribiste una sola vez, en la plantilla.

## ✅ Criterios de éxito

- `forge test` pasa los 5 tests sin warnings.
- Explicas por qué la comprobación del 0 va en `latestPrice` y no en cada fuente.
- Explicas por qué `Converter` acepta `HalfFeed` y qué riesgo tiene eso.
- Calculas el `interfaceId` de `IPriceFeed` con `cast sig`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Herencia](../ejercicio-01-herencia/README.md) | **Ejercicio 02 — Interfaces y contratos abstractos** | [Ejercicio 03 — Librerías →](../ejercicio-03-librerias/README.md) |
