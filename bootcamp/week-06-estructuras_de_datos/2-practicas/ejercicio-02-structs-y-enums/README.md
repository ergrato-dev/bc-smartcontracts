# Ejercicio 02 — Structs y enums

> Al terminar habrás creado structs con nombres, guardado y devuelto structs desde un
> mapping, cambiado el estado de un enum a través de una referencia `storage`, convertido
> un enum a número y borrado un struct con `delete`.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 01](../ejercicio-01-mappings/README.md) terminado;
[Teorías 02 y 04](../../1-teoria/02-structs-y-enums.md) leídas.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/TaskBoard.sol` | Un tablero de tareas: el enum `Status` (`Todo`, `Doing`, `Done`), el struct `Task`, el mapping `tasks` y tres errores ya declarados. Aquí trabajas |
| `test/TaskBoard.t.sol` | Seis tests, uno por paso. **No lo modifiques** |

Los tests leen las tareas de dos formas: con el getter público `board.tasks(1)`, que
devuelve los cuatro campos sueltos, y con `board.getTask(1)`, que devuelve el struct.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-06-estructuras_de_datos/2-practicas/ejercicio-02-structs-y-enums/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con `Warning (2018)` y `Warning (5667)`.

**Verifica**: seis `FAIL`, todos con `TODO: Paso 1`: todos los tests crean una tarea
primero.

## Paso 1: Crear un struct con nombres

**Por qué**: con nombres se ve qué valor va a cada campo, y cambiar el orden de la
declaración no rompe nada.

**Abre** `src/TaskBoard.sol`:

```solidity
function createTask(string calldata title, uint8 priority) external returns (uint256 id) {
    id = ++taskCount;
    tasks[id] = Task({title: title, owner: msg.sender, priority: priority, status: Status.Todo});
}
```

`title` llega en `calldata` (solo se lee) y al asignarlo al struct guardado se copia al
storage.

**Verifica**: `[PASS] test_Step1_CreateTask()`.

## Paso 2: Devolver el struct entero

**Por qué**: el getter público devuelve campos sueltos; una función puede devolver el
struct, y además comprobar que existe.

```solidity
function getTask(uint256 id) external view returns (Task memory) {
    Task memory task = tasks[id];
    if (task.owner == address(0)) revert TaskNotFound(id);
    return task;
}
```

Aquí la copia en `memory` es lo que quieres: vas a devolverla, no a modificar lo guardado.
Una tarea real siempre tiene dueño, así que `owner == address(0)` significa "no existe"
(teoría 05).

**Verifica**: `[PASS] test_Step2_GetTask()`.

## Paso 3: Cambiar el estado con una referencia `storage`

**Por qué**: para modificar un struct guardado necesitas apuntar a él, no copiarlo.

```solidity
function start(uint256 id) external {
    Task storage task = tasks[id];
    if (task.owner != msg.sender) revert NotTaskOwner(msg.sender);
    if (task.status != Status.Todo) revert InvalidStatus(task.status);
    task.status = Status.Doing;
}
```

Los enums se comparan con `==` y `!=`. Un error puede llevar un enum como parámetro:
viaja como número.

**Verifica**: `[PASS] test_Step3_Start()`.

Ahora rompe a propósito: cambia `Task storage task` por `Task memory task` y ejecuta
`forge test`. El compilador avisa en esa función:

```
Warning (2018): Function state mutability can be restricted to view
  --> src/TaskBoard.sol:46:5:
```

Y tres tests fallan, aunque `start` no revierte:

```
[FAIL: assertion failed] test_Step3_Start() (gas: 174614)
[FAIL: InvalidStatus(0)] test_Step4_Finish() (gas: 184013)
[FAIL: assertion failed: 0 != 1] test_Step5_StatusCode() (gas: 151371)
```

La tarea se quedó en `Todo` (0): `start` cambió una copia. Vuelve a poner `storage`.

## Paso 4: La siguiente transición

**Por qué**: cada estado solo puede pasar al siguiente. La guarda de estado impide saltos
como `Todo` → `Done`.

```solidity
function finish(uint256 id) external {
    Task storage task = tasks[id];
    if (task.owner != msg.sender) revert NotTaskOwner(msg.sender);
    if (task.status != Status.Doing) revert InvalidStatus(task.status);
    task.status = Status.Done;
}
```

**Verifica**: `[PASS] test_Step4_Finish()`. El test intenta terminar una tarea en `Todo` y
espera `InvalidStatus(Todo)`.

## Paso 5: Un enum es un número

**Por qué**: fuera del contrato (`cast`, los tests, una dApp) el enum se ve como `uint8`.

```solidity
function statusCode(uint256 id) external view returns (uint8 code, uint8 maxCode) {
    code = uint8(tasks[id].status);
    maxCode = uint8(type(Status).max);
}
```

**Verifica**: `[PASS] test_Step5_StatusCode()`: `Todo` es 0, `Doing` 1 y el máximo, `Done`,
2.

## Paso 6: `delete` sobre un struct

**Por qué**: borrar deja **todos** los campos en su valor por defecto, también el estado.

```solidity
function removeTask(uint256 id) external {
    if (tasks[id].owner != msg.sender) revert NotTaskOwner(msg.sender);
    delete tasks[id];
}
```

**Verifica**: `forge test` termina con
`6 tests passed, 0 failed, 0 skipped (6 total tests)` y sin warnings. El test comprueba
que, tras borrar, el título es `""`, el dueño `address(0)` y `taskCount` sigue en 1: el id
1 no se reutiliza.

## ✅ Criterios de éxito

- `forge test` pasa los 6 tests sin warnings.
- Explicas por qué `start` con `memory` no revierte pero no hace nada.
- Explicas qué estado tiene una tarea borrada y por qué eso es un problema con este enum
  (pista: ¿qué valor es el 0?).

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Mappings](../ejercicio-01-mappings/README.md) | **Ejercicio 02 — Structs y enums** | [Ejercicio 03 — Arrays →](../ejercicio-03-arrays/README.md) |
