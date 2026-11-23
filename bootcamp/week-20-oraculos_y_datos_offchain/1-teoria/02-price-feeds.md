# Teoría 02 — Price feeds

## 🎯 Objetivos

- Leer un price feed de Chainlink desde Solidity con `AggregatorV3Interface`.
- Rechazar un precio no positivo o demasiado antiguo.
- Convertir dólares a wei y wei a dólares con los decimales correctos y redondeando a favor del
  protocolo.
- Probar un consumidor con un feed falso y contra el feed real de Sepolia con un fork.

## 1. Qué problema resuelve

La teoría 01 leyó el precio con `cast`. Ahora lo lee tu contrato, en la misma transacción en la
que cobra. Ahí aparecen tres preguntas que con `cast` no importaban:

1. **¿Me fío de este número?** Si es 0, negativo o de hace un día, cobrar con él es cobrar mal.
2. **¿Cuántos decimales tiene?** El precio llega como entero con 8 decimales, el ETH se cuenta en
   wei (18 decimales) y tu tasa en dólares, con los que elijas. Un error de escala cobra mil
   millones de veces de más o de menos.
3. **¿Hacia dónde redondeo?** Una división entera pierde la parte decimal. Ese wei de menos,
   repetido en cada alta, es dinero que el protocolo regala.

## 2. Cómo funciona

### La interfaz

Todos los feeds de Chainlink tienen la misma interfaz, `AggregatorV3Interface`. Las dos funciones
que usarás:

```solidity
function decimals() external view returns (uint8);

function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
```

- `answer` es `int256`, con signo: hay feeds que pueden dar valores negativos (un tipo de interés,
  por ejemplo). En uno de precios, un valor no positivo es un error.
- `updatedAt` es el timestamp de la ronda. `block.timestamp - updatedAt` es su antigüedad en
  segundos.
- Los demás campos no hacen falta para un precio: con la desestructuración de Solidity (`(, x,,
  y,) = ...`) te quedas solo con los que usas.

En la imagen del bootcamp está en `/opt/lib/chainlink-contracts` (el paquete
`@chainlink/contracts` 1.4.0); con el remapping `@chainlink/contracts/`, el `import` es el mismo
que en la documentación de Chainlink:

```solidity
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
```

### La antigüedad máxima

Un feed escribe al menos una vez por latido (teoría 01). Si la última ronda tiene más, el feed
está parado o su red tiene problemas. Tu contrato decide cuánto acepta con una antigüedad máxima:

- Algo más que el latido, para no parar el protocolo por un retraso de segundos: con un latido de
  1 hora, 3 horas es razonable.
- Nunca "lo que sea": sin límite, un feed parado sigue cobrando con el precio del día que se paró.

### La cuenta de los decimales

Quieres cobrar `usdFee` dólares, guardados con 18 decimales (25 dólares son `25e18`). El precio
tiene `d` decimales (8 en ETH/USD). Los wei que valen:

```text
wei = usdFee × 10^d / precio
```

Comprueba las unidades con números: `25e18 × 1e8 / 3000e8 = 8333333333333333`, unos 0,00833 ETH.
Los 18 decimales de `usdFee` acaban siendo los 18 del wei, y los `d` del precio se cancelan con
el `10^d`. Por eso el contrato **lee** `decimals()` en vez de suponer 8: un feed con 18 decimales
daría un resultado 10¹⁰ veces menor si lo supusieras.

### Redondear a favor del protocolo

`25e18 × 1e8 / 3000e8` es 8333333333333333,33…: la división entera lo deja en ...333. El
protocolo cobra un poco menos de 25 dólares. Lo correcto al **cobrar** es redondear hacia arriba;
al **pagar** (convertir wei del protocolo en dólares que entrega), hacia abajo. Así nadie saca
valor del redondeo.

`Math.mulDiv(a, b, c, Math.Rounding.Ceil)` de OpenZeppelin calcula `a × b / c` sin desbordar en
la multiplicación intermedia (usa 512 bits) y redondea como le digas.

## 3. Cómo se escribe

### Leer y comprobar

En `src/PriceConsumer.sol` del ejercicio 01:

```solidity
function price() public view returns (uint256) {
    (, int256 answer,, uint256 updatedAt,) = FEED.latestRoundData();
    if (answer <= 0) revert InvalidPrice(answer);
    if (block.timestamp - updatedAt > MAX_AGE) revert StalePrice(updatedAt);
    return uint256(answer);
}

function usdToWei(uint256 usdAmount) public view returns (uint256) {
    return Math.mulDiv(usdAmount, 10 ** FEED.decimals(), price(), Math.Rounding.Ceil);
}
```

- `uint256(answer)` es seguro después de comprobar `answer > 0`; antes, un `-1` se convertiría en
  2²⁵⁶ − 1, un número de 78 dígitos.
- Si `updatedAt` es 0 (una ronda que no se completó), la antigüedad es enorme y también revierte.

### El redondeo, medido

Un test con las dos divisiones. **Dónde**: en el proyecto del ejercicio 01, en un
`test/Demo.t.sol` tuyo:

```solidity
import {Test, console} from "forge-std/Test.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract DemoTest is Test {
    function test_Rounding() public pure {
        uint256 usd = 25e18;
        uint256 price = 3000e8;
        console.log("hacia abajo:", usd * 1e8 / price);
        console.log("hacia arriba:", Math.mulDiv(usd, 1e8, price, Math.Rounding.Ceil));
    }
}
```

```bash
forge test --match-test test_Rounding -vv
```

```text
[PASS] test_Rounding() (gas: 8362)
Logs:
  hacia abajo: 8333333333333333
  hacia arriba: 8333333333333334
```

Un wei de diferencia: poco en un alta, pero siempre del mismo lado.

### Un feed falso para los tests

`MockV3Aggregator`, de Chainlink, es un feed que controlas tú: lo creas con sus decimales y un
precio inicial, y lo cambias cuando quieras.

```solidity
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/shared/mocks/MockV3Aggregator.sol";

MockV3Aggregator feed = new MockV3Aggregator(8, 3000e8); // 8 decimales, 3000 dólares
feed.updateAnswer(0);                                    // nueva ronda con precio 0, hora actual
vm.warp(block.timestamp + 1 hours + 1);                  // el precio pasa a tener más de 1 hora
```

`updateAnswer` guarda la hora del bloque como `updatedAt`. Con `vm.warp` (semana 09) mueves el
reloj para probar la antigüedad.

### El feed real, con un fork

Un fork (semana 09) ejecuta el test sobre una copia del estado de Sepolia: el feed de verdad,
sin gastar nada. En el mismo `test/Demo.t.sol`, con dos `import` más
(`AggregatorV3Interface` y `PriceConsumer` de `../src/PriceConsumer.sol`):

```solidity
function test_SepoliaFeed() public {
    vm.createSelectFork("https://ethereum-sepolia-rpc.publicnode.com");
    AggregatorV3Interface feed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    PriceConsumer consumer = new PriceConsumer(feed, 3 hours);
    console.log("precio:", consumer.price());
    console.log("25 dolares en wei:", consumer.usdToWei(25e18));
}
```

```bash
forge test --match-test test_SepoliaFeed -vv
```

```text
[PASS] test_SepoliaFeed() (gas: 944141)
Logs:
  precio: 172036000000
  25 dolares en wei: 14531842172568533
```

A 1720,36 dólares, 25 dólares son unos 0,01453 ETH. El precio que veas será otro. Los tests del
bootcamp no usan forks: necesitan red y su resultado cambia cada hora. Sirven para comprobar que
tu contrato entiende el feed real antes de desplegar.

## 4. Antipatrones y riesgos

- **No comprobar `updatedAt`.** Tu contrato cobra con un precio de ayer si el feed se para. Con
  un precio de garantía en un préstamo (semana 30), alguien pide prestado con el precio viejo y
  se lleva la diferencia.
- **Suponer los decimales.** `answer * 1e10` "para pasar a 18" funciona hasta que cambias de feed.
  Lee `decimals()`.
- **Dividir antes de multiplicar.** `usdFee / price * 1e8` pierde todo en la primera división si
  `usdFee < price`. Multiplica primero, o usa `mulDiv`.
- **Redondear a favor del usuario.** Un wei por operación, repetido en un bucle o con importes
  pequeños, es una fuga. Al cobrar, hacia arriba; al pagar, hacia abajo.
- **Exigir el importe exacto con un precio que cambia.** Si el feed escribe una ronda entre que tu
  página calcula la tasa y la transacción entra en un bloque, el importe exacto ya no coincide y
  revierte. No se pierde dinero, pero el usuario repite. La alternativa es aceptar de más y
  devolver el cambio, como el `buy` del ejercicio 01.
- **Guardar el precio en storage "para ahorrar gas".** Copiarlo a una variable propia lo deja
  congelado sin la comprobación de antigüedad. Léelo del feed cada vez.

## 5. Trucos

- Un `error StalePrice(uint256 updatedAt)` con el dato que falló hace que el mensaje del revert
  diga cuándo fue la última ronda: lo ves sin abrir el explorador.
- `cast --format-units <answer> 8` convierte el precio a dólares en la terminal.
- Para otra moneda sin feed directo (EUR/ETH), se combinan dos feeds (ETH/USD y EUR/USD) con
  `mulDiv`: cada feed con su comprobación de antigüedad.

## ✅ Checklist

- [ ] Leo `latestRoundData` y me quedo con `answer` y `updatedAt`.
- [ ] Revierto con un precio no positivo o más antiguo que mi límite, y sé elegir el límite.
- [ ] Hago la cuenta de dólares a wei con `decimals()` y compruebo sus unidades.
- [ ] Redondeo hacia arriba al cobrar y hacia abajo al pagar, con `Math.mulDiv`.
- [ ] Pruebo con `MockV3Aggregator` y `vm.warp`, y contra Sepolia con un fork.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — El problema del oráculo](01-el-problema-del-oraculo.md) | **Teoría 02 — Price feeds** | [Teoría 03 — Aleatoriedad con VRF →](03-aleatoriedad-con-vrf.md) |
