# Proyecto — Registro modular

> Octava capa del protocolo de tu dominio: el registro se parte en piezas reutilizables
> (dueño, apertura, validación de etiquetas), publica su interfaz para que otros contratos
> lo usen y declara con ERC-165 qué interfaces cumple. Por fuera hace lo mismo que en la
> semana 07.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados y tu proyecto de la
semana 07 en `main`.

## Capa que se añade y por qué ahora

Tu registro tiene ya 13 errores, 4 eventos, 2 modificadores y la regla de las etiquetas
dentro de `_register`. Las semanas que vienen añaden contratos al protocolo (un token en la
11, un NFT en la 12) que necesitan el mismo dueño, la misma apertura y las mismas reglas.
Copiarlas sería repetir fallos. Ahora sabes partirlas:

- **`Owned`** y **`Openable`** (contratos abstractos): el dueño con `onlyOwner` y el
  interruptor con `whenOpen` y `setOpen`. `Openable` hereda de `Owned`.
- **`LabelLib`** (librería): la regla de una etiqueta válida.
- **`IRegistry`** (interfaz): los tipos, eventos, errores y funciones que el registro
  ofrece a quien registra. La semana 10 la usa para llamar al registro desde otro contrato,
  la 17 desde el frontend y la 19 desde el indexador.
- **`IERC165`**: el registro responde `true` para `IRegistry` y para `IERC165`.

Es un **refactor** (*refactoring*): cambia cómo está escrito el código, no lo que hace.
Los 37 tests de la semana 07 siguen ahí y tienen que seguir pasando; los 7 nuevos
prueban las piezas.

**El dominio te lo asigna el instructor.** Usa los nombres y la tasa de tu semana 07.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-08
   ```

2. Copia el starter entero, con su `.gitignore`, en una carpeta `week-08/` (ajusta la
   ruta a donde clonaste el bootcamp):

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-08-herencia_interfaces_y_librerias/3-proyecto/starter week-08
   ```

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-08
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   forge test
   ```

**Verifica**: `36 tests passed, 8 failed, 0 skipped (44 total tests)`. Pasan los de la
semana 07, salvo `test_NamesAreSet` (los nombres están vacíos), porque `Registry.sol`
todavía es el registro de la semana 07 entero.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml` | Configuración del bootcamp. No lo cambies |
| `.gitignore` | Deja fuera de git `out/` y `cache/` |
| `src/Registry.sol` | El registro de la semana 07, resuelto, en un solo contrato, más un `supportsInterface` por escribir. Lo que falta lleva `// TODO:` |
| `src/IRegistry.sol` | La interfaz con el enum, el struct, los eventos y los errores de quien registra, y solo una función, `getItem`, como ejemplo |
| `src/Owned.sol` | El dueño: `OWNER`, `NotOwner`, el constructor y `onlyOwner` sin su comprobación |
| `src/Openable.sol` | La apertura: `isOpen`, `OpenChanged`, `RegistryClosed`, el constructor, y `whenOpen` y `setOpen` sin cuerpo |
| `src/LabelLib.sol` | La librería con `MAX_LENGTH` y un `isValid` por escribir |
| `src/IERC165.sol` | La interfaz de ERC-165. Ya escrita |
| `test/Registry.t.sol` | Los 44 tests. **No lo modifiques** |

Los tests nombran cada error y cada evento por la pieza que lo declara: `Owned.NotOwner`,
`Openable.RegistryClosed`, `IRegistry.WrongFee`, `Registry.TransferFailed` (teoría 01).
Por eso, al mover una declaración, tiene que ir a la pieza que dice la tabla. Leen los
recursos con `IRegistry(address(registry)).getItem(id)`: a través de la interfaz, como lo
hará otro contrato.

## Requisitos

1. **Nombres y tasa** de tu dominio, los de la semana 07.
2. **`Owned`**: `onlyOwner` revierte con `NotOwner(msg.sender)` si quien llama no es
   `OWNER`.
3. **`Openable is Owned`**: `whenOpen` revierte con `RegistryClosed()` si está cerrado;
   `setOpen(open)`, solo el dueño, guarda y emite `OpenChanged(open)`.
4. **`LabelLib.isValid(label)`**: `true` si la etiqueta tiene entre 1 y `MAX_LENGTH`
   bytes.
5. **`IRegistry`** declara las siete funciones de quien registra: `register`,
   `registerBatch`, `retire`, `getItem`, `idsOf`, `remaining` e `isFull`. Ni `setOpen` ni
   `withdrawFees`, que son del dueño.
6. **`contract Registry is IERC165, IRegistry, Openable`**, sin nada repetido: lo que
   declaran las piezas se borra de `Registry.sol`. Quedan en `Registry` solo sus propias
   cosas: nombres, `MAX_BATCH`, `REGISTRATION_FEE`, `CAPACITY`, contadores, mappings,
   `FeesWithdrawn`, los cuatro errores del dueño y el constructor (que ya no asigna
   `OWNER` ni `isOpen`: lo hacen los constructores de las piezas).
7. **`_register`** valida con `label.isValid()` (`using LabelLib for string;`), y
   `MAX_LABEL_LENGTH` vale `LabelLib.MAX_LENGTH`.
8. **`supportsInterface`**: `true` para `type(IRegistry).interfaceId` y
   `type(IERC165).interfaceId`, `false` para el resto.
9. **NatSpec**: en las funciones que implementan una interfaz, `/// @inheritdoc IRegistry`
   (o `IERC165`) copia la documentación de la interfaz en vez de repetirla. El resto de
   funciones `external`, con su `@notice` y `@param`.
10. **Desplegado en anvil** desde la cuenta de tu `INDEX`, con las llamadas de abajo.

### Un orden que funciona

Haz el refactor a pasos cortos y ejecuta `forge test` después de cada uno: si algo deja de
pasar, sabes qué paso lo rompió.

1. Las piezas sueltas: `Owned`, `Openable`, `LabelLib`. Los tests con `Harness` pasan a
   verde; `Registry` todavía no las usa.
2. Las seis firmas que faltan en `IRegistry`: verde
   `test_InterfaceDeclaresTheRegistryFunctions`.
3. La herencia: añade los `import` y `is IERC165, IRegistry, Openable`. `forge build` da
   una lista larga de errores, casi todos `Error (9097): Identifier already declared.`:
   bórralos uno a uno hasta que compile. Los 37 de la semana 07 tienen que seguir en verde.
4. `LabelLib` en `_register`, y `supportsInterface`.

## Cómo verificar

```bash
forge test
```

**Verifica**: cuarenta y cuatro `[PASS]` y
`44 tests passed, 0 failed, 0 skipped (44 total tests)`, sin warnings.

El identificador de `IRegistry` no depende de tu dominio, solo de las siete firmas. Es el
XOR de sus selectores:

```bash
cast sig "register(string)"
cast sig "registerBatch(string[])"
cast sig "retire(uint256)"
cast sig "getItem(uint256)"
cast sig "idsOf(address)"
cast sig "remaining()"
cast sig "isFull()"
```

```
0xf2c298be
0xd0b5a8a6
0x3790cf57
0x3129e773
0x7df3a07f
0x55234ec0
0xbabd3d9a
```

Los siete XOR dan `0xb6a3cb19`. Con solo `getItem`, como en el starter, el identificador
sería `0x3129e773`: eso es lo que te dice el test en rojo.

Después, despliega y prueba en anvil. Con `anvil --silent &` en marcha y la clave de tu
`INDEX` (aquí `3`, capacidad `50` y tasa `0.01 ether`, los de los ejemplos):

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 3)
forge create src/Registry.sol:Registry --private-key "$PK" --broadcast --constructor-args 50
```

```
Deployer: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
Deployed to: 0x057ef64E23666F000b34aE31332854aCBd1c8544
Transaction hash: 0x5936fafc052bdceae8280d40ebabf1cd00223a7c0e0bb1a0d45f0e5bee2ae556
```

Una sola dirección: las piezas heredadas y la librería van dentro. El hash cambia con tu
código, tus nombres, tu tasa y tu capacidad. Registra uno y pregunta por las interfaces:

```bash
REGISTRY=0x057ef64E23666F000b34aE31332854aCBd1c8544   # tu "Deployed to"
cast send "$REGISTRY" "register(string)" "north" --value 0.01ether --private-key "$PK"
cast call "$REGISTRY" "supportsInterface(bytes4)(bool)" 0xb6a3cb19
cast call "$REGISTRY" "supportsInterface(bytes4)(bool)" 0x01ffc9a7
cast call "$REGISTRY" "supportsInterface(bytes4)(bool)" 0xffffffff
```

Un recibo con `status 1 (success)` y:

```
true
true
false
```

Ahora un error de cada pieza. La librería, con una etiqueta vacía:

```bash
cast send "$REGISTRY" "register(string)" "" --value 0.01ether --private-key "$PK"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x3d36cb8d, data: "0x3d36cb8d": InvalidLabel
```

`Owned`, con la cuenta del `INDEX` siguiente al tuyo intentando cerrar:

```bash
PK_OTHER=$(cast wallet private-key "test test test test test test test test test test test junk" 4)
cast send "$REGISTRY" "setOpen(bool)" false --private-key "$PK_OTHER"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x245aecd3: 00000000000000000000000015d34aaf54267db7d7c367839aaf71a00a2c6a65, data: "0x245aecd300000000000000000000000015d34aaf54267db7d7c367839aaf71a00a2c6a65": NotOwner(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65)
```

`Openable`: cierra tú y vuelve a registrar:

```bash
cast send "$REGISTRY" "setOpen(bool)" false --private-key "$PK"
cast send "$REGISTRY" "register(string)" "south" --value 0.01ether --private-key "$PK"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x3dc4deb2, data: "0x3dc4deb2": RegistryClosed
```

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna, para que veas qué pieza reutilizaría otro
contrato del mismo protocolo:

| Dominio | Otro contrato del protocolo | Qué piezas reutiliza |
| ------- | --------------------------- | -------------------- |
| Biblioteca | Un contrato de préstamos | `Openable` (cerrar préstamos en vacaciones) y `IRegistry` (comprobar que el libro existe) |
| Tienda en línea | Un contrato de reseñas | `LabelLib` (títulos de reseña) e `IRegistry` (solo se reseñan productos activos) |
| Cine | Un contrato de entradas | `Owned` (el dueño fija precios) e `IRegistry` (solo hay sesiones en salas activas) |

## Criterios de calidad (no automatizables)

- Nada repetido: ninguna declaración está a la vez en `Registry` y en una pieza.
- Cada pieza tiene sus comentarios ¿Qué? ¿Para qué? ¿Impacto? y no depende de
  `Registry`: `Owned`, `Openable` y `LabelLib` servirían en otro contrato tal cual.
- `virtual` solo donde un hijo deba sustituir algo. En este proyecto, en ningún sitio.
- Sabes explicar los riesgos que quedan: `IRegistry` y `supportsInterface` dicen qué
  promete el registro, no que cumpla las reglas (un contrato falso puede responder lo
  mismo); y quien llame al registro por su interfaz confía en esa dirección, así que debe
  saber de dónde la sacó.

## Entrega

```bash
git add week-08
git commit -m "refactor(week-08): split the registry into inherited pieces, a library and an interface"
git push -u origin week-08
```

Abre un pull request `week-08` → `main` en tu repositorio. En la descripción pega la
salida de `forge create` y de las llamadas de arriba, incluidos los tres errores.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Librerías](../2-practicas/ejercicio-03-librerias/README.md) | **Proyecto — Registro modular** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
