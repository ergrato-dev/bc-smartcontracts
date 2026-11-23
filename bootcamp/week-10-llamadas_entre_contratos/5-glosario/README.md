# 📖 Glosario — Semana 10

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| `abi.encodeCall` | Construye los bytes de una llamada (selector y argumentos) comprobando en compilación que los argumentos encajan con la función | `abi.encodeCall(Bank.withdraw, (amount))` |
| `abi.encodePacked` | Codifica cada valor con su tamaño mínimo, sin offsets ni longitudes. Con dos tipos dinámicos seguidos, dos entradas distintas pueden dar los mismos bytes | `abi.encodePacked("ab", "c")` |
| Cabeza y cola (*head* y *tail*) | Las dos partes de una codificación ABI: en la cabeza, un hueco de 32 bytes por argumento; en la cola, el contenido de los tipos dinámicos | `0x40` en la cabeza, `4` y `686f6c61` en la cola |
| Código de creación (*init code*) | El bytecode del constructor seguido de sus argumentos codificados. Su hash entra en la dirección de `CREATE2` | `bytes.concat(type(Vault).creationCode, abi.encode(owner))` |
| `CREATE2` | Instrucción que crea un contrato en una dirección que depende de quien despliega, un salt y el hash del código de creación | `new Vault{salt: s}(owner)` |
| `delegatecall` | Llamada que ejecuta el código del destino con el storage, el `msg.sender` y el `msg.value` de quien llama | `LOGIC.delegatecall(data)` |
| Fábrica (*factory*) | Contrato que despliega otros contratos | `VaultFactory.create2(salt)` |
| Hook (gancho) | Contrato al que otro avisa cuando pasa algo, para que reaccione sin que el primero dependa de él | `onItemRegistered(id, registrant, label)` |
| Linter (*lint*) | Analizador que forge ejecuta después de compilar y que avisa de patrones arriesgados | `warning[calls-loop]: external call inside a loop` |
| Llamada de bajo nivel (*low-level call*) | Llamada con `call`, `staticcall` o `delegatecall` que devuelve `(bool, bytes)` y no revierte por sí misma | `(bool ok, bytes memory data) = shop.call(data);` |
| `multicall` | Función que ejecuta varias llamadas al mismo contrato en una transacción, con `delegatecall` a sí mismo | `registry.multicall(calls)` |
| Offset (desplazamiento) | En la cabeza ABI, la posición donde empieza el contenido de un tipo dinámico, contada desde el inicio de los argumentos | `…0040` |
| Salt (sal) | Valor de 32 bytes que elige quien despliega con `CREATE2` y que entra en la dirección | `keccak256(abi.encode(msg.sender, salt))` |
| Slot | Posición numerada (0, 1, 2…) del storage de un contrato, asignada a cada variable por orden de declaración | `forge inspect Host storageLayout` |
| `staticcall` | Llamada de bajo nivel que no permite cambiar el estado: si el destino escribe, falla | `shop.staticcall(abi.encodeCall(Shop.priceOf, (1)))` |
| `try`/`catch` | Llamada externa que, si el destino revierte, ejecuta el `catch` en vez de revertir la función | `try hook.onItemRegistered(...) {} catch (bytes memory r) {}` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 11 — ERC-20 y OpenZeppelin →](../../week-11-erc20_y_openzeppelin/README.md) |
