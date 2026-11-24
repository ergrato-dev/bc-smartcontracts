# 📖 Glosario — Semana 27

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Acceso frío y caliente (*cold* / *warm access*) | El primer acceso de una transacción a un slot o una cuenta es frío y cuesta más; los siguientes, calientes (EIP-2929) | `SLOAD` frío 2100, caliente 100 |
| `anvil_setCode` | Método RPC de anvil que pone un bytecode en una dirección sin desplegar nada | `cast rpc anvil_setCode $P 0x34600c57...` |
| `cast storage` | Lee la palabra de 32 bytes guardada en un slot de un contrato | `cast storage $C 0` |
| Contador de programa (*program counter*, PC) | Posición del bytecode del siguiente opcode que va a ejecutar la EVM | El `pc` 12 de la traza, donde está el `JUMPDEST` |
| `debug_traceTransaction` | Método RPC que devuelve la ejecución de una transacción opcode a opcode, con gas y pila | Con anvil arrancado con `--steps-tracing` |
| *Dispatcher* | Código del principio del contrato que compara el selector de la calldata con el de cada función y salta a la suya | El `PUSH4 <selector> EQ PUSH2 <destino> JUMPI` de cada función |
| Expansión de memoria (*memory expansion*) | Coste de ampliar la memoria de una llamada: `3 · w + w² / 512` para `w` palabras | 1 KiB, 98 de gas; 1 MiB, 2 195 456 |
| `INVALID` | Opcode `0xfe`: termina la llamada, deshace los cambios y gasta todo el gas | `fe` |
| `JUMPDEST` | Opcode que marca una posición válida para `JUMP` y `JUMPI`. Saltar a otra gasta todo el gas | `5b` en el byte 12 de `noValue` |
| Opcode de salto (`JUMP` / `JUMPI`) | Cambia el contador de programa; `JUMPI` solo si la condición no es cero | `CALLVALUE PUSH1 0x0c JUMPI` |
| Palabra (*word*) | Unidad de 32 bytes con la que trabaja la EVM: cada elemento de la pila, cada slot y cada lectura de memoria | `MLOAD` lee una palabra entera |
| Pila (*stack*) | Zona de hasta 1024 palabras donde los opcodes toman y dejan sus operandos; solo se alcanzan las 16 de arriba | `PUSH1 2 PUSH1 3 ADD` deja `5` |
| Prólogo | Primeros bytes del bytecode de solc: guardan `0x80` en el puntero de memoria libre | `6080604052` |
| Puntero de memoria libre (*free memory pointer*) | Palabra en la posición `0x40` de la memoria que dice dónde empieza la memoria sin usar | Empieza valiendo `0x80` |
| Reembolso (*refund*) | Gas que la EVM devuelve al acabar la transacción por poner a cero un slot; como mucho, un quinto del gas usado (EIP-3529) | `refund 4800` tras borrar un slot |
| Returndata | Bytes que devuelve la última llamada: la respuesta de una función o los datos de su revert | `Error(string)`, `Panic(uint256)` o un error personalizado |
| Slot cero (*zero slot*) | Palabra de memoria en `0x60` que se deja a cero como valor inicial de los arrays de memoria vacíos | `0x60`-`0x7f` |
| *Stack too deep* | Error del compilador cuando una función necesita más valores vivos que las 16 posiciones de la pila que alcanzan `DUP` y `SWAP` | Una función con 17 parámetros `uint256` |
| Suelo de calldata (*calldata floor*) | Gas mínimo de una transacción según los bytes de su calldata: 10 por *token* (EIP-7623) | 100 bytes `0xff`, `gasUsed` 25 000 |
| `vm.etch` | Cheatcode que pone un bytecode en una dirección dentro de un test | `vm.etch(program, code)` en `test/Programs.t.sol` |
| `vm.load` | Cheatcode que lee un slot de storage de cualquier contrato dentro de un test | `vm.load(address(registry), bytes32(uint256(8)))` |
| Zona de trabajo (*scratch space*) | Las dos primeras palabras de la memoria, `0x00`-`0x3f`, que Solidity usa para cálculos cortos como un `keccak256` | El hash del slot de un mapping |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 28 — Yul e inline assembly →](../../week-28-yul_e_inline_assembly/README.md) |
