# Teoría 05 — Patrones de colecciones

## 🎯 Objetivos

- Combinar un mapping y un array para tener búsqueda directa **y** lista recorrible.
- Saber si algo existe sin confundirlo con el valor por defecto.
- Quitar de un conjunto con swap-and-pop manteniendo el índice al día.
- Leer listas largas por páginas.
- Reconocer qué deja `delete` sin borrar en un struct que contiene un mapping.

---

## 1. Qué problema resuelve

Cada estructura de las teorías anteriores resuelve una parte:

| Necesito | Mapping | Array |
| -------- | ------- | ----- |
| Leer el valor de una clave, coste fijo | ✅ | Solo si la clave es el índice |
| Saber cuántos hay | ❌ | ✅ |
| Recorrerlos | ❌ | ✅, con gas por elemento |
| Saber si algo está, coste fijo | Con un indicador explícito | ❌: hay que recorrer |

Un protocolo casi siempre necesita varias filas a la vez: "¿esta cuenta es miembro?" y
"dame la lista de miembros". La solución es usar **las dos** estructuras sobre los mismos
datos y mantenerlas sincronizadas.

## 2. Existencia: no fiarse del valor por defecto

Ya lo viste en las teorías 01 y 02: un mapping responde a cualquier clave. Tres formas de
saber si algo existe de verdad:

```solidity
// 1. Un indicador explícito.
mapping(address => bool) public isMember;

// 2. Un enum cuyo primer valor es "no existe".
enum Status { None, Active, Retired }
if (items[id].status == Status.None) revert ItemNotFound(id);

// 3. Un campo que nunca vale 0 en un registro real.
if (tasks[id].owner == address(0)) revert TaskNotFound(id);
```

La 2 es la más expresiva: además de "existe o no", dice en qué estado está. La 3 vale
solo si el campo nunca puede ser 0 en un dato válido.

## 3. Conjunto recorrible: mapping + array

Crea `src/MemberSet.sol`. El array guarda los miembros en orden; el mapping guarda dónde
está cada uno en el array:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract MemberSet {
    address[] private _members;
    // Posición + 1 de cada miembro en _members. 0 significa "no está".
    mapping(address => uint256) private _indexPlusOne;

    error AlreadyMember(address account);
    error NotMember(address account);

    function add(address account) external {
        if (_indexPlusOne[account] != 0) revert AlreadyMember(account);
        _members.push(account);
        _indexPlusOne[account] = _members.length;
    }

    function remove(address account) external {
        uint256 indexPlusOne = _indexPlusOne[account];
        if (indexPlusOne == 0) revert NotMember(account);
        uint256 index = indexPlusOne - 1;
        uint256 lastIndex = _members.length - 1;
        if (index != lastIndex) {
            address last = _members[lastIndex];
            _members[index] = last;
            _indexPlusOne[last] = indexPlusOne;
        }
        _members.pop();
        delete _indexPlusOne[account];
    }

    function contains(address account) external view returns (bool) {
        return _indexPlusOne[account] != 0;
    }

    function size() external view returns (uint256) {
        return _members.length;
    }
}
```

- **Por qué "posición + 1"**: la posición 0 es válida (el primer miembro), pero también es
  el valor por defecto. Sumando 1, el 0 queda libre para significar "no está".
- `contains` y `add` cuestan lo mismo con 3 miembros que con 3000: solo leen el mapping.
- `remove` es el swap-and-pop de la teoría 03, con un paso más: el elemento que se mueve
  (`last`) tiene que actualizar su posición en el mapping. Si se olvida, el mapping apunta a
  una posición que ya no es suya.

Con `a`, `b` y `c` añadidos, quitar `a` deja `[c, b]`: `c` ocupó la posición 0. Un test
que lo comprueba pasa:

```
[PASS] test_Remove() (gas: 136060)
```

## 4. Leer por páginas

Devolver el array entero se vuelve imposible cuando crece (teoría 03). La alternativa es
leerlo en trozos: desde `start`, como mucho `limit` elementos.

```solidity
function page(uint256 start, uint256 limit) external view returns (address[] memory result) {
    uint256 length = _members.length;
    if (start >= length) return result;
    uint256 end = start + limit > length ? length : start + limit;
    result = new address[](end - start);
    for (uint256 i = start; i < end; i++) {
        result[i - start] = _members[i];
    }
}
```

Quien lee desde fuera pide `page(0, 100)`, `page(100, 100)`... hasta recibir una página
vacía. Cada llamada tiene un coste acotado por `limit`. Si `start` pasa del final, devuelve
un array vacío: `result` sin asignar es un array de longitud 0.

## 5. `delete` y los mappings anidados

Un struct puede contener un mapping. Entonces solo puede vivir en storage, y `delete` lo
trata de forma especial:

```solidity
contract Groups {
    struct Group {
        uint256 size;
        mapping(address => bool) isMember;
    }

    mapping(uint256 => Group) private _groups;

    function join(uint256 id) external {
        _groups[id].isMember[msg.sender] = true;
        _groups[id].size++;
    }

    function remove(uint256 id) external {
        delete _groups[id];
    }

    function isMember(uint256 id, address account) external view returns (bool) {
        return _groups[id].isMember[account];
    }

    function size(uint256 id) external view returns (uint256) {
        return _groups[id].size;
    }
}
```

Compila sin warnings. Un test hace `join(1)`, `remove(1)` y espera que `size(1)` sea 0 y
que ya no sea miembro:

```
[FAIL: assertion failed: true != false] test_DeleteKeepsMapping() (gas: 420835)
```

`size` volvió a 0, pero `isMember` sigue en `true`. `delete` no puede borrar un mapping
porque no sabe qué claves tiene. Si después se crea otro grupo con el id 1, hereda los
miembros del anterior.

## 6. Antipatrones y riesgos

- **Dos estructuras desincronizadas**: añadir al array y olvidar el mapping (o al revés)
  deja datos contradictorios. Toda escritura toca las dos en la misma función, y un test
  comprueba ambas.
- **Reutilizar ids o claves tras `delete`** cuando el struct tiene mappings dentro: los
  datos viejos reaparecen. Usa ids nuevos (un contador que nunca baja) o marca el registro
  como retirado en lugar de borrarlo.
- **Listas que crecen sin límite y se devuelven enteras**: página siempre, y nunca las
  recorras dentro de una transacción.
- **Existencia por un campo que puede valer 0**: un `weight == 0` no dice que el envío no
  exista si un peso 0 es válido.

## 7. Trucos

- Si un registro puede dejar de usarse, un estado `Retired` suele ser mejor que `delete`:
  conserva el historial y evita reutilizar ids.
- El patrón "posición + 1" sirve para cualquier conjunto: direcciones, ids, hashes.
- La semana 11 usa OpenZeppelin, que trae este conjunto ya escrito y auditado
  (`EnumerableSet`). Escribirlo una vez a mano te deja entender qué hace.

## ✅ Checklist

- [ ] Compruebo la existencia con un indicador, un enum con `None` o un campo que nunca es 0.
- [ ] Escribo un conjunto con mapping + array y explico el "posición + 1".
- [ ] Actualizo el mapping del elemento que se mueve en swap-and-pop.
- [ ] Leo una lista por páginas.
- [ ] Explico por qué `delete` no borra un mapping dentro de un struct.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — storage, memory y calldata](04-storage-memory-y-calldata.md) | **Teoría 05 — Patrones de colecciones** | [Ejercicio 01 — Mappings →](../2-practicas/ejercicio-01-mappings/README.md) |
