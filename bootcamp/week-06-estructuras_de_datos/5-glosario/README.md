# 📖 Glosario — Semana 06

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Array dinámico (*dynamic array*) | Lista de valores del mismo tipo que crece con `push` y se reduce con `pop` | `uint256[] public values;` |
| Array fijo (*fixed-size array*) | Lista con un número de elementos fijado en la declaración; no tiene `push` ni `pop` | `uint256[3] public podium;` |
| `calldata` | Ubicación de los argumentos de la transacción: solo lectura y sin copia | `function f(string calldata label)` |
| Copia | Asignación que duplica los datos: cambiar una no cambia la otra | `Item memory item = items[id];` |
| `delete` | Devuelve una variable o entrada a su valor por defecto; no borra mappings anidados | `delete points[msg.sender];` |
| Enum | Tipo con una lista cerrada de valores con nombre; por dentro, un `uint8` desde 0 | `enum Status { None, Active, Retired }` |
| Getter | Función de lectura que el compilador crea para una variable `public`; en un mapping recibe la clave | `points(address)` |
| Índice (*index*) | Posición de un elemento en un array, desde 0 | `values[0]` |
| Mapping | Tabla de claves y valores en storage; toda clave devuelve un valor | `mapping(address => uint256) public points;` |
| Mapping anidado (*nested mapping*) | Mapping cuyo valor es otro mapping; se lee con varias claves | `isFriend[a][b]` |
| `memory` | Memoria temporal de una llamada: modificable, desaparece al terminar | `string memory text = "hola";` |
| Paginación (*pagination*) | Leer una lista larga en trozos de tamaño acotado | `page(100, 100)` |
| `Panic(0x21)` | Error al convertir a un enum un número que no corresponde a ningún valor | `Status(3)` con tres valores |
| `Panic(0x31)` | Error al hacer `pop` de un array vacío | `values.pop()` |
| `Panic(0x32)` | Error al leer o escribir fuera de rango en un array | `values[5]` con 3 elementos |
| Referencia (*reference*) | Variable que apunta a los mismos datos que otra: cambiar una cambia la otra | `Item storage item = items[id];` |
| `storage` (ubicación) | Ubicación de las variables de estado; en una variable local, una referencia a ellas | `Task storage task = tasks[id];` |
| Struct | Tipo que agrupa varios campos con nombre | `struct Item { uint256 id; address registrant; }` |
| Swap-and-pop | Quitar un elemento de un array copiando el último en su lugar y haciendo `pop`; cambia el orden | `values[i] = values[length - 1]; values.pop();` |
| Tipo de referencia (*reference type*) | Tipo cuyos datos pueden ser grandes y exigen ubicación: arrays, structs, `string`, `bytes`, mappings | `string calldata label` |
| Tupla (*tuple*) | Lista de valores entre paréntesis; así se ve un struct fuera del contrato | `(1, 0xf39F..., 1, "north")` |
| Ubicación de datos (*data location*) | Dónde vive un tipo de referencia: `storage`, `memory` o `calldata` | `Item memory` |
| Valor por defecto (*default value*) | Valor de lo que nunca se escribió: 0, `false`, `address(0)`, `""` o el primer valor del enum | `points[nadie] == 0` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | Semana 07 (próximamente) |
