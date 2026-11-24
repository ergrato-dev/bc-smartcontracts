# Ejercicio 03 — Specs de contrato

> Al terminar habrás escrito specs con cuentas simbólicas y con una llamada simbólica a cualquier
> función, habrás encontrado con ellas dos fallos de un token que sus tests no ven y habrás
> leído en la traza de Halmos qué función los provoca.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 03](../../1-teoria/03-halmos.md) y
[Teoría 04](../../1-teoria/04-especificaciones-y-limites.md) leídas y el
[ejercicio 02](../ejercicio-02-halmos/README.md) terminado.

## Contexto

`Token` es un ERC-20 mínimo escrito a mano, sin OpenZeppelin: saldos, `approve`, `transfer`,
`transferFrom`, `mint` del dueño y `burnFrom`, que quema tokens de otra cuenta con la allowance
que te dio. Sus cuatro tests unitarios pasan, todos con dos cuentas distintas.

`test.sh` ejecuta `forge test`, una compilación sin warnings y `halmos --no-status`.

| Archivo | Qué es |
| ------- | ------ |
| `src/Token.sol` | El token. Pasos 2 y 4 |
| `test/Token.t.sol` | Cuatro tests unitarios, en verde, y dos para los contraejemplos. Pasos 2 y 4 |
| `test/TokenSpec.t.sol` | Las specs de Halmos, con `SymTest`. Pasos 1 y 3 |
| `foundry.toml` | Con el remapping de `halmos-cheatcodes`, `dynamic_test_linking = false` y `ast = true` |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-25-verificacion_formal/2-practicas/ejercicio-03-specs-de-contrato/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `4 tests passed, 2 failed`: los dos tests de contraejemplos, con su `TODO`.

## Paso 1: Una transferencia mueve, y nada más

**Por qué**: lo que promete `transfer`: `from` pierde `amount` y `to` lo gana. Con dos
direcciones simbólicas, Halmos prueba también el caso que ningún test unitario escribe: que
`from` y `to` sean la misma cuenta. Entonces el saldo no cambia.

```solidity
function check_TransferKeepsBalances(address from, address to, uint256 minted, uint256 amount) public {
    token.mint(from, minted);
    uint256 fromBefore = token.balanceOf(from);
    uint256 toBefore = token.balanceOf(to);
    vm.prank(from);
    token.transfer(to, amount);
    if (from == to) {
        assertEq(token.balanceOf(from), fromBefore);
    } else {
        assertEq(token.balanceOf(from), fromBefore - amount);
        assertEq(token.balanceOf(to), toBefore + amount);
    }
}
```

**Abre** `test/TokenSpec.t.sol` y, en `check_TransferKeepsBalances`, borra el
`assertTrue(false, ...)` y descomenta el cuerpo.

**Verifica**: `halmos --no-status --function check_TransferKeepsBalances` falla:

```text
Counterexample:
    p_amount_uint256_fc1a535_00 = 0x4000000000000000000000000000000000000000000000000000000000000000
    p_from_address_6d9aab1_00 = 0x00
    p_minted_uint256_870450e_00 = 0x8000000000000000000000000000000000000000000000000000000000000000
    p_to_address_f377499_00 = 0x00
[FAIL] check_TransferKeepsBalances(address,address,uint256,uint256) (paths: 9, time: 0.10s, bounds: [])
```

`from` y `to` son la misma dirección. Tus valores pueden ser otros; esa igualdad, no.

## Paso 2: Leer el saldo después de escribirlo

**Por qué**: `_transfer` lee los dos saldos al principio y escribe los dos al final. Si `from ==
to`, la segunda escritura usa el saldo de antes de la primera: la cuenta gana `amount` en vez de
quedarse igual. Es un fallo real de tokens escritos a mano. Primero el test, con el contraejemplo
en pequeño; después la corrección.

```solidity
function test_SelfTransferKeepsBalance() public {
    vm.prank(alice);
    token.transfer(alice, 100);
    assertEq(token.balanceOf(alice), 100);
}
```

```solidity
balanceOf[to] += amount;
```

**Abre** `test/Token.t.sol` y, en `test_SelfTransferKeepsBalance`, borra el `revert` y descomenta
el cuerpo. `forge test --mt SelfTransfer` falla con `assertion failed: 200 != 100`: alice se
transfiere 100 a sí misma y acaba con 200. Después, en `src/Token.sol`, en `_transfer`, borra las
dos líneas `// <- Paso 2` y descomenta la de debajo.

**Verifica**: `forge test --mt SelfTransfer` pasa, y Halmos:

```text
[PASS] check_TransferKeepsBalances(address,address,uint256,uint256) (paths: 12, time: 0.41s, bounds: [])
```

## Paso 3: Nadie te quita tus tokens

**Por qué**: una promesa sobre **todas** las funciones: ninguna llamada de otra cuenta, sin que
le hayas dado allowance, baja tu saldo. `svm.createCalldata("Token")` es una llamada a cualquier
función de `Token`, con cualquier argumento. `vm.assume(ok)` se queda con las llamadas que salen
bien: si la llamada revierte, tu saldo tampoco cambia.

```solidity
function check_NobodyTakesYourTokens(address caller, address victim, uint256 minted) public {
    vm.assume(caller != victim);
    vm.assume(caller != address(this));
    token.mint(victim, minted);
    bytes memory data = svm.createCalldata("Token");
    vm.prank(caller);
    (bool ok,) = address(token).call(data);
    vm.assume(ok);
    assertGe(token.balanceOf(victim), minted);
}
```

`caller != address(this)`: el test es el dueño del token, y el dueño sí puede emitir.

**Abre** `TokenSpec.t.sol` y, en `check_NobodyTakesYourTokens`, borra el `assertTrue(false, ...)`
y descomenta el cuerpo.

**Verifica**: Halmos falla, y el contraejemplo trae dos símbolos nuevos, `p_from_..._05` y
`p_amount_..._06`: los argumentos de la llamada simbólica.

```text
Counterexample:
    p_amount_uint256_66fcf7e_06 = 0x8000000000000000000000000000000000000000000000000000000000000000
    p_caller_address_fc53eb4_00 = 0x8000000000000000000000000000000000000000
    p_from_address_0fa50b1_05 = 0x00
    p_minted_uint256_e441425_00 = 0x8000000000000000000000000000000000000000000000000000000000000000
    p_victim_address_5792c89_00 = 0x00
[FAIL] check_NobodyTakesYourTokens(address,address,uint256) (paths: 12, time: 0.40s, bounds: [])
```

¿Qué función? `transferFrom` también tiene un `from`. La traza lo dice:

```bash
halmos --no-status --function check_NobodyTakesYourTokens -vv --early-exit 2>&1 | grep "0xaaaa0002::"
```

```text
        CALL 0xaaaa0002::mint(Concat(0x000000000000000000000000, Extract(0x9f, 0x00, p_victim_address_b2709a0_00), ...
        CALL 0xaaaa0002::burnFrom(Concat(p_from_address_72a1c33_05, p_amount_uint256_96a624d_06)) (caller: ...
        STATICCALL 0xaaaa0002::balanceOf(Concat(0x000000000000000000000000, Extract(0x9f, 0x00, ...
```

`0xaaaa0002` es el token. Después de `mint`, la llamada simbólica resultó ser `burnFrom(victim,
amount)`, desde una cuenta cualquiera. (La línea larga va recortada aquí; en tu terminal sale
entera y con colores.)

## Paso 4: `burnFrom` gasta allowance

**Por qué**: `burnFrom` dice "con la allowance que `from` dio a quien llama", pero no la
comprueba: cualquiera quema los tokens de cualquiera. `transferFrom` sí la gasta, con
`_spendAllowance`; `burnFrom` tiene que hacer lo mismo.

```solidity
function test_RevertWhen_BurnFromWithoutAllowance() public {
    vm.prank(bob);
    vm.expectRevert(abi.encodeWithSelector(Token.InsufficientAllowance.selector, bob, 0, 1));
    token.burnFrom(alice, 1);
}
```

```solidity
_spendAllowance(from, amount);
```

**Abre** `test/Token.t.sol` y, en `test_RevertWhen_BurnFromWithoutAllowance`, borra el `revert` y
descomenta el cuerpo: falla con `next call did not revert as expected`. Después, en
`src/Token.sol`, descomenta la primera línea de `burnFrom`.

**Verifica**: `bash test.sh` termina sin error: `6 passed` y las dos specs demostradas.

```text
[PASS] check_NobodyTakesYourTokens(address,address,uint256) (paths: 12, time: 0.38s, bounds: [])
[PASS] check_TransferKeepsBalances(address,address,uint256,uint256) (paths: 12, time: 0.40s, bounds: [])
Symbolic test result: 2 passed; 0 failed; time: 0.80s
```

`check_NobodyTakesYourTokens` vale ahora para las cinco funciones de `Token` que cambian estado, y
para las que le añadas mañana sin tocar la spec.

## Para pensar

- En el paso 3, quita `vm.assume(caller != victim)`. ¿Qué contraejemplo da Halmos? ¿Es un fallo
  del token o de la spec?
- `check_NobodyTakesYourTokens` dice que tu saldo no baja. ¿Demuestra que nadie puede **subir**
  el `totalSupply` sin ser el dueño? Escribe esa spec.
- Ejecuta la spec del paso 3 con `--solver z3`, varias veces. ¿Cambia el resultado? ¿Y el tiempo?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Halmos](../ejercicio-02-halmos/README.md) | **Ejercicio 03 — Specs de contrato** | [Proyecto — Specs de tu protocolo →](../../3-proyecto/README.md) |
