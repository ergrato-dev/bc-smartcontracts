# 📖 Glosario — Semana 21

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Cerrojo de reentrancy (*reentrancy guard*) | Variable que una función marca al entrar y desmarca al salir; si al entrar ya está marcada, revierte | `nonReentrant` de `ReentrancyGuardTransient` |
| Conversión a un tipo más pequeño (*downcast*) | Pasar un entero a un tipo con menos bits; Solidity se queda con los bits bajos sin comprobar | `uint8(300)` da 44 |
| Exploit | Código o secuencia de transacciones que aprovecha una vulnerabilidad | El contrato `Thief` que vacía `EtherStore` |
| Hallazgo (*finding*) | Vulnerabilidad o defecto que una auditoría encuentra, con su severidad, su prueba y su corrección | H-01: return bomb del hook |
| Informe de auditoría (*audit report*) | Documento que dice qué código se revisó, con qué métodos, qué hallazgos hay y en qué estado queda cada uno | `week-21/audit/README.md` |
| Límite de gas del bloque (*block gas limit*) | Gas máximo que suman todas las transacciones de un bloque; una que necesite más no cabe en ninguno | `30000000` en anvil |
| Phishing | Engañar a alguien para que firme una transacción que hace algo distinto de lo que cree | Un "reclama tu premio" que vacía una cartera con `tx.origin` |
| Reentrancy de solo lectura (*read-only reentrancy*) | Otro protocolo lee un `view` tuyo mientras tu contrato está a mitad de una operación y recibe un valor falso | Un préstamo que calcula un precio con tu `totalAssets()` a medias |
| Reentrancy entre funciones (*cross-function reentrancy*) | El atacante vuelve a entrar por otra función que lee el estado que la primera aún no ha actualizado | `transfer` durante `withdraw` |
| Regla de 63/64 (EIP-150) | Una llamada recibe como mucho 63/64 del gas que queda; el 1/64 restante es para terminar la función que llama | Con 64 000 de gas, el contrato llamado recibe 63 000 como mucho |
| Return bomb | Un contrato llamado devuelve o revierte con datos enormes para que quien llama pague copiarlos y emitirlos | `revert Junk(new bytes(64_000))` |
| `SafeCast` | Librería de OpenZeppelin que convierte entre tipos enteros y revierte si el valor no cabe | `SafeCast.toUint64(x)` |
| Saldo forzado (*forced ether*) | ETH que llega a un contrato sin ejecutar su código, con `selfdestruct` o como recompensa de bloque | `Forcer` mete 3 ETH en `Game` |
| Severidad (*severity*) | Gravedad de un hallazgo según su impacto y lo fácil que es explotarlo | Crítica, alta, media, baja, informativa |
| Transient storage (EIP-1153) | Almacenamiento que funciona como el storage pero se borra al final de cada transacción; cada escritura cuesta 100 de gas | El cerrojo de `ReentrancyGuardTransient` |
| Vulnerabilidad (*vulnerability*) | Fallo del código que alguien puede usar para hacer lo que el contrato no debería permitir | Enviar ETH antes de restar el saldo |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | Semana 22 (próximamente) |
