# Ejercicio 03 — Calldata y memoria

> Al terminar habrás escrito a mano la calldata de una función con un string y la de una con un
> `string[]`, habrás comprobado qué calldatas rechaza Solidity y cuáles deja pasar, habrás abierto
> los tres formatos de error byte a byte y habrás medido cómo crece el coste de la memoria.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 02 — La memoria](../../1-teoria/02-la-memoria.md) y
[Teoría 04 — Calldata y returndata](../../1-teoria/04-calldata-y-returndata.md) leídas, y el
[ejercicio 02](../ejercicio-02-storage-al-descubierto/README.md) en verde.

## Contexto

Proyecto Foundry. `Inbox` es un buzón de notas con cuatro funciones: `post` (una dirección, un
importe y un string), `totalLength` (un `string[]`), `split` (que divide) y `allocate` (que
reserva memoria).

| Archivo | Qué es |
| ------- | ------ |
| `src/Inbox.sol` | El contrato. No lo cambies |
| `test/Calldata.t.sol` | Los tests, ya escritos, y los ayudantes `_...`: tu trabajo, pasos 1 a 5 |

Los tests llaman a `Inbox` con `address(inbox).call(datos)`, con los bytes que construyen tus
ayudantes, y miran `ok` y la returndata `ret`. Para construir bytes, `abi.encodePacked` pega sus
argumentos sin relleno: un `uint256` son 32 bytes y un `bytes4`, 4. Es la herramienta para poner
cada palabra donde va.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-27-evm_por_dentro/2-practicas/ejercicio-03-calldata-y-memoria/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `0 passed; 6 failed`, cada uno con su `TODO: Paso N`.

## Paso 1: La calldata de `post`, a mano

**Por qué**: es la tabla de la teoría 04 escrita en Solidity. Tres argumentos: dos estáticos en su
sitio y, en el sitio del string, su offset. Tres palabras de cabeza son `0x60` bytes, así que el
string empieza en `0x60`.

| Posición | Contenido |
| -------- | --------- |
| — | `Inbox.post.selector` |
| `0x00` | `to`, como `uint256` |
| `0x20` | `amount` |
| `0x40` | `0x60` |
| `0x60` | La longitud del string |
| `0x80` | Sus bytes y el relleno hasta la palabra (`_padding`) |

**Abre** `test/Calldata.t.sol`, borra el `revert` de `_postCalldata` y descomenta sus líneas.
Ejecuta `forge test`.

**Verifica**: `2 passed; 4 failed`. `testFuzz_Paso1_PostByHand` compara tu calldata con la de
`abi.encodeCall` para 256 combinaciones de dirección, importe y texto, y
`test_Paso1_CallWithHandMadeCalldata` la envía: `post` devuelve 1.

## Paso 2: Un `string[]`, a mano

**Por qué**: el único argumento es dinámico, así que la cabeza es una palabra con el offset
`0x20`. En `0x20` empieza el array: su longitud, una tabla con un offset por elemento y los
elementos. Los offsets de la tabla se cuentan desde el final de la longitud: el primer elemento
está justo detrás de la tabla, a `n · 32` bytes, y cada uno de los siguientes, detrás del
anterior.

El ayudante construye la tabla y los elementos a la vez: antes de añadir cada elemento, su offset
es el tamaño de la tabla más lo que ya ocupan los elementos anteriores.

**Abre** `test/Calldata.t.sol` y resuelve `_totalLengthCalldata`.

**Verifica**: `3 passed; 3 failed`. El test usa cuatro notas: dos cortas, una vacía y una de 43
bytes, que ocupa dos palabras. `totalLength` devuelve 48.

## Paso 3: Lo que rechaza el decodificador

**Por qué**: el código que genera solc valida la calldata antes de ejecutar `post`. Dos copias
estropeadas de la calldata del paso 1 lo comprueban:

- `_withDirtyAddress`: pone `0xff` en el byte 4, el primero de la palabra de `to`. Una dirección
  solo usa los 20 bytes bajos; los 12 altos tienen que ser cero.
- `_withoutLastWord`: quita la última palabra. El string anuncia 4 bytes que ya no están.

El test añade un tercer caso, ya escrito: la misma calldata con 4 bytes de más al final.

**Abre** `test/Calldata.t.sol` y resuelve `_withDirtyAddress` y `_withoutLastWord`.

**Verifica**: `4 passed; 2 failed`. Las dos primeras llamadas fallan con returndata vacía: el
decodificador no da motivo. La tercera funciona, y `posted` vale 1: **dos calldatas con distinto
keccak256 hacen la misma llamada**. Por eso un contrato que apunta "este hash de `msg.data` ya se
usó" no impide repetir una llamada.

## Paso 4: Abrir la returndata

**Por qué**: la returndata de un revert es un selector de 4 bytes y sus argumentos codificados en
ABI. `bytes4(ret)` da el selector. Para decodificar el resto con `abi.decode` necesitas los bytes
sin el selector: en memoria no hay `ret[4:]`, así que se copian a un `bytes` nuevo.

**Abre** `test/Calldata.t.sol` y resuelve `_split`.

**Verifica**: `5 passed; 1 failed`. `test_Paso4_ThreeRevertFormats` provoca los tres formatos:

| Llamada | Selector | Argumentos |
| ------- | -------- | ---------- |
| `post` con una nota de 65 bytes | `NoteTooLong.selector` | `(65, 64)` |
| `post` a `address(0)` | `bytes4(keccak256("Error(string)"))` | `"Inbox: zero address"` |
| `split(10, 0)` | `bytes4(keccak256("Panic(uint256)"))` | `0x12`: división entre cero |

## Paso 5: El coste de la memoria

**Por qué**: `allocate(size)` reserva `size` bytes con `new bytes(size)`. Si la memoria costara lo
mismo por byte, cuatro veces más memoria costaría cuatro veces más gas. El término cuadrático de
la teoría 02 dice que cuesta más.

El ayudante mide con `gasleft()` antes y después de la llamada. El test llama una vez antes de
medir: la primera llamada a una dirección es fría y paga 2600 de gas de más, que estropearía la
comparación.

**Abre** `test/Calldata.t.sol` y resuelve `_allocateGas`. Ejecuta con `-vv` para ver los logs:

```bash
forge test --mt test_Paso5 -vv
```

**Verifica**: `6 passed; 0 failed` con todo el archivo, y en los logs:

```text
  gas con 32 KiB: 14306
  gas con 128 KiB: 63530
```

Cuatro veces más memoria, 4,4 veces más gas. El test acaba con un megabyte y un millón de gas: la
llamada se queda sin gas y falla.

## Para pensar

- En el paso 3, ¿qué pasaría si `Inbox` leyera `to` con
  `address(uint160(uint256(bytes32(msg.data[4:36]))))` en vez de recibirlo como argumento?
- El paso 2 da 48 con cuatro notas. ¿Cuántos bytes de calldata ocupa la llamada? ¿Cuántos de ellos
  son ceros? Calcula su gas con la tabla de la teoría 04.
- `allocate` es `pure` y no guarda nada. ¿Por qué sigue siendo un riesgo que cualquiera elija
  `size`, si quien paga el gas es quien llama?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Storage al descubierto](../ejercicio-02-storage-al-descubierto/README.md) | **Ejercicio 03 — Calldata y memoria** | [Proyecto — Mapa de storage →](../../3-proyecto/README.md) |
