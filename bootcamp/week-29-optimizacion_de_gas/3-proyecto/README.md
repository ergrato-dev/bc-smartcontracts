# Proyecto — Un alta más barata

> Cada alta de tu registro escribe en storage un dato que ya tiene: el id del recurso, que es la
> clave del mapping. Esta semana mides el gas de las altas, quitas esa escritura sin cambiar el
> layout del proxy, decides las ejecuciones del optimizador con números, y dejas el gas guardado
> en un archivo que `test.sh` comprueba.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 28 en
`main`.

## Capa que se añade y por qué ahora

Desde la semana 03, `_register` escribe el recurso entero:

```solidity
_items[id] =
    Item({id: id, registrant: registrant, status: Status.Active, registeredAt: block.timestamp, label: label});
```

El primer campo de `Item` es `id`, y ocupa su propio slot (semana 27). Pero para leer
`_items[id]` ya hay que saber el id: guardarlo otra vez es un `SSTORE` frío de cero a otro valor,
22 100 de gas, en cada alta. Lo paga cada usuario, para siempre.

La solución obvia sería quitar `id` del struct. No puedes: tu registro está detrás de un proxy con
recursos dados de alta, y quitar el primer campo movería todos los demás un slot (semana 15). Lo
que sí puedes es **dejar de escribirlo**: el campo sigue en el struct y en su slot, pero el alta no
lo toca y `getItem` lo rellena con la clave. Es una optimización que respeta el layout, y tiene su
precio: el primer slot de un recurso ya no significa lo mismo para los antiguos que para los nuevos.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-29
   ```

2. Copia el starter en `week-29/` y pon encima tus contratos, tus pruebas y tu informe de la
   semana 28:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-29-optimizacion_de_gas/3-proyecto/starter week-29
   cp -r week-28/contracts/src week-28/contracts/script week-29/contracts/
   cp -r week-28/contracts/test/invariant week-28/contracts/test/formal week-28/contracts/test/audit week-28/contracts/test/evm week-28/contracts/test/asm week-29/contracts/test/
   cp week-28/detectors/unpaused_register.py week-29/detectors/
   cp -r week-28/audit week-29/
   ls -l week-29/contracts/lib
   ```

   **Verifica**: `lib -> /opt/lib`. Tus `src/`, `script/`, tus tests y tu detector son los de la
   semana 28, y `week-29/audit/README.md`, tu informe.

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-29
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   cd contracts
   forge test
   ```

**Verifica**: `42 tests passed, 3 failed`. Los tres de `test/gas/RegisterGas.t.sol` que miran el id:

```text
[FAIL: assertion failed: 999 != 1] test_GetItemIdComesFromTheKey()
[FAIL: el alta escribe el id del recurso: 0x8983...733a == 0x8983...733a] test_BatchDoesNotWriteItemIds()
[FAIL: el alta escribe el id del recurso: 0x8983...733a == 0x8983...733a] test_RegisterDoesNotWriteItemId()
```

El cuarto, `test_RetireGas`, pasa: solo mide.

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/`, `contracts/script/`, `contracts/test/` (salvo `gas/`) | Los de la solución de la semana 28: tu referencia. Tú usas los tuyos |
| `contracts/src/Registry.sol` | `_register` y `getItem` con su `// TODO (semana 29)` |
| `contracts/test/gas/RegisterGas.t.sol` | Los cuatro tests de gas. **No los modifiques** |
| `mutants.sh` | Los diecisiete mutantes de la semana 28 y tres nuevos, de gas. **No lo modifiques** |
| `test.sh` | El de la semana 28, con la comprobación de snapshots antes de `forge test` |
| `check-report.sh` | El de la semana 28, que además busca en el informe cada número de `snapshots/RegisterGasTest.json` |
| `detectors/` | El detector de la semana 23; pon encima el tuyo |

## La línea de base

Antes de cambiar nada, guarda lo que cuesta ahora. `forge test` ya escribió
`snapshots/RegisterGasTest.json` (teoría 01):

```bash
cat snapshots/RegisterGasTest.json
```

```text
{
  "register": "239957",
  "registerBatch3": "535513",
  "retire": "41352"
}
```

Cada número es una transacción entera con aislamiento: la segunda alta de `alice` (la primera paga
además su primer certificado, sus primeros puntos y su array de ids), un lote de tres y una
retirada, todo en V3 con el hook de puntos. Tus números serán otros si tu `Item` tiene otros
campos.

Haz commit de la línea de base, fuera del contenedor:

```bash
git add week-29
git commit -m "test(week-29): add gas tests and baseline snapshot"
```

Así, después de optimizar, `git diff week-29/contracts/snapshots` te da el antes y el después.

## El alta sin el id

En `_register`, en lugar de asignar el struct entero, escribe los campos uno a uno a través de un
puntero `storage`, todos menos `id`:

```solidity
Item storage item = _items[id];
item.registrant = registrant;
```

y los que quedan de tu `Item`. En `getItem`, después de copiar el recurso a memoria, rellena el id
con la clave: `item.id = id;`. No cambies el struct ni el orden de sus campos.

**Verifica**: `forge test` da `44 tests passed, 1 failed`. Los cuatro de gas pasan, y falla tu mapa
de storage:

```text
[FAIL: assertion failed: 0 != 1] test_ItemAtMappingSlot()
```

Es lo que tenía que pasar: el test leía el primer slot de un recurso y esperaba su id. Ahora es 0
en los recursos nuevos. Cambia en `test/evm/StorageMap.t.sol` lo que espera de ese slot, con un
comentario que diga por qué, y comprueba que `getItem` sigue dando el id. Sigue con
`45 tests passed, 0 failed`, y vuelve a mirar el archivo:

```bash
git diff snapshots/
```

Con la solución de referencia, `register` pasa de 239 957 a 217 324 y `registerBatch3`, de 535 513
a 467 613. `retire` no cambia: no escribe ningún `Item` nuevo.

## Los tests de gas

| # | Test | Qué comprueba |
| - | ---- | ------------- |
| 1 | `test_RegisterDoesNotWriteItemId` | Con `vm.record` y `vm.accesses`, ninguna escritura del alta va al primer slot de su `Item`; `getItem` da el id. Guarda `register` |
| 2 | `test_BatchDoesNotWriteItemIds` | Lo mismo con un lote de tres. Guarda `registerBatch3` |
| 3 | `test_GetItemIdComesFromTheKey` | Con 999 en el primer slot del recurso 1, `getItem(1).id` sigue siendo 1 |
| 4 | `test_RetireGas` | Guarda `retire` |

`test.sh` ejecuta esta suite con `FORGE_SNAPSHOT_CHECK=true` **antes** que `forge test`, que
reescribe el archivo: si un número del archivo ya no es el del código, falla con
`Snapshots differ from previous run`. Por eso, después de cada cambio en `src/`, ejecuta
`forge test` y haz commit del archivo con el cambio.

## Las ejecuciones del optimizador

Desde la semana 20, tu `foundry.toml` tiene `optimizer_runs = 200` (teoría 03). Mide qué darían
otros valores sin tocar el archivo:

```bash
for r in 1 200 10000; do
  echo "runs $r"
  FOUNDRY_OPTIMIZER_RUNS=$r forge build --sizes 2>&1 | grep -E '^\| RegistryV3 '
  FOUNDRY_OPTIMIZER_RUNS=$r forge test --mc RegisterGasTest >/dev/null
  grep '"register"' snapshots/RegisterGasTest.json
done
```

Con la solución de referencia:

```text
runs 1
| RegistryV3         | 14,636           | 14,885            | 9,940              | 34,267              |
  "register": "219082",
runs 200
| RegistryV3         | 15,117           | 15,366            | 9,459              | 33,786              |
  "register": "217324",
runs 10000
| RegistryV3         | 18,185           | 18,434            | 6,391              | 30,718              |
  "register": "216993",
```

Las columnas son el tamaño del bytecode desplegado y del de despliegue, y el margen de cada uno
hasta su límite: 24 576 y 49 152 bytes. Decide con la teoría 03: lo que
ahorra cada alta, lo que cuesta cada despliegue (200 de gas por byte) y el margen que queda. Si
cambias `optimizer_runs`, cambian todos los números: vuelve a ejecutar `forge test` y a guardar el
archivo. Si no lo cambias, escribe por qué.

Estas ejecuciones con `FOUNDRY_OPTIMIZER_RUNS` reescriben `snapshots/RegisterGasTest.json` con
otros números. Al acabar, `forge test` sin la variable lo deja como estaba.

## El informe

Añade a `week-29/audit/README.md`:

1. Una sección `## Gas (semana 29)`, antes de `## Hallazgos`, con:
   - La tabla de antes y después de `register`, `registerBatch3` y `retire`, con los números tal
     cual salen del archivo, sin separador de miles: `check-report.sh` los busca así.
   - Qué cambió y lo que cuesta: los recursos antiguos tienen el id en su primer slot y los nuevos
     no; ninguna versión futura puede reutilizar ese slot.
   - La tabla de los tests de `test/gas` y la de los tres mutantes nuevos con lo que mata cada uno.
   - Tu tabla de ejecuciones del optimizador y tu decisión.
   - Lo que no hiciste y por qué: al menos un campo de `Item` que cabría empaquetado y que el
     layout del proxy no deja mover.
2. En la sección del mapa de storage (semana 27), la fila de `Item`: el primer slot, a 0 en las
   altas nuevas.
3. Las líneas de `Registry.sol` en el alcance.

Usa las diez preguntas de la teoría 04 para revisar tu cambio antes de escribir la sección.

## Cómo verificar

```bash
bash test.sh
```

**Verifica**, en este orden:

- `✅ informe: secciones, commit, hallazgos, gas y N pruebas citadas`. Con la solución de
  referencia, N es 41.
- `4 tests passed, 0 failed`: la suite de gas con la comprobación de snapshots.
- `45 tests passed, 0 failed`.
- Halmos: `Symbolic test result: 5 passed; 0 failed`.
- `forge lint` sin avisos y Slither con `0 result(s) found`.
- `2 passed` en los tests del detector.
- Medusa: `Test summary: 13 test(s) passed, 0 test(s) failed`.
- `mutants.sh`, los veinte muertos. Los tres últimos los matan los tests de `test/gas`:

  ```text
  ✅ el alta vuelve a escribir el id: muerto
  ✅ getItem lee el id del storage: muerto
  ✅ el alta lee count una vez más: muerto
  ```

  El último no cambia lo que hace el registro: añade una lectura de storage. Ningún test de
  comportamiento lo ve; solo la comprobación de snapshots, porque el gas sube. Los mutantes buscan
  `item.registrant = registrant;`, `item.id = id;` y `assert(activeCount <= capacity);`: si lo
  escribiste de otra forma, `mutants.sh` dice `la expresión no cambia`. Ajusta tu código a esas
  líneas, no el script.

## Ejemplos de adaptación

| Dominio | Lo que cambia |
| ------- | ------------- |
| Biblioteca | El `Item` es un libro con su ISBN: si el ISBN ya es la clave, tampoco hace falta guardarlo en el struct |
| Tienda en línea | Un pedido con su importe y su fecha: `registeredAt` en `uint64` cabría junto al cliente, pero solo en un despliegue nuevo; escríbelo en "lo que no se hizo" |
| Cine | Una entrada por asiento: un bitmap de asientos ocupados por sesión ahorraría más que quitar el id, pero cambia la interfaz; mídelo en un contrato aparte antes de proponerlo |

## Criterios de calidad (no automatizables)

- El struct `Item` no cambia: ni campos, ni orden, ni tipos.
- El comentario de `_register` dice por qué no se escribe `id` y qué pasa con los recursos
  antiguos.
- El mapa de storage explica, con un comentario, por qué el primer slot es 0.
- Los números del informe son los de tu `snapshots/RegisterGasTest.json`, y la decisión del
  optimizador lleva los tuyos, no los de este README.

## Entrega

1. `bash test.sh` acaba sin error: informe, gas, tests, specs, `forge lint`, Slither, detector,
   Medusa y los veinte mutantes.
2. `week-29/audit/README.md` con la sección `## Gas (semana 29)`.
3. Commit y pull request:

   ```bash
   git add week-29
   git commit -m "perf(week-29): stop writing the item id on every registration"
   git push -u origin week-29
   ```

   Abre el pull request `week-29` → `main` y fusiónalo cuando esté en verde.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Optimizar sin romper](../2-practicas/ejercicio-03-optimizar-sin-romper/README.md) | **Proyecto — Un alta más barata** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
