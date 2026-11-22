# Teoría 03 — Errores personalizados

## 🎯 Objetivos

- Declarar errores personalizados, con y sin parámetros, y revertir con ellos.
- Usar un error personalizado dentro de `require`.
- Calcular el selector de un error y decodificar sus datos con `cast`.
- Comprobar en un test que una llamada revierte con un error concreto.

---

## 1. Qué problema resuelve

Un mensaje como `"value too large"` dice qué falló, pero no con qué valores, y el texto
entero viaja dentro del bytecode del contrato. Un **error personalizado** (*custom error*)
es un tipo de error con nombre y parámetros que declaras tú, como una función sin cuerpo.
Al revertir con él, quien llama recibe su nombre y los valores exactos que causaron el
fallo.

## 2. Declarar y revertir

```solidity
contract E {
    error TooLarge(uint256 value, uint256 max);
    error Empty();

    uint256 public value;

    function setCustom(uint256 v) external {
        if (v > 100) revert TooLarge(v, 100);
        value = v;
    }

    function empty() external pure {
        revert Empty();
    }
}
```

- `error Nombre(tipos);` declara el error dentro del contrato. Por convención, el nombre va
  en `PascalCase` y describe la situación (`TooLarge`, `NotOwner`, `RegistryFull`).
- `revert Nombre(valores);` revierte con él. Fíjate en que no lleva paréntesis alrededor
  como `revert("...")`: es `revert` seguido del error.

En un test, el error aparece con sus valores:

```
[FAIL: TooLarge(101, 100)] test_custom() (gas: 27603)
```

## 3. Errores personalizados en `require`

Con el compilador del bootcamp (0.8.38), `require` acepta un error personalizado en lugar del texto:

```solidity
function setReqCustom(uint256 v) external {
    require(v <= 100, TooLarge(v, 100));
    value = v;
}
```

```
[FAIL: TooLarge(101, 100)] test_reqcustom() (gas: 27653)
```

Mismo error, misma guarda. Elige la forma que se lea mejor: `require` para "exijo que…",
`if` + `revert` cuando la condición natural es la del fallo.

## 4. Selector y datos

Un error se codifica igual que una llamada a función (semana 03): los 4 primeros bytes del
keccak256 de su firma y después los argumentos, de 32 bytes cada uno.

```bash
cast sig "NotOwner(address)"
```

```
0x245aecd3
```

Esta función revierte si quien llama no es el dueño:

```solidity
function setOwner(uint256 v) external {
    if (msg.sender != OWNER) revert NotOwner(msg.sender);
    value = v;
}
```

Llamada desde la cuenta 1 de anvil:

```bash
cast call "$CONTRACT" "setOwner(uint256)" 1 --from 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

```
Error: execution reverted: NotOwner(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)

Context:
- server returned an error response: error code 3: execution reverted: custom error 0x245aecd3: 00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8, data: "0x245aecd300000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8"
```

`cast` reconoce el error cuando conoce su firma, como aquí. Lo que el nodo devuelve de
verdad es `data`: el selector `0x245aecd3` y la dirección rellenada a 32 bytes. Si solo
tienes los datos, `cast decode-error` los traduce con la firma:

```bash
cast decode-error --sig "NotOwner(address)" 0x245aecd300000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8
```

```
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

## 5. Por qué son más baratos

Dos contratos iguales salvo por la guarda: uno con
`require(v <= 100, "value must be at most one hundred")` y otro con
`if (v > 100) revert TooLarge(v)`. `forge build --sizes` muestra el tamaño del código
desplegado (*runtime size*), en bytes:

```
| Contract   | Runtime Size (B) | Initcode Size (B) | Runtime Margin (B) | Initcode Margin (B) |
| WithError  | 390              | 418               | 24,186             | 48,734              |
| WithString | 546              | 574               | 24,030             | 48,578              |
```

El mensaje de texto ocupa 156 bytes más de código. Desplegar cuesta más cuanto más código
se guarda: el `gasUsed` del recibo de `forge create` es 170581 para `WithString` y 137207
para `WithError`. Cuando la llamada **no** revierte, las dos gastan lo mismo (`cast estimate` da 43744 en
ambas): la guarda solo pesa en el despliegue y en el camino del error.

## 6. En los tests: `vm.expectRevert`

`vm.expectRevert(datos)` se escribe justo antes de una llamada y hace que el test pase solo
si esa llamada revierte con esos datos exactos:

```solidity
// Error sin parámetros: basta el selector.
vm.expectRevert(E.Empty.selector);
e.empty();

// Error con parámetros: selector y argumentos.
vm.expectRevert(abi.encodeWithSelector(E.TooLarge.selector, 101, 100));
e.setCustom(101);

// Mensaje de texto.
vm.expectRevert(bytes("value too large"));
e.setReq(101);
```

- `E.Empty.selector` es el selector del error, calculado por el compilador.
- `abi.encodeWithSelector(selector, argumentos...)` construye los mismos bytes que el
  contrato devuelve al revertir: el selector seguido de cada argumento en 32 bytes. Es lo
  que ves en `data`. La semana 10 explica la codificación ABI en detalle.

## 7. Riesgos

- **Errores ambiguos**: un único `error Invalid()` para cinco reglas distintas obliga a
  adivinar cuál falló. Un error por situación.
- **Datos sensibles en el error**: los argumentos se ven en los datos del revert, igual
  que el storage. Nada de secretos (que tampoco deberían estar en el contrato).
- **Tests que solo esperan "un revert"**: `vm.expectRevert()` sin datos pasa con cualquier
  error, también con uno que no es el que querías comprobar. Pasa siempre los datos.

## 8. Trucos

- Incluye en el error los valores que necesita quien llama para entender el fallo:
  `RegistryFull(capacity)` dice cuál era el límite.
- `cast sig "Error(string)"` y `cast sig "TuError(...)"` te dejan reconocer un revert por
  sus 4 primeros bytes.

## ✅ Checklist

- [ ] Declaro un error con parámetros y revierto con él, con `if` y con `require`.
- [ ] Calculo su selector con `cast sig` y decodifico sus datos con `cast decode-error`.
- [ ] Explico por qué un error personalizado ocupa menos bytecode que un mensaje.
- [ ] Escribo `vm.expectRevert` para un error sin parámetros, con parámetros y con texto.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — require y revert](02-require-y-revert.md) | **Teoría 03 — Errores personalizados** | [Teoría 04 — assert, panic y unchecked →](04-assert-panic-y-unchecked.md) |
