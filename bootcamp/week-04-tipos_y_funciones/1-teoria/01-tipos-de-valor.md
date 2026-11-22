# Teoría 01 — Tipos de valor

## 🎯 Objetivos

- Elegir entre `uint`, `int`, `bool`, `address` y `bytesN` según lo que guarda el dato.
- Conocer el rango de cada tamaño de entero y qué pasa al salirse de él.
- Distinguir conversiones implícitas (que el compilador acepta solo) de explícitas.
- Saber el valor por defecto de cada tipo.

---

## 1. Qué problema resuelve

En la semana 03 usaste `uint256` para todo lo numérico y `address` para `msg.sender`. Un
protocolo real guarda más cosas: si un recurso está activo, una cantidad que puede ser
negativa, un hash. Elegir bien el tipo hace dos cosas: el compilador rechaza los errores
de tipo antes de desplegar, y el dato ocupa lo justo en el storage, que es lo que más gas
cuesta.

Un **tipo de valor** es un tipo cuyo dato se copia entero al asignarlo o pasarlo a una
función: si cambias la copia, el original no cambia. Todos caben en una palabra de
32 bytes de la EVM. Los tipos que no se copian así (`string`, arrays, `struct`) son
**tipos por referencia** y llegan en la semana 06.

## 2. Enteros sin signo: `uint8` a `uint256`

`uintN` guarda enteros de 0 a 2ᴺ − 1, con N múltiplo de 8 entre 8 y 256. `uint` a secas
es lo mismo que `uint256`; en este bootcamp se escribe siempre el tamaño.

| Tipo | Mínimo | Máximo |
| ---- | ------ | ------ |
| `uint8` | 0 | 255 |
| `uint16` | 0 | 65535 |
| `uint256` | 0 | 115792089237316195423570985008687907853269984665640564039457584007913129639935 |

`type(T).min` y `type(T).max` dan los límites de cualquier entero:

```solidity
function maxUint8() external pure returns (uint8) {
    return type(uint8).max; // 255
}
```

**Salirse del rango revierte.** Desde la versión 0.8 del compilador, toda suma, resta o
multiplicación se comprueba: si el resultado no cabe, la transacción se deshace. Con un
`uint8` que vale 255:

```solidity
small += 1; // ❌ en ejecución
```

```
├─ [23536] C::inc()
│   └─ ← [Revert] panic: arithmetic underflow or overflow (0x11)
```

Es el mismo `panic (0x11)` del `removePoints` de la semana 03. La semana 05 estudia esta
comprobación y cuándo se desactiva.

La **división entera** descarta los decimales: `7 / 2` da `3`. Solidity no tiene números
decimales: los importes se guardan en la unidad más pequeña (como el wei, semana 02) y
se multiplica antes de dividir.

## 3. Enteros con signo: `int8` a `int256`

`intN` admite negativos: de −2ᴺ⁻¹ a 2ᴺ⁻¹ − 1. Un `int8` va de −128 a 127. Úsalo solo
cuando el dato pueda ser negativo de verdad (una variación, un saldo deudor); para
cantidades y contadores, `uint`.

```solidity
function minInt8() external pure returns (int8) {
    return type(int8).min; // -128
}
```

## 4. `bool`

`true` o `false`. Lo producen las comparaciones (`==`, `!=`, `<`, `>=`...) y se combinan
con `&&`, `||` y `!`:

```solidity
function isAdult(uint256 age) external pure returns (bool) {
    return age >= 18;
}
```

## 5. `address`

Una dirección de 20 bytes (semana 02). El compilador exige que una dirección escrita en
el código tenga bien las mayúsculas del **checksum** (la mezcla de mayúsculas y
minúsculas que detecta erratas, semana 02): `cast to-check-sum-address` la corrige.
`address(0)` es la dirección cero, el valor por defecto: se usa para "nadie".

```solidity
function isZeroAddress(address account) external pure returns (bool) {
    return account == address(0);
}
```

La semana 07 presenta `address payable`, la que puede recibir ETH.

## 6. `bytes1` a `bytes32`

`bytesN` guarda exactamente N bytes. El más usado es `bytes32`, que es lo que devuelve
`keccak256` (semana 01). `bytes4` es el tamaño de un selector (semana 03):

```solidity
function selectorOf(string memory signature) external pure returns (bytes4) {
    return bytes4(keccak256(bytes(signature)));
}
```

`selectorOf("increment()")` devuelve `0xd09de08a`, lo mismo que `cast sig`.
(`string memory` es un texto que se recibe como parámetro: `memory` se explica en la
semana 06.)

## 7. Conversiones

El compilador convierte **solo** cuando no se puede perder información: de `uint8` a
`uint256` sí, al revés no:

```solidity
function f(uint256 x) external pure returns (uint8) {
    uint8 y = x; // ❌
    return y;
}
```

```
Error (9574): Type uint256 is not implicitly convertible to expected type uint8.
```

Un literal que no cabe también se rechaza:

```solidity
uint8 small = 256; // ❌
```

```
Error (7407): Type int_const 256 is not implicitly convertible to expected type uint8. Literal is too large to fit in uint8.
```

Con una **conversión explícita**, `uint8(x)`, el compilador obedece, pero **no
comprueba nada**: se queda con los bits bajos y descarta el resto sin revertir.
`uint8(256)` da `0`, `uint8(300)` da `44` y `uint16(70000)` da `4464`. Lo mismo al
cambiar de signo: `uint8(int8(-1))` da `255`.

## 8. Valores por defecto

Una variable que nadie asignó vale "todo a cero":

| Tipo | Valor por defecto |
| ---- | ----------------- |
| `uint*`, `int*` | `0` |
| `bool` | `false` |
| `address` | `0x0000000000000000000000000000000000000000` |
| `bytes32` | `0x00…00` (32 bytes a cero) |

No existe `null` ni "sin definir": no puedes distinguir "guardé un 0" de "nunca guardé
nada" mirando el valor.

## 9. Antipatrones y riesgos

- **Conversión explícita a un tipo menor**: trunca en silencio. Un importe de
  `256` convertido a `uint8` pasa a ser `0`. Convierte solo lo que sabes que cabe.
- **Usar `int` para cantidades**: un saldo negativo que no debería existir deja de ser un
  error que revierte y pasa a ser un número válido.
- **Tipos pequeños "para ahorrar gas" en variables sueltas**: un `uint8` solo ahorra si
  comparte slot con otras variables (Teoría 02). Suelto ocupa un slot entero igual.
- **Tratar el 0 como "no existe"**: si 0 es un valor válido (un identificador, un
  importe), necesitas otra forma de saber si el dato existe. Por eso los identificadores
  del registro empiezan en 1.

## 10. Trucos

- `cast max-uint uint8` y `cast min-int int8` dan los límites sin escribir código.
- `cast to-dec` y `cast to-hex` convierten entre bases al leer slots.
- Escribe siempre el tamaño (`uint256`, no `uint`): el storage layout y la ABI usan el
  nombre completo.

## ✅ Checklist

- [ ] Elijo `uint`, `int`, `bool`, `address` o `bytesN` según el dato.
- [ ] Sé el rango de `uint8`, `int8` y `uint256`, y qué pasa si una suma se sale.
- [ ] Explico por qué `uint8(300)` da 44 y no revierte.
- [ ] Sé el valor por defecto de cada tipo.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 04 — Tipos y funciones](../README.md) | **Teoría 01 — Tipos de valor** | [Teoría 02 — Variables de estado y storage →](02-variables-de-estado-y-storage.md) |
