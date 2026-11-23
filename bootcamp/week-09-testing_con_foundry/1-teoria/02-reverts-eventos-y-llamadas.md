# Teoría 02 — Reverts, eventos y llamadas

## 🎯 Objetivos

- Exigir un revert concreto, con su error y sus argumentos, con `vm.expectRevert`.
- Exigir un evento con `vm.expectEmit` y leer los eventos a mano con `vm.recordLogs`.
- Exigir que el contrato llame a otra dirección con `vm.expectCall`.
- Entender por qué todos estos cheatcodes van **antes** de la llamada.

---

## 1. Qué problema resuelve

Con `assertEq` compruebas el estado **después** de una llamada: saldos, contadores,
mappings. Hay tres cosas que no dejan estado que leer:

- **Un revert.** La llamada deshace todo lo que hizo. Si el test no lo espera, el revert
  sube hasta el test y lo hace fallar.
- **Un evento.** Los logs no se guardan en el storage: un contrato no puede leerlos
  (semana 07).
- **Una llamada a otro contrato.** Que el saldo de alice suba no dice cuántas veces la
  llamaron ni con qué datos.

Para las tres, forge ofrece un cheatcode de **expectativa** (*expect*): le dices qué tiene
que pasar en la siguiente llamada y él lo comprueba.

## 2. Cómo funciona una expectativa

Las tres siguen el mismo esquema: la expectativa, y justo después la llamada que la tiene
que cumplir.

```solidity
vm.expectRevert(...);   // 1. qué espero
faucet.drip();          // 2. la llamada que lo cumple
```

Si la llamada cumple, el test sigue. Si no, falla con un mensaje que dice qué esperaba y qué
pasó. Es igual que `vm.prank`: afecta a la **siguiente** llamada. Por eso nunca se escribe
después; a esas alturas la llamada ya pasó.

## 3. `vm.expectRevert`

Hay cuatro formas, de más a menos estricta:

| Forma | Pasa si la siguiente llamada revierte con… |
| ----- | ------------------------------------------ |
| `vm.expectRevert(abi.encodeWithSelector(E.selector, a, b))` | El error `E` con esos argumentos exactos |
| `vm.expectRevert(E.selector)` | El error `E` sin argumentos (para un error que no tiene) |
| `vm.expectPartialRevert(E.selector)` | El error `E`, con argumentos cualesquiera |
| `vm.expectRevert(bytes("mensaje"))` | `require(..., "mensaje")` o `revert("mensaje")` |
| `vm.expectRevert()` | Cualquier revert, por cualquier motivo |

En `test/Faucet.t.sol`:

```solidity
function test_RevertWhen_Empty() public {
    vm.deal(address(faucet), 0.05 ether);
    vm.prank(alice);
    vm.expectRevert(Faucet.Empty.selector);
    faucet.drip();
}
```

Para un error con argumentos tienes que calcular el valor exacto. Si te equivocas, forge
te enseña los dos:

```solidity
// ❌ El siguiente drip se permite en 1 + 1 days = 86401, no en 86400
function test_WrongRevertArgs() public {
    vm.startPrank(alice);
    faucet.drip();
    vm.expectRevert(abi.encodeWithSelector(Faucet.TooSoon.selector, 1 days));
    faucet.drip();
}
```

```
[FAIL: Error != expected error: TooSoon(86401 [8.64e4]) != TooSoon(86400 [8.64e4])] test_WrongRevertArgs() (gas: 88707)
```

`vm.prank` y `vm.expectRevert` se pueden escribir en cualquier orden entre sí; lo que
importa es que los dos vayan antes de la llamada.

## 4. `vm.expectEmit`

`vm.expectEmit(address(faucet))` dice: "la siguiente llamada tiene que hacer que `faucet`
emita este evento". El evento esperado se escribe con `emit` justo después, en el test:

```solidity
function test_EmitsDripped() public {
    vm.expectEmit(address(faucet));
    emit Faucet.Dripped(alice, 0.1 ether);
    vm.prank(alice);
    faucet.drip();
}
```

El orden es: expectativa, evento esperado y llamada. El `emit` del test no emite nada real:
forge lo usa como molde.

Sin argumentos, `vm.expectEmit()` compara todos los topics y los datos, pero no quién lo
emite. Con la dirección, también eso, que es lo que quieres casi siempre: si otro contrato
emitiera un `Dripped` falso, el test con dirección fallaría. Existe una forma larga,
`vm.expectEmit(bool, bool, bool, bool, address)`, para no comparar algunos topics o los
datos; úsala solo si un valor de verdad no se puede predecir.

### Leer los eventos a mano

Cuando necesitas contar eventos o comprobar un campo suelto, `vm.recordLogs()` empieza a
grabar y `vm.getRecordedLogs()` devuelve lo emitido desde entonces como un array de
`Vm.Log` (importa `Vm` desde `forge-std/Test.sol`):

| Campo | Qué es |
| ----- | ------ |
| `emitter` | Dirección del contrato que emitió |
| `topics[0]` | El selector del evento: `Faucet.Dripped.selector` |
| `topics[1..3]` | Los parámetros `indexed`, como `bytes32` |
| `data` | Los parámetros no indexados, en ABI; se leen con `abi.decode` |

El ejercicio 01 lo usa para comprobar campo a campo un evento con un parámetro `indexed`.

## 5. `vm.expectCall`

`vm.expectCall(destino, valor, datos)` exige que, durante la siguiente llamada, el contrato
llame a `destino` enviando `valor` wei con esos `datos`. El envío de ETH a una cuenta es una
llamada con datos vacíos (`""`):

```solidity
function test_SendsEther() public {
    vm.expectCall(alice, 0.1 ether, "");
    vm.prank(alice);
    faucet.drip();
}
```

Para un contrato, los datos son el selector y los argumentos:
`abi.encodeCall(IContrato.funcion, (arg))`. Si la llamada no llega, el mensaje dice cuántas
veces se esperaba y cuántas ocurrió, como verás en el ejercicio 01.

## 6. Antipatrones y riesgos

- **`vm.expectRevert()` vacío.** Pasa con cualquier revert, también con uno que no
  esperabas:

  ```solidity
  // ❌ Quiere probar Empty, pero el drip revierte antes con TooSoon
  function test_BareExpectRevertHidesTheReason() public {
      vm.prank(alice);
      faucet.drip();
      vm.deal(address(faucet), 0);
      vm.prank(alice);
      vm.expectRevert();
      faucet.drip();
  }
  ```

  ```
  [PASS] test_BareExpectRevertHidesTheReason() (gas: 89496)
  ```

  Pasa, y no prueba lo que dice su nombre. Exige siempre el error concreto.
- **La expectativa después de la llamada.** Ya no hay llamada que la cumpla:

  ```
  [FAIL: expected an emit, but no logs were emitted afterwards. you might have mismatched events or not enough events were emitted] test_ExpectEmitAfterTheCall() (gas: 65543)
  ```

- **Probar el camino feliz y nada más.** Cada `revert` del contrato es una regla. Si ningún
  test lo provoca, nadie sabe si funciona; la teoría 05 enseña a encontrar los que faltan.
- **Comprobar solo el evento.** Un evento dice qué afirma el contrato, no lo que hizo.
  Comprueba también el estado: el evento y el saldo.

## 7. Trucos

- Para errores con argumentos, construye el valor esperado con las mismas constantes del
  contrato (`faucet.COOLDOWN()`) en vez de escribir el número a mano.
- `abi.encodeWithSelector` no comprueba los tipos; `abi.encodeCall` sí, pero solo vale para
  funciones. Para errores, cuida el orden y el tipo de los argumentos.
- Si un test con `expectEmit` falla, mira la traza con `-vvvv`: ahí ves el evento que se
  emitió de verdad, campo a campo.

## ✅ Checklist

- [ ] Exijo un error con sus argumentos exactos y sé por qué el `expectRevert()` vacío es
      peligroso.
- [ ] Escribo `expectEmit` con la dirección del emisor y en el orden correcto.
- [ ] Leo eventos con `recordLogs` y decodifico un topic `indexed` y los datos.
- [ ] Exijo un envío de ETH con `expectCall`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — Cheatcodes](01-cheatcodes.md) | **Teoría 02 — Reverts, eventos y llamadas** | [Teoría 03 — Fuzz testing →](03-fuzz-testing.md) |
