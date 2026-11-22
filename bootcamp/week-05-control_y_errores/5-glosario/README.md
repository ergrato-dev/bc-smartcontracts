# 📖 Glosario — Semana 05

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| `_` (en un modificador) | Marca dónde se ejecuta el cuerpo de la función; lo anterior va antes y lo posterior, después | `modifier onlyOwner() { ...; _; }` |
| Aritmética comprobada | Comprobación que añade el compilador a sumas, restas y multiplicaciones; si el resultado no cabe, revierte con `Panic(0x11)` | `uint8(255) + 1` revierte |
| `assert` | Comprueba un invariante; si falla, revierte con `Panic(0x01)` y señala un bug del contrato | `assert(count <= CAPACITY);` |
| `break` / `continue` | Salir del bucle / saltar a la siguiente vuelta | `if (i % 2 == 0) continue;` |
| Control de flujo | Instrucciones que eligen qué código se ejecuta y cuántas veces | `if`, `for`, `while` |
| Datos del revert | Bytes que devuelve una llamada que revierte: selector del error y sus argumentos | `data: "0x245aecd3..."` |
| DoS (denegación de servicio) | Ataque que impide que otros usen un contrato, por ejemplo con un bucle que agota el gas | Bucle sin límite de vueltas |
| `Error(string)` | Formato de los reverts con mensaje de texto; selector `0x08c379a0` | `require(v <= 100, "value too large");` |
| Error personalizado | Tipo de error con nombre y parámetros declarado en el contrato; más barato que un mensaje | `error NotOwner(address caller);` |
| Guarda | Comprobación al principio de una función que revierte si no se cumple una regla | `if (!isOpen) revert RegistryClosed();` |
| Invariante | Propiedad del contrato que tiene que cumplirse siempre | `count <= CAPACITY` |
| Modificador | Bloque de código con nombre que se aplica a la firma de una función y se ejecuta alrededor de ella | `function setOpen(bool) external onlyOwner` |
| Operador ternario | Expresión que elige entre dos valores según una condición | `a >= b ? a : b` |
| `Panic(uint256)` | Formato de los errores que genera el compilador; selector `0x4e487b71` y un código | `0x01`, `0x11`, `0x12` |
| Poscondición | Comprobación que se hace después de ejecutar la función | `_; if (count > LIMIT) revert ...;` |
| `require` | Sigue si la condición es verdadera; si no, revierte con un mensaje o un error personalizado | `require(capacity > 0, InvalidCapacity());` |
| `revert` | Detiene la ejecución, deshace los cambios de la llamada y devuelve un error | `revert RegistryFull(CAPACITY);` |
| `status 0` | Recibo de una transacción que entró en el bloque y revirtió; pagó el gas | `cast send ... --gas-limit 100000` |
| `unchecked` | Bloque sin aritmética comprobada: los valores dan la vuelta en lugar de revertir | `unchecked { return a + b; }` |
| `vm.expectRevert` | Cheatcode que hace que un test pase solo si la siguiente llamada revierte con esos datos | `vm.expectRevert(Tank.AlreadyEmpty.selector);` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 06 — Estructuras de datos →](../../week-06-estructuras_de_datos/README.md) |
