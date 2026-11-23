# Teoría 04 — Aritmética y `unchecked`

## 🎯 Objetivos

- Explicar qué comprueba la checked math de Solidity 0.8 y qué deja fuera.
- Saber cuándo `unchecked` es seguro y cuándo regala saldo.
- Reconocer las conversiones que cortan bits sin avisar y usar `SafeCast`.
- Evitar la pérdida de precisión de dividir antes de multiplicar, y elegir hacia dónde redondear.

## 1. Qué problema resuelve

Los enteros de la EVM tienen tamaño fijo: un `uint8` va de 0 a 255; un `uint256`, de 0 a
2²⁵⁶ - 1. Un **overflow** (desbordamiento) es una operación cuyo resultado no cabe: `255 + 1` en
un `uint8`. Un **underflow**, el caso de abajo: `0 - 1`. La EVM no da error: se queda con los bits
que caben y el número **da la vuelta**, como un cuentakilómetros.

Antes de Solidity 0.8, eso pasaba sin aviso. En 2018, el token BeautyChain (BEC) tenía una
función de envío por lotes que calculaba `uint256 amount = cnt * _value`. Un atacante pidió
enviar 2²⁵⁵ tokens a dos direcciones: el producto dio la vuelta hasta 0, la comprobación de saldo
pasó, y cada dirección recibió 2²⁵⁵ tokens creados de la nada. Varios exchanges congelaron el
token.

## 2. Cómo funciona

### Lo que la checked math cubre

Desde Solidity 0.8, `+`, `-`, `*` y `/` comprueban el resultado. Si no cabe, la operación revierte
con un **panic** (semana 05): un error especial con un código. Los dos que verás:

| Código | Cuándo |
| ------ | ------ |
| `0x11` | Overflow o underflow en `+`, `-`, `*`, `++`, `--` |
| `0x12` | División o módulo por cero |

En forge-std, `stdError.arithmeticError` y `stdError.divisionError` son esos dos panics, listos
para `vm.expectRevert`.

### Lo que no cubre

Tres cosas se saltan la comprobación, y las tres compilan sin warning. **Dónde**: en un proyecto
Foundry, `test/Math.t.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test, console} from "forge-std/Test.sol";

contract MathTest is Test {
    function test_Math() public pure {
        uint8 small = 0;
        unchecked {
            small -= 1;
        }
        console.log("unchecked 0 - 1 en uint8:", small);
        uint256 big = 300;
        console.log("uint8(300):", uint8(big));
        int256 negative = -1;
        console.log("uint256(int256(-1)):", uint256(negative));
        uint256 a = 7;
        console.log("7 / 2 * 2:", a / 2 * 2);
        console.log("7 * 2 / 2:", a * 2 / 2);
        uint256 x = 1;
        console.log("1 << 256:", x << 256);
    }
}
```

**Ejecuta** `forge test -vv --mt test_Math`:

```text
  unchecked 0 - 1 en uint8: 255
  uint8(300): 44
  uint256(int256(-1)): 115792089237316195423570985008687907853269984665640564039457584007913129639935
  7 / 2 * 2: 6
  7 * 2 / 2: 7
  1 << 256: 0
```

Línea a línea:

1. **`unchecked { ... }`** apaga la comprobación dentro del bloque. `0 - 1` da 255, el mayor
   `uint8`.
2. **Conversión a un tipo más pequeño** (downcast). `uint8(300)` se queda con los 8 bits bajos de
   300 (`0x12C`): `0x2C`, 44. Sin revertir.
3. **Conversión entre con y sin signo.** `-1` en un `int256` son 256 bits a 1; leídos como
   `uint256`, son 2²⁵⁶ - 1.
4. **División entera.** No es un overflow, pero pierde: `7 / 2` es 3, y `3 * 2` es 6. Multiplicar
   primero conserva el 7.
5. **Desplazamientos** (`<<`, `>>`). No se comprueban: los bits que salen por la izquierda se
   pierden.

Y una cuarta, que verás en la semana 28: en `assembly`, ninguna operación se comprueba.

### Cuándo `unchecked` es seguro

`unchecked` existe porque comprobar cuesta gas (unas decenas por operación). Es seguro cuando
**una comprobación anterior** garantiza que el resultado cabe:

```solidity
if (balance < amount) revert InsufficientBalance(balance, amount);
unchecked {
    balanceOf[msg.sender] = balance - amount; // no puede bajar de 0: lo acabamos de comprobar
}
```

OpenZeppelin lo hace así en su ERC-20. Si borras el `if` o lo cambias de sitio, el `unchecked`
queda abierto y nada te avisa. Por eso, en código que mueve valor, ahorrar 30 de gas rara vez
compensa: déjalo para la semana 29, con medidas en la mano.

El caso clásico de `unchecked`, el contador de un bucle, ya no hace falta: desde Solidity 0.8.22,
el compilador quita solo la comprobación de `i++` en un `for` cuando `i` se compara con un límite.

## 3. Cómo se escribe

### `SafeCast`

`SafeCast` de OpenZeppelin convierte comprobando: revierte si el valor no cabe.

```solidity
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

uint64 unlockAt = SafeCast.toUint64(block.timestamp + duration);
uint256 price = SafeCast.toUint256(answer); // revierte si `answer` es negativo
```

El error dice cuántos bits pedías y qué valor no cabía. En el ejercicio 03, con
`block.timestamp + duration = 2⁶⁴`:

```text
SafeCastOverflowedUintDowncast(64, 18446744073709551616 [1.844e19])
```

¿Por qué convertir a tipos pequeños? Para **empaquetar**: varias variables en un mismo slot de
storage de 32 bytes (semana 06), como un `uint192` y un `uint64` juntos. Empaquetar ahorra gas,
pero cada conversión es un sitio donde cortar bits.

### Multiplicar primero, y sin desbordar

Para `a * b / c`, multiplica antes de dividir. Si `a * b` puede no caber en 256 bits aunque el
resultado final sí quepa, usa `Math.mulDiv(a, b, c)` de OpenZeppelin (semana 20): calcula el
producto con 512 bits por dentro.

### Redondear a favor del protocolo

Toda división redondea. La pregunta es a favor de quién. La regla: **a favor del protocolo**.

- Lo que cobras o lo que alguien deposita para recibir participaciones: hacia arriba
  (`Math.Rounding.Ceil`), como tu tasa en dólares de la semana 20.
- Lo que pagas o las participaciones que entregas: hacia abajo.

Un wei de diferencia parece nada. Pero si alguien puede repetir una operación que redondea a su
favor, en un bucle, en muchas transacciones, el wei se multiplica. La semana 22 tiene ataques
enteros construidos sobre redondeos.

## 4. Antipatrones y riesgos

- **`unchecked` sin la comprobación justo encima.** Si no puedes señalar la línea que garantiza
  que no desborda, quita el `unchecked`.
- **`uintN(x)` con un `x` que viene de fuera.** Parámetros, sumas con `block.timestamp`, precios
  de un oráculo. `SafeCast`.
- **`uint256(int)` sin mirar el signo.** Comprueba `x > 0` antes (como haces con el precio del
  feed en `RegistryV3`) o usa `SafeCast.toUint256`.
- **Dividir antes de multiplicar.** Cada división intermedia tira decimales.
- **Redondear siempre hacia abajo "porque es lo que hace Solidity".** Elige la dirección según
  quién gana con el redondeo.
- **Confiar en la versión del compilador del código que copias.** Un contrato con
  `pragma solidity ^0.7.0` no tiene checked math: cualquier `+` puede dar la vuelta.

## 5. Trucos

- `type(uint64).max` da el mayor valor de un tipo: útil en tests para probar el borde.
- Un fuzz test (semana 09) con `bound(x, 0, type(uint256).max)` encuentra overflows que tú no
  pensarías probar.
- `vm.expectRevert(stdError.arithmeticError)` comprueba un panic `0x11` sin escribir su
  codificación.
- Para revisar un contrato, busca `unchecked`, `uint8(` a `uint248(`, `int(` y `<<`: son la lista
  corta de sitios donde la checked math no mira.

## ✅ Checklist

- [ ] Sé qué operaciones revierten con `0x11` y `0x12`, y cuáles no comprueban nada.
- [ ] Solo uso `unchecked` con una comprobación justo encima que lo justifique.
- [ ] Convierto a tipos pequeños y de con signo a sin signo con `SafeCast`.
- [ ] Multiplico antes de dividir, y uso `Math.mulDiv` cuando el producto puede no caber.
- [ ] Decido hacia dónde redondea cada división, a favor del protocolo.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Denegación de servicio](03-denegacion-de-servicio.md) | **Teoría 04 — Aritmética y `unchecked`** | [Ejercicio 01 — Reentrancy →](../2-practicas/ejercicio-01-reentrancy/README.md) |
