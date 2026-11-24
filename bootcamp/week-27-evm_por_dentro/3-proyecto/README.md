# Proyecto — Mapa de storage

> Abres la fase de EVM avanzada con un test que ningún test anterior podía escribir: el mapa de
> storage de tu protocolo, leído slot a slot del proxy ya usado. Si una versión futura mueve una
> variable, este test se pone en rojo antes de que la actualización llegue a la red.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 26 en
`main`.

## Capa que se añade y por qué ahora

Tu registro vive detrás de un proxy UUPS desde la semana 15, y ha pasado por tres versiones. Cada
actualización cambió el código y dejó el storage donde estaba: el proxy guarda los datos y la
implementación nueva los lee **por posición**, no por nombre. Si `RegistryV4` inserta una
variable antes de `maxPerAccount`, la versión nueva lee `maxPerAccount` del slot de otra variable
(teoría 03, "Mover el storage de un proxy").

Tus tests de comportamiento no lo ven: cada uno despliega un proxy nuevo con la versión nueva, y
en un proxy nuevo todo está en su sitio. `mutants.sh` lo demuestra: los dos mutantes nuevos de esta
semana mueven el storage y sobreviven a los 31 tests que ya tenías.

Esta semana sabes calcular el slot de cada dato. Con eso escribes `test/evm/StorageMap.t.sol`: lee
cada variable con `vm.load` en el slot que calculas tú y la compara con su getter. Es la prueba
que respalda la línea "las variables nuevas van siempre al final" de tu informe.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-27
   ```

2. Copia el starter en `week-27/` y pon encima tus contratos, tus pruebas y tu informe de la
   semana 26:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-27-evm_por_dentro/3-proyecto/starter week-27
   cp -r week-26/contracts/src week-26/contracts/script week-27/contracts/
   cp -r week-26/contracts/test/invariant week-26/contracts/test/formal week-26/contracts/test/audit week-27/contracts/test/
   cp week-26/detectors/unpaused_register.py week-27/detectors/
   cp -r week-26/audit week-27/
   ls -l week-27/contracts/lib
   ```

   **Verifica**: `lib -> /opt/lib`. Tus `src/`, `script/`, `test/invariant/`, `test/formal/`,
   `test/audit/` y tu detector son los de la semana 26, y `week-27/audit/README.md`, tu informe.

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-27
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   cd contracts
   forge test
   ```

**Verifica**: `31 tests passed, 5 failed`. Los cinco de `test/evm/StorageMap.t.sol`, cada uno con
su `TODO`.

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/`, `contracts/script/`, `contracts/test/` (salvo `evm/`) | Los de la solución de la semana 26: tu referencia. Tú usas los tuyos |
| `contracts/test/evm/StorageMap.t.sol` | **Tu trabajo**: el mapa de storage. `setUp`, `_word` y `_namespace` hechos; cinco tests con su `// TODO` |
| `check-report.sh` | El de la semana 26. **No lo modifiques** |
| `mutants.sh` | Los doce mutantes de la semana 26 y dos nuevos que mueven el storage. **No lo modifiques** |
| `test.sh` | `check-report.sh` primero y después todo lo de la semana 26, con `test/evm` |
| `detectors/` | El detector de la semana 23; pon encima el tuyo |

El `setUp` despliega el protocolo con los scripts de las semanas 16 a 20, lo actualiza a V2 y a
V3, da `PAUSER_ROLE` a `pauser` y hace dos altas de `alice`: `"ajedrez"` y
`"un nombre de treinta y dos bytes"`, una etiqueta corta y una de exactamente 32 bytes. `_word(n)`
lee el slot `n` del **proxy** como `uint256`.

## El mapa

Empieza por el layout que da el compilador, dentro de `contracts/`:

```bash
forge inspect RegistryV3 storageLayout
```

Con la solución de referencia, las variables propias del registro ocupan los slots 0 a 11:

| Slot | Variable | Versión |
| ---- | -------- | ------- |
| 0 | `capacity` | V1 |
| 1 | `loyalty` | V1 |
| 2 | `certificate` | V1 |
| 3 | `count` | V1 |
| 4 | `activeCount` | V1 |
| 5 | `_items` | V1 |
| 6 | `_idsOf` | V1 |
| 7 | `hook` | V1 |
| 8 | `maxPerAccount` | V2 |
| 9 | `priceFeed` | V3 |
| 10 | `usdFee` | V3 |
| 11 | `maxPriceAge` | V3 |

Las de OpenZeppelin (`Initializable`, `AccessControl`, `Pausable`, `EIP712`, `Nonces`) no están en
esos slots: cada una vive en su espacio de nombres ERC-7201, con números de 77 cifras. Si tu
protocolo tiene más variables o están en otro orden, **tu** tabla es la de tu `forge inspect`, y los
números de tus tests, los tuyos.

## Los tests del mapa

| # | Test | Qué comprueba |
| - | ---- | ------------- |
| 1 | `test_ImplementationAtEip1967Slot` | El proxy guarda la dirección de V3 en el slot de ERC-1967 (semana 15), y esa implementación dice que es la versión 3 |
| 2 | `test_StateVariablesAtTheirSlots` | Cada variable de la tabla, en su slot, con el valor de su getter y el que pone el `setUp` |
| 3 | `test_ItemAtMappingSlot` | Un `Item` del mapping `_items`: sus cuatro slots, el `status` empaquetado junto a `registrant`, una etiqueta corta y una larga |
| 4 | `test_IdsOfAtArraySlot` | El array dinámico `_idsOf[alice]`: su longitud y cada elemento |
| 5 | `test_RolesAndPauseInNamespacedStorage` | Los roles de `AccessControl` y la pausa de `Pausable`, en sus espacios de nombres ERC-7201, antes y después de `pause()` |

Pistas, todas de la teoría 03:

- Una dirección son los 20 bytes bajos de su slot: `address(uint160(_word(n)))`. Un campo
  empaquetado se saca con un desplazamiento: el `status` está en el byte 20, `uint8(w >> 160)`.
- El valor de `mapping[k]` empieza en `keccak256(abi.encode(k, slot))`. Los campos de un struct
  van seguidos a partir de ahí, cada uno en el slot siguiente salvo los que se empaquetan.
- Un string de 31 bytes o menos va en su slot, alineado a la izquierda, con la longitud por 2 en el
  último byte. Uno de 32 o más guarda `longitud * 2 + 1` y sus datos empiezan en
  `keccak256(abi.encode(slot))`. Por eso la segunda etiqueta tiene 32 bytes: es la más corta que
  ya es larga.
- Un array dinámico guarda su longitud en el slot y sus elementos desde `keccak256(abi.encode(slot))`.
- `RoleData` es un struct con un mapping (`hasRole`) en su primer slot y `adminRole` en el segundo.
  Un mapping dentro de un mapping: `keccak256(abi.encode(cuenta, slotDelRoleData))`.

## El informe

Añade a `week-27/audit/README.md`, después de la sección de la semana 26, una sección
`## Mapa de storage` con tu tabla de slots y, para cada fila, el test que la comprueba. En la
revisión de correcciones, el hallazgo de centralización sigue **Reconocido**: esta semana no cambia
tus contratos.

## Cómo verificar

```bash
bash test.sh
```

**Verifica**, en este orden:

- `✅ informe: secciones, commit, hallazgos y N pruebas citadas`. Con la solución de referencia,
  N es 27.
- `36 tests passed, 0 failed`.
- Halmos: `Symbolic test result: 5 passed; 0 failed`.
- `forge lint` sin avisos y Slither con `0 result(s) found`.
- `2 passed` en los tests del detector.
- Medusa: `Test summary: 13 test(s) passed, 0 test(s) failed`.
- `mutants.sh`, los catorce muertos. Los dos últimos los matan tus tests del mapa:

  ```text
  ✅ V2 mete una variable antes de maxPerAccount: muerto
  ✅ el struct Item cambia de orden: muerto
  ```

  Si `el struct Item cambia de orden` sobrevive, `test_ItemAtMappingSlot` no comprueba en qué slot
  y en qué byte está `status`.

`test.sh` tarda unos cuatro minutos.

## Ejemplos de adaptación

| Dominio | Lo que el mapa tiene que cubrir |
| ------- | ------------------------------- |
| Biblioteca | Un struct `Book` con `isbn` (`bytes13`) empaquetado junto al prestatario: el ISBN en sus bytes exactos |
| Tienda en línea | Un mapping anidado `stock[tienda][producto]`: dos `keccak256` encadenados, como `hasRole` |
| Cine | Un array de asientos por sesión, `seats[sessionId]`: un mapping de arrays, como `_idsOf` |

## Criterios de calidad (no automatizables)

- Cada slot del test sale de una cuenta escrita en el código (`keccak256(abi.encode(...))`), no de
  un número copiado de una traza.
- Cada variable de tu `forge inspect` tiene su comprobación, también las que añadiste tú.
- Los valores esperados vienen del `setUp`, no solo del getter: un getter y un slot pueden estar
  mal los dos a la vez.
- La sección del informe dice qué pasa si alguien mueve una variable y qué test lo detecta.

## Entrega

1. `bash test.sh` acaba sin error: informe, tests, specs, `forge lint`, Slither, detector, Medusa
   y los catorce mutantes.
2. `week-27/audit/README.md` con la sección `## Mapa de storage`.
3. Commit y pull request:

   ```bash
   git add week-27
   git commit -m "test(week-27): add storage map of the registry proxy"
   git push -u origin week-27
   ```

   Abre el pull request `week-27` → `main` y fusiónalo cuando esté en verde.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Calldata y memoria](../2-practicas/ejercicio-03-calldata-y-memoria/README.md) | **Proyecto — Mapa de storage** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
