# Teoría 04 — try/catch

## 🎯 Objetivos

- Llamar a otro contrato con `try` y seguir si revierte.
- Distinguir en el `catch` un `require` con mensaje, un `panic` y un error personalizado.
- Saber qué fallos **no** atrapa `try`.
- Limitar el gas de una llamada a un contrato que no controlas.

---

## 1. Qué problema resuelve

Con una llamada por interfaz, si el destino revierte, revierte tu función. Con `call`
puedes seguir, pero codificas y decodificas a mano y una cuenta sin código parece un éxito
(teoría 02). `try`/`catch` junta lo mejor de las dos: escribes la llamada como por interfaz,
con los tipos comprobados, y si el destino revierte, decides tú qué hacer.

El caso típico es **avisar a otro contrato sin depender de él**: tu registro avisa a un
contrato de puntos cada vez que alguien registra. Si el de puntos falla, el registro tiene
que seguir funcionando. Es el proyecto de esta semana.

## 2. Cómo funciona

```solidity
try destino.funcion(args) returns (uint256 resultado) {
    // el destino terminó bien: aquí usas `resultado`
} catch Error(string memory message) {
    // revirtió con require(cond, "mensaje") o revert("mensaje")
} catch Panic(uint256 code) {
    // revirtió por un panic: assert, división por cero, overflow...
} catch (bytes memory data) {
    // cualquier otro revert: errores personalizados, o sin datos
}
```

- Solo se puede usar `try` con una **llamada externa** (o con `new`, teoría 05).
- Los `catch` son opcionales, pero si no pones `catch (bytes memory)` ni `catch {}`, un
  error que no encaje con los demás **revierte tu función**.
- Si el destino revierte, sus cambios se deshacen; los tuyos de antes del `try`, no.

Los errores `Error(string)` y `Panic(uint256)` son los que genera Solidity: `require` con
mensaje y los fallos de la semana 05. Un error personalizado llega como `bytes`, y lo
reconoces por su selector, como en la teoría 02.

## 3. Cómo se escribe

En `src/Quote.sol`, una tienda que falla de tres formas distintas y un cliente que lo
cuenta todo con eventos:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Store {
    error SoldOut(uint256 id);

    function quote(uint256 id) external pure returns (uint256) {
        require(id != 0, "id cero");
        if (id > 3) revert SoldOut(id);
        return 100 / (3 - id);
    }
}

contract Client {
    Store public immutable STORE;

    event Quoted(uint256 id, uint256 price);
    event FailedWithMessage(uint256 id, string message);
    event FailedWithPanic(uint256 id, uint256 code);
    event WasSoldOut(uint256 id);
    event FailedWithData(uint256 id, bytes data);

    constructor(Store store) {
        STORE = store;
    }

    function ask(uint256 id) external {
        try STORE.quote(id) returns (uint256 price) {
            emit Quoted(id, price);
        } catch Error(string memory message) {
            emit FailedWithMessage(id, message);
        } catch Panic(uint256 code) {
            emit FailedWithPanic(id, code);
        } catch (bytes memory data) {
            // forge-lint: disable-next-line(unsafe-typecast)
            if (bytes4(data) == Store.SoldOut.selector) {
                emit WasSoldOut(id);
            } else {
                emit FailedWithData(id, data);
            }
        }
    }
}
```

Un test que pregunta por los ids del 0 al 4, en `test/Quote.t.sol`:

```solidity
Client client = new Client(new Store());

function test_Ask() public {
    for (uint256 id = 0; id <= 4; id++) {
        client.ask(id);
    }
}
```

```bash
forge test --match-path test/Quote.t.sol -vvvv
```

La traza, filtrada a los reverts y los eventos:

```
    │   │   └─ ← [Revert] id cero
    │   ├─ emit FailedWithMessage(id: 0, message: "id cero")
    │   ├─ emit Quoted(id: 1, price: 50)
    │   ├─ emit Quoted(id: 2, price: 100)
    │   │   └─ ← [Revert] panic: division or modulo by zero (0x12)
    │   ├─ emit FailedWithPanic(id: 3, code: 18)
    │   │   └─ ← [Revert] SoldOut(4)
    │   ├─ emit WasSoldOut(id: 4)
```

Cinco llamadas, tres fallos, y `ask` nunca revirtió. El panic llega con su código (`18` es
`0x12`, división por cero). El error personalizado entra por `catch (bytes memory)`, y el
selector lo identifica.

`bytes4(data)` se queda con los 4 primeros bytes y descarta el resto. `forge build` avisa
con `warning[unsafe-typecast]: typecast can truncate values`, porque recortar suele ser un
error. Aquí es justo lo que quieres, y el comentario
`// forge-lint: disable-next-line(unsafe-typecast)` silencia ese aviso en la línea
siguiente. Los avisos del **linter** (*lint*: el analizador que forge ejecuta después de
compilar) cuentan como warnings: con `--deny warnings`, uno sin silenciar hace fallar el
build.

Con llamadas externas verás otros dos a menudo: `calls-loop` (una llamada dentro de un
bucle: si una revierte, revierte el bucle entero) y `reentrancy-events` (un evento emitido
después de una llamada externa). Son riesgos reales. Cuando los has resuelto o los asumes a
propósito, `// forge-lint: disable-next-item(calls-loop, reentrancy-events)` encima de la
función los silencia en toda ella. Silenciar sin entender el aviso es esconderlo.

## 4. Lo que `try` no atrapa

`try` solo atrapa un revert **dentro del destino**. Hay tres fallos que ocurren en tu
contrato y revierten tu función igual:

| Fallo | Por qué no se atrapa |
| ----- | -------------------- |
| El destino es una cuenta sin código | Tu contrato comprueba después de la llamada que había código, y revierte él: `call to non-contract address` en la traza |
| El destino devuelve algo que no encaja con `returns (uint256 price)` | Decodificar es trabajo de tu contrato, después de que el destino terminase bien |
| Un revert dentro de las llaves del `try` o del `catch` | Ya es tu código, no el del destino |

El segundo caso, con un destino que tiene `fallback() external {}` y por tanto no devuelve
nada:

```
    │   ├─ [40] Silent::fallback(1) [staticcall]
    │   │   └─ ← [Stop]
    │   └─ ← [Revert] EvmError: Revert
```

El destino terminó bien (`Stop`), pero no devolvió los 32 bytes de un `uint256` y `ask`
revirtió. Si avisas a un contrato cualquiera, comprueba antes que es el que esperas: que
tiene código y que declara la interfaz con ERC-165 (semana 08).

## 5. Antipatrones y riesgos

- **Sin tope de gas.** El destino recibe 63/64 del gas que queda (teoría 02). Uno hostil o
  roto (un bucle infinito) lo gasta todo, y tu función se queda con 1/64 para terminar: a
  menudo no basta y tu función revierte. Con `try STORE.quote{gas: 50_000}(id)` el
  peor caso está acotado.
- **Quien llama elige el gas.** Al revés también: quien envía la transacción puede dar justo
  el gas para que tu función termine pero el destino se quede sin él. El `catch` lo
  atrapa y sigues. Si el aviso es importante (un pago), no lo pongas en un `try`; si es
  accesorio (unos puntos), acéptalo y documéntalo.
- **`catch {}` vacío.** Tragarse el error sin dejar rastro hace imposible saber qué pasó.
  Emite un evento con los `bytes` del error: el indexador de la semana 19 lo verá.
- **Llamar a un destino que llama de vuelta.** Como con `call`, el destino puede volver a
  entrar en tu contrato antes de que termines. Haz el `try` al final, con tu estado ya
  actualizado (checks-effects-interactions).

## 6. Trucos

- `try new Contrato(args) returns (Contrato c) { … } catch { … }` atrapa un constructor que
  revierte.
- Si solo quieres saber si falló, `catch {}` sin parámetros, o `catch (bytes memory)` para
  emitir los datos.
- `cast decode-error` con la firma del error lee los `bytes` que emitiste en un evento.

## ✅ Checklist

- [ ] Escribo un `try` con `returns` y los tres tipos de `catch`.
- [ ] Reconozco un error personalizado dentro de `catch (bytes memory)` por su selector.
- [ ] Explico qué tres fallos no atrapa `try`.
- [ ] Pongo tope de gas a un aviso y sé qué puede hacer quien elige el gas de la transacción.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 03 — delegatecall](03-delegatecall.md) | **Teoría 04 — try/catch** | [Teoría 05 — CREATE y CREATE2 →](05-create-y-create2.md) |
