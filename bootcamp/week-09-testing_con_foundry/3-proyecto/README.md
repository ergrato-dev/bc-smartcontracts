# Proyecto — Registro a prueba de fuzzing

> Novena capa del protocolo de tu dominio: el registro no cambia, pero sus pruebas sí.
> Escribes siete propiedades con fuzzing, un test sobre un fork de tu despliegue en anvil y
> un `.gas-snapshot` que vigila el gas. Y compruebas que esas pruebas detectan fallos que
> los 44 tests de ejemplo dejan pasar.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados y tu proyecto de la
semana 08 en `main`.

## Capa que se añade y por qué ahora

Tu registro tiene 44 tests y `forge coverage` le da 100 % en líneas, instrucciones, ramas y
funciones. Parece terminado. Pero cada uno de esos tests prueba **un caso**: la hora es
siempre `1`, la capacidad casi siempre `3`, la cuota equivocada es `0` o `fee + 1`. Un fallo
que no se vea con esos valores pasa.

Esta semana añades lo que faltaba:

- **Siete propiedades** en `test/RegistryFuzz.t.sol`, cada una válida para cualquier
  cuenta, etiqueta, hora, capacidad o cuota.
- **Un test de fork** en `test/RegistryFork.t.sol`, contra el registro que despliegas en
  anvil, con el estado que dejas con `cast`.
- **Un `.gas-snapshot`** versionado: a partir de ahora, un cambio de gas aparece en el pull
  request.

Las semanas que vienen cambian el registro: llamadas a otros contratos (10), un token
(11), roles (13), una versión actualizable (15). Cada cambio pasará por estas pruebas.

**El dominio te lo asigna el instructor.** Usa los nombres y la tasa de tu semana 08.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-09
   ```

2. Copia el starter entero, con su `.gitignore`, en una carpeta `week-09/` (ajusta la
   ruta a donde clonaste el bootcamp). Después sustituye su `src/` por el tuyo de la
   semana 08:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-09-testing_con_foundry/3-proyecto/starter week-09
   cp week-08/src/*.sol week-09/src/
   ```

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-09
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   forge test
   ```

**Verifica**: con tu `src/`, `44 tests passed, 8 failed, 0 skipped (52 total tests)`:
pasan los 44 de la semana 08 y fallan los 8 tests nuevos, cada uno con su `TODO`. (Con el
`src/` del starter, que tiene los nombres vacíos, falla además `test_NamesAreSet`: 43 y 9.)
Los warnings `(5667)` y `(2018)` son de los parámetros que aún no usas.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml` | Configuración del bootcamp. No lo cambies |
| `.gitignore` | Deja fuera de git `out/` y `cache/` |
| `src/*.sol` | El registro modular de la semana 08 resuelto, con los nombres vacíos. Sustitúyelo por el tuyo |
| `test/Registry.t.sol` | Los 44 tests de la semana 08, sin cambios. **No lo modifiques** |
| `test/RegistryFuzz.t.sol` | Las siete propiedades, con la firma, la descripción y una pista. Aquí trabajas |
| `test/RegistryFork.t.sol` | El test de fork, con su descripción. Aquí trabajas |

Las firmas de los tests no se cambian: el nombre y los parámetros son parte del contrato
del proyecto. El cuerpo es tuyo.

## Requisitos

1. **Las siete propiedades** de `RegistryFuzz.t.sol`, cada una con lo que dice su
   `// TODO:`:

   | Test | Propiedad |
   | ---- | --------- |
   | `testFuzz_RegisterStoresItem` | Cualquier cuenta, etiqueta válida y hora: el recurso se guarda con su registrante, su etiqueta, `registeredAt` igual a la hora y estado `Active` |
   | `testFuzz_RevertWhen_LabelTooLong` | Toda etiqueta de `MAX_LABEL_LENGTH + 1` a 1000 bytes revierte con `InvalidLabel` |
   | `testFuzz_RevertWhen_FeeIsWrong` | Cualquier cuota de 0 a 100 ether distinta de la tasa revierte con `WrongFee(fee, sent)` |
   | `testFuzz_RevertWhen_BatchFeeIsWrong` | En un lote, cualquier cuota distinta de `amount * fee`, de menos o de más, revierte con `WrongFee` |
   | `testFuzz_RevertWhen_StrangerRetires` | Nadie más que quien registró puede retirar: `NotRegistrant(stranger, id)` |
   | `testFuzz_NeverExceedsCapacity` | Con cualquier capacidad de 1 a 50, el registro se llena justo en ella y el siguiente revierte con `RegistryFull` |
   | `testFuzz_WithdrawSendsAllFees` | El dueño retira y `to` recibe exactamente lo cobrado; el registro queda a 0 |

2. **Entradas con sentido**: `bound` para rangos, `vm.assume` solo para excluir valores
   concretos, y cada exclusión justificada (teoría 03). Ninguna propiedad pierde tantas
   entradas que el fuzzer se rinda.
3. **El test de fork** `test_Fork_RegistersOnACopy`: sin `FORK_URL` se salta; con ella,
   abre el fork de anvil, toma el registro de la variable `REGISTRY` y comprueba lo que dice
   su `// TODO:`.
4. **`.gas-snapshot`** generado con `forge snapshot --fuzz-seed 1`, versionado, y
   `forge snapshot --fuzz-seed 1 --check` en verde.
5. **Los dos mutantes** de abajo detectados por tus propiedades.
6. **Desplegado en anvil** desde la cuenta de tu `INDEX`, con un recurso registrado, y el
   test de fork pasando contra ese despliegue.

## Cómo verificar

```bash
forge test
```

**Verifica**: `51 tests passed, 0 failed, 1 skipped (52 total tests)`, sin warnings. El
saltado es el de fork, porque no hay `FORK_URL`. Repite `forge test` dos o tres veces:
cada ejecución prueba entradas distintas y todas tienen que pasar.

### El gas, en un archivo

```bash
forge snapshot --fuzz-seed 1
forge snapshot --fuzz-seed 1 --check
```

`.gas-snapshot` tiene 52 líneas, una por test. Las de ejemplo guardan el gas del test; las
de fuzz, sus `runs` y el gas medio y mediano; la de fork, `(gas: 0)`, porque se saltó. Por
ejemplo:

```
RegistryFuzzTest:testFuzz_RegisterStoresItem(address,string,uint256) (runs: 256, μ: 251607, ~: 250449)
RegistryTest:test_RegisterStoresItem() (gas: 246216)
```

Tus números dependen de tu código. Lo que importa es que `--check` termine sin listar
diferencias: la semilla fija hace que se repitan.

### ¿Detectan fallos tus propiedades?

Una prueba vale lo que los fallos que detecta. Introduce a propósito estos dos fallos
(**mutantes**, *mutants*) en `src/Registry.sol`, uno cada vez. Antes de cada uno, borra
los fallos guardados (`rm -rf cache/fuzz`), para que forge no repita los del anterior.

**Mutante 1.** En `_register`, guarda el número de bloque en vez de la hora:

```solidity
registeredAt: block.number,
```

```bash
rm -rf cache/fuzz
forge test --fuzz-seed 1
```

`Suite result: ok. 44 passed` en `RegistryTest`: los 44 de ejemplo no lo ven, porque en el
test el bloque y la hora valen los dos `1`. Tu propiedad sí:

```
[FAIL: assertion failed: 1 != 6655684206567237786; counterexample: … ] testFuzz_RegisterStoresItem(address,string,uint256) …
Ran 3 test suites …: 50 tests passed, 1 failed, 1 skipped (52 total tests)
```

(La línea está recortada; el valor del contraejemplo depende de tu código.) Deshaz el
cambio.

**Mutante 2.** En `registerBatch`, acepta pagos de más:

```solidity
if (msg.value < fee) revert WrongFee(fee, msg.value);
```

```bash
rm -rf cache/fuzz
forge test --fuzz-seed 1
```

De nuevo `44 passed` en los de ejemplo, que solo prueban un lote pagado de menos. Y:

```
[FAIL: next call did not revert as expected; counterexample: … ] testFuzz_RevertWhen_BatchFeeIsWrong(uint256,uint256) …
Ran 3 test suites …: 50 tests passed, 1 failed, 1 skipped (52 total tests)
```

Deshaz el cambio. Si alguno de los dos mutantes pasa tus tests, a tu propiedad le falta
algo: revisa qué comprueba y con qué rango.

### En anvil, y sobre su fork

Con `anvil --silent &` en marcha y la clave de tu `INDEX` (aquí `3`, capacidad `50` y
tasa `0.01 ether`, los de los ejemplos):

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 3)
forge create src/Registry.sol:Registry --private-key "$PK" --broadcast --constructor-args 50
```

```
Deployer: 0x90F79bf6EB2c4f870365E785982E1f101E93b906
Deployed to: 0x057ef64E23666F000b34aE31332854aCBd1c8544
Transaction hash: 0xdac19a07ba30b9154998371ce85500064c9fa51a8d686e576feb95b181ddd8e7
```

Con un anvil recién arrancado, la dirección es la de la semana 08: depende solo de la
cuenta y de su nonce. El hash cambia
con tu código, tus nombres, tu tasa y tu capacidad. Registra uno y ejecuta el test de fork:

```bash
REGISTRY=0x057ef64E23666F000b34aE31332854aCBd1c8544   # tu "Deployed to"
cast send "$REGISTRY" "register(string)" "north" --value 0.01ether --private-key "$PK"
FORK_URL=http://127.0.0.1:8545 REGISTRY="$REGISTRY" forge test --match-path test/RegistryFork.t.sol
cast call "$REGISTRY" "count()(uint256)"
```

Un recibo con `status 1 (success)`, `[PASS] test_Fork_RegistersOnACopy()` y `1`: en la
copia se registraron dos recursos, en anvil sigue habiendo uno.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna, con una propiedad propia que añadirían
además de las siete:

| Dominio | Propiedad extra |
| ------- | --------------- |
| Biblioteca | Con cualquier número de socios registrando a la vez, ningún socio ve en `idsOf` un libro que registró otro |
| Tienda en línea | Tras cualquier lote de productos, `count` sube exactamente lo que mide el lote y `remaining` baja lo mismo |
| Cine | Una sala retirada no vuelve a estar activa, se intente lo que se intente después con ella |

## Criterios de calidad (no automatizables)

- Cada propiedad dice algo que vale para cualquier entrada válida y no repite la fórmula
  del contrato.
- Los rangos de `bound` son los que el contrato admite, no los que hacen pasar el test. Un
  comentario explica cada `vm.assume`.
- Los nombres de las cuentas (`makeAddr("alice")`) y de los tests se leen en la salida sin
  abrir el código.
- Sabes explicar los límites que quedan: 256 entradas no son una demostración; un fuzz test
  de una llamada no prueba secuencias (semana 24); y el test de fork confía en el nodo y en
  la dirección que le das.

## Entrega

```bash
git add week-09
git commit -m "test(week-09): add fuzz properties, a fork test and a gas snapshot"
git push -u origin week-09
```

Abre un pull request `week-09` → `main` en tu repositorio. En la descripción pega la
salida de `forge test`, la de los dos mutantes y la del test de fork.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Forks, gas y cobertura](../2-practicas/ejercicio-03-forks-gas-y-cobertura/README.md) | **Proyecto — Registro a prueba de fuzzing** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
