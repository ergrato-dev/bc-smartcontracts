# Teoría 04 — storage, memory y calldata

## 🎯 Objetivos

- Explicar qué guarda cada ubicación de datos y cuánto dura.
- Saber cuándo es obligatorio escribir `storage`, `memory` o `calldata`.
- Predecir si una asignación copia o crea una referencia.
- Elegir `calldata` para los parámetros que solo se leen.

---

## 1. Qué problema resuelve

Un `uint256` ocupa 32 bytes y se copia sin pensarlo. Un struct, un array o un `string`
pueden ocupar mucho más. Son **tipos de referencia**: el compilador necesita saber
**dónde** vive cada uno para decidir si una asignación copia los datos o solo apunta a
ellos. Esa decisión cambia el gas que pagas y, sobre todo, si tus cambios se guardan o se
pierden.

## 2. Las tres ubicaciones

| Ubicación | Qué es | Cuánto dura | Se puede modificar |
| --------- | ------ | ----------- | ------------------ |
| `storage` | El almacenamiento permanente del contrato (semana 04): las variables de estado | Para siempre | Sí, y es lo más caro |
| `memory` | Memoria temporal de la llamada, como la RAM de un programa | Hasta que termina la llamada | Sí |
| `calldata` | Los datos de entrada de la transacción: los argumentos codificados que envió quien llama | Hasta que termina la llamada | No: solo lectura |

![Las tres ubicaciones de datos. Storage guarda el struct de forma permanente. Una variable local storage apunta a ese mismo struct, así que modificarla cambia lo guardado. Una variable local memory es una copia temporal: modificarla no cambia lo guardado y se pierde al terminar la llamada. Calldata son los argumentos de la transacción, de solo lectura](../0-assets/02-storage-memory-y-calldata.svg)

Las variables de estado están siempre en storage; no se escribe. Lo que sí hay que escribir
es la ubicación de los **parámetros, valores de retorno y variables locales** de tipo
referencia. Si falta, no compila:

```solidity
function sum(uint256[] nums) external pure returns (uint256) { // ❌
```

```
Error (6651): Data location must be "memory" or "calldata" for parameter in external function, but none was given.
```

En una variable local:

```solidity
uint256[] nums = values; // ❌
```

```
Error (6651): Data location must be "storage", "memory" or "calldata" for variable, but none was given.
```

Y un parámetro de una función `external` no puede ser `storage`: los datos llegan de fuera,
no del storage de este contrato.

## 3. Copia o referencia

La regla, según de dónde a dónde asignas:

| Asignación | Resultado |
| ---------- | --------- |
| storage → variable local `storage` | **Referencia**: apunta a lo guardado |
| storage → variable local `memory` | **Copia** |
| `memory` → `memory` | **Referencia** a la misma memoria |
| `memory` o `calldata` → variable de estado | **Copia** al storage |

Mira el caso que más errores produce. Crea `src/Locations.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Locations {
    struct Package {
        address sender;
        uint256 weight;
    }

    mapping(uint256 => Package) public packages;

    constructor() {
        packages[1] = Package(msg.sender, 100);
    }

    // Copia: el cambio se pierde.
    function setWeightCopy(uint256 id, uint256 weight) external {
        Package memory p = packages[id];
        p.weight = weight;
    }

    // Referencia: el cambio se guarda.
    function setWeightRef(uint256 id, uint256 weight) external {
        Package storage p = packages[id];
        p.weight = weight;
    }
}
```

`forge build` compila, pero avisa:

```
Warning (2018): Function state mutability can be restricted to view
  --> src/Locations.sol:17:5:
```

El compilador ha visto que `setWeightCopy` no escribe nada en storage. Un test que llama a
cada una con `999` y lee `packages(1)` después lo confirma:

```
[FAIL: assertion failed: 100 != 999] test_Copy() (gas: 41517)
[PASS] test_Ref() (gas: 39068)
```

`setWeightCopy` no revierte: modifica una copia que desaparece al terminar la llamada. El
peso sigue en 100. Trata ese warning como un error: casi siempre significa una copia donde
querías una referencia.

Entre variables `memory` pasa lo contrario: comparten los datos.

```solidity
uint256[] memory a = new uint256[](1);
uint256[] memory b = a;
b[0] = 7;
// a[0] también vale 7
```

`new` seguido del tipo y de la longitud entre paréntesis crea un array en memory, como `a` arriba. Su tamaño queda fijo: un array
en memory no tiene `push`.

## 4. calldata para los parámetros

Un parámetro `calldata` se lee directamente de los datos de la transacción, sin copiarlo.
Un parámetro `memory` se copia primero a memoria. Dos funciones iguales que suman un array
de 100 elementos, una con cada ubicación, medidas en un test:

```
[PASS] test_SumCalldata() (gas: 64122)
[PASS] test_SumMemory() (gas: 86752)
```

La copia cuesta unas 22 000 unidades de gas más. A cambio, `calldata` es de solo lectura:

```solidity
function first(uint256[] calldata nums) external pure returns (uint256) {
    nums[0] = 1; // ❌
```

```
Error (6182): Calldata arrays are read-only.
```

Regla práctica: en una función `external`, `calldata` para todo parámetro que solo lees;
`memory` si necesitas modificarlo. Lo que devuelves va en `memory`.

Pasar un `calldata` a una variable de estado lo copia al storage, que es justo lo que
quieres al guardar un dato nuevo:

```solidity
function setPodium(uint256[3] calldata top) external {
    podium = top; // copia los 3 valores al storage
}
```

## 5. Antipatrones y riesgos

- **Modificar una copia `memory` creyendo que guardas**: no revierte, no falla, no hace
  nada. Solo lo delata el warning 2018 o un test que lee el valor después.
- **Referencia `storage` donde querías una copia**: si haces `Package storage p` para
  "trabajar con un borrador" y lo modificas, has cambiado el dato guardado.
- **`memory` en parámetros por costumbre**: compila y funciona, pero cada llamada paga la
  copia. En funciones `external`, `calldata`.
- **Devolver arrays enormes de storage**: copiarlos a memory cuesta gas por elemento. Desde
  fuera (`cast call`) no lo pagas tú, pero si otro contrato llama a esa función dentro de
  una transacción, sí.

## 6. Trucos

- Para leer varios campos de un struct guardado, una referencia `storage` evita copiar
  campos que no usas.
- Para modificar varios campos del mismo struct, `Item storage item = items[id];` y después
  `item.a = ...; item.b = ...;` se lee mejor que repetir `items[id]`.
- Si el compilador te pide `view` en una función que debería escribir, busca un `memory`.

## ✅ Checklist

- [ ] Explico qué guarda storage, memory y calldata, y cuánto dura cada uno.
- [ ] Sé cuándo es obligatorio escribir la ubicación.
- [ ] Predigo si una asignación copia o referencia, y explico por qué `setWeightCopy` no
      guarda.
- [ ] Uso `calldata` en los parámetros `external` que solo leo.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Arrays](03-arrays.md) | **Teoría 04 — storage, memory y calldata** | [Teoría 05 — Patrones de colecciones →](05-patrones-de-colecciones.md) |
