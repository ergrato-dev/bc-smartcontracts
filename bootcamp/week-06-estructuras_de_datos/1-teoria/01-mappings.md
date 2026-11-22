# Teoría 01 — Mappings

## 🎯 Objetivos

- Declarar mappings simples y anidados, y leerlos y escribirlos desde una función.
- Explicar por qué toda clave de un mapping devuelve un valor, aunque nadie la haya escrito.
- Leer un mapping público con `cast call`.
- Saber qué no se puede hacer con un mapping: recorrerlo, contarlo o copiarlo.

---

## 1. Qué problema resuelve

Hasta la semana 05 el registro guardaba números sueltos: `count`, `CAPACITY`,
`lastRegistrant`. Un protocolo real guarda un dato **por cuenta** o **por identificador**:
los puntos de cada usuario, el dueño de cada recurso. Con variables sueltas no se puede:
no sabes de antemano cuántas cuentas habrá.

Un **mapping** es una tabla de claves y valores guardada en el storage del contrato (el
almacenamiento permanente que viste en la semana 04). Para cada clave hay un valor, y se
accede a él en una sola operación, sin recorrer nada. Es la estructura de datos más usada
en Solidity: los saldos de un token, los permisos de cada cuenta y los recursos por id son
mappings.

## 2. Cómo se escribe

Crea `src/Balances.sol` en un proyecto Foundry (el de la semana 03 sirve):

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Balances {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => bool)) public isApproved;

    function set(uint256 amount) external {
        balanceOf[msg.sender] = amount;
    }

    function approve(address spender) external {
        isApproved[msg.sender][spender] = true;
    }

    function reset() external {
        delete balanceOf[msg.sender];
    }
}
```

- `mapping(TipoClave => TipoValor) nombre;` declara el mapping. Aquí, a cada dirección le
  corresponde un `uint256`.
- `balanceOf[clave]` lee o escribe el valor de esa clave, como un array con índice.
- Un **mapping anidado** (`mapping(address => mapping(address => bool))`) es un mapping
  cuyo valor es otro mapping: `isApproved[dueño][otro]` responde "¿el dueño aprobó a
  `otro`?". Se lee con dos claves.
- `delete balanceOf[clave]` devuelve esa entrada a su valor por defecto (aquí, 0).

Las claves pueden ser tipos elementales (`address`, `uint256`, `bytes32`, `bool`, `string`,
`bytes`...), enums o contratos. Un struct no puede ser clave:

```
Error (7804): Only elementary types, user defined value types, contract types or enums are allowed as mapping keys.
```

## 3. Cómo funciona: toda clave existe

Un mapping no guarda una lista de claves. Para leer `balanceOf[x]`, la EVM calcula una
posición de storage a partir de `x` (con keccak256, el hash de la semana 01) y lee lo que
hay ahí. Si nadie escribió nunca en esa posición, lo que hay es el **valor por defecto** del
tipo: `0` para números, `false` para `bool`, `address(0)` para direcciones.

Compruébalo. Con `anvil --silent &` en marcha dentro del contenedor y la cuenta 0 de anvil:

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 0)
forge create src/Balances.sol:Balances --private-key "$PK" --broadcast
```

```
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
```

Lee el saldo de la cuenta 1, que nunca llamó al contrato:

```bash
C=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast call $C "balanceOf(address)(uint256)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

```
0
```

No revierte: devuelve `0`. Ahora la cuenta 0 guarda 250 y se lee:

```bash
cast send $C "set(uint256)" 250 --private-key "$PK"
cast call $C "balanceOf(address)(uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

```
250
```

El getter de un mapping público recibe la clave como parámetro. En uno anidado, recibe las
dos claves en orden:

```bash
cast send $C "approve(address)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 --private-key "$PK"
cast call $C "isApproved(address,address)(bool)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
cast call $C "isApproved(address,address)(bool)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

```
true
false
```

La 0 aprobó a la 1; la 1 no aprobó a nadie. El orden de las claves importa.

Tras `cast send $C "reset()" --private-key "$PK"`, el saldo de la cuenta 0 vuelve a leer
`0`: `delete` no "borra la clave", deja el valor por defecto, que es lo mismo que nunca
haberla escrito.

## 4. Lo que un mapping no puede hacer

- **No tiene longitud** ni lista de claves. `balanceOf.length` no compila:

  ```
  Error (9582): Member "length" not found or not visible after argument-dependent lookup in mapping(address => uint256).
  ```

  Si necesitas contar o recorrer, guardas aparte un contador o un array de claves
  (teoría 05).

- **Solo vive en storage.** No puedes copiarlo a una variable local:

  ```solidity
  mapping(address => uint256) memory m = balanceOf; // ❌
  ```

  ```
  Error (4061): Type mapping(address => uint256) is only valid in storage because it contains a (nested) mapping.
  ```

  `memory` es la memoria temporal de una llamada; la teoría 04 la explica.

- **No distingue "vale 0" de "nunca se escribió".** Si necesitas saber si una cuenta se dio
  de alta, guárdalo explícitamente con otro mapping a `bool` o con un campo de estado.

## 5. Antipatrones y riesgos

- **Confundir "no existe" con "vale 0"**: un contrato que da un premio "si nunca te
  registraste" comprobando `points[msg.sender] == 0` se lo da también a quien se registró y
  gastó todos sus puntos. Usa un indicador explícito.
- **Creer que un mapping `private` es secreto**: `private` solo impide que **otros
  contratos** lo lean. Cualquiera lee el storage de un contrato con `cast storage`. Nada
  sensible en un mapping (ni en ningún otro sitio de la cadena).
- **Mapping anidado con las claves al revés**: `isApproved[spender][owner]` en lugar de
  `isApproved[owner][spender]` compila y da permisos a quien no los pidió. Nombra las
  claves en un comentario y pruébalo con dos cuentas distintas.

## 6. Trucos

- Un mapping `public` crea su getter solo; no escribas una función `getBalance(address)`
  que haga lo mismo.
- `delete m[k]` devuelve gas al liberar storage: es más barato que escribir un valor
  distinto de cero.
- Nombra el mapping por lo que responde: `balanceOf[cuenta]`, `isMember[cuenta]`,
  `ownerOf[id]`.

## ✅ Checklist

- [ ] Declaro un mapping simple y uno anidado, y los leo con `cast call`.
- [ ] Explico por qué leer una clave nunca escrita devuelve 0 y no revierte.
- [ ] Sé por qué un mapping no tiene `length` ni puede ir en `memory`.
- [ ] Distingo "vale 0" de "nunca se dio de alta" con un mapping a `bool`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 06](../README.md) | **Teoría 01 — Mappings** | [Teoría 02 — Structs y enums →](02-structs-y-enums.md) |
