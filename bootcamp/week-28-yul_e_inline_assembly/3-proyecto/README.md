# Proyecto — La llamada al hook en assembly

> Tu registro ya no copia al log el motivo enorme de un hook (H-01, semana 21), pero sigue
> copiándolo a su memoria, y esa copia la paga quien registra. Esta semana reescribes la llamada al
> hook en assembly para copiar solo 4 bytes, y la pruebas contra lo que hacía la versión en
> Solidity.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 27 en
`main`.

## Capa que se añade y por qué ahora

Desde la semana 21, `_notifyHook` llama al hook con tope de gas y dentro de un `try`:

```solidity
try IRegistrationHook(current).onItemRegistered{gas: HOOK_GAS}(id, registrant, label) {}
catch (bytes memory reason) {
    emit HookFailed(id, reason.length < 4 ? bytes("") : abi.encodePacked(bytes4(reason)));
}
```

El evento solo lleva el selector. Pero `catch (bytes memory reason)` copia antes a memoria **toda**
la returndata del hook (teoría 03). Un hook que revierte con 192 000 bytes de ceros gasta unos
88 000 de gas, dentro de su tope de 100 000; la copia cuesta al registro otro tanto, **fuera** del
tope. Con la solución de referencia de la semana 27, un alta pasa de 244 296 de gas a 436 689.

Solidity no tiene forma de decir "atrapa el error y copia solo 4 bytes". Assembly, sí: `call` con
tamaño de salida 0 no copia nada, y `returndatacopy(0, 0, 4)` copia el selector al scratch space.
Es el uso del assembly que justifica la teoría 01: lo que Solidity no puede expresar, en la
función más pequeña posible.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-28
   ```

2. Copia el starter en `week-28/` y pon encima tus contratos, tus pruebas y tu informe de la
   semana 27:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-28-yul_e_inline_assembly/3-proyecto/starter week-28
   cp -r week-27/contracts/src week-27/contracts/script week-28/contracts/
   cp -r week-27/contracts/test/invariant week-27/contracts/test/formal week-27/contracts/test/audit week-27/contracts/test/evm week-28/contracts/test/
   cp week-27/detectors/unpaused_register.py week-28/detectors/
   cp -r week-27/audit week-28/
   ls -l week-28/contracts/lib
   ```

   **Verifica**: `lib -> /opt/lib`. Tus `src/`, `script/`, `test/invariant/`, `test/formal/`,
   `test/audit/`, `test/evm/` y tu detector son los de la semana 27, y `week-28/audit/README.md`,
   tu informe.

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-28
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   cd contracts
   forge test
   ```

**Verifica**: `40 tests passed, 1 failed`. El que falla es el de la bomba:

```text
[FAIL: assertion failed: 436689 >= 344296] test_ReturnBombCostsAtMostHookGas()
```

Los otros cuatro de `test/asm/HookCall.t.sol` ya pasan con la versión en Solidity: son la
**referencia**. Lo que hace tu assembly tiene que seguir pasándolos.

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/`, `contracts/script/`, `contracts/test/` (salvo `asm/`) | Los de la solución de la semana 27: tu referencia. Tú usas los tuyos |
| `contracts/src/Registry.sol` | `_notifyHook` con su `// TODO (semana 28)`: la firma de `_callHook` y una pista |
| `contracts/test/asm/HookCall.t.sol` | Los cinco tests de la llamada en assembly. **No los modifiques** |
| `contracts/test/attackers/RevertDataHook.sol` | Un hook que revierte con los bytes exactos que le das: 0, 1, 3, 4... |
| `contracts/test/attackers/MemoryBombHook.sol` | La return bomb más grande que cabe en `HOOK_GAS`: 192 000 bytes |
| `mutants.sh` | Los catorce mutantes de la semana 27 y tres nuevos, contra tu assembly. **No lo modifiques** |
| `test.sh`, `check-report.sh` | Los de la semana 27; `test.sh` ejecuta también `test/asm` |
| `detectors/` | El detector de la semana 23; pon encima el tuyo |

## La llamada en assembly

`_notifyHook` se queda en Solidity: codifica la calldata con `abi.encodeCall`, llama a `_callHook`
y emite el evento. Solo la llamada va en assembly, en una función privada con esta firma:

```solidity
function _callHook(address target, bytes memory data) private returns (bool ok, uint256 size, bytes4 selector)
```

| Devuelve | Qué es |
| -------- | ------ |
| `ok` | Si la llamada acabó bien |
| `size` | `returndatasize()` después de la llamada |
| `selector` | Los 4 primeros bytes de la returndata si la llamada falló y hubo 4 o más; si no, cero |

Y `_notifyHook` emite lo mismo que antes:

```solidity
if (!ok) emit HookFailed(id, size < 4 ? bytes("") : abi.encodePacked(selector));
```

Pistas, de las teorías 02 y 03:

- `data` es un `bytes memory`: sus datos empiezan en `add(data, 0x20)` y su longitud es
  `mload(data)`.
- `call(HOOK_GAS, target, 0, entrada, tamaño, 0, 0)` no copia nada de la respuesta. `HOOK_GAS` es
  una constante: el bloque la ve.
- `returndatacopy` revierte si copias más de lo que hay. Copia solo si `returndatasize()` es 4 o
  más, y solo si la llamada falló.
- Los 4 bytes copiados a `0x00` quedan en los 4 bytes altos de `mload(0)`. Los 28 bajos son lo que
  hubiera en el scratch space: límpialos con una máscara antes de dar el valor a `selector`.
- Con las devoluciones con nombre, `forge lint` no avisa de `uninitialized-local` (teoría 04).
- Marca el bloque `memory-safe` solo si lo es, y escribe en un comentario por qué.

`try` comprobaba que el hook tuviera código; `call`, no. Busca en tu `Registry.sol` qué lo
garantiza ya y escríbelo en el comentario de `_callHook`.

## Los tests de la llamada

| # | Test | Qué comprueba |
| - | ---- | ------------- |
| 1 | `test_ReturnBombCostsAtMostHookGas` | Con `MemoryBombHook`, el alta no gasta `HOOK_GAS` más que con un revert de 4 bytes |
| 2 | `testFuzz_FailedHookEmitsSelector` | Para cualquier returndata, `HookFailed` lleva lo mismo que con `try`: el selector, o `""` si hay menos de 4 bytes |
| 3 | `test_ShortRevertsEmitEmptyReason` | Con 0 a 5 bytes de motivo, uno a uno: el fuzzer casi nunca genera esos tamaños |
| 4 | `test_SucceedingHookEmitsNothing` | Con el hook del despliegue, que funciona, no hay `HookFailed` y `alice` recibe sus puntos |
| 5 | `test_BatchWithBombHookKeepsReturnValue` | `registerBatch` con la bomba: tres altas, tres llamadas, y el valor que devuelve Solidity después sigue bien |

El 5 llama a `_callHook` tres veces en la misma llamada, con Solidity escribiendo en memoria entre
una y otra: es el caso en que una escritura fuera del scratch space se notaría.

## El informe

Añade a `week-28/audit/README.md`:

1. Una sección `## Assembly (semana 28)`, antes de `## Hallazgos`, con una tabla por bloque de
   assembly de `src/`: qué hace, por qué es `memory-safe` y qué tests lo comprueban. Debajo, lo
   que `try` hacía y tu assembly ya no (comprobar el código del hook, decodificar), y por qué no
   hace falta. Y la tabla de mutantes nuevos con el test que mata cada uno.
2. Un hallazgo nuevo, `H-05 — El registro copia a memoria todo el motivo de revert del hook`, en
   la tabla y con su sección: descripción, impacto con **tus** números de gas, prueba
   (`test_ReturnBombCostsAtMostHookGas`), corrección y estado. Severidad baja, como H-01: hace
   falta que el administrador ponga un hook malicioso.
3. Su fila en la revisión de correcciones y el resumen de severidades actualizado.

Usa las diez preguntas de la teoría 04 para revisar tu bloque antes de escribir la sección.

## Cómo verificar

```bash
bash test.sh
```

**Verifica**, en este orden:

- `✅ informe: secciones, commit, hallazgos y N pruebas citadas`. Con la solución de referencia,
  N es 37.
- `41 tests passed, 0 failed`.
- Halmos: `Symbolic test result: 5 passed; 0 failed`.
- `forge lint` sin avisos y Slither con `0 result(s) found`.
- `2 passed` en los tests del detector.
- Medusa: `Test summary: 13 test(s) passed, 0 test(s) failed`.
- `mutants.sh`, los diecisiete muertos. Los tres últimos los matan tus tests de `test/asm`:

  ```text
  ✅ copia toda la returndata: muerto
  ✅ copia 4 bytes de una returndata más corta: muerto
  ✅ avisa de un fallo cuando el hook funciona: muerto
  ```

  Los mutantes buscan líneas concretas de `_callHook`: `returndatacopy(0, 0, 4)`, `gt(size, 3)` e
  `if (!ok) emit HookFailed`. Si escribiste lo mismo de otra forma, `mutants.sh` dice
  `la expresión no cambia`: ajusta tu código a esas líneas, no el script.

## Ejemplos de adaptación

| Dominio | Lo que cambia |
| ------- | ------------- |
| Biblioteca | Un hook que avisa a la red de bibliotecas de cada préstamo: el mismo `_callHook`, con la calldata de `onLoan` |
| Tienda en línea | Dos hooks, inventario y envíos: `_callHook` se llama dos veces y cada fallo deja su evento; el test de la bomba, con cada uno |
| Cine | Un hook que reserva el asiento en otro contrato y **sí** devuelve algo (el número de asiento): copia 32 bytes si `ok` y la returndata trae 32, y comprueba ese tamaño como en el paso 2 del ejercicio 03 |

## Criterios de calidad (no automatizables)

- El assembly está en una función privada que solo hace la llamada; la codificación y el evento
  siguen en Solidity.
- El comentario de `_callHook` justifica `memory-safe` y dice qué comprobación de `try` deja de
  hacerse y por qué no hace falta.
- La máscara del selector está, aunque ningún mutante la pruebe, y el informe explica por qué es
  un mutante equivalente (teoría 04).
- Los números de gas del informe son los de tu `forge test -vv`, no los de este README.

## Entrega

1. `bash test.sh` acaba sin error: informe, tests, specs, `forge lint`, Slither, detector, Medusa
   y los diecisiete mutantes.
2. `week-28/audit/README.md` con la sección `## Assembly (semana 28)` y el hallazgo H-05.
3. Commit y pull request:

   ```bash
   git add week-28
   git commit -m "fix(week-28): call the registration hook without copying its returndata"
   git push -u origin week-28
   ```

   Abre el pull request `week-28` → `main` y fusiónalo cuando esté en verde.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Llamadas en assembly](../2-practicas/ejercicio-03-llamadas-en-assembly/README.md) | **Proyecto — La llamada al hook en assembly** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
