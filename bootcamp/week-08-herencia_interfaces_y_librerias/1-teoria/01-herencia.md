# Teoría 01 — Herencia

## 🎯 Objetivos

- Explicar qué problema resuelve la herencia en un contrato.
- Heredar con `is` y saber qué pasa al contrato hijo y qué no.
- Pasar argumentos al constructor de un contrato padre.
- Explicar por qué un contrato con herencia se despliega como uno solo.

---

## 1. Qué problema resuelve

Desde la semana 05 escribes el mismo bloque en cada contrato: una variable con el dueño,
el error `NotOwner` y el modificador `onlyOwner`. En el registro de tu proyecto, además,
el `isOpen` con su `whenOpen` y su `setOpen`. Si mañana encuentras un fallo en ese bloque,
tienes que corregirlo en cada copia, y basta con olvidar una.

La **herencia** (*inheritance*) deja escribir ese bloque una vez, en su propio contrato, y
reutilizarlo en otros. Es la misma idea que en cualquier lenguaje con clases, con una
diferencia importante que verás en la sección 4: no hay "objetos padre" en la cadena.

## 2. Cómo se escribe

`contract Hijo is Padre` hace que `Hijo` reciba todo lo que `Padre` declara. Crea
`src/Counter.sol` en un proyecto Foundry (el del ejercicio 01 de la semana 03 te sirve):

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Owned {
    address public owner;
    uint256 private _secret = 42;

    error NotOwner(address caller);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        _;
    }

    function _isOwner(address account) internal view returns (bool) {
        return account == owner;
    }
}

contract Capped {
    uint256 public immutable CAP;

    error CapReached(uint256 cap);

    constructor(uint256 cap) {
        CAP = cap;
    }
}

contract Counter is Owned, Capped {
    uint256 public count;

    constructor(uint256 cap) Capped(cap) {}

    function increment() external onlyOwner {
        if (count == CAP) revert CapReached(CAP);
        count++;
    }

    function amIOwner() external view returns (bool) {
        return _isOwner(msg.sender);
    }
}
```

`Counter` hereda de dos contratos a la vez: `Owned` le da el dueño y `onlyOwner`, `Capped`
le da el tope. Dentro de `Counter` usas `owner`, `onlyOwner`, `_isOwner`, `CAP` y
`CapReached` como si los hubieras escrito ahí.

## 3. Qué se hereda

| Lo que declara el padre | ¿Lo ve el hijo? |
| ----------------------- | --------------- |
| Variables de estado `public` e `internal` | Sí |
| Variables de estado `private` | No (pero ocupan su sitio en el storage) |
| Funciones `public`, `internal` y `external` | Sí; las `external` solo desde fuera, como siempre |
| Funciones `private` | No |
| Modificadores, eventos, errores, structs y enums | Sí |
| Constructor | No se hereda: se **ejecuta** al desplegar el hijo |

Es la columna "contratos que heredan" de la tabla de visibilidad de la semana 04: ahí
`internal` y `private` se diferenciaban solo en esto. `internal` es "para mí y para quien
herede de mí".

Prueba a leer `_secret` desde `Counter`, por ejemplo con `return _secret == 42;` en
`amIOwner`. `forge build` responde:

```
Error (7576): Undeclared identifier.
```

Y no puedes redeclarar en el hijo algo que ya declara el padre. Añade
`address public owner;` en `Counter`:

```
Error (9097): Identifier already declared.
```

Solidity no deja que una variable del hijo tape a la del padre (en otros lenguajes se
llama *shadowing*): así nunca hay dos `owner` distintos con el mismo nombre.

## 4. Un solo contrato en la cadena

Con anvil recién arrancado (`anvil --silent &`), despliega solo `Counter` con un tope de 2:

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 0)
forge create src/Counter.sol:Counter --private-key "$PK" --broadcast --constructor-args 2
```

```
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
```

Una dirección, no tres. Al compilar, el compilador **copia** en `Counter` todo lo que
hereda: el bytecode desplegado lleva el código de `Owned`, el de `Capped` y el suyo. Ni
`Owned` ni `Capped` existen en la cadena. Pregúntale a `Counter` por lo heredado:

```bash
C=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast call $C "owner()(address)"
cast call $C "CAP()(uint256)"
cast send $C "increment()" --private-key "$PK"
cast call $C "count()(uint256)"
```

```
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
2
status               1 (success)
1
```

El constructor de `Owned` se ejecutó durante el despliegue de `Counter`: `owner` es la
cuenta 0. Con la cuenta 1, el modificador heredado hace su trabajo:

```bash
PK1=$(cast wallet private-key "test test test test test test test test test test test junk" 1)
cast send $C "increment()" --private-key "$PK1"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x245aecd3: 00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8, data: "0x245aecd300000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8": NotOwner(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
```

## 5. Constructores de los padres

Al desplegar `Counter`, se ejecutan los constructores de todos sus padres, de más general a
más específico (`Owned`, `Capped` y por último `Counter`). Si un padre pide argumentos,
el hijo se los da. Hay dos formas:

```solidity
// En la lista de herencia, si el valor es fijo:
contract Counter is Owned, Capped(10) { ... }

// En el constructor del hijo, si depende de sus propios argumentos:
constructor(uint256 cap) Capped(cap) {}
```

Una de las dos, nunca ambas: con `Capped(10)` en la lista y `Capped(cap)` en el
constructor, `Error (3364): Base constructor arguments given twice.`

`Owned` no pide nada, así que no aparece. Si quitas el constructor de `Counter`, nadie le
da a `Capped` su `cap`:

```
Error (3415): No arguments passed to the base constructor. Specify the arguments or mark "Counter" as abstract.
```

"Abstract" es la salida de la teoría 03: un contrato que no se puede desplegar solo.

## 6. Antipatrones y riesgos

- **Copiar y pegar en vez de heredar**: cada copia de `onlyOwner` es un sitio más donde
  se puede colar un fallo, y una corrección que hay que repetir.
- **`private` como secreto**: el hijo no ve `_secret`, pero cualquiera lo lee del storage.
  Las variables del padre van primero: `owner` en la posición 0 y `_secret` en la 1.
  `cast storage $C 1` devuelve
  `0x000000000000000000000000000000000000000000000000000000000000002a`, que es 42
  (semana 04).
- **Heredar sin leer**: lo que heredas entra en tu contrato con tus mismos permisos. Un
  padre con una función `public` que cambia el estado sin modificador es una función
  `public` tuya. Lee todo el padre antes de heredar de él, sobre todo si no lo escribiste
  tú (la semana 11 hereda de OpenZeppelin).
- **Cadenas largas**: cinco niveles de herencia esconden qué hace una función. Si para
  entender `increment` tienes que abrir cuatro archivos, aplana.

## 7. Trucos

- Prefijo `_` para lo `internal`: dice "esto es para el contrato y sus hijos".
- Un error heredado se nombra por el contrato que lo **declara**: en un test escribes
  `Owned.NotOwner.selector`, no `Counter.NotOwner.selector`. El segundo da
  `Error (9582): Member "NotOwner" not found or not visible after argument-dependent lookup`.
- Los tests del bootcamp ya heredan desde la semana 03: `contract CounterTest is Test`
  recibe de `Test` las funciones `assertEq` y `vm`.

## ✅ Checklist

- [ ] Escribo un contrato que hereda de dos con `is`.
- [ ] Digo qué ve el hijo de un padre y qué no.
- [ ] Paso argumentos al constructor de un padre de las dos formas.
- [ ] Explico por qué `Counter` tiene una sola dirección en la cadena.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 08 — Herencia, interfaces y librerías](../README.md) | **Teoría 01 — Herencia** | [Teoría 02 — `virtual`, `override` y `super` →](02-virtual-override-y-super.md) |
