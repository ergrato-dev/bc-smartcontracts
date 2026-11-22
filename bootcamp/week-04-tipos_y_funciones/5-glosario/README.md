# 📖 Glosario — Semana 04

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| `bool` | Tipo de valor con `true` o `false`; lo producen las comparaciones | `return age >= 18;` |
| `bytesN` | Tipo de valor de exactamente N bytes (1 a 32) | `bytes4 selector`, `bytes32 hash` |
| Checksum (dirección) | Mezcla de mayúsculas y minúsculas de una dirección que detecta erratas; el compilador la exige en direcciones literales | `cast to-check-sum-address 0xf39f...` |
| `constant` | Variable con valor conocido al compilar; vive en el bytecode, no en el storage | `uint256 public constant MAX_LIMIT = 1000;` |
| Constructor | Función que se ejecuta una sola vez, al desplegar; no queda en el código desplegado | `constructor(uint256 capacity) { ... }` |
| `--constructor-args` | Opción de `forge create` que pasa los argumentos del constructor; va al final | `forge create ... --constructor-args 100` |
| Conversión explícita | Cambio de tipo escrito a mano; no comprueba nada y puede truncar | `uint8(300)` da `44` |
| Conversión implícita | Cambio de tipo que hace el compilador solo, cuando no se pierde información | de `uint8` a `uint256` |
| Desestructurar | Recoger en variables los varios valores que devuelve una función | `(uint256 t, address w) = ledger.summary();` |
| Empaquetado (*packing*) | Que varias variables pequeñas compartan un slot del storage | `uint128 a; uint128 b;` en el slot 0 |
| Getter | Función de lectura que el compilador genera para una variable `public` | `count()` |
| `immutable` | Variable que se fija en el constructor y vive en el bytecode; solo tipos de valor | `address public immutable OWNER;` |
| `int` (`int8`…`int256`) | Entero con signo | `type(int8).min` es `-128` |
| `internal` | Visibilidad: solo desde el propio contrato y los que heredan de él; es la de las variables de estado sin visibilidad | `function _fee(...) internal pure` |
| Mutabilidad | Lo que una función promete hacer con el estado: nada, leer (`view`) o ni leer (`pure`) | `function get() external view` |
| NatSpec | Formato de comentarios `///` de Solidity para documentar la interfaz | `/// @notice Registra un recurso.` |
| Offset | Byte del slot en el que empieza una variable empaquetada, contando desde la derecha | `b` en offset 16 |
| `private` | Visibilidad: solo desde el propio contrato; el dato sigue siendo legible en el storage | `uint256 private secret = 7;` |
| `public` | Visibilidad: desde fuera y desde dentro; en una variable genera su getter | `uint256 public count;` |
| Retorno con nombre | Valor de retorno con nombre que se devuelve solo al terminar la función | `returns (uint256 net, uint256 fee)` |
| `SCREAMING_SNAKE_CASE` | Convención de nombres para `constant` e `immutable` | `PROTOCOL_NAME` |
| Storage layout | Reparto de las variables de estado en slots y offsets que decide el compilador | `forge inspect Config storageLayout` |
| Tipo de valor | Tipo cuyo dato se copia entero al asignarlo; cabe en 32 bytes | `uint256`, `bool`, `address` |
| Tipo por referencia | Tipo que no se copia entero al asignarlo (`string`, arrays, `struct`); semana 06 | `string memory` |
| `type(T).max` / `.min` | Límites de un tipo entero | `type(uint8).max` es `255` |
| `uint` (`uint8`…`uint256`) | Entero sin signo; `uint` a secas es `uint256` | `uint256 public count;` |
| Variable de estado | Variable declarada fuera de las funciones; vive en el storage | `uint256 public limit;` |
| Variable local | Variable declarada dentro de una función; desaparece al terminar | `uint256 doubled = amount * 2;` |
| Visibilidad | Desde dónde se puede usar una función o variable: `external`, `public`, `internal`, `private` | `function add(...) public` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 05 — Control de flujo y errores →](../../week-05-control_y_errores/README.md) |
