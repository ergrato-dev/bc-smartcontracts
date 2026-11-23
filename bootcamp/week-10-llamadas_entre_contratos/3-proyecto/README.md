# Proyecto — Registro conectado

> Décima capa del protocolo de tu dominio: el registro deja de estar solo. Avisa de cada
> alta a otro contrato, un **hook**, sin depender de él: si el hook falla o gasta todo el
> gas, el registro sigue. Y ofrece un `multicall` para hacer varias cosas en una
> transacción.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados y tu proyecto de la
semana 09 en `main`.

## Capa que se añade y por qué ahora

Hasta ahora el registro solo hablaba con quien lo llamaba. Las próximas semanas lo conectan
con otros contratos: un token de fidelidad (semana 11) que premia cada alta, un certificado
(12), un frontend que agrupa llamadas (18). Esta semana pones la pieza que lo permite, con
lo que aprendiste:

- **Un hook** (*gancho*): un contrato al que el registro avisa con
  `onItemRegistered(id, registrant, label)` después de cada alta. El dueño lo elige con
  `setHook`, que comprueba con ERC-165 que de verdad es un hook. El aviso va dentro de un
  `try` con tope de gas: un hook roto deja un evento `HookFailed`, no un registro bloqueado.
- **Un contador de puntos**, `RegistrationPoints`, como primer hook: cada alta suma 10
  puntos a quien registró, y solo el registro puede sumarlos. En la semana 11 lo sustituye
  un token ERC-20.
- **Un `multicall`** con `delegatecall` a sí mismo: retirar varios recursos, o cerrar el
  registro y cobrar las tasas, en una transacción.

**El dominio te lo asigna el instructor.** Usa los nombres y la tasa de tu semana 09.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-10
   ```

2. Copia el starter entero, con su `.gitignore`, en una carpeta `week-10/` (ajusta la ruta a
   donde clonaste el bootcamp). Después trae tus pruebas de la semana 09 y su
   `.gas-snapshot`:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-10-llamadas_entre_contratos/3-proyecto/starter week-10
   cp week-09/test/RegistryFuzz.t.sol week-09/test/RegistryFork.t.sol week-10/test/
   cp week-09/.gas-snapshot week-10/
   ```

3. En `week-10/src/Registry.sol`, pon los nombres y la tasa de tu dominio (los dos primeros
   `// TODO:`). El resto de `src/` es igual que tu semana 09: si cambiaste algo allí,
   cópialo también.

4. Entra al contenedor y mira el rojo:

   ```bash
   cd week-10
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   forge test
   ```

**Verifica**: `53 tests passed, 15 failed, 1 skipped (69 total tests)`. Pasan los 44 de
ejemplo, tus 7 propiedades y dos tests nuevos que ya se cumplen (un extraño no puede
llamar a `setHook`, y `multicall` rechaza el ETH); se salta el de fork. Fallan los 15
tests de la capa nueva, cada uno con su `TODO`.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml`, `.gitignore` | Los de siempre. No los cambies |
| `src/IRegistrationHook.sol` | La interfaz del hook. Terminada |
| `src/Registry.sol` | Tu registro, con las constantes, la variable `hook`, los eventos y los errores nuevos ya declarados, y una función por completar en cada `// TODO:` |
| `src/RegistrationPoints.sol` | El contador de puntos, con sus `// TODO:` |
| `src/` (resto) | `IRegistry`, `Owned`, `Openable`, `LabelLib` e `IERC165`, sin cambios |
| `test/Registry.t.sol` | Los 44 tests de ejemplo. **No lo modifiques** |
| `test/RegistryHook.t.sol` | 11 tests del hook y de los puntos, con tres hooks de prueba. **No lo modifiques** |
| `test/RegistryMulticall.t.sol` | 6 tests del `multicall`. **No lo modifiques** |

Encima de `multicall`, `_register` y `_notifyHook` hay comentarios
`// forge-lint: disable-next-item(...)`. Silencian avisos del linter sobre decisiones
tomadas a propósito, cada una explicada en su comentario (teoría 04). No los borres.

## Requisitos

1. **`_isHook(target)`**: `false` si `target` no tiene código. Si lo tiene, le pregunta con
   `try` y tope de `HOOK_CHECK_GAS` si soporta `type(IRegistrationHook).interfaceId`; si la
   llamada revierte (un contrato sin `supportsInterface`), `false`.
2. **`setHook(newHook)`**, solo el dueño: `ZeroAddress()` para `address(0)`,
   `InvalidHook(newHook)` si `_isHook` dice que no; si pasa, lo guarda y emite
   `HookChanged`. **`removeHook()`** vuelve a `address(0)` y emite
   `HookChanged(address(0))`.
3. **`_notifyHook(id, label)`**: sin hook, nada. Con hook, `try` a `onItemRegistered` con
   tope de `HOOK_GAS`; si revierte, `HookFailed(id, reason)`. Nunca revierte.
4. **Avisar después de registrar**: `register` avisa del recurso que acaba de registrar.
   `registerBatch` registra todo el lote y **después**, en un segundo bucle, avisa de cada
   alta: ningún hook ve un lote a medias.
5. **`multicall(calls)`**: `delegatecall` a `address(this)` con cada llamada. Si una falla,
   `CallFailed(i, reason)`; si no, guarda lo que devolvió en `results[i]`. No es `payable`.
6. **`RegistrationPoints`**: `ZeroAddress()` en el constructor si el registro es
   `address(0)`; `onItemRegistered` revierte con `NotRegistry(msg.sender)` si no llama el
   registro y si no suma `POINTS_PER_ITEM`; `supportsInterface` responde `true` para
   `IRegistrationHook` e `IERC165`.
7. **`.gas-snapshot` actualizado** y `forge snapshot --fuzz-seed 1 --check` en verde.
8. **Desplegado en anvil** desde la cuenta de tu `INDEX`: el registro, sus puntos como hook
   y un recurso registrado que sumó puntos. El test de fork pasa contra ese despliegue.

## Cómo verificar

```bash
forge test
```

**Verifica**: `68 tests passed, 0 failed, 1 skipped (69 total tests)`, sin warnings
(`forge test --deny warnings`). Fíjate en dos tests:

```bash
forge test --match-test RegisterSurvivesGasBurner -vvvv
```

```
    │   ├─ [100000] GasBurnerHook::onItemRegistered(1, alice: [0x328809Bc894f92807417D2dAD6b7C998c1aFdac6], "north")
    │   │   └─ ← [OutOfGas] EvmError: OutOfGas
```

El hook gastó exactamente `HOOK_GAS` y el registro siguió: `count()` vale 1. Y en
`test_RevertWhen_MulticallRegisters`, un `register` dentro del `multicall` revierte con
`WrongFee(fee, 0)`: sin `payable`, nadie puede pagar una vez y registrar dos.

### Lo que cuesta la capa nueva

Tu `.gas-snapshot` es el de la semana 09. Antes de regenerarlo, compáralo:

```bash
forge snapshot --fuzz-seed 1 --diff
```

Entre las líneas verás, por ejemplo:

```
↑ RegistryTest::test_RegisterStoresItem() (gas: 246216 → 248570 | 2354 0.956%)
```

Cada registro cuesta ahora unos 2 300 de gas más: leer `hook` del storage, aunque esté
vacío. Es el precio de poder conectarlo. Tus números serán otros; lo que importa es que
sabes de dónde sale la diferencia. Después regenera y comprueba:

```bash
forge snapshot --fuzz-seed 1
forge snapshot --fuzz-seed 1 --check
```

### En anvil, y sobre su fork

Con `anvil --silent &` recién arrancado y la clave de tu `INDEX` (aquí `3`, capacidad `50`
y tasa `0.01 ether`, los de los ejemplos), despliega el registro y, en la transacción
siguiente, sus puntos:

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 3)
forge create src/Registry.sol:Registry --private-key "$PK" --broadcast --constructor-args 50
REGISTRY=0x057ef64E23666F000b34aE31332854aCBd1c8544   # tu "Deployed to"
cast compute-address $(cast wallet address "$PK")
```

```
0x261D8c5e9742e6f7f1076Fa1F560894524e19cad
```

`cast compute-address` sin `--nonce` predice dónde quedará el siguiente contrato de esa
cuenta (teoría 05). Despliega los puntos y comprueba que coincide:

```bash
forge create src/RegistrationPoints.sol:RegistrationPoints --private-key "$PK" --broadcast --constructor-args $REGISTRY
POINTS=0x261D8c5e9742e6f7f1076Fa1F560894524e19cad   # tu "Deployed to"
cast send $REGISTRY "setHook(address)" $POINTS --private-key "$PK"
cast send $REGISTRY "register(string)" "north" --value 0.01ether --private-key "$PK"
cast call $POINTS "pointsOf(address)(uint256)" $(cast wallet address "$PK")
```

Dos recibos con `status 1 (success)` y `10`: el registro avisó a los puntos. Si intentas
sumarte puntos tú mismo, `cast send $POINTS "onItemRegistered(uint256,address,string)" 1 $(cast wallet address "$PK") x --private-key "$PK"`
falla con `custom error 0x631a294a`, el selector de `NotRegistry(address)`, seguido de tu
dirección.

Y el test de fork de la semana 09, sin cambios, contra este despliegue:

```bash
FORK_URL=http://127.0.0.1:8545 REGISTRY="$REGISTRY" forge test --match-path test/RegistryFork.t.sol
cast call "$REGISTRY" "count()(uint256)"
```

`[PASS] test_Fork_RegistersOnACopy()` y `1`. En la copia, el alta del test también avisó a
los puntos: el hook es parte del estado que el fork leyó de anvil.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna:

| Dominio | El hook | Un `multicall` útil |
| ------- | ------- | ------------------- |
| Biblioteca | Puntos de lector por cada libro donado | El socio retira tres libros que ya no presta |
| Tienda en línea | Puntos de cliente por cada producto publicado | El dueño cierra la tienda y cobra las tasas |
| Cine | Puntos de distribuidora por cada sala registrada | Consultar `getItem` de varias salas y `remaining` en una llamada |

## Criterios de calidad (no automatizables)

- Los avisos van **al final**, con el estado ya escrito: en `register` después de
  `_register`, y en `registerBatch` en un bucle aparte. Sabes explicar qué podría ver un
  hook si avisaras en mitad del lote.
- Sabes explicar los límites que asumes: quien envía la transacción puede darle poco gas
  para que el hook falle y el registro siga (los puntos se pierden, el registro no); un
  hook puede volver a llamar al registro; y `_isHook` revierte, en vez de devolver `false`,
  si un contrato responde a `supportsInterface` con algo que no es un `bool` (teoría 04).
- `RegistrationPoints` confía en `REGISTRY` y en nadie más: es su control de acceso.
- Cada `// forge-lint: disable-next-item` del registro tiene un comentario que explica por
  qué.

## Entrega

```bash
git add week-10
git commit -m "feat(week-10): notify a registration hook and add multicall"
git push -u origin week-10
```

Abre un pull request `week-10` → `main` en tu repositorio. En la descripción pega la salida
de `forge test`, la línea de `--diff` de un registro y los puntos que leíste en anvil.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — CREATE y CREATE2](../2-practicas/ejercicio-03-create-y-create2/README.md) | **Proyecto — Registro conectado** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
