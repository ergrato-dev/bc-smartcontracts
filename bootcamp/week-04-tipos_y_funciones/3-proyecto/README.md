# Proyecto — Registro configurable

> Cuarta capa del protocolo de tu dominio: el registro de la semana 03, rehecho con lo de
> esta semana. Nombres `constant`, dueño y capacidad `immutable` fijados en el
> constructor, estado legible con getters `public`, una función interna y NatSpec.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados y tu proyecto de la
semana 03 en `main`.

## Capa que se añade y por qué ahora

En la semana 03 el registro escribía a mano una función por cada dato que exponía y no
sabía quién lo había desplegado. Ahora sabes poner cada dato en su sitio: lo que nunca
cambia, en el bytecode; lo que se decide al desplegar, en el constructor; lo que cambia,
en el storage con su getter. El registro también gana un **dueño** y una **capacidad**:
todavía no los hace cumplir, pero la semana 05 se apoya en ellos para rechazar
registros de más y llamadas de quien no debe.

**El dominio te lo asigna el instructor.** El starter habla de un recurso genérico: tú le
das el nombre del tuyo, el mismo de la semana 03.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-04
   ```

2. Copia el starter entero, con su `.gitignore`, en una carpeta `week-04/` (ajusta la
   ruta a donde clonaste el bootcamp):

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-04-tipos_y_funciones/3-proyecto/starter week-04
   ```

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-04
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   forge test
   ```

**Verifica**: diez líneas `[FAIL: ...]` y
`0 tests passed, 10 failed, 0 skipped (10 total tests)`. Algunas fallan con
`TODO: register`; otras con `assertion failed`, porque los nombres están vacíos y el
constructor no guarda nada.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml` | Configuración del bootcamp. No lo cambies |
| `.gitignore` | Deja fuera de git `out/` y `cache/` |
| `src/Registry.sol` | El contrato con todas sus declaraciones; los nombres vacíos, el constructor sin cuerpo y cuatro funciones con `revert("TODO: ...")` |
| `test/Registry.t.sol` | Los 10 tests. **No lo modifiques**: comprueban propiedades (el dueño es quien despliega, los identificadores empiezan en 1, la capacidad restante baja), no los nombres de tu dominio |

Compara el starter con tu `Registry` de la semana 03: `protocolName()` pasa a ser la
constante `PROTOCOL_NAME`, `total()` y `latest` desaparecen porque `count` y
`lastRegistrant` son `public`.

## Requisitos

1. **`PROTOCOL_NAME`** y **`RESOURCE_NAME`**: `string public constant` con los nombres de
   la semana 03, en inglés.
2. **Constructor** con un parámetro `capacity`: guarda `msg.sender` en `OWNER` y
   `capacity` en `CAPACITY`, las dos `immutable`.
3. **`count`** y **`lastRegistrant`**: variables de estado `public`.
4. **`_nextId()`**: función `internal view` que devuelve `count + 1`.
5. **`register()`**: asigna a `count` lo que devuelve `_nextId()`, guarda `msg.sender` en
   `lastRegistrant` y devuelve el identificador.
6. **`remaining()`** (`view`): `CAPACITY - count`. **`isFull()`** (`view`): `true` si
   `count` es mayor o igual que `CAPACITY`.
7. **NatSpec**: toda función `external` y el constructor llevan `@notice`; el constructor,
   también `@param`.
8. **Desplegado en anvil** desde la cuenta del protocolo (tu `INDEX`) con la capacidad que
   decidas para tu dominio, y con un recurso registrado.

## Cómo verificar

```bash
forge test
```

**Verifica**: diez `[PASS]` y `10 tests passed, 0 failed, 0 skipped (10 total tests)`, sin
warnings.

Después, despliega y prueba en anvil. Con `anvil --silent &` en marcha y la clave de tu
`INDEX` (aquí `3` y capacidad `50`, los de los ejemplos):

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 3)
forge create src/Registry.sol:Registry --private-key "$PK" --broadcast --constructor-args 50
```

```
Deployer: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
Deployed to: 0x057ef64E23666F000b34aE31332854aCBd1c8544
Transaction hash: 0x15ece7d88b6966348249f2353440caa59dc90efc81af4596a8c2a382b4ef6eca
```

La dirección es la misma que en la semana 03 si anvil está recién arrancado: misma cuenta,
mismo nonce. El hash cambia con tus nombres y tu capacidad. Comprueba los getters y
registra un recurso:

```bash
REGISTRY=0x057ef64E23666F000b34aE31332854aCBd1c8544   # tu "Deployed to"
cast call "$REGISTRY" "PROTOCOL_NAME()(string)"
cast call "$REGISTRY" "OWNER()(address)"
cast call "$REGISTRY" "CAPACITY()(uint256)"
cast send "$REGISTRY" "register()" --private-key "$PK"
cast call "$REGISTRY" "count()(uint256)"
cast call "$REGISTRY" "remaining()(uint256)"
```

Con el dominio de ejemplo imprimen `"Repair Network"`, la dirección del `Deployer`, `50`,
un recibo con `status 1 (success)`, `1` y `49`.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna, para que veas el tipo de decisión:

| Dominio | `PROTOCOL_NAME` | `RESOURCE_NAME` | Qué representa `CAPACITY` |
| ------- | --------------- | --------------- | ------------------------- |
| Biblioteca | `Book Lending` | `Book` | Libros que caben en el catálogo |
| Tienda en línea | `Order Escrow` | `Order` | Pedidos abiertos que admite la tienda |
| Cine | `Ticket Office` | `Screening` | Funciones que se programan en la temporada |

## Criterios de calidad (no automatizables)

- Cada dato está en su sitio: nada que no cambie se queda en una variable de estado.
- `forge inspect Registry storageLayout` muestra solo `count` y `lastRegistrant`, y sabes
  explicar por qué.
- NatSpec en español que coincide con lo que hace cada función.
- Sabes explicar el riesgo de esta versión: `register()` acepta recursos aunque el
  registro esté lleno, y entonces `remaining()` revierte con `panic (0x11)`. La semana 05
  lo impide con `require`.

## Entrega

```bash
git add week-04
git commit -m "feat(week-04): add configurable registry with constants and immutables"
git push -u origin week-04
```

Abre un pull request `week-04` → `main` en tu repositorio. En la descripción pega la
salida de `forge create` y de las seis llamadas de arriba.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Constructor y constantes](../2-practicas/ejercicio-03-constructor-y-constantes/README.md) | **Proyecto — Registro configurable** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
