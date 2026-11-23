# Teoría 02 — call y staticcall

## 🎯 Objetivos

- Llamar a otro contrato con `call` y `staticcall` y leer su resultado: `(bool, bytes)`.
- Distinguir un éxito, un error con nombre y un fallo sin datos.
- Saber cuánto gas recibe la llamada y cómo limitarlo.
- Evitar los tres fallos clásicos: no mirar el `bool`, llamar a una cuenta sin código y
  llamar a lo que te pidan.

---

## 1. Qué problema resuelve

Cuando llamas a través de una interfaz (`shop.buy(1)`, semana 08), Solidity hace tres
cosas por ti: comprueba que la dirección tiene código, codifica la llamada y, si el destino
revierte, **revierte también tu función** con el mismo error. Casi siempre es lo que
quieres.

A veces no:

- Quieres seguir aunque el destino falle: avisar a varios contratos y que uno roto no
  bloquee a los demás.
- No conoces la función al compilar: ejecutas bytes que te dan (un `multicall`, una
  cartera que ejecuta lo que firma su dueño).
- Envías ETH, como en la semana 07: `to.call{value: x}("")` es esto mismo, con los datos
  vacíos.

Para eso está la **llamada de bajo nivel** (*low-level call*): `address.call(datos)`.

## 2. Cómo funciona

`destino.call{value: v, gas: g}(datos)` envía `datos` al destino, con `v` wei y como mucho
`g` de gas (las dos opciones son opcionales). Devuelve dos cosas y **nunca revierte por sí
misma**:

| Valor | Qué es |
| ----- | ------ |
| `bool ok` | `true` si la llamada terminó sin revertir |
| `bytes data` | Lo que devolvió el destino: el retorno codificado si `ok`, el error codificado si no |

`destino.staticcall(datos)` es igual, sin `value`, y además **prohíbe cambiar el estado**:
si el destino escribe en storage, emite un evento o envía ETH, la llamada falla. Es la que
usa Solidity para llamar a funciones `view` (por eso las ves como `[staticcall]` en las
trazas desde la semana 03).

## 3. Cómo se escribe

Un contrato que vende, en `src/Shop.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Shop {
    uint256 public constant PRICE = 0.01 ether;
    uint256 public sold;
    uint256 public visits;

    error SoldOut(uint256 id);
    error WrongPrice(uint256 expected, uint256 sent);

    function buy(uint256 id) external payable returns (uint256) {
        if (id > 3) revert SoldOut(id);
        if (msg.value != PRICE) revert WrongPrice(PRICE, msg.value);
        sold++;
        return sold;
    }

    function visit() external {
        visits++;
    }

    function priceOf(uint256 id) external pure returns (uint256) {
        return PRICE * id;
    }
}
```

Y uno que le compra con llamadas de bajo nivel, en `src/Buyer.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Shop} from "./Shop.sol";

contract Buyer {
    error ReadFailed(bytes reason);

    function buy(address shop, uint256 id) external payable returns (bool ok, bytes memory data) {
        (ok, data) = shop.call{value: msg.value}(abi.encodeCall(Shop.buy, (id)));
    }

    function price(address shop, uint256 id) external view returns (uint256) {
        (bool ok, bytes memory data) = shop.staticcall(abi.encodeCall(Shop.priceOf, (id)));
        if (!ok) revert ReadFailed(data);
        return abi.decode(data, (uint256));
    }

    function visitStatic(address shop) external view returns (bool ok, bytes memory data) {
        (ok, data) = shop.staticcall{gas: 50_000}(abi.encodeCall(Shop.visit, ()));
    }
}
```

`buy` solo devuelve lo que pasó, para que lo veas. En un contrato de verdad decides qué
hacer con cada caso, como `price`, que revierte con su propio error si la lectura falla.

Un test que imprime cada caso, en `test/Buyer.t.sol` (fragmento):

```solidity
Shop shop = new Shop();
Buyer buyer = new Buyer();

function test_Buy() public {
    (bool ok, bytes memory data) = buyer.buy{value: 0.01 ether}(address(shop), 1);
    console.log(ok);
    console.logBytes(data);
    assertEq(abi.decode(data, (uint256)), 1);
}

function test_BuySoldOut() public {
    (bool ok, bytes memory data) = buyer.buy{value: 0.01 ether}(address(shop), 9);
    console.log(ok);
    console.logBytes(data);
    assertEq(bytes4(data), Shop.SoldOut.selector);
}
```

`test_BuyFromAnAccount` y `test_VisitStatic` siguen el mismo patrón, con
`makeAddr("nobody")` como tienda y con `buyer.visitStatic(address(shop))`.

```bash
forge test --match-path test/Buyer.t.sol -vv
```

| Llamada | `ok` | `data` |
| ------- | ---- | ------ |
| `buy` a la tienda, id 1, 0,01 ether | `true` | `0x…0001`: el `uint256` 1 que devolvió `buy` |
| `buy` a la tienda, id 9 | `false` | `0x7e1f5a77…0009`: el error `SoldOut(9)` codificado |
| `buy` a `makeAddr("nobody")`, una cuenta sin código | **`true`** | `0x` |
| `staticcall` a `visit()`, que escribe | `false` | `0x` |
| Un selector que la tienda no tiene (el `"buy(uint,string)"` de la teoría 01) | `false` | `0x` |

Tres cosas que leer de esa tabla:

- **El error viaja codificado.** `0x7e1f5a77` es `cast sig "SoldOut(uint256)"`.
  `bytes4(data)` te da el selector para compararlo con `Shop.SoldOut.selector`, y
  `cast decode-error 0x7e1f5a77…0009 --sig "SoldOut(uint256)"` imprime `9`.
- **`0x` sin `ok` no dice por qué.** El destino no tiene la función, se quedó sin gas o
  rompió una regla de la EVM, como escribir dentro de un `staticcall`.
- **Una cuenta sin código "acepta" cualquier llamada.** La EVM no ejecuta nada y responde
  éxito. Los 0,01 ether de `test_BuyFromAnAccount` se quedaron en `nobody`. La llamada por
  interfaz lo habría impedido; la de bajo nivel no.

## 4. Cuánto gas recibe

Una llamada recibe como mucho **63/64 del gas que le queda** a quien llama (regla de la
EIP-150): el 1/64 restante garantiza que quien llama puede terminar aunque el destino lo
gaste todo. Con `{gas: n}` pones un tope menor.

Un fallo como el de `visitStatic` (escribir en un `staticcall`) no revierte con datos:
**consume todo el gas que recibió**. `test_VisitStatic` mide el gas antes y después:

```
[PASS] test_VisitStatic() (gas: 69201)
Logs:
  false 62359
  0x
```

Se gastaron los 50 000 del tope más lo que cuesta preparar la llamada. Sin el tope, se
habrían ido 63/64 de todo el gas de la transacción. Cuando llamas a un contrato que no
controlas y quieres seguir aunque falle, ponle tope.

## 5. Interfaz o bajo nivel

| | `shop.buy(1)` por interfaz | `address(shop).call(…)` |
| - | -------------------------- | ----------------------- |
| Comprueba que hay código | Sí: si no, revierte | No: éxito con `0x` |
| Si el destino revierte | Tu función revierte con el mismo error | `ok = false` y sigues |
| Codifica y decodifica | Sí, con los tipos comprobados | Tú, con `abi.encodeCall` y `abi.decode` |
| Cuándo | Por defecto | Para enviar ETH, para seguir ante un fallo, para datos que no conoces al compilar |

La teoría 04 trae `try`/`catch`: la comodidad de la interfaz con la posibilidad de seguir.

## 6. Antipatrones y riesgos

- **Ignorar `ok`.** `shop.call(datos);` sin mirar el resultado compila con
  `Warning (9302): Return value of low-level calls not used.` Si falla, tu contrato sigue
  como si hubiera funcionado. Mira siempre `ok` y decide.
- **Llamar a una dirección sin código.** Como en la tabla: éxito y `0x`. Si esperas un
  retorno, `abi.decode` revierte; si no, el error pasa sin que nadie lo vea. Comprueba
  `destino.code.length > 0` antes, o llama por interfaz.
- **Llamar a lo que te pidan.** Una función que hace `target.call(data)` con `target` y
  `data` elegidos por cualquiera ejecuta cualquier cosa **en nombre de tu contrato**: si tu
  contrato tiene tokens o permisos, quien llama los usa. Limita el destino, la función o
  quién puede pedirlo.
- **Llamar antes de actualizar tu estado.** Cualquier llamada externa da el control al
  destino, que puede volver a llamarte (*reentrancy*). Sigue checks-effects-interactions
  (semana 07): la llamada, al final. La semana 21 lo ataca a fondo.
- **Copiar sin límite lo que devuelve.** `data` se copia entero a memoria, y un destino
  hostil puede devolver muchísimos bytes para que pagues ese gas. Si no lo necesitas, no
  lo uses; si el destino no es de confianza, el tope de gas también limita esto.

## 7. Trucos

- `(bool ok,) = …` ignora `data` cuando no lo necesitas, como al enviar ETH.
- `abi.decode(data, (uint256))` solo si `ok` y si el destino tiene código.
- Para leer, `staticcall`: además de documentar que solo lees, te protege si el destino
  intenta escribir.

## ✅ Checklist

- [ ] Hago una llamada de bajo nivel y decodifico su retorno.
- [ ] Reconozco un error codificado y comparo su selector.
- [ ] Explico por qué una llamada a una cuenta sin código devuelve `true`.
- [ ] Pongo tope de gas a una llamada a un contrato que no controlo, y sé por qué.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — Codificación ABI](01-codificacion-abi.md) | **Teoría 02 — call y staticcall** | [Teoría 03 — delegatecall →](03-delegatecall.md) |
