# Teoría 04 — assert, panic y unchecked

## 🎯 Objetivos

- Distinguir un error de quien llama (`require`, `revert`) de un error del propio contrato
  (`assert`).
- Reconocer los códigos de `Panic` más comunes.
- Usar `unchecked` sabiendo qué protección se pierde y cuánto gas se ahorra.

---

## 1. Qué problema resuelve

`require` y `revert` rechazan llamadas que rompen una regla: un valor fuera de rango,
alguien que no es el dueño. Son fallos **esperados**: el contrato funciona bien y dice
"no". Hay otra clase de fallo: que el propio contrato llegue a un estado imposible por un
error de programación. Para eso existen `assert` y los **panics** (errores que genera la
propia EVM o el compilador, no tu código), y para el caso contrario, cuando tú sabes que
una operación no puede desbordar, `unchecked`.

## 2. `assert`: invariantes

Un **invariante** es una propiedad que tiene que cumplirse siempre, pase lo que pase:
"`count` nunca supera `CAPACITY`". `assert(condición)` la comprueba y, si es falsa,
revierte con un panic:

```solidity
contract P {
    uint256 public constant CAPACITY = 3;
    uint256 public count;

    function registerBuggy() external {
        count += 2;                 // ❌ error de programación: debería sumar 1
        assert(count <= CAPACITY);
    }
}
```

Llamada dos veces en un test:

```
[FAIL: panic: assertion failed (0x01)] test_assert() (gas: 76095)
```

La diferencia con `require` no es técnica sino de intención:

| | `require` / `revert` | `assert` |
| - | -------------------- | -------- |
| Qué comprueba | Entradas y permisos | Invariantes del propio contrato |
| Si falla | Quien llama hizo algo no permitido | El contrato tiene un bug |
| Qué devuelve | `Error(string)` o tu error personalizado | `Panic(uint256)` con código `0x01` |

En un contrato correcto, un `assert` **nunca** debería fallar. Si un test lo hace fallar,
has encontrado un bug.

## 3. Panics que genera el compilador

No hace falta escribir `assert` para ver un panic. El compilador añade comprobaciones a
ciertas operaciones y revierte con `Panic(código)` si fallan:

| Código | Causa | Salida en un test |
| ------ | ----- | ----------------- |
| `0x01` | `assert` falso | `panic: assertion failed (0x01)` |
| `0x11` | Suma, resta o multiplicación fuera de rango | `panic: arithmetic underflow or overflow (0x11)` |
| `0x12` | División o módulo entre cero | `panic: division or modulo by zero (0x12)` |

Todos devuelven el mismo selector, el de `Panic(uint256)`, seguido del código:

```bash
cast sig "Panic(uint256)"
```

```
0x4e487b71
```

Con `cast call`, el `assert` que falla devuelve
`data: "0x4e487b710000000000000000000000000000000000000000000000000000000000000001"`.

## 4. Aritmética comprobada y `unchecked`

Desde la semana 04 sabes que `uint8` con valor 255 más 1 revierte con `0x11`: es la
**aritmética comprobada** (*checked math*) de Solidity 0.8. Cada suma, resta y
multiplicación lleva una comprobación extra, que cuesta gas.

Un bloque `unchecked { ... }` la quita. Dentro, los valores **dan la vuelta** (*wrap*): al
pasar del máximo vuelven a empezar desde 0, como un cuentakilómetros.

```solidity
function wrap(uint8 x) external pure returns (uint8) {
    unchecked {
        return x + 1;
    }
}
```

```
[PASS] test_wrap() (gas: 6352)
```

El test comprueba `assertEq(p.wrap(255), 0)`: sin revert, 255 + 1 da 0.

### Cuánto se ahorra

Tres versiones del mismo bucle, que suma de 0 a `n - 1`:

```solidity
// a: todo comprobado.
function a(uint256 n) external pure returns (uint256 s) {
    for (uint256 i = 0; i < n; i++) { s += i; }
}

// b: solo el contador sin comprobar.
function b(uint256 n) external pure returns (uint256 s) {
    for (uint256 i = 0; i < n;) { s += i; unchecked { ++i; } }
}

// c: todo sin comprobar.
function c(uint256 n) external pure returns (uint256 s) {
    unchecked { for (uint256 i = 0; i < n; i++) { s += i; } }
}
```

`cast estimate` con `n = 100`:

```
46815
46271
28849
```

Quitar la comprobación del contador ahorra poco. Quitarla de `s += i` ahorra mucho, pero
`s` sí podría desbordar con un `n` enorme: ese ahorro es justo el que no debes hacer.

## 5. Riesgos

- **`unchecked` donde sí puede desbordar**: antes de la 0.8, todos los contratos
  funcionaban así, y los desbordamientos permitieron crear tokens de la nada en contratos
  reales. Solo es seguro cuando puedes demostrar que el valor no se sale del rango (un
  contador acotado por la condición del bucle, una resta después de comprobar
  `a >= b`).
- **`assert` para validar entradas**: un `assert` que falla por culpa de quien llama
  confunde: parece un bug del contrato. Para entradas, `require` o un error personalizado.
- **Conversiones**: `unchecked` no afecta a `uint8(valor)`; las conversiones explícitas
  truncan siempre, sin comprobar nada (semana 04).

## 6. Trucos

- Cuando uses `unchecked`, escribe al lado el comentario que demuestra por qué no desborda.
- Un `assert` al final de una función que escribe estado documenta el invariante y lo
  comprueba en cada test.

## ✅ Checklist

- [ ] Explico cuándo uso `assert` y cuándo `require`.
- [ ] Reconozco los panics `0x01`, `0x11` y `0x12` y el selector `0x4e487b71`.
- [ ] Explico qué cambia dentro de un bloque `unchecked` y cuándo es seguro usarlo.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Errores personalizados](03-errores-personalizados.md) | **Teoría 04 — assert, panic y unchecked** | [Teoría 05 — Modificadores →](05-modificadores.md) |
