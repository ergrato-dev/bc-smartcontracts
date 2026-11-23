# 📖 Glosario — Semana 08

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| `abstract` | Contrato que no se puede desplegar solo: le falta alguna función o está pensado para heredarse | `abstract contract Gate { ... }` |
| ERC-165 | Estándar para que un contrato diga qué interfaces cumple con `supportsInterface(bytes4)` | `supportsInterface(0x01ffc9a7)` devuelve `true` |
| Fila de linealización (*linearization*) | Orden único en que Solidity coloca todos los contratos de una jerarquía; `super` es el siguiente de la fila | `Market > Limits > Fees > Base` |
| Herencia (*inheritance*) | Un contrato recibe lo que declara otro con `is`; al compilar se copia todo en el hijo | `contract Counter is Owned, Capped` |
| Hook (gancho) | Función `internal virtual` que la plantilla del padre llama y cada hijo rellena | `_canEnter(account)` |
| `@inheritdoc` | Etiqueta NatSpec que copia la documentación de la función de un padre o una interfaz | `/// @inheritdoc IRegistry` |
| `interfaceId` | `bytes4` con el XOR de los selectores de las funciones de una interfaz, sin las heredadas | `type(ICounter).interfaceId` |
| Interfaz (*interface*) | Contrato sin código, solo con firmas `external`, eventos, errores y tipos; sirve para llamar a otro contrato y para prometer funciones | `interface ICounter { function increment() external; }` |
| Librería (*library*) | Bloque de funciones reutilizables sin estado; las `internal` se copian en el contrato que las usa | `library Clamp { ... }` |
| `override` | Marca la función de un hijo que sustituye a la de un padre o cumple la de una interfaz | `function layers() public pure override(Fees, Limits)` |
| Patrón de plantilla (*template method*) | El padre fija los pasos de una función y deja un hueco que rellena cada hijo | `enter()` llama a `_canEnter` |
| Punto básico (*basis point*, bps) | Centésima de porcentaje: 10 000 bps son el 100 % | `amount * 2_500 / 10_000` es el 25 % |
| Refactor (*refactoring*) | Cambio en cómo está escrito el código que no cambia lo que hace | El registro partido en piezas con los mismos tests |
| `self` | Nombre, por convención, del primer parámetro de una función de librería pensada para `using for` | `function add(Data storage self, uint256 value)` |
| `super` | Llama a la versión de la función del siguiente contrato en la fila de linealización | `super.transferOwnership(newOwner);` |
| `using ... for` | Adjunta las funciones de una librería a un tipo; el valor pasa como primer parámetro | `using Clamp for uint256;` y `score.clamp(0, 100)` |
| `virtual` | Permite que un hijo sustituya una función o un modificador | `function transferOwnership(address) public virtual` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 09 — Testing con Foundry →](../../week-09-testing_con_foundry/README.md) |
