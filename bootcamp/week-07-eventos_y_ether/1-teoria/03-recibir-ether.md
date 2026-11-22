# Teoría 03 — Recibir ETH

## 🎯 Objetivos

- Marcar una función como `payable` y leer cuánto llega con `msg.value`.
- Enviar ETH a un contrato con `cast send --value` y ver su saldo con `cast balance`.
- Explicar cuándo se ejecuta `receive` y cuándo `fallback`.
- Reconocer qué ETH rechaza un contrato y qué riesgos tiene aceptarlo.

---

## 1. Qué problema resuelve

Un contrato es una cuenta de Ethereum (semana 02): tiene dirección y saldo, igual que una
cuenta de usuario. Puede guardar ETH y, en un protocolo, eso es lo normal: una tienda cobra,
un bote de propinas acumula, un registro cobra una tasa.

Pero por defecto **un contrato rechaza el ETH**. Si no dice explícitamente "aquí se puede
pagar", toda transacción que le envía valor revierte. Así nadie pierde dinero enviándolo a
una función que no sabe qué hacer con él.

## 2. `payable` y `msg.value`

Crea `src/Shop.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Shop {
    uint256 public constant PRICE = 0.01 ether;

    event Bought(address indexed buyer, uint256 paid);

    error WrongPayment(uint256 expected, uint256 sent);

    function buy() external payable {
        if (msg.value != PRICE) revert WrongPayment(PRICE, msg.value);
        emit Bought(msg.sender, msg.value);
    }

    function ping() external pure returns (uint256) {
        return 1;
    }
}
```

- `payable` en `buy` permite que la llamada traiga ETH. El ETH entra en el saldo del
  contrato **antes** de que se ejecute la primera línea de la función.
- `msg.value` es cuánto llegó, en wei. Si la función revierte, el ETH vuelve a quien lo
  envió, igual que se deshace todo lo demás.
- `ping` no es `payable`: no acepta ni un wei.

Con anvil recién arrancado, despliega y compra. `--value` acepta unidades:

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 0)
forge create src/Shop.sol:Shop --private-key "$PK" --broadcast
S=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast send $S "buy()" --value 0.01ether --private-key "$PK"
cast balance $S --ether
```

El recibo trae `status 1 (success)` y el contrato tiene saldo:

```
0.010000000000000000
```

Pagar de más revierte con tu error, con los dos importes en wei:

```bash
cast send $S "buy()" --value 0.02ether --private-key "$PK"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x0dd32d1c: ...: WrongPayment(10000000000000000 [1e16], 20000000000000000 [2e16])
```

Y enviar valor a la función que no es `payable` revierte sin ningún mensaje:

```bash
cast send $S "ping()" --value 1 --private-key "$PK"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
```

Lo comprueba el compilador antes de llegar a la red: si un test o un contrato llama a una
función no `payable` con `{value: ...}`, no compila:

```
Error (7006): Cannot set option "value" on a non-payable function type.
```

## 3. `receive` y `fallback`

No todo el ETH llega llamando a una función. Una transferencia "a pelo", sin datos (como
las que hiciste entre cuentas en la semana 02), no nombra ninguna función. Prueba con la
tienda:

```bash
cast send $S --value 1ether --private-key "$PK"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
```

Revierte: `Shop` no sabe recibir ETH sin datos. Para eso hay dos funciones especiales, sin
la palabra `function` y sin nombre que llamar:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Router {
    event ViaReceive(address indexed from, uint256 value);
    event ViaFallback(address indexed from, uint256 value, bytes data);

    receive() external payable {
        emit ViaReceive(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ViaFallback(msg.sender, msg.value, msg.data);
    }
}
```

- `receive() external payable` se ejecuta cuando llega una llamada **sin datos**. Siempre
  es `payable`: solo existe para recibir ETH.
- `fallback() external` se ejecuta cuando los datos **no corresponden a ninguna función**
  del contrato. Puede ser `payable` o no.

Despliega `Router` con `forge create src/Router.sol:Router --private-key "$PK" --broadcast`
y envía dos veces: sin datos y con unos datos inventados, `0x12345678`, que no son el
selector de ninguna función. Si seguiste los pasos desde anvil recién arrancado, la
dirección es la de abajo (la cuenta 0 ya hizo dos transacciones: el despliegue de `Shop` y
la compra; las que revirtieron al estimar el gas no llegaron a enviarse):

```bash
R=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
cast send $R --value 1ether --private-key "$PK" --json | jq -r '.logs[0].topics[0]'
cast send $R 0x12345678 --value 2ether --private-key "$PK" --json | jq -r '.logs[0].topics[0]'
```

```
0xac86c8bdf9c04dcb036db0b32d3960d88f5052f8329a34f12a528ef445df75d3
0x7e2d701cfb3c607d95db749fcb37abd1e972ac8aea294becab6d2d99439461e7
```

Compáralos con `cast keccak "ViaReceive(address,uint256)"` y
`cast keccak "ViaFallback(address,uint256,bytes)"`: el primero pasó por `receive`; el
segundo, por `fallback`. `cast balance $R --ether` da `3.000000000000000000`.

Cómo elige la EVM:

| Llega | ¿Hay `receive`? | Se ejecuta |
| ----- | --------------- | ---------- |
| Datos de una función que existe | — | Esa función (si trae ETH, tiene que ser `payable`) |
| Datos que no son de ninguna función | — | `fallback`; si no hay, revierte |
| Sin datos | Sí | `receive` |
| Sin datos | No | `fallback` si es `payable`; si no, revierte |

## 4. Antipatrones y riesgos

- **`payable` por si acaso**: cada función `payable` es una puerta para el dinero. Si no
  esperas ETH, no la pongas: sin ella, un pago por error revierte y el usuario lo recupera.
- **Aceptar ETH sin forma de sacarlo**: un contrato con `receive` o funciones `payable`
  pero sin ninguna función que envíe ETH deja el dinero bloqueado para siempre. `forge
  build` avisa con su revisión de estilo:

  ```
  warning[locked-ether]: contract can receive ETH but has no mechanism to send it out
  ```

  Es lo que les pasa a `Shop` y `Router`. En la teoría 04 aprendes a enviar.
- **`fallback` `payable` que acepta cualquier cosa**: quien llama a una función mal escrita
  (un nombre equivocado, un contrato equivocado) pierde su ETH en vez de recibir un error.
  Si no necesitas aceptar llamadas desconocidas, que `fallback` revierta o que no exista.
- **Lógica pesada en `receive`**: quien envía con `transfer` (teoría 04) solo le da 2300 de
  gas. Un `receive` que escribe en storage no cabe y el envío falla.

## 5. Trucos

- Comprueba el importe exacto (`msg.value != PRICE`) con un error que diga cuánto se
  esperaba y cuánto llegó.
- `msg.sig` dentro de `fallback` te dice qué selector intentaron llamar: útil para un error
  claro como `UnknownFunction(msg.sig)`.
- `receive() external payable { tip(); }` reutiliza la lógica de una función `public`.

## ✅ Checklist

- [ ] Marco como `payable` solo las funciones que deben cobrar y leo `msg.value`.
- [ ] Envío ETH con `cast send --value` y compruebo el saldo con `cast balance`.
- [ ] Sé cuándo corre `receive`, cuándo `fallback` y cuándo revierte.
- [ ] Explico el riesgo del ETH bloqueado y de un `fallback` que acepta cualquier cosa.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — Unidades y variables globales](02-unidades-y-variables-globales.md) | **Teoría 03 — Recibir ETH** | [Teoría 04 — Enviar ETH →](04-enviar-ether.md) |
