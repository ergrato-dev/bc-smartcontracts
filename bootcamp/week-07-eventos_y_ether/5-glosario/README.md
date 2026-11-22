# 📖 Glosario — Semana 07

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| `address payable` | Dirección a la que el código puede enviar ETH; se obtiene con `payable(...)` | `payable(msg.sender)` |
| `block.timestamp` | Hora Unix, en segundos, del bloque en curso; la fija quien produce el bloque | `CLOSES_AT = block.timestamp + 7 days;` |
| `call` | Llamada de bajo nivel que envía ETH (y datos) con todo el gas que queda; devuelve si salió bien | `(bool ok,) = to.call{value: amount}("");` |
| Checks-effects-interactions (CEI) | Orden de una función: comprobaciones, cambios de estado y, al final, llamadas externas | Saldo a 0 antes de enviar |
| `emit` | Escribe un evento en los logs de la transacción | `emit Rang(msg.sender, rings);` |
| ETH forzado | ETH que llega a un contrato sin ejecutar su código (recompensa de bloque, `selfdestruct`) | Por eso solvencia con `>=` |
| Evento (*event*) | Aviso declarado en el contrato que queda en el recibo; lo leen quienes están fuera, no los contratos | `event Rang(address indexed by, uint256 total);` |
| `fallback` | Función especial que se ejecuta cuando los datos no son de ninguna función | `fallback() external { revert UnknownFunction(msg.sig); }` |
| `gwei` | 10^9 wei; la unidad habitual del precio del gas | `1 gwei` |
| `indexed` | Marca un parámetro de evento para que vaya a un topic y se pueda filtrar; como mucho tres | `address indexed by` |
| Log | Registro que deja un evento en el recibo: dirección, topics y data | `cast logs --address $C "Rang(address indexed,uint256)"` |
| `msg.sig` | Los 4 primeros bytes de los datos de la llamada: el selector | `0x12345678` |
| `msg.value` | Wei que llegan con la llamada | `if (msg.value != PRICE) revert ...` |
| `payable` | Permite que una función (o el constructor) reciba ETH | `function buy() external payable` |
| Pull / push | Pull: cada cuenta retira lo que se le debe. Push: el contrato envía a todos | `claim()` frente a `payAll()` |
| `receive` | Función especial que se ejecuta cuando llega ETH sin datos; siempre `payable` | `receive() external payable { tip(); }` |
| Reentrada (*reentrancy*) | Ataque en que quien recibe una llamada vuelve a entrar en el contrato antes de que termine | Cobrar dos veces en `withdrawAll` |
| Topic | Valor de 32 bytes de un log por el que se puede buscar; el topic 0 identifica el evento | `cast keccak "Rang(address,uint256)"` |
| `transfer` / `send` | Envíos de ETH con solo 2300 de gas; `transfer` revierte si falla, `send` devuelve `false` | `to.transfer(1 ether);` |
| `tx.origin` | Cuenta que firmó la transacción; no sirve para autorizar | `tx.origin != msg.sender` si llama un contrato |
| Wei | Unidad mínima de ETH: 1 ether = 10^18 wei | `1 wei` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 08 — Herencia, interfaces y librerías →](../../week-08-herencia_interfaces_y_librerias/README.md) |
