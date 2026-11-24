# Teoría 04 — Calldata y returndata

## 🎯 Objetivos

- Explicar cómo lee la EVM los datos de entrada: `CALLDATALOAD`, `CALLDATASIZE` y
  `CALLDATACOPY`.
- Saber qué comprueba el decodificador de Solidity y qué deja pasar.
- Codificar a mano tipos dinámicos anidados, como un `string[]`, con sus tablas de offsets.
- Leer la returndata de un revert en sus tres formatos: `Error(string)`, `Panic(uint256)` y
  errores personalizados.
- Calcular el gas de la calldata de una transacción, con el suelo de EIP-7623.

## Qué problema resuelve

En la semana 10 aprendiste la codificación ABI: selector y palabras de 32 bytes, con offsets
para los tipos dinámicos. Con `abi.encodeCall` y `abi.decode` no necesitabas más. Pero hay
situaciones en las que tienes los bytes y nada más:

- Una transacción falla y el explorador solo muestra la calldata y unos bytes de error.
- Un contrato firma, hashea o reenvía `msg.data` tal cual, y tienes que saber si dos calldatas
  distintas pueden hacer lo mismo.
- Un contrato llama a otro y decide algo según lo que le devuelve.

Para esos casos necesitas saber cómo ve la EVM los datos que entran (**calldata**) y los que
vuelven (**returndata**).

## Cómo funciona: la calldata desde la EVM

La calldata son los bytes de entrada de una llamada, de solo lectura.

- `CALLDATASIZE` da su longitud en bytes.
- `CALLDATALOAD(i)` mete en la pila los 32 bytes que empiezan en `i`. Si se pasa del final,
  completa con ceros: **nunca falla**.
- `CALLDATACOPY(destino, i, n)` copia `n` bytes a la memoria.

La EVM no sabe nada de selectores ni de tipos: todo eso lo escribe solc en el bytecode, como el
dispatcher de la teoría 01. En Solidity, `msg.data` es la calldata entera y `msg.sig`, sus 4
primeros bytes.

## Lo que comprueba el decodificador de Solidity

Antes de ejecutar una función `external`, el código que genera solc decodifica sus argumentos y
revierte, **sin datos de error**, si la calldata no es válida. Con el `Inbox` del ejercicio 03
desplegado en anvil y su llamada `post(bob, 5, "hola")`:

```bash
D=$(cast calldata "post(address,uint256,string)" $B 5 hola)
cast call $C $D
```

```text
0x0000000000000000000000000000000000000000000000000000000000000001
```

Con `0xff` en el primer byte de la dirección, que solo usa los 20 bytes bajos de su palabra:

```bash
cast call $C 0x$(echo $D | cut -c3-10)ff$(echo $D | cut -c13-)
```

```text
Error: server returned an error response: error code 3: execution reverted, data: "0x"
```

Sin la última palabra (el string anuncia 4 bytes que no llegan), lo mismo:

```bash
cast call $C ${D:0:$((${#D}-64))}
```

```text
Error: server returned an error response: error code 3: execution reverted, data: "0x"
```

Con cuatro bytes de más al final, en cambio:

```bash
cast call $C ${D}deadbeef
```

```text
0x0000000000000000000000000000000000000000000000000000000000000001
```

| Calldata | Qué hace el decodificador |
| -------- | ------------------------- |
| Bits altos en `address`, `bool` que no es 0 ni 1, `enum` fuera de rango, `uintN` que no cabe | Revierte sin datos |
| Más corta de lo que piden los argumentos, o un offset que se sale | Revierte sin datos |
| Bytes de más al final | Los ignora |
| Menos de 4 bytes, o un selector desconocido | `fallback` (o `receive`, si llega vacía) si existe; si no, revierte sin datos |

La tercera fila es la que importa en seguridad: **dos calldatas distintas
pueden ser la misma llamada**.

## Tipos dinámicos anidados

En un `string[]`, cada string es dinámico y el array también. El array va en la cola, como
cualquier dinámico, y empieza con su longitud. Detrás va una **tabla de offsets**, uno por
elemento, contados desde justo después de la longitud. Detrás de la tabla, cada string con su
longitud y sus bytes:

```bash
cast calldata "totalLength(string[])" "[ab,cde]"
```

```text
0xad70be7200000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000002616200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000036364650000000000000000000000000000000000000000000000000000000000
```

![Calldata de totalLength(["ab", "cde"]). Detrás del selector ad70be72, la palabra 0x00 es el offset del array, 0x20. En 0x20, la longitud del array, 2. En 0x40 y 0x60, la tabla de offsets: 0x40 y 0x80, contados desde 0x40, que apuntan a 0x80 y 0xc0. En 0x80, la longitud de "ab", 2, y en 0xa0 sus bytes. En 0xc0, la longitud de "cde", 3, y en 0xe0 sus bytes.](../0-assets/04-calldata-anidada.svg)

| Posición | Palabra | Qué es |
| -------- | ------- | ------ |
| `0x00` | `…0020` | El array empieza en `0x20` |
| `0x20` | `…0002` | Longitud del array |
| `0x40` | `…0040` | Elemento 0: en `0x40 + 0x40 = 0x80` |
| `0x60` | `…0080` | Elemento 1: en `0x40 + 0x80 = 0xc0` |
| `0x80` | `…0002` | `"ab"`: longitud |
| `0xa0` | `6162…` | `"ab"`: bytes |
| `0xc0` | `…0003` | `"cde"`: longitud |
| `0xe0` | `636465…` | `"cde"`: bytes |

Cada nivel de anidamiento repite la regla: offsets relativos al principio de su propio bloque.
Lo escribes a mano en el ejercicio 03.

## La returndata

`RETURN(p, n)` y `REVERT(p, n)` terminan una llamada y entregan `n` bytes de la memoria al que
llamó. Ahí, `RETURNDATASIZE` da su tamaño y `RETURNDATACOPY` los copia a memoria; duran hasta la
siguiente llamada. Si la llamada terminó con `REVERT`, esos bytes son el **motivo** del error, en
uno de tres formatos:

| Formato | Selector | Quién lo produce |
| ------- | -------- | ---------------- |
| `Error(string)` | `0x08c379a0` | `require(cond, "texto")` y `revert("texto")` |
| `Panic(uint256)` | `0x4e487b71` | El propio Solidity: desbordamiento, división entre cero, índice fuera de rango |
| Error personalizado | El de su firma | `revert MiError(args)` (semana 05) |

Los tres en el `Inbox`:

```bash
cast call $C "split(uint256,uint256)" 10 0
```

```text
Error: execution reverted: panic: division or modulo by zero (0x12)

Context:
- server returned an error response: error code 3: execution reverted: panic: division or modulo by zero (0x12), data: "0x4e487b710000000000000000000000000000000000000000000000000000000000000012"
```

```bash
cast call $C "post(address,uint256,string)" 0x0000000000000000000000000000000000000000 1 hola
```

```text
Error: execution reverted: Inbox: zero address

Context:
- server returned an error response: error code 3: execution reverted: Inbox: zero address, data: "0x08c379a000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000013496e626f783a207a65726f206164647265737300000000000000000000000000"
```

Con una nota de 65 caracteres, el error personalizado `NoteTooLong(65, 64)`: selector `0x283ee468`
y dos palabras, `0x41` y `0x40`. `cast decode-error` decodifica los formatos estándar:

```bash
cast decode-error 0x4e487b710000000000000000000000000000000000000000000000000000000000000012
```

```text
Panic(uint256)
18
```

Los códigos de `Panic` más comunes ([lista completa](https://docs.soliditylang.org/en/v0.8.38/control-structures.html#panic-via-assert-and-error-via-require)):

| Código | Causa |
| ------ | ----- |
| `0x01` | `assert` falso |
| `0x11` | Desbordamiento aritmético fuera de `unchecked` |
| `0x12` | División o módulo entre cero |
| `0x21` | Conversión a un `enum` fuera de rango |
| `0x32` | Índice de array fuera de rango |
| `0x41` | Reserva de memoria demasiado grande |

## El gas de la calldata

Cada byte de calldata cuesta: 4 de gas si es cero, 16 si no (EIP-2028). Desde el hardfork Prague
(mayo de 2025), **EIP-7623** añade un **suelo**: una transacción paga al menos 10 de gas por
*token*, donde un byte cero es 1 token y uno distinto, 4. El suelo solo manda cuando la
transacción ejecuta poco, como un envío de datos a una cuenta sin código. Cien bytes enviados a
la cuenta 1 de anvil:

| Datos | Normal: 21 000 + bytes | Suelo: 21 000 + 10 · tokens | `gasUsed` |
| ----- | ---------------------- | --------------------------- | --------- |
| 100 bytes `0x00` | 21 400 | 22 000 | `22000` |
| 100 bytes `0xff` | 22 600 | 25 000 | `25000` |

Los ceros salen baratos en los dos cálculos. Por eso una dirección con muchos ceros delante
(`0x0000...`) ahorra gas cada vez que va en una calldata.

## ⚠️ Antipatrones y riesgos

- **Hashear `msg.data` para evitar repeticiones.** Con bytes de más al final, la misma llamada
  tiene otro hash. Un contrato que guarda "este hash ya se usó" deja repetir la llamada. Hashea
  los argumentos decodificados, con su estructura, como EIP-712 (semana 14), y lleva un nonce.
- **Leer calldata sin el decodificador.** Las comprobaciones de la tabla las hace el código de
  solc. Quien lee la calldata a mano (`address(uint160(uint256(bytes32(msg.data[4:36]))))`, o el
  assembly de la semana 28) no recibe ninguna: los bits altos sucios se cortan en silencio, y en
  assembly `CALLDATALOAD` completa con ceros una calldata corta.
- **Fiarse del motivo de un revert ajeno.** Un contrato externo puede devolver los bytes que
  quiera, también un error con el selector de uno tuyo. Decide por `ok`, no por el texto, y
  limita lo que copias: la *return bomb* de la teoría 02.
- **El ataque de la dirección corta.** Antes de que el decodificador comprobara la longitud, una
  calldata con la dirección un byte más corta desplazaba el importe y lo multiplicaba por 256.
  Hoy revierte, como la calldata corta de arriba; con calldata leída a mano, vuelve.

## 💡 Trucos

- `cast calldata` codifica, `cast calldata-decode` decodifica y `cast decode-error` lee un motivo
  de revert.
- `cast call` decodifica los errores personalizados de tu proyecto, como `NoteTooLong(65, 64)`,
  porque encuentra su selector en los artefactos que compiló forge.
- Para ver la calldata en una traza, el `-vvvv` de `forge test` la muestra en cada llamada.

## ✅ Checklist

- [ ] Sé qué hacen `CALLDATALOAD`, `CALLDATASIZE` y `CALLDATACOPY`, y qué devuelve una lectura
  fuera del final.
- [ ] Sé qué calldatas rechaza el decodificador y cuáles deja pasar.
- [ ] Sé codificar un `string[]` a mano, con su tabla de offsets.
- [ ] Sé reconocer `Error(string)`, `Panic(uint256)` y un error personalizado por su selector.
- [ ] Sé por qué hashear `msg.data` no evita repeticiones.
- [ ] Sé calcular el gas de una calldata con el suelo de EIP-7623.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — El storage por dentro](03-el-storage-por-dentro.md) | **Teoría 04 — Calldata y returndata** | [Ejercicio 01 — Bytecode a mano →](../2-practicas/ejercicio-01-bytecode-a-mano/README.md) |
