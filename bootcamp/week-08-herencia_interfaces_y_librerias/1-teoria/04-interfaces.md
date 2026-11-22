# Teoría 04 — Interfaces

## 🎯 Objetivos

- Declarar una `interface` y conocer sus reglas.
- Llamar desde un contrato a otro contrato a través de su interfaz.
- Calcular el identificador de una interfaz (`interfaceId`).
- Declarar qué interfaces cumple un contrato con ERC-165 (`supportsInterface`).

---

## 1. Qué problema resuelve

Un contrato que quiere llamar a otro necesita saber qué funciones tiene, con qué
parámetros y qué devuelven. No necesita su código: el otro ya está desplegado, y quizá lo
escribió otra persona. Necesita solo la lista de firmas, como el ABI de la semana 03 pero
escrita en Solidity.

Eso es una **interfaz** (*interface*): un contrato sin código, solo con firmas. Sirve para
dos cosas:

- **Llamar a otro contrato** sabiendo solo su dirección y su interfaz.
- **Prometer**: un contrato que hereda de una interfaz se compromete a tener todas sus
  funciones. Cualquier contrato que la cumpla vale para quien llama.

## 2. Cómo se escribe

Crea `src/ICounter.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

interface ICounter {
    event Incremented(uint256 newCount);

    function count() external view returns (uint256);

    function increment() external;
}
```

Por convención el nombre empieza por `I`. Las reglas, con lo que responde `forge build`
si te las saltas:

| Regla | Si no |
| ----- | ----- |
| Sin variables de estado | `Error (8274): Variables cannot be declared in interfaces.` |
| Funciones sin cuerpo | `Error (4726): Functions in interfaces cannot have an implementation.` |
| Todas las funciones `external` | `Error (1560): Functions in interfaces must be declared external.` |
| Sin constructor ni modificadores | No tienen sentido sin código |

Sí puede declarar eventos, errores, structs y enums, y heredar de otras interfaces.
Sus funciones son `virtual` sin escribirlo.

## 3. Cumplir una interfaz

Crea `src/Booster.sol` con un contador que cumple `ICounter` y un contrato que lo usa:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {ICounter} from "./ICounter.sol";

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract SimpleCounter is ICounter, IERC165 {
    uint256 public count;

    function increment() external {
        count++;
        emit Incremented(count);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(ICounter).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}

contract Booster {
    function boost(ICounter counter, uint256 times) external returns (uint256) {
        for (uint256 i = 0; i < times; i++) {
            counter.increment();
        }
        return counter.count();
    }

    function counterId() external pure returns (bytes4) {
        return type(ICounter).interfaceId;
    }
}
```

`SimpleCounter is ICounter` promete `count()` e `increment()`. La variable
`uint256 public count` cumple `count()`: su getter tiene la misma firma. El evento
`Incremented` se hereda de la interfaz. Si borras `increment`:

```
Error (3656): Contract "SimpleCounter" should be marked as abstract.
```

Una promesa sin cumplir deja el contrato abstracto (teoría 03). Ni `virtual` ni
`override` hacen falta al cumplir una función de una interfaz.

## 4. Llamar a través de la interfaz

En `Booster`, el parámetro `ICounter counter` es una dirección con tipo: el ABI la
recibe como `address`, y en Solidity tiene las funciones de `ICounter`.
`counter.increment()` codifica la llamada, la envía y decodifica la respuesta, como hacía
`cast send` desde la terminal. La semana 10 enseña qué pasa por debajo.

Con anvil recién arrancado:

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 0)
forge create src/Booster.sol:SimpleCounter --private-key "$PK" --broadcast
forge create src/Booster.sol:Booster --private-key "$PK" --broadcast
C=0x5FbDB2315678afecb367f032d93F642f64180aa3
B=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
cast send $B "boost(address,uint256)" $C 3 --private-key "$PK"
cast call $C "count()(uint256)"
```

El recibo tiene `status 1 (success)` y tres logs con la dirección de `SimpleCounter`, no
la de `Booster`: el evento lo emite el contador. Y `count()` devuelve `3`.

`ICounter` no comprueba nada al llamar. Si pasas una cuenta sin código (la cuenta 1) o un
contrato sin `increment` (el propio `Booster`):

```bash
cast send $B "boost(address,uint256)" 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 1 --private-key "$PK"
cast send $B "boost(address,uint256)" $B 1 --private-key "$PK"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
```

Los dos revierten sin error con nombre: en el primero, Solidity comprueba que la dirección
tiene código antes de llamar; en el segundo, `Booster` no tiene esa función ni `fallback`.

## 5. El identificador de una interfaz y ERC-165

`type(ICounter).interfaceId` es un `bytes4`: el XOR de los selectores de todas sus
funciones (sin contar las que hereda de otras interfaces). Compruébalo:

```bash
cast call $B "counterId()(bytes4)"
cast sig "count()"
cast sig "increment()"
```

```
0xd6fbfa37
0x06661abd
0xd09de08a
```

`0x06661abd` XOR `0xd09de08a` es `0xd6fbfa37`. Si la interfaz cambia una sola firma, el
identificador cambia.

[ERC-165](https://eips.ethereum.org/EIPS/eip-165) es un estándar para preguntarle a un
contrato si cumple una interfaz antes de usarlo: el contrato tiene una función
`supportsInterface(bytes4)` que devuelve `true` para cada identificador que cumple. El
de la propia ERC-165 es `0x01ffc9a7` (`cast sig "supportsInterface(bytes4)"`).

```bash
cast call $C "supportsInterface(bytes4)(bool)" 0xd6fbfa37
cast call $C "supportsInterface(bytes4)(bool)" 0x01ffc9a7
cast call $C "supportsInterface(bytes4)(bool)" 0xffffffff
```

```
true
true
false
```

El estándar exige `false` para `0xffffffff`. Los NFT de la semana 12 usan ERC-165 para
que un mercado sepa qué tipo de token tiene delante.

## 6. Antipatrones y riesgos

- **La interfaz no garantiza el comportamiento**: `ICounter` dice que hay un
  `increment`, no qué hace. Un contrato malicioso cumple la interfaz y, en `increment`,
  hace lo que quiera, incluso volver a llamarte (reentrada, semana 07). Llamar a un
  contrato que no controlas es pasarle el control: CEI aplica igual que al enviar ETH.
- **`supportsInterface` tampoco**: cualquiera puede devolver `true` para todo. Te dice
  qué promete un contrato, no si es de fiar.
- **Llamadas en bucle**: `forge build` avisa `warning[calls-loop]: external call inside a
  loop` en `boost`. Si una de las llamadas revierte, revierte todo el bucle: el DoS de la
  semana 07 con llamadas en vez de envíos.
- **Interfaz desfasada**: si escribes a mano la interfaz de un contrato ajeno y una firma
  no coincide (un `uint256` donde era `uint128`), el selector es otro y la llamada falla
  al ejecutarse, no al compilar.

## 7. Trucos

- Un archivo por interfaz, `IContrato.sol`, que importan quien la cumple y quien llama.
- Declara en la interfaz los eventos y errores públicos del contrato: un frontend
  (semana 17) o un indexador (semana 19) solo necesita la interfaz.
- Un contrato solo se convierte a su interfaz si la hereda: `ICounter c = counter;`
  compila con un `SimpleCounter`, no con otro contrato. Con una dirección, conviértela tú:
  `ICounter(direccion)`.

## ✅ Checklist

- [ ] Escribo una interfaz y un contrato que la cumple.
- [ ] Llamo a otro contrato a través de su interfaz.
- [ ] Calculo un `interfaceId` con `cast sig` y explico de dónde sale.
- [ ] Implemento `supportsInterface` y digo qué garantiza y qué no.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — Contratos abstractos](03-contratos-abstractos.md) | **Teoría 04 — Interfaces** | [Teoría 05 — Librerías →](05-librerias.md) |
