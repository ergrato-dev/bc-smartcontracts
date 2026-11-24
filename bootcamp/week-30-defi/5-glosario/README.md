# 📖 Glosario — Semana 30

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| AMM (*automated market maker*) | Contrato que cambia un token por otro con una fórmula sobre sus reservas, sin libro de órdenes | `Pair` del ejercicio 01 |
| Arbitraje | Comprar donde un token es barato y venderlo donde es caro, hasta que los precios se igualan | Mover un pool de 4 B por A a 9 B por A |
| Close factor | Parte máxima de una deuda que se puede pagar en una liquidación | 50 %: de 3000, hasta 1500 |
| Comisión (*fee*) | Lo que cobra un swap, en puntos básicos, y se queda en el pool | `FEE_BPS = 30`, un 0,3 % |
| DeFi (*decentralized finance*) | Contratos que cambian, prestan y hacen rendir tokens sin una empresa en medio | AMM, vault, préstamo |
| Deuda escalada | La deuda dividida por el índice del momento en que se pidió | `_scaledDebt[user]` |
| ERC-4626 | Estándar de vaults: `deposit`, `mint`, `withdraw`, `redeem` y sus `preview*` y `max*` | `contract PointsVault is ERC4626` |
| Factor de salud (*health factor*) | Garantía por el umbral de liquidación, entre la deuda; por debajo de 1 se liquida | `1066666666666666666` |
| Garantía (*collateral*) | Lo que se deposita para pedir prestado y se pierde si no se devuelve | 2 WETH |
| Impacto en el precio (*price impact*) | Lo que empeora el precio efectivo de un swap frente al marginal por su tamaño | 10 A: −9,3 % |
| Índice (*borrow index*) | Número que crece con el interés y mueve todas las deudas a la vez | `borrowIndex` |
| Liquidación | Pagar parte de la deuda de una posición enferma y llevarse su garantía con premio | `liquidate(alice, 1500 ether)` |
| LP share | ERC-20 que representa la parte de un proveedor en las reservas de un pool | 200 shares con 100 A y 400 B |
| LTV (*loan-to-value*) | Lo máximo que se puede deber frente al valor de la garantía | 75 % |
| Offset (`_decimalsOffset`) | Decimales de más de las shares de un vault, que añaden `10^offset` shares virtuales | `return 6;` |
| Pérdida impermanente (*impermanent loss*) | Lo que pierde un proveedor de liquidez frente a guardar sus tokens cuando el precio cambia | −7,7 % si el precio sube 2,25 veces |
| Precio marginal | El precio de una cantidad muy pequeña: el cociente de las reservas | `y / x` = 4 |
| Producto constante | La regla de un AMM: el producto de las reservas no baja con un swap | `x · y = k` |
| Proveedor de liquidez (*liquidity provider*) | Quien aporta los dos tokens a un pool y recibe LP shares | `alice` abre el pool |
| Puntos básicos (*basis points*) | Centésimas de porcentaje: 10 000 son el 100 % | 30 = 0,3 % |
| Reserva | Lo que un pool anota que tiene de cada token, que no es su saldo | `reserve0` |
| Shares virtuales | Shares y activo que el vault cuenta sin que existan, contra el ataque de inflación | `totalSupply + 10^offset` |
| Umbral de liquidación (*liquidation threshold*) | Parte de la garantía por encima de la cual la deuda se puede liquidar | 80 % |
| Vault | Contrato que guarda un activo en nombre de muchos a cambio de shares | `FeeVault` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | Semana 31 (próximamente) |
