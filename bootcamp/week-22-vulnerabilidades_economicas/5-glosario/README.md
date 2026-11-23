# 📖 Glosario — Semana 22

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Arbitraje (*arbitrage*) | Comprar donde algo está barato y vender donde está caro; devuelve los pools a su precio | Vender GOV en un pool que lo paga a 4000 cuando fuera vale 1000 |
| Back-running | Colocar una transacción justo después de otra que ya está en la mempool | La venta del atacante tras el swap de Alice |
| Bóveda (*vault*) | Contrato que guarda un token y reparte participaciones proporcionales a lo depositado | `Vault` del ejercicio 03 |
| Colateral (*collateral*) | Lo que dejas de garantía al pedir prestado; se queda si no devuelves | 500 GOV en `SpotLender` |
| Commit-reveal | Esquema en dos transacciones: primero el hash de un valor y un secreto, después el valor | `CommitRevealPuzzle` |
| Constructor de bloques (*block builder*) | Quien elige y ordena las transacciones de un bloque y lo vende al validador que lo propone | Ordena por propina y añade las suyas |
| Donación (*donation*) | Enviar tokens a un contrato sin llamar a ninguna de sus funciones; cambia su `balanceOf` | `token.transfer(address(vault), 10_000e18)` |
| Flash loan | Préstamo sin garantía que se devuelve en la misma transacción o la revierte entera | `USD.flashLoan(this, address(USD), loan, "")` |
| Front-running | Colocar una transacción justo antes de otra que ya está en la mempool | Copiar `solve("rollup")` con más propina |
| Liquidación (*liquidation*) | Pagar la deuda de otro cuyo colateral ya no la cubre y quedarse el colateral con descuento | Hundir el precio para liquidar a usuarios honrados |
| MEV (*maximal extractable value*) | Valor que se saca eligiendo qué transacciones entran en un bloque y en qué orden | El beneficio de un sándwich |
| Mempool | Transacciones firmadas que esperan a entrar en un bloque; cualquier nodo las ve | `cast rpc txpool_status` en anvil |
| Participaciones (*shares*) | Unidades que dan derecho a una parte proporcional de lo que hay en una bóveda | 25 participaciones valen 50 tokens |
| Participaciones virtuales (*virtual shares*) | Participaciones y tokens que se suman a los totales sin ser de nadie, para que nadie fije la proporción | `VIRTUAL_SHARES = 1e3` |
| Pool de liquidez (*liquidity pool*) | Contrato con reservas de dos tokens que cambia uno por otro con una fórmula | `Pool` con `reserveUsd × reserveGov = k` |
| Precio al contado (*spot price*) | Precio que sale de las reservas de un pool en este momento | `reserveUsd * 1e18 / reserveGov` |
| Punto básico (*basis point*, bps) | Una centésima de punto porcentual | 10 bps = 0,1 % |
| Sándwich (*sandwich attack*) | Comprar antes y vender después de un swap ajeno, cobrando el precio que paga la víctima | Alice recibe 41,6 GOV en vez de 90,9 |
| Searcher | Bot que busca en la mempool transacciones de las que sacar MEV | Un generalized front-runner |
| Slippage | Diferencia entre el precio que ves al firmar y el que obtienes al ejecutarse | `minAmountOut` con un 1 % de tolerancia |
| TWAP (*time-weighted average price*) | Precio medio de un pool durante un periodo, ponderado por el tiempo | El oráculo de Uniswap v2 |
| Vulnerabilidad económica | Fallo en el que el código hace lo que dice pero alguien gana con un precio, un orden o un redondeo | H-02: la tasa exacta |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | Semana 23 (próximamente) |
