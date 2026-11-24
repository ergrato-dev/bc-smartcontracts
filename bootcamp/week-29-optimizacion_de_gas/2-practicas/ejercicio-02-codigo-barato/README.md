# Ejercicio 02 — Código barato

> Al terminar habrás dejado unos arrays en la calldata, cambiado mensajes de error por custom
> errors, leído un `struct` con un puntero a storage, ordenado una condición para que decida lo
> barato y quitado una comprobación que ya estaba hecha. Y habrás visto que no todo ahorra lo mismo.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 03 — El código y el compilador](../../1-teoria/03-el-codigo-y-el-compilador.md)
leída y el [ejercicio 01](../ejercicio-01-storage-barato/README.md) en verde.

## Contexto

Proyecto Foundry. `Payroll` es una nómina: el dueño contrata empleados, fija un presupuesto y paga
a muchos en una llamada con `payAll`. Solo lleva la cuenta de lo pagado: no mueve ETH. `payAll`
salta los importes a cero y los empleados bloqueados, y revierte si un pago pasa del presupuesto.

| Archivo | Qué es |
| ------- | ------ |
| `src/Payroll.sol` | El contrato: tu trabajo, pasos 1 a 5 |
| `test/Payroll.t.sol` | Dos tests de comportamiento, en verde desde el principio, y uno de gas o de tamaño por paso, con un tope. No lo cambies |

El `setUp` contrata a 10 empleados, `address(1)` a `address(10)`, y bloquea al 5. Los tests pagan
a los 10 con los importes 1 a 10, salvo el 3 y el 7, que van a cero. Como en el ejercicio 01, cada
paso borra las líneas que acaban en `// <- Paso N` y descomenta las suyas.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-29-optimizacion_de_gas/2-practicas/ejercicio-02-codigo-barato/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `2 tests passed, 5 failed`. Los cuatro tests de gas miden la misma llamada, cada uno
con un tope más bajo, y el de tamaño mira el bytecode:

```text
[FAIL: Paso 1: payAll gasta demasiado: 250757 >= 250500] test_Paso1_PayAllFitsBudget()
[FAIL: Paso 2: el bytecode ocupa demasiado: 5268 >= 4800] test_Paso2_BytecodeFitsBudget()
```

## Paso 1: Los arrays, en la calldata

**Por qué**: `payAll` recibe `to` y `amounts` como `memory`: al entrar, copia los dos arrays de la
calldata a memoria. No los modifica, así que la copia sobra (teoría 03).

**Abre** `src/Payroll.sol` y cambia la firma de `payAll`:

```solidity
function payAll(address[] calldata to, uint256[] calldata amounts) external {
```

**Verifica**: `3 tests passed, 4 failed`. `payAll` pasa de 250 757 a 249 966: 791 con dos arrays de
10 elementos. La copia crece con el array: con 100 empleados ahorraría diez veces más. El bytecode
también baja, de 5268 a 4966 bytes: ya no hay código para copiar.

## Paso 2: Custom errors

**Por qué**: cada `require` lleva su mensaje en el bytecode, y cada mensaje de más de 32 bytes
ocupa varias palabras. Un custom error son 4 bytes de selector (teoría 03).

**Abre** `src/Payroll.sol`. Descomenta las tres declaraciones de errores, debajo de `PASO 2`, y
cambia los cinco `require`: tres en `payAll`, uno en `hire` y uno en `setBlocked`. Por ejemplo:

```solidity
if (msg.sender != OWNER) revert NotOwner(msg.sender);
```

Fíjate en que la condición se invierte: `require` dice lo que tiene que cumplirse y el `if`, lo
que no.

**Verifica**: `4 tests passed, 3 failed`. El bytecode de despliegue pasa de 4966 a 4624 bytes.
`test_RevertWhen_OverBudgetOrWrongCaller` sigue en verde: comprueba que las tres llamadas
revierten, no con qué error.

## Paso 3: Un puntero a storage

**Por qué**: `Employee memory e = employees[to[i]]` copia el empleado entero: el slot del `name` y
el de `blocked` y `hiredAt`, dos `SLOAD` fríos por empleado. `payAll` solo usa `e.blocked`. Con
`storage`, `e` es el número del slot y `e.blocked` lee solo el suyo.

**Abre** `src/Payroll.sol` y cambia la línea del bucle:

```solidity
Employee storage e = employees[to[i]];
```

**Verifica**: `5 tests passed, 2 failed`. `payAll` pasa de 249 966 a 219 418: 30 548 menos, el
mayor ahorro del ejercicio, y no es un cambio en el código que ejecuta la EVM sino en los slots que
lee.

## Paso 4: Primero lo barato

**Por qué**: `e.blocked || amounts[i] == 0` lee storage antes de mirar el importe. Para los
importes a cero, la respuesta ya la da `amounts[i] == 0`, que es calldata. En el orden inverso, el
`SLOAD` de `e.blocked` no se ejecuta cuando el importe es cero.

**Abre** `src/Payroll.sol` y cambia la condición:

```solidity
if (amounts[i] == 0 || e.blocked) continue;
```

**Verifica**: `6 tests passed, 1 failed`. `payAll` pasa de 219 418 a 215 184: 4234, dos `SLOAD`
fríos menos, uno por importe a cero. Antes del paso 3, este mismo cambio no ahorra nada (da
249 996, 30 más): la copia en memoria ya ha leído `blocked` antes de llegar a la condición.

## Paso 5: `unchecked` donde ya está comprobado

**Por qué**: la línea de antes revierte si `amounts[i] > remaining`. Después, `remaining -=
amounts[i]` no puede bajar de cero, pero solc lo comprueba otra vez. `unchecked` quita esa segunda
comprobación (teoría 03).

**Abre** `src/Payroll.sol` y envuelve la resta:

```solidity
unchecked {
    remaining -= amounts[i];
}
```

**Verifica**: `7 tests passed, 0 failed`. `payAll` pasa de 215 184 a 213 931: 1253 en siete pagos.

Ahora haz la prueba al revés: quita la línea del `OverBudget` y deja el `unchecked`. Ejecuta
`forge test`: `test_RevertWhen_OverBudgetOrWrongCaller` falla con
`next call did not revert as expected`, porque `remaining` dio la vuelta en vez de revertir.
`unchecked` solo es seguro mientras la comprobación de encima siga ahí. Deshaz el cambio.

## Para pensar

- Ordena los cinco pasos por gas ahorrado. ¿Cuáles tocan storage y cuáles solo código?
- En el paso 2, la llamada que revierte también gasta menos. ¿Por qué el test mide el tamaño y no
  el gas de un revert?
- En el paso 5, si alguien añade mañana un `remaining += bonus` dentro del bucle, ¿sigue siendo
  seguro el `unchecked`? ¿Qué test lo detectaría?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Storage barato](../ejercicio-01-storage-barato/README.md) | **Ejercicio 02 — Código barato** | [Ejercicio 03 — Optimizar sin romper →](../ejercicio-03-optimizar-sin-romper/README.md) |
