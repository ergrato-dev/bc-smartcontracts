# Ejercicio 01 — Bytecode a mano

> Al terminar habrás escrito cinco programas de la EVM byte a byte, sin compilador: uno que
> devuelve un número, uno que lee la calldata, un contador en storage, uno que rechaza ETH con un
> salto y uno que copia su entrada en la memoria. Y habrás seguido uno de ellos opcode a opcode
> con anvil.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 01 — La máquina de pila](../../1-teoria/01-la-maquina-de-pila.md)
leída.

## Contexto

Proyecto Foundry. Cada programa es una función de la biblioteca `Programs` que devuelve sus bytes.
El test los instala con `vm.etch`, que pone un código en una dirección sin desplegar nada, y los
llama con `call`, como a cualquier contrato.

| Archivo | Qué es |
| ------- | ------ |
| `src/Programs.sol` | Los cinco programas: tu trabajo, pasos 1 a 5 |
| `test/Programs.t.sol` | Un test por programa. No lo cambies |

Cada instrucción va en su propio literal `hex"..."`, con un comentario que dice qué opcode es y
cómo queda la pila **después** de ejecutarla, con la cima a la izquierda: `pila: [2, x]` es `2`
encima de `x`. solc concatena los literales seguidos en un solo `bytes`.

Ten a mano [evm.codes](https://www.evm.codes): para cada opcode, su byte, qué saca de la pila y
qué mete.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-27-evm_por_dentro/2-practicas/ejercicio-01-bytecode-a-mano/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 passed; 5 failed`, cada uno con su `TODO: Paso N`. El compilador avisa de código
inalcanzable: son las líneas que hay detrás de cada `revert`.

## Paso 1: Devolver 42

**Por qué**: `RETURN` no devuelve un valor de la pila, sino un trozo de memoria. Para devolver
42, primero hay que escribirlo en la memoria con `MSTORE` y después decir qué trozo devolver.

| Bytes | Opcode | Pila después |
| ----- | ------ | ------------ |
| `60 2a` | `PUSH1 0x2a` | `[42]` |
| `5f` | `PUSH0` | `[0, 42]` |
| `52` | `MSTORE` | `[]`: memoria[0x00..0x20] = 42 |
| `60 20` | `PUSH1 0x20` | `[32]` |
| `5f` | `PUSH0` | `[0, 32]` |
| `f3` | `RETURN` | Devuelve memoria[0..32] |

`MSTORE` saca primero la posición (la cima) y después el valor: por eso el 42 entra antes que el
0. `RETURN` igual: posición en la cima, tamaño debajo.

**Abre** `src/Programs.sol`, borra el `revert` de `answer` y descomenta sus líneas. Ejecuta
`forge test`.

**Verifica**: `1 passed; 4 failed`. `test_Paso1_Answer` en verde: la respuesta tiene 32 bytes y
vale 42.

## Paso 2: El doble del argumento

**Por qué**: `CALLDATALOAD(i)` mete en la pila los 32 bytes de calldata que empiezan en `i`. Este
programa no tiene selector: el test le envía `abi.encode(x)`, una sola palabra, y el argumento
está en la posición 0.

Escribe tú la secuencia antes de mirar las líneas `//> `: `PUSH0`, `CALLDATALOAD`, el 2, `MUL`, y
la misma salida del paso 1.

**Abre** `src/Programs.sol` y resuelve `double`.

**Verifica**: `2 passed; 3 failed`. `testFuzz_Paso2_Double` prueba 256 valores de `x`.

## Paso 3: Un contador en storage

**Por qué**: `SLOAD` y `SSTORE` son los únicos opcodes que tocan el storage. `SSTORE` saca la
clave (la cima) y el valor, y no deja nada en la pila. Para escribir el valor nuevo **y**
devolverlo, hace falta una copia: `DUP1`.

```text
PUSH0  SLOAD  PUSH1 1  ADD  DUP1  PUSH0  SSTORE  PUSH0  MSTORE  PUSH1 0x20  PUSH0  RETURN
```

**Abre** `src/Programs.sol` y resuelve `counter`.

**Verifica**: `3 passed; 2 failed`. `test_Paso3_Counter` llama tres veces: la última respuesta es
3 y `vm.load(program, 0)` lee 3 en el slot 0.

Un byte mal puesto no da error de compilación: cambia el programa. Si escribes `60` (`PUSH1`) en
lugar de `5f` (`PUSH0`) delante de `SSTORE`, `PUSH1` se come como dato el byte siguiente, el `55`
de `SSTORE`, y el programa nunca escribe en storage. La traza de ese programa con anvil:

```text
5 DUP1 3 ["0x1"]
6 PUSH1 3 ["0x1","0x1"]
8 PUSH0 2 ["0x1","0x1","0x55"]
9 MSTORE 6 ["0x1","0x1","0x55","0x0"]
```

## Paso 4: Rechazar ETH con un salto

**Por qué**: `JUMPI` saca el destino (la cima) y una condición, y salta si la condición no es 0.
El destino es una posición en el código, y en esa posición tiene que haber un `JUMPDEST`. Para
saber el número tienes que contar bytes: por eso cada línea de `noValue` lleva su posición.

| `pc` | Bytes | Opcode |
| ---- | ----- | ------ |
| `0x00` | `34` | `CALLVALUE` |
| `0x01` | `60 0c` | `PUSH1 0x0c` |
| `0x03` | `57` | `JUMPI`: si llegó ETH, a `0x0c` |
| `0x04`-`0x0b` | `60 01 5f 52 60 20 5f f3` | Devuelve 1, como en el paso 1 |
| `0x0c` | `5b` | `JUMPDEST` |
| `0x0d`-`0x0f` | `5f 5f fd` | `REVERT(0, 0)`: revierte sin datos |

**Abre** `src/Programs.sol` y resuelve `noValue`.

**Verifica**: `4 passed; 1 failed`. El test envía 1 wei y espera un revert sin datos, y después
llama sin ETH y espera 1.

Comprueba también el gas. Cambia `600c` por `600b`: ahora el salto cae en el `RETURN` de `0x0b`,
que no es un `JUMPDEST`. La llamada con ETH sigue fallando sin datos, pero el test se pone rojo:

```text
[FAIL: assertion failed: 1056937692 >= 50000] test_Paso4_NoValue() (gas: 1056945116)
```

`REVERT` devuelve el gas que sobra; un salto inválido se lo gasta todo, más de mil millones en un
test de Foundry. Vuelve a poner `600c` antes de seguir.

## Paso 5: Devolver la calldata

**Por qué**: `CALLDATACOPY(destino, origen, tamaño)` copia calldata a la memoria, y
`CALLDATASIZE` da su tamaño. Con los dos, el programa devuelve exactamente lo que recibió, sea
cual sea su longitud: es el puente entre la calldata (teoría 04) y la memoria (teoría 02).

Como siempre, el primer argumento va en la cima: mete primero el tamaño, después el origen y por
último el destino.

**Abre** `src/Programs.sol` y resuelve `echo`.

**Verifica**: `5 passed; 0 failed`. `testFuzz_Paso5_Echo` prueba 256 entradas de longitudes
distintas, también la vacía.

## Paso 6: Seguir un programa con anvil

**Por qué**: un test dice si el programa funciona; la traza dice qué hizo en cada paso.

En el mismo contenedor, arranca anvil con `--steps-tracing`, pon el código de `noValue` en una
dirección con `anvil_setCode` y envíale 1 wei. `--gas-limit` evita que `cast` estime el gas, que
fallaría porque la llamada revierte:

```bash
anvil --silent --steps-tracing &
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 0)
P=0x00000000000000000000000000000000000c0de0
cast rpc anvil_setCode $P 0x34600c5760015f5260205ff35b5f5ffd
TX=$(cast send $P --value 1 --gas-limit 100000 --private-key "$PK" --json | jq -r .transactionHash)
cast receipt $TX gasUsed
cast rpc debug_traceTransaction $TX | jq -r '.structLogs[] | "\(.pc) \(.op) \(.gasCost) \(.stack)"'
```

`anvil_setCode` responde `null`. **Verifica**: la transacción usa `21020` de gas, y la traza salta
de `pc` 3 a 12. Ojo: en la traza la pila es la de **antes** de cada paso y la cima está a la
**derecha**, al revés que en los comentarios de `Programs.sol`:

```text
0 CALLVALUE 2 []
1 PUSH1 3 ["0x1"]
3 JUMPI 10 ["0x1","0xc"]
12 JUMPDEST 1 []
13 PUSH0 2 []
14 PUSH0 2 ["0x0"]
15 REVERT 0 ["0x0","0x0"]
```

Repite con el código del salto mal contado, `0x34600b5760015f5260205ff35b5f5ffd`. `gasUsed` es
`100000`, todo el límite, y el último paso de la traza lleva el error:

```bash
cast rpc debug_traceTransaction $TX | jq -c '.structLogs[-1] | {pc, op, error}'
```

```text
{"pc":3,"op":"JUMPI","error":"Some(InvalidJump)"}
```

## Para pensar

- `answer` ocupa 8 bytes. ¿Cuántos ocupa el contrato más pequeño de solc que devuelve 42? Míralo
  con `forge inspect`. ¿Qué hacen los bytes de más?
- `counter` no comprueba quién lo llama ni si llega ETH. ¿Qué opcodes añadirías, y dónde, para que
  solo pudiera llamarlo una dirección?
- `echo` devuelve cualquier tamaño. ¿Qué le pasa al gas con una calldata de 1 MiB? Mira la
  teoría 02.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Calldata y returndata](../../1-teoria/04-calldata-y-returndata.md) | **Ejercicio 01 — Bytecode a mano** | [Ejercicio 02 — Storage al descubierto →](../ejercicio-02-storage-al-descubierto/README.md) |
