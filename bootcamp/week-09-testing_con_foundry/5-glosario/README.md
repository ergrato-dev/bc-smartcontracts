# 📖 Glosario — Semana 09

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| `bound` | Ayudante de forge-std que lleva un número a un rango `[min, max]` sin descartar la entrada | `amount = bound(amount, 1, 5);` |
| Cheatcode (truco) | Función que la EVM de forge ofrece solo en los tests, en la dirección de `vm`, para cambiar lo que en una red no se puede cambiar | `vm.warp(1_700_000_000);` |
| Cobertura (*coverage*) | Proporción de líneas, instrucciones, ramas y funciones del contrato que ejecutaron los tests | `forge coverage --report summary` |
| Contraejemplo (*counterexample*) | Entrada con la que un fuzz test falló; forge la muestra en `args=[…]` y la guarda en `cache/fuzz/failures` | `counterexample: … args=[0, 115792…]` |
| Expectativa (*expect*) | Cheatcode que declara qué tiene que pasar en la siguiente llamada: un revert, un evento o una llamada | `vm.expectRevert(Faucet.Empty.selector);` |
| Fork (bifurcación) | Copia local de una red en un bloque: lee el estado del nodo por JSON-RPC y escribe solo en la copia | `vm.createSelectFork("http://127.0.0.1:8545");` |
| Fuzz test (prueba con entradas aleatorias) | Test con parámetros que forge ejecuta muchas veces con valores distintos | `function testFuzz_X(uint256 a) public` |
| `.gas-snapshot` | Archivo que genera `forge snapshot` con el gas de cada test; se versiona para ver cuándo cambia | `FaucetTest:test_Drip() (gas: 63627)` |
| Informe de gas (*gas report*) | Tabla con el gas mínimo, medio, mediano y máximo de cada función durante los tests | `forge test --gas-report` |
| Mutante (*mutant*) | Copia del contrato con un fallo introducido a propósito para comprobar que los tests lo detectan | `block.number` en vez de `block.timestamp` |
| Precompilado (*precompile*) | Dirección baja (`0x01`, `0x02`…) donde la EVM tiene una función propia en lugar de una cuenta | `assumeNotPrecompile(payer);` |
| `prank` | Cheatcode que hace que la siguiente llamada salga de otra cuenta; `startPrank` lo mantiene hasta `stopPrank` | `vm.prank(alice);` |
| Propiedad (*property*) | Afirmación que vale para cualquier entrada válida y que un fuzz test comprueba | "las partes suman el importe" |
| Punto básico (*basis point*, bp) | Centésima de punto porcentual: 1 bp = 0,01 %, 10 000 bps = 100 % | `250` bps = 2,5 % |
| Rama (*branch*) | Cada camino de un `if` o un `require`: el que se cumple y el que no | `if (!ok) revert TransferFailed();` |
| Semilla (*seed*) | Número del que el fuzzer saca sus entradas; con la misma semilla, las mismas entradas | `forge test --fuzz-seed 1` |
| Traza (*trace*) | Árbol de llamadas de un test, con el gas de cada una, que muestra `-vvvv` | `├─ [52625] Faucet::drip()` |
| Variable de entorno (*environment variable*) | Valor con nombre que la terminal pasa a un programa; el test lo lee con `vm.envOr` o `vm.envAddress` | `export FORK_URL=http://127.0.0.1:8545` |
| `vm.assume` | Cheatcode que descarta la entrada de un fuzz test si la condición es falsa | `vm.assume(to != address(0));` |
| `vm.warp` | Cheatcode que fija `block.timestamp`; `skip` y `rewind` lo mueven en segundos | `vm.warp(until - 1);` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | Semana 10 (próximamente) |
