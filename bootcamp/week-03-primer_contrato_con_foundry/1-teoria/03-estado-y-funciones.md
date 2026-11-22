# Teoría 03 — Estado y funciones

## 🎯 Objetivos

- Declarar una variable de estado y explicar dónde vive (el storage).
- Distinguir funciones que escriben, que leen (`view`) y que solo calculan (`pure`).
- Usar `msg.sender` para saber quién llama.
- Explicar por qué escribir en el storage cuesta gas y leerlo desde fuera no.

---

## 1. Qué problema resuelve

`Answer` (Teoría 01) siempre devuelve 42: no recuerda nada. Un registro, un contador o
un saldo necesitan **recordar** entre una transacción y la siguiente. En un programa
normal eso se guarda en una base de datos; en un contrato se guarda en la propia cadena.

## 2. Variables de estado y storage

Una **variable de estado** se declara dentro del contrato, fuera de las funciones:

```solidity
contract Counter {
    uint256 number;
    address lastCaller;
    // funciones...
}
```

Se guarda en el **storage** (almacenamiento) del contrato: la parte de su cuenta donde
viven sus datos (Teoría 02 de la semana 02: nonce, saldo, código y storage). Cada contrato
tiene el suyo. Dos despliegues del mismo `Counter` son dos cuentas con dos storages
independientes.

El storage es una tabla de **slots** (casillas) de 32 bytes, numerados desde 0. El
compilador asigna un slot a cada variable en el orden en que aparecen:

```bash
forge inspect Counter storageLayout
```

```
╭------------+---------+------+--------+-------+-------------------------╮
| Name       | Type    | Slot | Offset | Bytes | Contract                |
+========================================================================+
| number     | uint256 | 0    | 0      | 32    | src/Counter.sol:Counter |
|------------+---------+------+--------+-------+-------------------------|
| lastCaller | address | 1    | 0      | 20    | src/Counter.sol:Counter |
╰------------+---------+------+--------+-------+-------------------------╯
```

Un `address` (dirección, la de una cuenta) ocupa 20 bytes. Aquí tiene un slot para él solo
porque `number` llena el slot 0 entero.

**Todo slot empieza a cero**. Una variable que no asignaste vale `0` si es un número y
`address(0)` (la dirección `0x000...000`) si es una dirección. No existe "sin definir".

## 3. Tres clases de función

| Declaración | Puede | Se llama con | Gas para quien llama |
| ----------- | ----- | ------------ | -------------------- |
| `function set(uint256 newNumber) external` | Leer y escribir el storage | Transacción (`cast send`) | Sí |
| `function get() external view returns (uint256)` | Solo leer | Llamada (`cast call`) | No |
| `function add(uint256 a, uint256 b) external pure returns (uint256)` | Ni leer ni escribir | Llamada (`cast call`) | No |

```solidity
function get() external view returns (uint256) {
    return number;
}

function increment() external {
    number += 1;
}

function set(uint256 newNumber) external {
    number = newNumber;
}
```

`newNumber` es un **parámetro**: llega en la transacción, codificado detrás del selector.
`number += 1` es lo mismo que `number = number + 1`.

Una función sin `view` ni `pure` puede cambiar el estado. Llamarla con `cast call` la
ejecuta en una copia del nodo y descarta los cambios (Teoría 05): para que el cambio
quede, hace falta una transacción.

`view` y `pure` son promesas que el compilador comprueba:

```solidity
function inc() external view {
    number += 1; // ❌
}
```

```
Error (8961): Function cannot be declared as view because this expression (potentially) modifies the state.
```

```solidity
function get() external pure returns (uint256) {
    return number; // ❌
}
```

```
Error (2527): Function declared as pure, but this expression (potentially) reads from the environment or state and thus requires "view".
```

Y al revés, si no prometes nada pero la función solo lee, te avisa:

```
Warning (2018): Function state mutability can be restricted to view
```

## 4. `msg.sender`: quién llama

Dentro de una función, `msg.sender` es la dirección de quien la llamó: la EOA que firmó la
transacción, o el contrato que hizo la llamada. Es la base de todo control de acceso: "solo
el dueño puede...". La semana 07 presenta `msg` completo; por ahora basta con
`msg.sender`.

```solidity
function touch() external {
    lastCaller = msg.sender;
}

function getLastCaller() external view returns (address) {
    return lastCaller;
}
```

Si la cuenta 1 de anvil envía `touch()` (`PK1` es su clave privada de prueba y `COUNTER`
la dirección del contrato desplegado):

```bash
cast send "$COUNTER" "touch()" --private-key "$PK1"
cast call "$COUNTER" "getLastCaller()(address)"
```

```
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

Nadie puede poner otra dirección en `msg.sender`: sale de la firma de la transacción
(semana 02, Teoría 04).

## 5. Lo que cuesta escribir

Escribir en el storage es de lo más caro que hace la EVM: cada nodo de la red guarda ese
dato para siempre. El gas usado de tres transacciones seguidas a `Counter`, leído del
recibo en anvil:

| Transacción | `number` antes → después | `gasUsed` |
| ----------- | ------------------------ | --------- |
| `increment()` | 0 → 1 | 43539 |
| `increment()` | 1 → 2 | 26439 |
| `set(0)` | 2 → 0 | 21784 |

Pasar un slot de cero a no cero es lo más caro: ocupa espacio nuevo en el estado. Cambiar
un valor que ya existía cuesta menos. Devolver un slot a cero hasta recibe una
**devolución** (*refund*) de parte del gas, porque libera espacio. Los 21 000 de base de
toda transacción (semana 02) están incluidos en cada cifra.

Leer con `cast call` no cuesta nada a quien llama: lo ejecuta el nodo al que preguntas, y
no hay transacción.

## 6. Un nombre, una cosa

Una variable de estado y una función no pueden llamarse igual:

```solidity
uint256 total;

function total() external view returns (uint256) { // ❌
    return total;
}
```

```
Error (2333): Identifier already declared.
```

Por eso el proyecto guarda la cuenta en `count` y la devuelve con `total()`.

## 7. Antipatrones y riesgos

- **Cualquiera puede llamar**: una función `external` sin comprobaciones la ejecuta
  **cualquier cuenta**. El `set` de `Counter` deja a un desconocido poner el número que
  quiera. Esta semana es aceptable porque no hay nada valioso; desde la semana 05
  aprenderás a restringirlo con `require` y modificadores. Revisa siempre quién puede
  llamar a cada función que escribe.
- **Creer que el storage es privado**: `cast storage DIRECCIÓN SLOT` lee cualquier slot de
  cualquier contrato, tenga o no una función que lo devuelva. Comprueba que el
  `lastCaller` de arriba está en el slot 1:

  ```bash
  cast storage "$COUNTER" 1
  ```

  ```
  0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8
  ```

  Ningún dato del storage es secreto.
- **Escribir de más**: cada escritura se paga. Guardar lo que se puede calcular, o
  escribir un valor que no cambió, gasta gas de todos los que usen el contrato.

## 8. Trucos

- `forge inspect Contrato storageLayout` dice en qué slot está cada variable.
- Si el compilador avisa con el warning 2018, añade `view` o `pure`: la ABI le dice así a
  quien use el contrato que esa función no cambia nada.
- Las cuentas de prueba de anvil: `cast wallet address --private-key PK` da la dirección
  de una clave.

## ✅ Checklist

- [ ] Explico dónde se guarda una variable de estado y qué vale antes de asignarla.
- [ ] Elijo entre función que escribe, `view` y `pure`, y sé con qué se llama cada una.
- [ ] Uso `msg.sender` y explico por qué no se puede falsificar.
- [ ] Explico por qué un `increment()` de 0 a 1 cuesta más que de 1 a 2.
- [ ] Leo un slot del storage con `cast storage`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — Un proyecto Foundry](02-proyecto-foundry.md) | **Teoría 03 — Estado y funciones** | [Teoría 04 — Tests con forge →](04-tests-con-forge.md) |
