# Proyecto — Registro de recursos

> Sexta capa del protocolo de tu dominio: cada recurso deja de ser un número y pasa a ser
> un registro con datos propios. Un struct `Item` con id, quién lo registró, estado (un
> enum) y etiqueta; un mapping de ids a recursos; la lista de ids de cada cuenta; y la
> posibilidad de retirar un recurso para liberar su plaza.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados y tu proyecto de la
semana 05 en `main`.

## Capa que se añade y por qué ahora

Hasta la semana 05, `register()` solo subía un contador: el registro sabía **cuántos**
recursos había, pero no **cuáles** ni **de quién**. `lastRegistrant` guardaba solo el
último. Ahora sabes guardar un dato por clave y agrupar campos: cada id apunta a su
`Item`, y cada cuenta tiene su lista de ids. `lastRegistrant` desaparece: cada `Item`
guarda su `registrant`.

Dos cambios de reglas:

- **La capacidad cuenta recursos activos** (`activeCount`), no ids emitidos (`count`).
  Retirar un recurso libera su plaza.
- **Un id no se reutiliza nunca.** `count` solo sube; un recurso retirado sigue
  consultable con su historia.

**El dominio te lo asigna el instructor.** El starter habla de un recurso genérico: tú le
das el nombre del tuyo, el mismo de las semanas anteriores, y decides qué significa la
etiqueta.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-06
   ```

2. Copia el starter entero, con su `.gitignore`, en una carpeta `week-06/` (ajusta la
   ruta a donde clonaste el bootcamp):

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-06-estructuras_de_datos/3-proyecto/starter week-06
   ```

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-06
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   forge test
   ```

**Verifica**: `3 tests passed, 20 failed, 0 skipped (23 total tests)`. Los tres que pasan
prueban el constructor y `setOpen`, que el starter ya trae de la semana 05.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml` | Configuración del bootcamp. No lo cambies |
| `.gitignore` | Deja fuera de git `out/` y `cache/` |
| `src/Registry.sol` | Todas las declaraciones: el enum `Status`, el struct `Item`, los dos mappings y los nueve errores. Los modificadores, el constructor y `setOpen` ya están resueltos, como en tu semana 05. El resto lleva `revert("TODO: ...")` |
| `test/Registry.t.sol` | Los 23 tests. **No lo modifiques**: comprueban las reglas y los datos, no los nombres de tu dominio |

Los modificadores existen, pero `register` y `registerBatch` **no los llevan todavía**:
ponlos tú.

## Requisitos

1. **Nombres**: `PROTOCOL_NAME` y `RESOURCE_NAME` de tu dominio.
2. **`Status`** empieza por `None`: un id que nadie registró tiene status `None`. Es la
   comprobación de existencia de todo el contrato.
3. **`_register(label)`**: `InvalidLabel()` si la etiqueta está vacía o pasa de
   `MAX_LABEL_LENGTH` (32) bytes; toma el id de `_nextId()`, actualiza `count`, guarda el
   `Item` en `Active`, añade el id a `_idsOf[msg.sender]`, suma uno a `activeCount` y
   comprueba con `assert` que `activeCount <= CAPACITY`.
4. **`register(label)`**: solo abierto; `RegistryFull(CAPACITY)` si `activeCount` ya llegó a
   `CAPACITY`. Devuelve el id.
5. **`registerBatch(labels)`**: solo abierto; `InvalidAmount(labels.length)` si no está
   entre 1 y `MAX_BATCH`; `RegistryFull(CAPACITY)` si no caben **todos**. Si una etiqueta
   no es válida, revierte el lote entero. Devuelve el id del primero.
6. **`retire(id)`**: con una referencia `storage`: `ItemNotFound(id)` si no existe,
   `NotRegistrant(msg.sender, id)` si quien llama no lo registró, `ItemNotActive(id)` si ya
   está retirado. Pasa a `Retired` y resta uno a `activeCount`.
7. **`getItem(id)`**: devuelve el `Item` entero; `ItemNotFound(id)` si no existe.
8. **`idsOf(account)`**: los ids que registró `account`, activos y retirados.
9. **`remaining()`** e **`isFull()`** sobre `activeCount`.
10. **Parámetros de texto en `calldata`**, no en `memory`.
11. **NatSpec** (`@notice`, y `@param` donde haya parámetros) en toda función `external`.
12. **Desplegado en anvil** desde la cuenta de tu `INDEX`, con las llamadas de abajo.

## Cómo verificar

```bash
forge test
```

**Verifica**: veintitrés `[PASS]` y `23 tests passed, 0 failed, 0 skipped (23 total tests)`,
sin warnings.

Después, despliega y prueba en anvil. Con `anvil --silent &` en marcha y la clave de tu
`INDEX` (aquí `3` y capacidad `50`, los de los ejemplos):

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 3)
forge create src/Registry.sol:Registry --private-key "$PK" --broadcast --constructor-args 50
```

```
Deployer: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
Deployed to: 0x057ef64E23666F000b34aE31332854aCBd1c8544
Transaction hash: 0x2f178738e3929f54eaaf21c69da55d2a88249ce2a060e5d005cde76d1e6f2a1b
```

Con anvil recién arrancado, la dirección es la de las semanas anteriores; el hash cambia
con tu código, tus nombres y tu capacidad.

Registra uno y un lote de dos. Un `string[]` se pasa a `cast` como lista entre comillas
simples:

```bash
REGISTRY=0x057ef64E23666F000b34aE31332854aCBd1c8544   # tu "Deployed to"
cast send "$REGISTRY" "register(string)" "north" --private-key "$PK"
cast send "$REGISTRY" "registerBatch(string[])" '["east","west"]' --private-key "$PK"
cast call "$REGISTRY" "getItem(uint256)((uint256,address,uint8,string))" 2
cast call "$REGISTRY" "idsOf(address)(uint256[])" 0x90F79bf6EB2c4f870365E785982E1f101E93b906
```

Dos recibos con `status 1 (success)` y:

```
(2, 0x90F79bf6EB2c4f870365E785982E1f101E93b906, 1, "east")
[1, 2, 3]
```

El `1` del struct es `Active`. Otra cuenta (la del `INDEX` siguiente al tuyo) intenta
retirar el recurso 1:

```bash
PK_OTHER=$(cast wallet private-key "test test test test test test test test test test test junk" 4)
cast send "$REGISTRY" "retire(uint256)" 1 --private-key "$PK_OTHER"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x0e5151a0: 00000000000000000000000015d34aaf54267db7d7c367839aaf71a00a2c6a650000000000000000000000000000000000000000000000000000000000000001, data: "0x0e5151a000000000000000000000000015d34aaf54267db7d7c367839aaf71a00a2c6a650000000000000000000000000000000000000000000000000000000000000001": NotRegistrant(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65, 1)
```

Tú sí puedes:

```bash
cast send "$REGISTRY" "retire(uint256)" 1 --private-key "$PK"
cast call "$REGISTRY" "getItem(uint256)((uint256,address,uint8,string))" 1
cast call "$REGISTRY" "activeCount()(uint256)"
cast call "$REGISTRY" "remaining()(uint256)"
```

```
(1, 0x90F79bf6EB2c4f870365E785982E1f101E93b906, 2, "north")
2
48
```

Estado `2` (`Retired`), dos activos y 48 plazas libres. Un id que no existe y una etiqueta
vacía:

```bash
cast call "$REGISTRY" "getItem(uint256)((uint256,address,uint8,string))" 9
cast send "$REGISTRY" "register(string)" "" --private-key "$PK"
```

```
Error: execution reverted: ItemNotFound(9)
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x3d36cb8d, data: "0x3d36cb8d": InvalidLabel
```

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna, para que veas el tipo de decisión:

| Dominio | Qué es la etiqueta | Qué significa retirar |
| ------- | ------------------ | --------------------- |
| Biblioteca | El código de estantería del libro | El libro se da de baja del fondo |
| Tienda en línea | La referencia del producto | El producto se descataloga |
| Cine | El nombre de la sala | La sala cierra por reforma |

## Criterios de calidad (no automatizables)

- `retire` usa `Item storage`; `getItem` usa `Item memory`. Sabes explicar por qué cada uno.
- Las guardas van antes de escribir; el `assert` va después.
- `registerBatch` comprueba cantidad y capacidad **antes** del bucle.
- Sabes explicar los riesgos que quedan: `idsOf` devuelve el array entero y crece con cada
  registro de esa cuenta, sin límite (desde fuera es gratis, dentro de una transacción no);
  y el dueño no puede retirar recursos ajenos. La semana 13 trae roles.

## Entrega

```bash
git add week-06
git commit -m "feat(week-06): store each resource as a struct with status and owner lists"
git push -u origin week-06
```

Abre un pull request `week-06` → `main` en tu repositorio. En la descripción pega la
salida de `forge create` y de las llamadas de arriba, incluidos los tres errores.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Arrays](../2-practicas/ejercicio-03-arrays/README.md) | **Proyecto — Registro de recursos** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
