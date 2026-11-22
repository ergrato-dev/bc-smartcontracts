# Teoría 03 — Arrays

## 🎯 Objetivos

- Declarar arrays de tamaño fijo y dinámico en storage, y usar `push`, `pop` y `length`.
- Predecir qué pasa al leer fuera de rango, al hacer `pop` de un array vacío y al usar
  `delete` sobre un elemento.
- Quitar un elemento sin dejar huecos con swap-and-pop.
- Medir cómo crece el gas de recorrer un array y explicar el riesgo de DoS.

---

## 1. Qué problema resuelve

Un mapping responde "¿qué valor tiene esta clave?", pero no "¿cuáles hay?". Un **array** es
una lista ordenada de valores del mismo tipo, accesibles por posición (índice, desde 0).
Sí tiene longitud y sí se puede recorrer. A cambio, recorrerlo cuesta gas por cada
elemento, y ese detalle decide cómo se usa en un contrato.

## 2. Cómo se escribe

Crea `src/Numbers.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Numbers {
    uint256[] public values;
    uint256[3] public top;

    function add(uint256 value) external {
        values.push(value);
    }

    function addMany(uint256 n) external {
        for (uint256 i = 0; i < n; i++) {
            values.push(i);
        }
    }

    function removeLast() external {
        values.pop();
    }

    function clearAt(uint256 index) external {
        delete values[index];
    }

    function length() external view returns (uint256) {
        return values.length;
    }

    function getAll() external view returns (uint256[] memory) {
        return values;
    }

    function sum() external view returns (uint256 total) {
        for (uint256 i = 0; i < values.length; i++) {
            total += values[i];
        }
    }
}
```

- `uint256[]` es un **array dinámico**: empieza vacío y crece con `push(valor)`, que añade
  al final. `pop()` quita el último. `length` dice cuántos hay.
- `uint256[3]` es un **array de tamaño fijo**: siempre tiene 3 elementos, que empiezan en 0.
  No tiene `push` ni `pop`:

  ```
  Error (9582): Member "push" not found or not visible after argument-dependent lookup in uint256[3] storage ref.
  ```

- `values[i]` lee o escribe la posición `i`.
- El getter de un array público recibe el índice: `values(uint256)`. Para el array entero
  hace falta una función como `getAll`.

`string` y `bytes` también son arrays (de bytes). `bytes` tiene `length`; `string` no, y
para medir un texto se convierte: `bytes(texto).length`.

## 3. Cómo funciona: los bordes

Despliega en anvil con la cuenta 0 (`C=0x5FbDB2315678afecb367f032d93F642f64180aa3`, como en
la teoría 01). Con el array vacío, `pop` revierte:

```bash
cast send $C "removeLast()" --private-key "$PK"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: panic: called `.pop()` on an empty array (0x31), data: "0x4e487b710000000000000000000000000000000000000000000000000000000000000031": Panic(49)
```

Añade tres valores (`add` con 10, 20 y 30) y lee fuera de rango:

```bash
cast call $C "values(uint256)(uint256)" 1
cast call $C "values(uint256)(uint256)" 3
```

```
20
Error: server returned an error response: error code 3: execution reverted, data: "0x"
```

El getter automático revierte sin datos. En tu propio código, `values[index]` con un índice
fuera de rango revierte con `Panic(0x32)`; en un test se ve así:

```
[FAIL: panic: array out-of-bounds access (0x32)] test_OutOfBounds() (gas: 7911)
```

Ahora `delete` sobre el elemento 1:

```bash
cast send $C "clearAt(uint256)" 1 --private-key "$PK"
cast call $C "getAll()(uint256[])"
cast call $C "length()(uint256)"
```

```
[10, 0, 30]
3
```

`delete values[i]` **no quita** el elemento: lo deja en su valor por defecto. La longitud
sigue igual y queda un hueco.

## 4. Quitar sin huecos: swap-and-pop

Para quitar de verdad el elemento `i` hay dos opciones: desplazar todos los siguientes una
posición (un bucle que cuesta más cuanto más largo es el array) o **swap-and-pop**: copiar
el último en la posición `i` y hacer `pop`. Cuesta lo mismo con 3 elementos que con 3000;
a cambio, el orden cambia.

![Swap-and-pop: para quitar el elemento de la posición 1 de [10, 20, 30, 40], el último (40) se copia en la posición 1 y se hace pop. Resultado: [10, 40, 30], tres elementos, sin huecos y con el orden cambiado](../0-assets/01-swap-and-pop.svg)

```solidity
function removeAt(uint256 index) external {
    uint256 length = values.length;
    if (index >= length) revert IndexOutOfBounds(index, length);
    values[index] = values[length - 1];
    values.pop();
}
```

Si `index` ya es el último, la copia es sobre sí mismo y el `pop` lo quita: funciona sin
caso especial.

## 5. El gas de recorrer

`sum()` recorre todo el array. `cast estimate` dice cuánto gas costaría como transacción.
Con los 3 elementos de antes:

```bash
cast estimate $C "sum()"
```

```
31476
```

Tras `addMany(97)` (100 elementos) y después `addMany(900)` (1000 elementos):

```
286877
2656577
```

Unas 2650 unidades de gas por elemento, sin fin. El **gas limit** del bloque en anvil
(el máximo de gas que cabe en un bloque, semana 02) es 30000000: con unos 11000
elementos, `sum()` ya no cabría en ningún bloque. Si una función imprescindible recorre ese
array, el contrato queda bloqueado para siempre.

## 6. Antipatrones y riesgos

- **Array que cualquiera hace crecer y que el contrato recorre**: es un DoS (denegación de
  servicio). Un atacante llena el array y la función que lo recorre deja de funcionar. O
  limitas la longitud (`MAX_LENGTH`) o no lo recorres en una transacción.
- **`delete` para "quitar"**: deja un hueco con valor 0 que después se cuenta, se suma o se
  confunde con un elemento real.
- **Swap-and-pop cuando el orden importa**: si el array es una cola (primero en entrar,
  primero en salir), swap-and-pop la desordena.
- **Índices que llegan de fuera sin comprobar**: el `Panic(0x32)` protege, pero no dice
  nada útil. Comprueba antes y revierte con tu propio error.

## 7. Trucos

- Guarda `values.length` en una variable local antes del bucle: leer storage en cada vuelta
  cuesta más.
- Devolver un array entero (`getAll`) en una función `view` es cómodo para leer desde
  fuera; dentro de una transacción, cuesta como recorrerlo.
- Un array fijo no cambia de tamaño: útil para "los 3 mejores" o "los 7 días".

## ✅ Checklist

- [ ] Uso `push`, `pop`, `length` e índices en un array dinámico.
- [ ] Sé qué devuelve `delete values[i]` y en qué se diferencia de `pop`.
- [ ] Escribo swap-and-pop y explico por qué cambia el orden.
- [ ] Explico con números por qué recorrer un array sin límite es un riesgo de DoS.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — Structs y enums](02-structs-y-enums.md) | **Teoría 03 — Arrays** | [Teoría 04 — storage, memory y calldata →](04-storage-memory-y-calldata.md) |
