# Teoría 03 — Denegación de servicio

## 🎯 Objetivos

- Explicar qué es una denegación de servicio en un contrato y por qué puede ser permanente.
- Reconocer los cuatro caminos: una llamada que revierte, un bucle sin límite, un saldo
  forzado y otro contrato que gasta o devuelve demasiado.
- Cambiar un envío push por un patrón pull.
- Medir con Foundry cuánto gas crece una función con los datos que guarda.

## 1. Qué problema resuelve

Una **denegación de servicio** (DoS, denial of service) es un ataque que no roba nada: impide
que el contrato haga su trabajo. En una aplicación web suele ser temporal; se cae el servidor y
se levanta otro. En un contrato puede ser **permanente**: el código no se cambia (salvo detrás
de un proxy) y, si una función revierte siempre, revierte para siempre, y los fondos que
dependen de ella se quedan dentro.

En 2016, un juego llamado King of the Ether pagaba al rey anterior cada vez que alguien se
coronaba. Un día, el pago a una cartera que era un contrato falló, y la corona se quedó
atascada. La subasta del ejercicio 03 repite exactamente ese fallo.

## 2. Cómo funciona

### Camino 1: una llamada que revierte

Si tu función envía ETH o llama a otro contrato, y revierte cuando esa llamada falla, el otro
contrato decide si tu función termina. Basta con un contrato sin `receive` (rechaza todo ETH) o
con un `receive` que revierta.

El arreglo es el patrón **pull**: en vez de enviar (push), apuntas lo que se debe y cada uno lo
retira con su propia transacción. Si alguien no puede cobrar, solo le afecta a él.

![Arriba, patrón push: la puja de Bob devuelve el ETH del bloqueador, la devolución falla y la puja revierte, para siempre. Abajo, patrón pull: la puja de Bob solo apunta lo debido; Alice retira lo suyo, y el bloqueador no puede retirar pero no bloquea a nadie](../0-assets/03-push-frente-a-pull.svg)

### Camino 2: un bucle sin límite

Cada bloque tiene un **límite de gas** (block gas limit): la suma del gas de todas sus
transacciones no puede pasar de ahí. Una transacción que necesite más no cabe en ningún bloque.
Con un anvil arrancado (`anvil --silent &`):

```bash
cast block latest -f gasLimit --rpc-url http://127.0.0.1:8545
```

```text
30000000
```

Un bucle que recorre un array que crece con cada usuario gasta más con cada usuario. Llegará un
día en que no cabe. **Dónde**: en un proyecto Foundry, `src/Airdrop.sol`:

```solidity
contract Airdrop {
    address[] public members;
    mapping(address => uint256) public points;

    function join() external {
        members.push(msg.sender);
    }

    function distribute() external {
        for (uint256 i = 0; i < members.length; i++) {
            points[members[i]] += 1;
        }
    }
}
```

Un test que llena el array con 10, 100 y 1000 miembros y mide `distribute` con `gasleft()`:

```solidity
function test_GasGrows() public {
    uint256[3] memory sizes = [uint256(10), 100, 1000];
    for (uint256 s = 0; s < sizes.length; s++) {
        Airdrop airdrop = _filled(sizes[s]); // despliega y hace `join` desde `sizes[s]` cuentas
        uint256 before = gasleft();
        airdrop.distribute();
        console.log(sizes[s], before - gasleft());
    }
}
```

**Ejecuta** `forge test -vv --mt test_GasGrows`:

```text
  10 272520
  100 2511180
  1000 24897780
```

Unos 25 000 de gas por miembro, casi todo el `SSTORE` que pasa `points` de 0 a 1. Con 1000
miembros, 25 millones; con 1500, no cabe en 30. Otro test lo comprueba llamando con ese tope:

```solidity
(bool ok,) = address(airdrop).call{gas: 30_000_000}(abi.encodeCall(Airdrop.distribute, ()));
```

```text
  1500 miembros con 30 millones de gas: false
```

Si `join` es abierto, un atacante ni siquiera tiene que esperar: llena el array él mismo con
cuentas de usar y tirar, y el reparto deja de funcionar para todos.

Arreglos: que cada uno **reclame** lo suyo (pull otra vez), o procesar por **lotes** con un
índice guardado (`distribute(uint256 count)` que sigue donde lo dejó la anterior), o poner un
máximo al tamaño. Tu registro limita los lotes con `MAX_BATCH`.

### Camino 3: un saldo que no esperabas

`address(this).balance` no solo cambia con tus funciones `payable`. Un contrato que hace
`selfdestruct(destino)` envía todo su ETH a `destino` **sin ejecutar su código**: ni `receive`
ni `fallback`. Desde EIP-6780, `selfdestruct` ya no borra el contrato salvo en la transacción
que lo creó, pero sigue enviando el ETH.

Un contrato que compara su saldo con un número exacto se rompe así. **Dónde**: `src/Forced.sol`:

```solidity
contract Game {
    uint256 public constant TARGET = 3 ether;

    function play() external payable {
        require(msg.value == 1 ether, "1 ETH");
        // ❌ Comparar con el saldo: alguien puede meter ETH sin llamar a play.
        require(address(this).balance <= TARGET, "game over");
    }
}

contract Forcer {
    constructor(address payable target) payable {
        selfdestruct(target);
    }
}
```

Compilarlo ya avisa:

```text
Warning (5159): "selfdestruct" has been deprecated. Note that, starting from the Cancun hard fork, the underlying opcode no longer deletes the code and data associated with an account and only transfers its Ether to the beneficiary, unless executed in the same transaction in which the contract was created (see EIP-6780). Any use in newly deployed contracts is strongly discouraged even if the new behavior is taken into account. Future changes to the EVM might further reduce the functionality of the opcode.
```

Un test que despliega `Forcer` con 3 ETH apuntando al juego y después intenta jugar:

```text
  saldo del juego 3000000000000000000
```

y `play` revierte con `game over` sin que nadie haya jugado. Arreglo: lleva la cuenta en una
variable propia (`uint256 pot`) que solo tus funciones cambian, y no uses el saldo para decidir.

### Camino 4: otro contrato que gasta o devuelve demasiado

Cuando llamas a otro contrato sin tope de gas, le das casi todo el que queda. La EVM le pasa como
mucho **63/64** del gas disponible (EIP-150) y se queda 1/64 para terminar tu función. Si el otro
contrato lo gasta todo, a tu función le queda ese 1/64, y puede no bastar.

Tu registro llama al hook con `{gas: HOOK_GAS}` dentro de un `try`: el hook tiene 100 000 de gas
como mucho, y si falla, el alta sigue. El ataque del hook que gasta todo (proyecto) lo comprueba.

Pero hay una segunda trampa: lo que el otro contrato **devuelve**. `catch (bytes memory reason)`
copia a tu memoria todo el motivo del revert, y si después lo emites en un evento, pagas 8 de gas
por cada byte del log. Un hook que revierte con 64 000 bytes, cosa que le cuesta menos de su
tope, sube el alta de tu registro de unos 305 000 de gas a 921 568. Se llama **return bomb**, y es
el hallazgo que corriges en el proyecto.

## 3. Cómo se escribe

- **Pull**: un `mapping(address => uint256)` con lo debido y una función `withdraw` con CEI
  (ejercicio 03).
- **Lotes**: un parámetro que limita cuántos elementos procesa cada llamada, o un `MAX` al
  añadir.
- **Llamadas externas**: con tope de gas (`{gas: N}`), dentro de un `try`, y sin copiar entero
  lo que devuelven.
- **Saldos**: tu propia contabilidad, nunca `address(this).balance ==`.

## 4. Antipatrones y riesgos

- **Enviar a varios en un bucle.** Si uno falla, fallan todos; si son muchos, no cabe. Doble
  DoS.
- **Revertir porque otro contrato falló, cuando no hace falta.** A veces es lo correcto (un pago
  que debe llegar), pero entonces que lo pida quien cobra (pull).
- **Arrays que solo crecen.** Cualquier función que los recorra entera tiene fecha de caducidad.
  Las `view` también: aunque no gastan gas fuera de la cadena, un contrato que las llame sí, y los
  nodos RPC cortan las llamadas muy largas.
- **Igualdades estrictas con el saldo.** `address(this).balance == x` o `<= x`.
- **Copiar y emitir lo que devuelve otro contrato.** Limítalo al selector (4 bytes).
- **Depender de un orden concreto en el bloque.** Un atacante con dinero puede llenar varios
  bloques de transacciones propias (block stuffing) para que la tuya no entre antes de un plazo.
  Los plazos cortos son frágiles.

## 5. Trucos

- `gasleft()` antes y después de una llamada en un test da su coste exacto. Mídelo con 10, 100 y
  1000 elementos: si crece lineal, pon un límite.
- `forge test --gas-report` da el gas mínimo, medio y máximo de cada función en todos los tests.
- Un contrato que rechaza ETH para tus tests: uno vacío, sin `receive` ni `fallback`.
- Para forzar ETH en un test no hace falta `selfdestruct`: `vm.deal(address(target), amount)`
  cambia el saldo directamente.

## ✅ Checklist

- [ ] Explico por qué una DoS en un contrato puede ser permanente.
- [ ] Cambio un envío push por un mapping de lo debido y un `withdraw` con CEI.
- [ ] Sé cuánto gas cabe en un bloque de anvil y mido cuánto crece una función con sus datos.
- [ ] No decido nada con `address(this).balance`: llevo mi propia cuenta.
- [ ] Llamo a contratos externos con tope de gas, en un `try` y sin copiar entero lo que devuelven.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 02 — Control de acceso y `tx.origin`](02-control-de-acceso-y-tx-origin.md) | **Teoría 03 — Denegación de servicio** | [Teoría 04 — Aritmética y `unchecked` →](04-aritmetica-y-unchecked.md) |
