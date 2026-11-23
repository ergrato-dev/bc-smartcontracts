# Teoría 01 — Codificación ABI

## 🎯 Objetivos

- Leer, palabra por palabra, los bytes de una llamada a una función.
- Construir esos bytes en Solidity con `abi.encode`, `abi.encodeWithSignature`,
  `abi.encodeWithSelector` y `abi.encodeCall`, y saber cuál elegir.
- Decodificarlos con `abi.decode` y con `cast`.
- Reconocer los riesgos de `abi.encodePacked` y de las firmas escritas a mano.

---

## 1. Qué problema resuelve

Desde la semana 03 sabes que una transacción a un contrato lleva en `data` un **selector**
(los 4 primeros bytes del keccak256 de la firma) seguido de los argumentos. En la semana 08
llamaste a otro contrato a través de una interfaz: `counter.increment()`. Solidity
construyó esos bytes por ti.

Esta semana los construyes tú. Lo necesitas para:

- Llamar a una función que no conoces al compilar: un `multicall` recibe una lista de
  llamadas ya codificadas y las ejecuta (teoría 03).
- Leer lo que devuelve una llamada de bajo nivel, que llega como `bytes` (teoría 02).
- Entender un revert: el error personalizado `SoldOut(9)` viaja codificado igual que una
  llamada.
- Calcular un hash de varios valores (semana 14, firmas), o la dirección de un contrato
  (teoría 05).

Las reglas de codificación son la **ABI** (*Application Binary Interface*, semana 03). La
especificación está en
[docs.soliditylang.org/en/v0.8.38/abi-spec.html](https://docs.soliditylang.org/en/v0.8.38/abi-spec.html).

## 2. Cómo funciona: palabras de 32 bytes

La ABI escribe los argumentos en **palabras** de 32 bytes (64 caracteres hex), uno detrás
de otro. Hay dos clases de tipos:

- **Estáticos** (`uint256`, `address`, `bool`, `bytes32`...): ocupan una palabra y van en
  su sitio, rellenos con ceros a la izquierda.
- **Dinámicos** (`string`, `bytes`, arrays sin tamaño): su tamaño no se sabe de antemano.
  En su sitio va un **offset** (*desplazamiento*): a cuántos bytes del inicio de los
  argumentos empieza su contenido. Al final, en la **cola**, van su longitud y sus datos,
  rellenos con ceros a la derecha.

Con `cast` (en el contenedor, sin anvil) codificas la llamada `buy(7, "hola")`:

```bash
cast calldata "buy(uint256,string)" 7 hola
```

```
0xb7dc3b18000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000004686f6c6100000000000000000000000000000000000000000000000000000000
```

![Calldata de buy(7, "hola"): 4 bytes de selector b7dc3b18 y cuatro palabras de 32 bytes. Palabra 0x00: el 7. Palabra 0x20: el offset 0x40, que apunta a la palabra 0x40. Palabra 0x40: la longitud del string, 4. Palabra 0x60: los bytes de "hola", 686f6c61, rellenos con ceros a la derecha](../0-assets/01-calldata-abi.svg)

| Posición | Palabra | Qué es |
| -------- | ------- | ------ |
| — | `b7dc3b18` | Selector de `buy(uint256,string)` |
| `0x00` | `…0007` | El `uint256` 7, en su sitio |
| `0x20` | `…0040` | El `string`: su contenido empieza en el byte `0x40` |
| `0x40` | `…0004` | Longitud del `string`: 4 bytes |
| `0x60` | `686f6c61…` | "hola" en UTF-8, relleno a la derecha |

Los offsets se cuentan desde el final del selector. Para decodificar los mismos bytes:

```bash
cast calldata-decode "buy(uint256,string)" 0xb7dc3b18000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000004686f6c6100000000000000000000000000000000000000000000000000000000
```

```
7
"hola"
```

## 3. Cómo se escribe en Solidity

Crea `src/Encoding.sol` en un proyecto con la plantilla del bootcamp:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

interface IShop {
    function buy(uint256 id, string calldata note) external payable;
}

contract Encoding {
    function encoded() external pure returns (bytes memory) {
        return abi.encode(uint256(7), "hola");
    }

    function packed() external pure returns (bytes memory) {
        return abi.encodePacked(uint256(7), "hola");
    }

    function withSignature() external pure returns (bytes memory) {
        return abi.encodeWithSignature("buy(uint256,string)", 7, "hola");
    }

    function withSelector() external pure returns (bytes memory) {
        return abi.encodeWithSelector(IShop.buy.selector, 7, "hola");
    }

    function withCall() external pure returns (bytes memory) {
        return abi.encodeCall(IShop.buy, (7, "hola"));
    }

    function decoded(bytes memory data) external pure returns (uint256 id, string memory note) {
        (id, note) = abi.decode(data, (uint256, string));
    }
}
```

Con `anvil --silent &` en marcha, despliégalo desde la cuenta 0 y llama a cada función:

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 0)
forge create src/Encoding.sol:Encoding --private-key "$PK" --broadcast
E=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast call $E "packed()(bytes)"
```

```
0x0000000000000000000000000000000000000000000000000000000000000007686f6c61
```

Las cinco funciones, comparadas:

| Función | Qué devuelve con `(7, "hola")` |
| ------- | ------------------------------ |
| `abi.encode(a, b)` | Las cuatro palabras de la tabla de arriba, sin selector. Es lo que `cast abi-encode "f(uint256,string)" 7 hola` imprime |
| `abi.encodePacked(a, b)` | `…0007686f6c61`: cada valor con su tamaño mínimo, sin offsets ni longitudes. No se puede decodificar |
| `abi.encodeWithSignature("buy(uint256,string)", a, b)` | Selector más `abi.encode(a, b)`: la llamada completa |
| `abi.encodeWithSelector(IShop.buy.selector, a, b)` | Los mismos bytes |
| `abi.encodeCall(IShop.buy, (a, b))` | Los mismos bytes |

Las tres últimas dan exactamente lo mismo que `cast calldata`. La diferencia está en qué
comprueba el compilador. Con `encodeCall`, si los argumentos no encajan con la función, no
compila:

```solidity
return abi.encodeCall(IShop.buy, ("hola", 7)); // ❌
```

```
Error (5407): Cannot implicitly convert component at position 0 from "literal_string "hola"" to "uint256".
```

`encodeWithSelector` y `encodeWithSignature` aceptan cualquier argumento, y la segunda,
además, cualquier texto como firma. Usa `abi.encodeCall` siempre que tengas la interfaz.

`abi.decode(data, (uint256, string))` hace el camino inverso: tú le dices los tipos, en
orden. `cast call $E "decoded(bytes)(uint256,string)" $(cast call $E "encoded()(bytes)")`
imprime `7` y `"hola"`.

## 4. Antipatrones y riesgos

- **Una firma escrita a mano con un error.** `abi.encodeWithSignature("buy(uint,string)", …)`
  compila. Pero Solidity calcula el selector del texto tal cual, y `uint` no es `uint256`:

  ```bash
  cast keccak "buy(uint,string)"    # 0xd378caeb…
  cast keccak "buy(uint256,string)" # 0xb7dc3b18…
  ```

  El destino no tiene ninguna función `0xd378caeb` y la llamada falla (teoría 02). Un
  espacio de más (`"buy(uint256, string)"`) da otro selector distinto. Ojo: `cast sig`
  normaliza `uint` a `uint256` y no te avisa. `abi.encodeCall` no tiene este problema.
- **`abi.encodePacked` con dos dinámicos seguidos para un hash.** Sin longitudes, `("ab", "c")`
  y `("a", "bc")` producen los mismos bytes, y por tanto el mismo hash:

  ```solidity
  keccak256(abi.encodePacked("ab", "c")) == keccak256(abi.encodePacked("a", "bc")) // true
  ```

  Si ese hash identifica un permiso o una firma, dos entradas distintas valen lo mismo.
  Para hashear varios valores usa `abi.encode`. `encodePacked` solo es seguro cuando los
  tamaños son fijos (como en la teoría 05).
- **Decodificar con tipos equivocados.** `abi.decode` no sabe qué hay en los bytes: confía
  en los tipos que le das. Si no encajan (faltan bytes, un `bool` que no es 0 ni 1), la
  llamada revierte sin mensaje. Decodifica solo lo que sabes de dónde viene.

## 5. Trucos

- `cast calldata-decode` para una llamada, `cast abi-decode "f()(uint256,string)" 0x…` para
  un retorno (sin selector) y `cast decode-error 0x… --sig "SoldOut(uint256)"` para un
  error.
- `Contrato.funcion.selector` y `Contrato.Error.selector` te dan el `bytes4` sin calcular
  keccak a mano.
- Una palabra que empieza por muchos ceros es un número o una dirección. Una que termina en
  muchos ceros es el contenido de un `string` o un `bytes`.

## ✅ Checklist

- [ ] Leo un calldata con un `string`: selector, valor, offset, longitud y datos.
- [ ] Elijo `abi.encodeCall` cuando tengo la interfaz, y sé por qué.
- [ ] Decodifico una llamada, un retorno y un error con `cast`.
- [ ] Explico por qué `abi.encodePacked` con dos `string` no sirve para un hash.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Semana 10 — Llamadas entre contratos](../README.md) | **Teoría 01 — Codificación ABI** | [Teoría 02 — call y staticcall →](02-call-y-staticcall.md) |
