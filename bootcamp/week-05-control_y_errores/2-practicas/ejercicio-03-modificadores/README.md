# Ejercicio 03 — Modificadores

> Al terminar habrás escrito cuatro modificadores (dueño, apertura, poscondición y uno con
> parámetro), los habrás combinado en una función y habrás comprobado que un revert deshace
> también lo que el cuerpo ya había escrito.

**Duración estimada**: 2 h 30 min
**Prerrequisitos**: [Ejercicio 02](../ejercicio-02-errores/README.md) terminado;
[Teoría 05](../../1-teoria/05-modificadores.md) leída.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Gate.sol` | Una puerta con dueño (`OWNER`), apertura (`isOpen`), aforo (`LIMIT = 10`) y entradas en grupo de hasta `MAX_BATCH = 3`. Errores y firmas ya escritos. Aquí trabajas |
| `test/Gate.t.sol` | Seis tests, uno por paso. Usan `alice`, una cuenta de prueba creada con `makeAddr`, y `vm.prank` para llamar desde ella. **No lo modifiques** |

Las funciones ya llevan sus modificadores en la firma. Tú escribes los modificadores
(pasos 1 a 4) y los cuerpos que faltan (pasos 5 y 6).

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-05-control_y_errores/2-practicas/ejercicio-03-modificadores/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con `Warning (5740): Unreachable code.`: en los modificadores, el `_` que va
detrás del `revert` no se alcanza nunca. Desaparece al resolver los pasos, igual que
`Warning (2018)`.

**Verifica**: seis `FAIL`. Casi todos fallan con `TODO: Paso 1`: necesitan abrir la puerta
con `setOpen`, que lleva `onlyOwner`.

## Paso 1: `onlyOwner`

**Por qué**: abrir y cerrar la puerta es cosa del dueño.

**Abre** `src/Gate.sol`:

```solidity
modifier onlyOwner() {
    if (msg.sender != OWNER) revert NotOwner(msg.sender);
    _;
}
```

**Verifica**: `[PASS] test_Step1_OnlyOwner()`. El test prueba las dos caras: `alice`
revierte con `NotOwner(alice)` y el test, que desplegó el contrato y es el dueño, abre la
puerta.

## Paso 2: `whenOpen`

**Por qué**: con la puerta cerrada no entra nadie.

```solidity
modifier whenOpen() {
    if (!isOpen) revert Closed();
    _;
}
```

`!isOpen` es la negación de un `bool`: `true` cuando la puerta está cerrada.

**Verifica**: `[PASS] test_Step2_WhenOpen()`.

## Paso 3: Una poscondición

**Por qué**: el aforo se comprueba **después** de entrar, con el `count` ya actualizado.

```solidity
modifier withinLimit() {
    _;
    if (count > LIMIT) revert LimitExceeded(count, LIMIT);
}
```

**Verifica**: `[PASS] test_Step3_WithinLimit()`. Diez entran; el undécimo revierte con
`LimitExceeded(11, 10)`: el cuerpo ya había puesto `count` a 11 cuando el modificador
comprobó. Aun así, el test comprueba después que `count` sigue en `10`: el revert deshizo
el `count++`.

Prueba a mover la comprobación antes de `_`. El test falla:

```
[FAIL: next call did not revert as expected] test_Step3_WithinLimit() (gas: 400158)
```

Antes de `_`, `count` todavía vale 10 y `10 > 10` es falso: entra uno de más. Déjala
después.

## Paso 4: Un modificador con parámetro

**Por qué**: la cantidad de `enterMany` tiene límites. El modificador recibe el parámetro
de la función.

```solidity
modifier validAmount(uint256 amount) {
    if (amount == 0 || amount > MAX_BATCH) revert InvalidAmount(amount);
    _;
}
```

**Verifica**: `[PASS] test_Step4_ValidAmount()` (`0` y `4` revierten). Fíjate en la firma
de `enterMany`: `whenOpen validAmount(amount) withinLimit`. El test pasa aunque el cuerpo
de `enterMany` todavía tenga su `revert("TODO: Paso 5")`: `validAmount` revierte antes de
llegar a él.

## Paso 5: El cuerpo de `enterMany`

**Por qué**: con las tres reglas en los modificadores, el cuerpo solo hace su trabajo.

```solidity
function enterMany(uint256 amount) external whenOpen validAmount(amount) withinLimit {
    for (uint256 i = 0; i < amount; i++) {
        count++;
    }
}
```

**Verifica**: `[PASS] test_Step5_EnterMany()`. Con 9 dentro, `enterMany(3)` hace tres
`count++` y `withinLimit` revierte con `LimitExceeded(12, 10)`. Las tres vueltas se
deshacen: `count` vuelve a `9`, no se queda en `10`. Una llamada revierte entera o no
revierte.

El bucle está acotado por `MAX_BATCH`: quien llama no puede pedir mil vueltas.

## Paso 6: `close`

**Por qué**: el dueño cierra la puerta y vacía el recinto.

```solidity
function close() external onlyOwner {
    isOpen = false;
    count = 0;
}
```

**Verifica**: `forge test` termina con
`6 tests passed, 0 failed, 0 skipped (6 total tests)` y sin warnings.

Ahora quita `onlyOwner` de la firma de `close` y ejecuta `forge build`: compila sin un
solo warning. `forge test` lo detecta:

```
[FAIL: next call did not revert as expected] test_Step6_Close() (gas: 133814)
```

`alice` cerró la puerta. El compilador no sabe quién debe poder llamar a cada función; los
tests sí. Vuelve a ponerlo.

## ✅ Criterios de éxito

- `forge test` pasa los 6 tests sin warnings.
- Explicas en qué orden se ejecutan los tres modificadores de `enterMany` y su cuerpo.
- Explicas por qué `count` vuelve a 9 en el paso 5 aunque el bucle llegó a 12.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Errores](../ejercicio-02-errores/README.md) | **Ejercicio 03 — Modificadores** | [Proyecto — Registro con reglas →](../../3-proyecto/README.md) |
