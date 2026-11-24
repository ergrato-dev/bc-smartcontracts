# Teoría 01 — La máquina de pila

## 🎯 Objetivos

- Explicar cómo ejecuta la EVM un contrato: palabras de 32 bytes, pila, contador de programa y
  opcodes.
- Nombrar las zonas de datos de la EVM y decir qué guarda cada una y cuánto duran sus datos.
- Leer el bytecode que genera solc: el prólogo, la comprobación de ETH y el *dispatcher* que
  elige la función por su selector.
- Seguir una transacción opcode a opcode con anvil, con el gas de cada paso.
- Reconocer los fallos que solo se entienden desde dentro: *stack too deep* y la diferencia entre
  revertir y agotar el gas.

## Qué problema resuelve

Desde la semana 03 escribes Solidity y lo despliegas, y en la semana 02 viste que un contrato es
**bytecode**: una secuencia de bytes que la EVM ejecuta. Entre los dos hay un compilador que no
has necesitado mirar. Ahora sí:

- **Gas.** Cada opcode tiene un precio. La semana 29 optimiza gas, y no se optimiza lo que no se
  ve.
- **Auditoría.** Hay contratos desplegados sin código fuente verificado: su bytecode es lo único
  que tienes. Y hay fallos que solo se entienden mirando qué hace la EVM, no lo que parece decir
  Solidity.
- **Depuración.** Cuando una transacción falla sin mensaje de error, la traza opcode a opcode dice
  dónde y por qué.
- **Yul.** La semana 28 escribe código casi a nivel de opcode. Esta semana aprendes qué hace cada
  uno.

## Cómo funciona

La **EVM** (*Ethereum Virtual Machine*, semana 02) es una **máquina de pila**: no tiene registros
con nombre como un procesador. Cada instrucción saca sus operandos de lo alto de una pila y deja
ahí su resultado. `ADD` saca dos números y mete su suma.

- **Palabra** (*word*): la unidad de la EVM, 32 bytes (256 bits). Cada elemento de la pila es una
  palabra; por eso `uint256` es el tipo natural de Solidity.
- **Opcode**: una instrucción de un byte. `0x01` es `ADD`; `0x54`, `SLOAD`. Los `PUSH1` a `PUSH32`
  llevan detrás, en el propio código, de 1 a 32 bytes de dato que meten en la pila. `PUSH0`
  (EIP-3855) mete un cero sin dato detrás.
- **Contador de programa** (*program counter*, `pc`): la posición del byte que se ejecuta. Avanza
  solo, salvo con `JUMP` y `JUMPI`, que saltan a una posición marcada con `JUMPDEST`.
- **Pila** (*stack*): hasta 1024 palabras, pero los opcodes solo llegan a las 16 de arriba:
  `DUP1`..`DUP16` copian una y `SWAP1`..`SWAP16` la intercambian con la cima.

La pila es solo una de las zonas donde vive un dato durante la ejecución:

![Las zonas de datos de la EVM, anidadas por lo que duran. Mientras dura una llamada: la pila, de hasta 1024 palabras; la memoria, bytes que empiezan a cero; la calldata, de solo lectura; y la returndata de la última llamada. Mientras dura la transacción: el transient storage. Para siempre, en la cuenta del contrato: el storage, con slots de 32 bytes, y el código, de solo lectura. Cada zona tiene sus opcodes.](../0-assets/01-zonas-de-datos-de-la-evm.svg)

| Zona | Qué guarda | Cuánto dura | Opcodes |
| ---- | ---------- | ----------- | ------- |
| Pila | Operandos y resultados | Una llamada | `PUSH`, `POP`, `DUP`, `SWAP` |
| Memoria | Bytes de trabajo, empiezan a cero | Una llamada | `MLOAD`, `MSTORE`, `MSIZE` (teoría 02) |
| Storage | Slots de 32 bytes del contrato | Para siempre | `SLOAD`, `SSTORE` (teoría 03) |
| Transient storage | Slots como los de storage | Una transacción | `TLOAD`, `TSTORE` (teoría 03) |
| Calldata | Los datos de entrada | Una llamada, solo lectura | `CALLDATALOAD`, `CALLDATASIZE`, `CALLDATACOPY` (teoría 04) |
| Returndata | Lo que devolvió la última llamada | Hasta la siguiente llamada | `RETURNDATASIZE`, `RETURNDATACOPY` (teoría 04) |
| Código | El bytecode | Lo que dure el contrato | `CODECOPY`, `CODESIZE` |

Cada **llamada** (una transacción, o un `call` de un contrato a otro) empieza con pila y memoria
vacías. Solo el storage, el transient storage y los saldos pasan de una llamada a otra.

## Un programa a mano, paso a paso

Este programa de 14 bytes es un contador: suma 1 al slot 0 del storage y devuelve el valor nuevo.
Lo escribes a mano en el ejercicio 01. En el contenedor, sin anvil:

```bash
cast disassemble 0x5f54600101805f555f5260205ff3
```

```text
00000000: PUSH0
00000001: SLOAD
00000002: PUSH1 0x01
00000004: ADD
00000005: DUP1
00000006: PUSH0
00000007: SSTORE
00000008: PUSH0
00000009: MSTORE
0000000a: PUSH1 0x20
0000000c: PUSH0
0000000d: RETURN
```

La columna de la izquierda es el `pc`. `PUSH1 0x01` ocupa dos bytes (`60 01`), por eso el
siguiente está en `0x04`.

Para verlo ejecutarse, arranca anvil con `--steps-tracing`: guarda cada paso de cada transacción.
`anvil_setCode` pone ese código en una dirección cualquiera, sin desplegar:

```bash
anvil --silent --steps-tracing &
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 0)
P=0x00000000000000000000000000000000000c0de0
cast rpc anvil_setCode $P 0x5f54600101805f555f5260205ff3
TX=$(cast send $P --private-key "$PK" --json | jq -r .transactionHash)
cast rpc debug_traceTransaction $TX | jq -r '.structLogs[] | "\(.pc) \(.op) \(.gasCost) \(.stack)"'
```

```text
0 PUSH0 2 []
1 SLOAD 2100 ["0x0"]
2 PUSH1 3 ["0x0"]
4 ADD 3 ["0x0","0x1"]
5 DUP1 3 ["0x1"]
6 PUSH0 2 ["0x1","0x1"]
7 SSTORE 20000 ["0x1","0x1","0x0"]
8 PUSH0 2 ["0x1"]
9 MSTORE 6 ["0x1","0x0"]
10 PUSH1 3 []
12 PUSH0 2 ["0x20"]
13 RETURN 0 ["0x20","0x0"]
```

`debug_traceTransaction` devuelve un objeto por paso, y `jq` saca cuatro campos: el `pc`, el
opcode, su gas y la pila **antes** de ejecutarlo, con la cima a la derecha. Léelo así:

- En `pc` 1, `SLOAD` saca la clave `0x0` y mete lo que hay en el slot 0: un `0x0`, porque nadie lo
  había escrito.
- En `pc` 7, `SSTORE` saca la clave (`0x0`, la cima) y el valor (`0x1`). Cuesta 20 000 de gas:
  escribir un slot que estaba a cero es lo más caro de la EVM (teoría 03).
- En `pc` 9, `MSTORE` escribe la palabra `0x1` en la posición 0 de la memoria, y `RETURN` devuelve
  `0x20` bytes desde la posición 0.

Envía la misma transacción otra vez. Ahora `SLOAD` lee `0x1` y `SSTORE` cuesta 2900, no 20 000:
cambiar un valor que no es cero es más barato que crear uno.

## Cómo se escribe: el bytecode de solc

Solidity genera lo mismo, con más pasos. En una carpeta de prueba con el `foundry.toml` de
[`docs/plantillas/starter-foundry/`](../../../docs/plantillas/starter-foundry/), escribe
`src/Counter.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Counter {
    uint256 public count;

    function add(uint256 n) external {
        count += n;
    }
}
```

`forge inspect Counter deployedBytecode` da el código que queda en la cadena (el **runtime
bytecode**, sin el constructor). Desensamblado:

```bash
forge build
cast disassemble $(forge inspect Counter deployedBytecode) | head -24
```

```text
00000000: PUSH1 0x80
00000002: PUSH1 0x40
00000004: MSTORE
00000005: CALLVALUE
00000006: DUP1
00000007: ISZERO
00000008: PUSH2 0x000f
0000000b: JUMPI
0000000c: PUSH0
0000000d: PUSH0
0000000e: REVERT
0000000f: JUMPDEST
00000010: POP
00000011: PUSH1 0x04
00000013: CALLDATASIZE
00000014: LT
00000015: PUSH2 0x0034
00000018: JUMPI
00000019: PUSH0
0000001a: CALLDATALOAD
0000001b: PUSH1 0xe0
0000001d: SHR
0000001e: DUP1
0000001f: PUSH4 0x06661abd
```

Por bloques:

| `pc` | Qué hace | Por qué |
| ---- | -------- | ------- |
| `0x00`-`0x04` | `mstore(0x40, 0x80)` | El **puntero de memoria libre** de Solidity (teoría 02) |
| `0x05`-`0x0e` | Si `CALLVALUE` no es 0, `REVERT` | Ninguna función es `payable`: solc rechaza el ETH antes de mirar nada más |
| `0x11`-`0x18` | Si hay menos de 4 bytes de calldata, salta a `0x34` | Sin selector no hay función que elegir |
| `0x19`-`0x1d` | `CALLDATALOAD(0) >> 224` | Los 4 primeros bytes de la calldata: el selector |
| `0x1e` en adelante | Compara con cada selector y salta | El **dispatcher** |

La continuación del desensamblado:

```text
00000024: EQ
00000025: PUSH2 0x0038
00000028: JUMPI
00000029: DUP1
0000002a: PUSH4 0x1003e2d2
0000002f: EQ
00000030: PUSH2 0x0056
00000033: JUMPI
00000034: JUMPDEST
00000035: PUSH0
00000036: PUSH0
00000037: REVERT
```

Los dos selectores son los de `forge inspect Counter methodIdentifiers`:

```text
| add(uint256) | 1003e2d2   |
| count()      | 06661abd   |
```

Si el selector es `0x06661abd`, salta a `0x38`, el getter de `count`; si es `0x1003e2d2`, a
`0x56`, `add`. Si no es ninguno, llega a `0x34`: `REVERT` sin datos. Ese es el `revert` vacío que
recibes al llamar a una función que el contrato no tiene. Con un `fallback`, solc saltaría ahí.

El bytecode termina con unos bytes que no se ejecutan, `a2646970667358...`: los **metadatos** del
compilador (versión de solc y el hash de los metadatos), que los verificadores usan para casar
código y fuente.

## El gas de cada paso

En la traza, cada opcode tiene su `gasCost`. Las aritméticas cuestan 3; `PUSH0`, 2; `SLOAD` de un
slot que no se ha leído en la transacción, 2100. El gas de una transacción es 21 000 de base, más
la calldata (teoría 04), más la suma de los pasos. Las dos transacciones del contador:

```bash
cast receipt $TX gasUsed
```

```text
43126
```

La segunda da `26026`. La diferencia, 17 100, es exactamente la de `SSTORE` (20 000 frente a
2900). La tabla completa de precios está en [evm.codes](https://www.evm.codes), con el hardfork
que elijas.

## ⚠️ Antipatrones y riesgos

- **Stack too deep.** Una función con muchas variables locales o parámetros necesita más de las
  16 posiciones a las que llegan `DUP` y `SWAP`. Con 17 parámetros `uint256`:

  ```text
  Error: Compiler error (/solidity/libsolidity/codegen/LValue.cpp:50): Stack too deep. Try compiling with `--via-ir` (cli) or the equivalent `viaIR: true` (standard JSON) while enabling the optimizer. Otherwise, try removing local variables.
  ```

  Agrupa los datos en un `struct`, divide la función o compila con `via_ir = true`, que reordena
  la pila. No es un fallo de seguridad, pero `via_ir` cambia el bytecode y el gas: decídelo pronto,
  no la víspera del despliegue.
- **Revertir no es lo mismo que fallar.** `REVERT` deshace los cambios y devuelve el gas que
  sobra. Un salto a una posición sin `JUMPDEST`, el opcode `INVALID` (`0xfe`) o una pila vacía
  también deshacen todo, pero **gastan todo el gas** de la llamada. Lo comprueba el ejercicio 01.
- **El dispatcher no comprueba nada más.** Un selector que no existe cae en `fallback` si lo hay.
  Un `fallback` que acepta cualquier cosa (un proxy, semana 15) responde a funciones que nadie
  escribió.
- **El bytecode es público.** Lo que va en el código, constantes incluidas, lo lee cualquiera con
  `cast code`. Nada secreto va en un contrato.

## 💡 Trucos

- `cast disassemble` lee bytecode; `cast code <dirección>` lo trae de la cadena.
- `forge inspect <Contrato> deployedBytecode` (runtime) y `bytecode` (con el constructor).
- anvil con `--steps-tracing` y `debug_traceTransaction`, o `debug_traceCall` para una llamada sin
  transacción. Con `jq` eliges los campos que quieres ver.
- [evm.codes](https://www.evm.codes) explica cada opcode con su gas y tiene un *playground* donde
  ejecutar bytecode paso a paso.

## ✅ Checklist

- [ ] Sé qué es una palabra, un opcode, el `pc` y por qué la EVM es una máquina de pila.
- [ ] Sé qué guarda cada zona de datos y cuánto duran sus datos.
- [ ] Sé encontrar en el bytecode de solc el prólogo, la comprobación de `CALLVALUE` y el
  dispatcher.
- [ ] Sé trazar una transacción opcode a opcode con anvil y leer la pila de cada paso.
- [ ] Sé por qué un `REVERT` devuelve gas y un salto inválido no.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 27 — La EVM por dentro](../README.md) | **Teoría 01 — La máquina de pila** | [Teoría 02 — La memoria →](02-la-memoria.md) |
