# 📖 Glosario — Semana 29

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Aislamiento (`isolate`) | Modo de Foundry, activado por defecto en la 1.9, en que cada llamada de un test a otro contrato se ejecuta como su propia transacción | `set(2)` da 26 618 con él y 5414 con `--no-isolate` |
| Bitmap | Una palabra de 256 bits usada como 256 `bool`, un bit cada uno | `_words[i >> 8] \|= 1 << (i & 0xff)` |
| Cortocircuito (*short-circuit*) | `a \|\| b` y `a && b` no evalúan `b` si `a` ya decide el resultado | `amounts[i] == 0 \|\| e.blocked` |
| Dispatcher | El código del principio de un contrato que compara el selector con los de sus funciones, en orden | `firstPublic` y `firstExternal`, idénticas, gastan 3338 y 3404 |
| Ejecuciones del optimizador (`optimizer_runs`) | Cuántas veces se espera que se ejecute cada instrucción del contrato: pocas dan bytecode pequeño, muchas, bytecode barato de ejecutar | 200 en el registro: 15 117 bytes; 10 000: 18 185 |
| Empaquetar (*packing*) | Ordenar variables o campos para que varios compartan un slot de 32 bytes | `address`, `uint64` y `uint8` en un slot |
| Gas base (*intrinsic gas*) | Lo que paga cualquier transacción antes de ejecutar nada | 21 000 |
| Línea de base (*baseline*) | El gas medido antes de optimizar, guardado para comparar | `register` 239 957 antes del proyecto |
| Puntero a storage | Una variable local `storage`: el número de un slot, sin copiar nada | `Employee storage e = employees[a];` |
| Snapshot con nombre | Gas de una llamada guardado con `vm.snapshotGasLastFrame` en `snapshots/<Test>.json` | `"register": "217324"` |
| Tope de gas (*gas budget*) | Un test que falla si una llamada gasta más de un número | `assertLt(gas, 80_000)` |
| Tope del reembolso | Desde EIP-3529, el reembolso no pasa de un quinto del gas usado | 9721 de reembolso en un cerrojo de 0 y 1 |
| `FORGE_SNAPSHOT_CHECK` | Variable de entorno que hace fallar los tests si un snapshot con nombre cambió | `Snapshots differ from previous run` |
| `transient` (variable de estado) | Una variable de estado en transient storage: solc la lee y escribe con `TLOAD` y `TSTORE` | `bool transient _locked;` |
| `vm.lastFrameGas` | Cheatcode que devuelve el gas de la última llamada del test: usado, reembolso y más | `vm.lastFrameGas().gasTotalUsed` |
| `via_ir` | Configuración de solc que compila pasando por Yul y optimiza el programa entero | `FOUNDRY_VIA_IR=true forge test` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | Semana 30 (próximamente) |
