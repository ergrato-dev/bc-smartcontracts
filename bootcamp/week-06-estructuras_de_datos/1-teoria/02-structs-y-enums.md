# Teoría 02 — Structs y enums

## 🎯 Objetivos

- Declarar un struct y crearlo de las tres formas que admite Solidity.
- Guardar structs en un mapping y leerlos con el getter público y con una función.
- Declarar un enum, convertirlo a número y saber qué pasa con un número fuera de rango.
- Elegir el primer valor de un enum pensando en el valor por defecto.

---

## 1. Qué problema resuelve

Un envío de una empresa de paquetería tiene remitente, peso y estado. Con mappings sueltos
serían tres: `senderOf[id]`, `weightOf[id]`, `statusOf[id]`. Funciona, pero cada función
que crea un envío tiene que acordarse de escribir los tres, y nada impide olvidar uno.

Un **struct** agrupa varios campos con nombre en un solo tipo, como una clase sin métodos.
Un **enum** es un tipo con una lista cerrada de valores con nombre: el estado de un envío
es `Created`, `Shipped` o `Delivered`, y nada más. Juntos describen un registro completo.

## 2. Cómo se escribe

Crea `src/Shipping.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Shipping {
    enum Status {
        Created,
        Shipped,
        Delivered
    }

    struct Package {
        address sender;
        uint256 weight;
        Status status;
    }

    mapping(uint256 => Package) public packages;
    uint256 public packageCount;

    function create(uint256 weight) external returns (uint256 id) {
        id = ++packageCount;
        packages[id] = Package({sender: msg.sender, weight: weight, status: Status.Created});
    }

    function ship(uint256 id) external {
        packages[id].status = Status.Shipped;
    }

    function getPackage(uint256 id) external view returns (Package memory) {
        return packages[id];
    }

    function fromCode(uint8 code) external pure returns (Status) {
        return Status(code);
    }

    function lastStatus() external pure returns (Status) {
        return type(Status).max;
    }
}
```

- `struct Nombre { tipo campo; ... }` declara el tipo. Nombre en `PascalCase`.
- `enum Nombre { A, B, C }` declara el enum. Sus valores se escriben `Status.Created`.
- `packages[id].status = ...` escribe un solo campo del struct guardado.
- `++packageCount` suma 1 y devuelve el valor nuevo: los ids empiezan en 1.
- `getPackage` devuelve el struct entero; `memory` indica que se devuelve una copia (la
  teoría 04 lo explica).

## 3. Tres formas de crear un struct

```solidity
// 1. Con nombres: el orden da igual y se lee qué es cada valor.
packages[id] = Package({sender: msg.sender, weight: weight, status: Status.Created});

// 2. Por posición: en el orden de la declaración.
packages[id] = Package(msg.sender, weight, Status.Created);

// 3. Campo a campo, sobre el struct guardado.
packages[id].sender = msg.sender;
packages[id].weight = weight;
```

Prefiere la forma con nombres. Por posición, cambiar el orden de dos campos del mismo tipo
compila sin avisar. Con tipos distintos, el compilador sí lo detecta:

```solidity
packages[1] = Package(weight, msg.sender, Status.Created); // ❌
```

```
Error (9553): Invalid type for argument in function call. Invalid implicit conversion from uint256 to address requested.
```

Y si falta un campo (`Package(msg.sender, weight)`):

```
Error (9755): Wrong argument count for struct constructor: 2 arguments given but expected 3.
```

En la forma 3, los campos que no escribas se quedan con su valor por defecto.

## 4. Leer structs desde fuera

Despliega en anvil, crea un envío de 1200 gramos y márcalo como enviado:

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 0)
forge create src/Shipping.sol:Shipping --private-key "$PK" --broadcast
C=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast send $C "create(uint256)" 1200 --private-key "$PK"
cast send $C "ship(uint256)" 1 --private-key "$PK"
```

El getter público de un mapping de structs devuelve **los campos sueltos**, no el struct.
Un enum viaja como `uint8`:

```bash
cast call $C "packages(uint256)(address,uint256,uint8)" 1
```

```
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
1200
1
```

`getPackage` devuelve el struct como una **tupla** (una lista de valores entre paréntesis);
en la firma de `cast`, la tupla se escribe con paréntesis dobles:

```bash
cast call $C "getPackage(uint256)((address,uint256,uint8))" 1
```

```
(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266, 1200, 1)
```

## 5. Enums por dentro

Un enum es un número: el primer valor es 0, el segundo 1, y así hasta un máximo de 256
valores. `uint8(Status.Shipped)` da `1`; `Status(2)` da `Delivered`; `type(Status).max` da
el último:

```bash
cast call $C "fromCode(uint8)(uint8)" 2
cast call $C "lastStatus()(uint8)"
```

```
2
2
```

Convertir un número que no corresponde a ningún valor revierte:

```bash
cast call $C "fromCode(uint8)(uint8)" 3
```

```
Error: execution reverted: panic: failed to convert value into enum type (0x21)
```

Es un `Panic` (semana 05) con un código nuevo, `0x21`: conversión inválida a un enum.

## 6. Antipatrones y riesgos

- **El primer valor del enum es el valor por defecto.** Lee un envío que no existe:

  ```bash
  cast call $C "packages(uint256)(address,uint256,uint8)" 2
  ```

  ```
  0x0000000000000000000000000000000000000000
  0
  0
  ```

  Estado `0` es `Created`: el envío 2, que nadie creó, parece recién creado. Si un contrato
  decide "solo se puede enviar lo que está en `Created`", cualquiera podría "enviar" ids
  inexistentes. Pon primero un valor que signifique "no existe" (`None`) y comprueba
  contra él.
- **Reordenar o insertar valores en un enum** cambia el número de los que van detrás. Lo
  ya guardado como `1` pasa a significar otra cosa. Añade valores solo al final.
- **Structs que crecen sin límite**: un campo `string` o un array dentro del struct deja
  que quien llama guarde datos de cualquier tamaño y pague por ello. Limita su longitud.

## 7. Trucos

- `type(Status).max` y `type(Status).min` evitan escribir números mágicos.
- En los tests, un enum se compara con `==` dentro de `assertTrue`:
  `assertTrue(status == Shipping.Status.Shipped);`.
- Si el struct tiene más de cuatro o cinco campos, crea con nombres siempre.

## ✅ Checklist

- [ ] Declaro un struct y un enum, y creo el struct con nombres.
- [ ] Leo un struct con el getter público y con una función que lo devuelve entero.
- [ ] Convierto un enum a `uint8` y explico el `Panic(0x21)`.
- [ ] Explico por qué el primer valor de un enum debería ser `None`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — Mappings](01-mappings.md) | **Teoría 02 — Structs y enums** | [Teoría 03 — Arrays →](03-arrays.md) |
