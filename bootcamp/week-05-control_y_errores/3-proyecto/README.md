# Proyecto — Registro con reglas

> Quinta capa del protocolo de tu dominio: el registro de la semana 04 hace cumplir sus
> reglas. Capacidad máxima, apertura y cierre por el dueño, registro por lotes con un
> bucle acotado, errores personalizados, modificadores y un invariante con `assert`.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados y tu proyecto de la
semana 04 en `main`.

## Capa que se añade y por qué ahora

En la semana 04 el registro guardaba `OWNER` y `CAPACITY`, pero no los usaba:
`register()` aceptaba recursos de más y entonces `remaining()` revertía con
`panic (0x11)`. Ahora sabes decir "no": el registro rechaza lo que rompe sus reglas con un
error que explica por qué, y el dueño puede cerrarlo. También gana `registerBatch`, para
dar de alta varios recursos en una transacción, con un máximo de vueltas.

**El dominio te lo asigna el instructor.** El starter habla de un recurso genérico: tú le
das el nombre del tuyo, el mismo de las semanas 03 y 04.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-05
   ```

2. Copia el starter entero, con su `.gitignore`, en una carpeta `week-05/` (ajusta la
   ruta a donde clonaste el bootcamp):

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-05-control_y_errores/3-proyecto/starter week-05
   ```

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-05
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   forge test
   ```

**Verifica**: dieciocho líneas `[FAIL: ...]` y
`0 tests passed, 18 failed, 0 skipped (18 total tests)`.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml` | Configuración del bootcamp. No lo cambies |
| `.gitignore` | Deja fuera de git `out/` y `cache/` |
| `src/Registry.sol` | Todas las declaraciones: constantes, variables, los cinco errores y los dos modificadores. Los cuerpos llevan `revert("TODO: ...")` |
| `test/Registry.t.sol` | Los 18 tests. **No lo modifiques**: comprueban las reglas (capacidad, apertura, dueño, lotes), no los nombres de tu dominio |

Los modificadores están declarados, pero **ninguna función los lleva todavía**: decidir
dónde va cada uno es parte del proyecto. Puedes copiar de tu semana 04 lo que no cambia.

## Requisitos

1. **Nombres**: `PROTOCOL_NAME` y `RESOURCE_NAME` de tu dominio, como en la semana 04.
2. **Constructor**: rechaza `capacity == 0` con `InvalidCapacity` usando `require`;
   guarda `OWNER` y `CAPACITY`; deja el registro abierto (`isOpen = true`).
3. **`onlyOwner`** revierte con `NotOwner(msg.sender)`; **`whenOpen`** revierte con
   `RegistryClosed()`.
4. **`register()`**: solo con el registro abierto; si `count` ya llegó a `CAPACITY`,
   `RegistryFull(CAPACITY)`. Guarda `lastRegistrant` y devuelve el identificador.
5. **`registerBatch(amount)`**: solo abierto; `InvalidAmount(amount)` si `amount` no está
   entre 1 y `MAX_BATCH`; `RegistryFull(CAPACITY)` si no caben **todos**. Registra con un
   bucle que llama a `_register()`, guarda `lastRegistrant` y devuelve el identificador del
   primero.
6. **`setOpen(bool)`**: solo el dueño.
7. **`_register()`**: asigna `_nextId()` a `count`, comprueba con `assert` que
   `count <= CAPACITY` y devuelve `count`. Es el invariante del registro: si las guardas
   están bien, nunca falla.
8. **`remaining()`** e **`isFull()`** como en la semana 04. Ahora `remaining()` no puede
   revertir: explica por qué.
9. **NatSpec** (`@notice`, y `@param` donde haya parámetros) en el constructor y en toda
   función `external`.
10. **Desplegado en anvil** desde la cuenta de tu `INDEX`, con las llamadas de abajo.

## Cómo verificar

```bash
forge test
```

**Verifica**: dieciocho `[PASS]` y `18 tests passed, 0 failed, 0 skipped (18 total tests)`,
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
Transaction hash: 0x11a9c13168bb9be014297fde01da8928bfc5ccaffe61bd3869a3445ee977e147
```

Con anvil recién arrancado, la dirección es la misma de la semana 04: misma cuenta, mismo
nonce. El hash cambia con tu código, tus nombres y tu capacidad.

Registra uno y un lote de cinco:

```bash
REGISTRY=0x057ef64E23666F000b34aE31332854aCBd1c8544   # tu "Deployed to"
cast send "$REGISTRY" "register()" --private-key "$PK"
cast send "$REGISTRY" "registerBatch(uint256)" 5 --private-key "$PK"
cast call "$REGISTRY" "count()(uint256)"
cast call "$REGISTRY" "remaining()(uint256)"
```

Dos recibos con `status 1 (success)`, `6` y `44`.

Ahora rompe las reglas. Un lote de seis:

```bash
cast send "$REGISTRY" "registerBatch(uint256)" 6 --private-key "$PK"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x3728b83d: , data: "0x3728b83d0000000000000000000000000000000000000000000000000000000000000006": InvalidAmount(6)
```

Una cuenta que no es la dueña (la del `INDEX` siguiente al tuyo) intenta cerrar:

```bash
PK_OTHER=$(cast wallet private-key "test test test test test test test test test test test junk" 4)
cast send "$REGISTRY" "setOpen(bool)" false --private-key "$PK_OTHER"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x245aecd3: 00000000000000000000000015d34aaf54267db7d7c367839aaf71a00a2c6a65, data: "0x245aecd300000000000000000000000015d34aaf54267db7d7c367839aaf71a00a2c6a65": NotOwner(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65)
```

El dueño cierra y la otra cuenta intenta registrar:

```bash
cast send "$REGISTRY" "setOpen(bool)" false --private-key "$PK"
cast send "$REGISTRY" "register()" --private-key "$PK_OTHER"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x3dc4deb2, data: "0x3dc4deb2": RegistryClosed
```

Ninguna de las tres transacciones rechazadas llegó a enviarse: `cast` estimó el gas,
vio el revert y se detuvo.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna, para que veas el tipo de decisión:

| Dominio | Qué representa un lote | Cuándo cierra el dueño |
| ------- | ---------------------- | ---------------------- |
| Biblioteca | Varios libros de una donación | Durante el inventario anual |
| Tienda en línea | Varios pedidos de un mismo cliente | En una incidencia de pagos |
| Cine | Las funciones de un mismo día | Al cerrar la programación de la temporada |

## Criterios de calidad (no automatizables)

- Cada modificador está en todas las funciones que lo necesitan y en ninguna más.
- Las guardas van antes de escribir estado; el `assert` va después.
- `registerBatch` comprueba la capacidad **antes** del bucle, no dentro.
- Sabes explicar el riesgo que queda: `OWNER` es `immutable`. Si se pierde su clave, nadie
  puede volver a abrir o cerrar el registro. La semana 13 lo resuelve.

## Entrega

```bash
git add week-05
git commit -m "feat(week-05): enforce registry rules with custom errors and modifiers"
git push -u origin week-05
```

Abre un pull request `week-05` → `main` en tu repositorio. En la descripción pega la
salida de `forge create` y de las llamadas de arriba, incluidos los tres errores.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Modificadores](../2-practicas/ejercicio-03-modificadores/README.md) | **Proyecto — Registro con reglas** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
