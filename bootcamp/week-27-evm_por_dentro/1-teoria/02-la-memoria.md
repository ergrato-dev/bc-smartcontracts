# Teoría 02 — La memoria

## 🎯 Objetivos

- Explicar qué es la memoria de la EVM: bytes que empiezan a cero, nuevos en cada llamada.
- Leer y escribir memoria con `MLOAD`, `MSTORE` y `MSTORE8`, y saber qué mide `MSIZE`.
- Conocer cómo reparte Solidity la memoria: zona de trabajo, puntero de memoria libre, slot cero
  y datos.
- Calcular el coste de ampliar la memoria y ver por qué crece más deprisa que el tamaño.
- Reconocer los ataques que se apoyan en ese coste.

## Qué problema resuelve

La pila solo guarda palabras sueltas y solo llega a 16 de ellas. Un `string`, un array o los
argumentos codificados para llamar a otro contrato necesitan un sitio donde poner muchos bytes
seguidos. Ese sitio es la **memoria** (*memory*): la zona de trabajo de cada llamada.

En la semana 06 viste `memory` como ubicación de datos frente a `storage` y `calldata`. Aquí ves
la memoria desde la EVM: cómo se direcciona, quién decide dónde va cada cosa y cuánto cuesta.

## Cómo funciona

La memoria es un array de bytes que empieza vacío en cada llamada y desaparece al acabar.

- **Se direcciona por byte**, con posiciones (*offsets*) desde 0. `MSTORE(p, v)` escribe la
  palabra `v` en los bytes `p` a `p + 31`; `MLOAD(p)` lee esos 32 bytes; `MSTORE8(p, v)` escribe
  solo el byte bajo de `v`.
- **Todo está a cero** hasta que se escribe. Leer más allá de lo escrito no falla: devuelve ceros.
- **Crece por palabras.** Tocar el byte `p` amplía la memoria hasta la palabra que lo contiene,
  aunque sea una lectura. `MSIZE` devuelve el tamaño actual, siempre múltiplo de 32.
- **Es de la llamada.** Un `call` a otro contrato empieza con memoria vacía; no puede leer ni
  escribir la tuya. Los datos van y vuelven copiados por calldata y returndata (teoría 04).

## El coste de ampliar

Ampliar la memoria a `w` palabras cuesta, en total:

```text
coste(w) = 3 · w + w² / 512
```

Al ampliar, la EVM cobra la diferencia entre el coste del tamaño nuevo y el del que ya había.
Con pocas palabras domina el término lineal; con muchas, el cuadrático:

| Memoria | Palabras | `3 · w` | `w² / 512` | Total |
| ------- | -------- | ------- | ---------- | ----- |
| 1 KiB | 32 | 96 | 2 | 98 |
| 32 KiB | 1024 | 3072 | 2048 | 5120 |
| 128 KiB | 4096 | 12 288 | 32 768 | 45 056 |
| 1 MiB | 32 768 | 98 304 | 2 097 152 | 2 195 456 |

Se mide con una función que reserva `size` bytes y un test que la llama con varios tamaños:

```solidity
function allocate(uint256 size) external pure returns (uint256) {
    return new bytes(size).length;
}
```

```solidity
uint256 before = gasleft();
greeter.allocate(sizes[i]);
console.log(sizes[i] / 1024, "KiB:", before - gasleft());
```

```text
  1 KiB: 4396
  32 KiB: 12419
  64 KiB: 24731
  128 KiB: 61643
  1024 KiB: 2298731
```

Además de la ampliación, cada medida incluye la llamada y la puesta a cero de los bytes. De 32 a
64 KiB el gas se multiplica por 2; de 64 a 128, por 2,5; de 128 KiB a 1 MiB, por 37. Un megabyte
cuesta más de 2 millones de gas: la memoria es barata en pequeño y prohibitiva en grande.

## Cómo la reparte Solidity

La EVM no sabe qué hay en cada posición. Es solc quien decide, con una convención fija:

![Mapa de la memoria de Solidity. De 0x00 a 0x3f, la zona de trabajo, para calcular hashes. En 0x40, el puntero de memoria libre, que vale 0x80 al empezar. En 0x60, el slot cero, que siempre vale 0 y sirve de array vacío. Desde 0x80, los datos: cada reserva se coloca donde dice el puntero, que avanza y nunca vuelve atrás.](../0-assets/02-mapa-de-la-memoria.svg)

| Posición | Qué es |
| -------- | ------ |
| `0x00`-`0x3f` | **Zona de trabajo** (*scratch space*): 64 bytes para cálculos cortos, como el keccak256 de una clave de mapping |
| `0x40`-`0x5f` | **Puntero de memoria libre** (*free memory pointer*): la primera posición sin usar |
| `0x60`-`0x7f` | **Slot cero**: siempre 0. Un `bytes memory` vacío apunta aquí |
| `0x80` en adelante | Los datos: arrays, strings, structs y codificaciones ABI |

Por eso todo contrato de solc empieza con `6080604052`: `PUSH1 0x80, PUSH1 0x40, MSTORE`, que
pone el puntero en `0x80`. Para reservar `n` bytes, solc lee el puntero, usa esa posición y lo
avanza `n` bytes redondeados a palabras. **Nunca lo hace retroceder**: Solidity no libera memoria
durante la llamada.

Un `bytes` o un `string` en memoria es una palabra con la longitud y, detrás, los bytes. Se ve en
una traza. Con este contrato:

```solidity
contract Greeter {
    function greet() external pure returns (string memory) {
        return "hola";
    }
}
```

desplegado en anvil (arrancado con `--steps-tracing`), `debug_traceCall` traza una llamada sin
enviar transacción. Con `enableMemory`, cada paso lleva la memoria entera:

```bash
DATA=$(cast calldata "greet()")
cast rpc debug_traceCall "{\"to\":\"$C\",\"data\":\"$DATA\"}" latest '{"enableMemory":true}' \
  | jq -c '.structLogs[] | select(.op=="RETURN") | {stack, memory}'
```

La memoria en el `RETURN`, palabra a palabra:

| Posición | Palabra | Qué es |
| -------- | ------- | ------ |
| `0x00`, `0x20` | `0` | Zona de trabajo, sin usar |
| `0x40` | `…00c0` | Puntero de memoria libre: `0xc0` |
| `0x60` | `0` | Slot cero |
| `0x80` | `…0004` | El string `"hola"`: su longitud |
| `0xa0` | `686f6c61…` | Sus bytes |
| `0xc0` | `…0020` | La respuesta en ABI: el offset del string |
| `0xe0` | `…0004` | Su longitud |
| `0x100` | `686f6c61…` | Sus bytes |

Y la pila, con la cima a la derecha: `["0xcfae3217","0x60","0xc0"]`. `RETURN` devuelve `0x60`
bytes desde `0xc0`, la codificación ABI. Fíjate en que el puntero sigue en `0xc0`: solc codifica
la respuesta en la memoria libre sin reservarla, porque después de `RETURN` no hay nada más.

## La memoria en una llamada a otro contrato

`CALL` y `STATICCALL` (semana 10) no reciben los argumentos por la pila: reciben **dónde están
en la memoria**. `STATICCALL` saca de la pila, por este orden, el gas, la dirección, la posición y
el tamaño de los argumentos, y la posición y el tamaño donde copiar la respuesta. Con un contrato
que llama al `Greeter` de arriba:

```solidity
import {Greeter} from "./Greeter.sol";

contract Caller {
    function relay(Greeter greeter) external view returns (string memory) {
        return greeter.greet();
    }
}
```

desplegado en anvil después del `Greeter` (`$C` es la dirección de `Caller` y `$G` la del
`Greeter`), la traza del `STATICCALL`:

```bash
DATA=$(cast calldata "relay(address)" $G)
cast rpc debug_traceCall "{\"to\":\"$C\",\"data\":\"$DATA\"}" latest '{"enableMemory":true}' \
  | jq -c '.structLogs[] | select(.op=="STATICCALL") | {depth, stack: .stack[-6:], memory}'
```

```text
{"depth":1,"stack":["0x0","0x80","0x4","0x80","0x5fbdb2315678afecb367f032d93f642f64180aa3","0x1c96daf"],"memory":["0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000080","0x0000000000000000000000000000000000000000000000000000000000000000","0xcfae321700000000000000000000000000000000000000000000000000000000"]}
```

Leída desde la cima (a la derecha): gas `0x1c96daf`, la dirección del `Greeter`, argumentos en
`0x80` con `0x4` bytes (el selector `cfae3217`, que solc escribió en la memoria libre) y respuesta
en `0x80` con `0x0` bytes. solc no sabe cuánto devolverá `greet`, así que no pide copia: después
lee `RETURNDATASIZE` (`0x60`) y copia con `RETURNDATACOPY` justo lo que llegó.

El primer paso del `Greeter` (`depth` 2) tiene `"memory":[]`: la llamada empieza con su propia
memoria vacía. La de `Caller` sigue intacta y le espera.

## ⚠️ Antipatrones y riesgos

- **Tamaños que elige otro.** `new bytes(n)`, un `uint256[] memory` de longitud `n` o un bucle
  que añade a un array en memoria, con `n` que viene de la calldata o del storage, dejan que otro
  decida cuánto gas gastas. Con 1 MiB, tu transacción no cabe en un bloque. Pon un límite.
- **Return bomb.** `(bool ok, bytes memory ret) = target.call(...)` copia en tu memoria **toda** la
  returndata de `target`, y pagas tú la ampliación. Un contrato malicioso devuelve un motivo de
  revert enorme y tu transacción se queda sin gas. Es el `ReturnBombHook` del proyecto de la
  semana 21. Pon tope de gas a la llamada y no copies lo que no necesitas.
- **Memoria no es storage.** Cambiar un `struct` copiado a `memory` no cambia el storage (semana
  06). Desde dentro: la copia está en otra zona, y al acabar la llamada desaparece.
- **El puntero de memoria libre es una convención.** La EVM no lo protege. Solidity lo respeta
  siempre; el código en assembly de la semana 28 puede romperlo, y entonces dos datos ocupan los
  mismos bytes.

## 💡 Trucos

- Para ver la memoria en una traza, `{"enableMemory":true}` en `debug_traceTransaction` o
  `debug_traceCall`. Sin esa opción, la memoria sale vacía.
- `MSIZE` mide la memoria tocada, no la usada: una lectura lejos amplía y cobra igual que una
  escritura.
- Para medir el gas de algo en un test, `gasleft()` antes y después. Para comparar, llama una vez
  antes para que la dirección ya esté *caliente* (teoría 03).

## ✅ Checklist

- [ ] Sé qué hacen `MLOAD`, `MSTORE`, `MSTORE8` y `MSIZE`.
- [ ] Sé por qué la memoria empieza vacía en cada llamada y qué pasa con ella al acabar.
- [ ] Sé calcular el coste de ampliar la memoria y por qué un megabyte no cabe en una transacción
  normal.
- [ ] Sé qué hay en `0x00`, `0x40`, `0x60` y `0x80`, y qué hace `6080604052`.
- [ ] Sé por qué un tamaño que elige otro, o una returndata sin límite, son un riesgo.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — La máquina de pila](01-la-maquina-de-pila.md) | **Teoría 02 — La memoria** | [Teoría 03 — El storage por dentro →](03-el-storage-por-dentro.md) |
