# 📖 Glosario — Semana 24

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Acción | Función de un handler o un harness que el fuzzer puede llamar; prepara lo necesario y llama al protocolo | `deposit(actorSeed, assets)` del `VaultHandler` |
| Aserción (*assertion test*) | Prueba de Medusa: falla si una llamada acaba en un `assert` fallido | `assert(vesting.released() == releasedBefore + amount)` |
| Corpus | Secuencias que Medusa guarda porque alcanzaron código nuevo, y que muta para ir más lejos | `corpus: 3` en la salida de Medusa |
| Cuentas del handler (*actors*) | Pocas direcciones fijas desde las que el handler llama al protocolo | `0xA11CE`, `0xB0B` y `0xCA401` |
| Encoger (*shrinking*) | Quitar llamadas a una secuencia que falla mientras siga fallando, hasta dejar las imprescindibles | `(original: 5, shrunk: 2)` |
| Fuzzing con estado (*stateful fuzzing*) | Fuzzing que genera secuencias de llamadas, cada una sobre el estado que dejó la anterior | `forge test` con funciones `invariant_` |
| Fuzzing guiado por cobertura (*coverage-guided*) | Fuzzing que prefiere las entradas que alcanzan código nuevo | Medusa y su cuenta de `branches` |
| Fuzzing sin estado (*stateless fuzzing*) | Fuzzing de una sola llamada, siempre desde el estado de `setUp` | Los tests con parámetros de la semana 09 |
| Handler | Contrato entre el fuzzer y el protocolo: elige cuentas, acota entradas, prepara precondiciones y cuenta lo que debería haber | `RegistryHandler` |
| Harness | Contrato que despliega el sistema en su constructor y lo ofrece al fuzzer; lo que Medusa necesita en vez de `setUp` | `VestingProperties` |
| Invariante | Afirmación sobre el estado que se cumple tras cualquier secuencia de llamadas | `activeCount <= capacity` |
| Mutante | El código con un fallo pequeño metido a propósito, para ver si la suite lo atrapa | `retire` sin `activeCount--` |
| Mutante equivalente | Un mutante que no cambia lo que hace el programa: ninguna suite lo puede matar | Cambiar `x > 0` por `x != 0` en un `uint` |
| Propiedad (*property test*) | Prueba de Medusa: una función `property_` que devuelve `true` si la invariante se cumple | `property_feesAccounted()` |
| Secuencia (*run*) | Una serie de llamadas desde `setUp`, hasta `depth` llamadas en forge | `runs: 256` |
| Tabla de llamadas | Cuántas veces llamó forge a cada función y cuántas revirtieron | `\| Vault \| deposit \| 63806 \| 63806 \|` |
| Variable fantasma (*ghost variable*) | Estado del handler que cuenta lo que el protocolo debería tener | `ghostFeesPaid` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 25 — Verificación formal →](../../week-25-verificacion_formal/README.md) |
