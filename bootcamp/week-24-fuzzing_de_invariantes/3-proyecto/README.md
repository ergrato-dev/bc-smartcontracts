# Proyecto — Invariantes de tu protocolo

> Escribes las invariantes de tu protocolo y el handler que las pone a prueba, las ejecutas con
> forge y con Medusa, y compruebas con mutantes que de verdad atrapan fallos. Añades al informe
> qué invariantes tiene la suite, qué fallos mata y qué no prueba.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 23 en
`main`.

## Capa que se añade y por qué ahora

Las semanas 21 a 23 revisaron tu protocolo a mano, con ataques escritos uno a uno y con
analizadores que buscan patrones. Ninguna de las tres prueba secuencias que nadie pensó. Esta
semana añade una suite que genera cientos de miles de llamadas en cada `test.sh` y comprueba,
tras cada una, lo que tu protocolo promete: que no hay más activos que capacidad, que el ETH
cuadra, que los puntos cuadran, que el límite por cuenta se respeta.

Un protocolo ya revisado probablemente no falle. Por eso la suite viene con su propia prueba: los
mutantes de `mutants.sh`, cuatro fallos que la suite tiene que atrapar.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-24
   ```

2. Copia el starter en `week-24/` y pon encima tus contratos, tu detector y tu informe de la
   semana 23:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-24-fuzzing_de_invariantes/3-proyecto/starter week-24
   cp -r week-23/contracts/src week-23/contracts/script week-24/contracts/
   cp week-23/detectors/unpaused_register.py week-24/detectors/
   cp -r week-23/audit week-24/
   ls -l week-24/contracts/lib
   ```

   **Verifica**: `lib -> /opt/lib`. Tus `src/`, `script/` y tu detector son los de la semana 23,
   y `week-24/audit/README.md`, tu informe.

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-24
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   bash test.sh
   ```

**Verifica**: `test.sh` se para en `forge test`: `26 tests passed, 1 failed`. Los 26 son los de
las semanas 20 a 23; el que falla es `RegistryInvariantsTest`, con cinco de sus seis invariantes
en `[FAIL: assertion failed]`. La sexta, `invariant_ActiveWithinCapacity`, ya está hecha.

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/`, `contracts/script/` | Los de la solución de la semana 23: tu referencia. Tú usas los tuyos |
| `contracts/test/invariant/RegistryHandler.sol` | **Tu trabajo**: el handler. El despliegue y tres acciones hechas; cuatro con su `// TODO` |
| `contracts/test/invariant/RegistryProperties.sol` | **Tu trabajo**: las seis invariantes como `property_`. Una hecha; cinco con su `// TODO` |
| `contracts/test/invariant/RegistryInvariants.t.sol` | Comprueba cada `property_` con forge, con `fail-on-revert`. **No lo modifiques** |
| `contracts/medusa.json` | La campaña de Medusa: 100 000 llamadas o 300 segundos. **No lo modifiques** |
| `contracts/foundry.toml` | Con `dynamic_test_linking = false` para Medusa (teoría 04) |
| `contracts/test/ClassicAttacks.t.sol` | Con un cambio: `test_RevertWhen_StrangerCallsPrivileged` despliega la implementación antes del `expectRevert`, porque sin enlazado dinámico el `new` contaba como la llamada esperada |
| `contracts/test/` (el resto) | Los tests de las semanas 20 a 23 |
| `detectors/` | El detector de la semana 23; pon encima el tuyo |
| `mutants.sh` | Cuatro mutantes que la suite tiene que matar. **No lo modifiques** |
| `test.sh` | Lo de la semana 23, más Medusa y `mutants.sh` |

## El handler

`RegistryHandler` despliega en su constructor el protocolo entero, como `DeployProtocol` y las
dos actualizaciones, pero sin los cheatcodes que Medusa no tiene (teoría 04). Queda en V3 con
capacidad 10, 5 altas por cuenta, la tasa en dólares de un price feed de prueba y un tesorero.
Las cuentas son tres: `0xA11CE`, `0xB0B` y `0xCA401`.

Ya están hechas, como modelo:

| Acción | Qué hace |
| ------ | -------- |
| `register(actorSeed, overpay)` | Un alta en ETH con hasta 1 ETH de más. Se intenta aunque el registro deba rechazarla, y `assert(accepted == allowed)` |
| `withdrawFees()` | El tesorero se lleva todo; suma a `ghostFeesWithdrawn` |
| `setPrice(price)` | El precio de ETH, entre 1000 y 5000 dólares |

Fíjate en `register`: calcula con `_canRegister` si el registro debe aceptar el alta, la intenta
dentro de un `try`, compara, y suma a `ghostFeesPaid` solo si salió bien. Y en `_fund`: da el ETH
a la cuenta y también al handler, porque con `vm.prank` Medusa paga el `value` desde el handler.

Las cuatro que escribes:

| # | Acción | Qué hace |
| - | ------ | -------- |
| 1 | `registerBatch(actorSeed, amount, overpay)` | Como `register`, con un lote de 1 a `MAX_BATCH` altas y la tasa de todas |
| 2 | `registerWithPoints(actorSeed)` | Aprueba `POINTS_PRICE` y llama a `registerWithPoints`. Debe aceptarse si hay sitio y la cuenta tiene los puntos. Suma a `ghostPointsRegistrations` |
| 3 | `retire(idSeed)` | Un id entre 1 y `count`; si está activo, lo retira quien tiene su certificado. Suma a `ghostRetired` |
| 4 | `transferCertificate(toSeed, idSeed)` | Pasa el certificado de un id a una de las tres cuentas |

Con `fail-on-revert`, ninguna acción puede revertir fuera de su `try`: si `retire` intenta un
recurso ya retirado, el test falla.

## Las invariantes

| # | `property_` | Qué dice |
| - | ----------- | -------- |
| — | `activeWithinCapacity` | `activeCount <= capacity`. Hecha |
| 5 | `activeMatchesRetired` | `activeCount == count − ghostRetired` |
| 6 | `certificatesMatchCount` | Los certificados de las tres cuentas suman `count` |
| 7 | `feesAccounted` | El saldo del registro es `ghostFeesPaid − ghostFeesWithdrawn`: lo pagado de más se devuelve |
| 8 | `pointsAccounted` | `loyalty.totalSupply() == REWARD * count − POINTS_PRICE * ghostPointsRegistrations` |
| 9 | `perAccountLimit` | Ninguna cuenta tiene más de `maxPerAccount` altas (`idsOf`) |

Si tu protocolo tiene reglas propias de tu dominio (otro tope, otra moneda, otro tipo de alta),
añade su acción y su invariante.

## Cómo verificar

```bash
bash test.sh
```

**Verifica**, en este orden:

- `27 tests passed`; `RegistryInvariantsTest` con las seis en `[PASS]` y
  `(runs: 256, calls: 128000, reverts: 0)`. Mira la tabla: las siete acciones, con 0 reverts.
- `forge lint` sin avisos y Slither con `0 result(s) found`: los tests no cuentan para ninguno de
  los dos, pero `src/` tiene que seguir igual.
- `2 passed` en los tests del detector.
- Medusa: `Test summary: 13 test(s) passed, 0 test(s) failed`, en unos 30 segundos.
- `mutants.sh`, los cuatro muertos:

  ```text
  ✅ retire no resta el activo: muerto
  ✅ no se devuelve lo pagado de más: muerto
  ✅ el alta con puntos no quema: muerto
  ✅ una alta de más por cuenta: muerto
  ```

`test.sh` tarda unos dos minutos y medio. Un mutante que sobrevive dice qué invariante o qué
acción te falta: `retire no resta el activo` sobrevive si `retire` no hace nada o si
`activeMatchesRetired` no compara con `ghostRetired`. Si un mutante dice que la expresión no
cambia el archivo, tu línea es distinta de la de la solución de referencia: compárala, no
modifiques `mutants.sh`.

## El informe de auditoría

Añade a `week-24/audit/README.md`, antes de `## Hallazgos`:

1. **Las invariantes**, una por fila, con lo que dicen.
2. **Las campañas**: motor, versión, configuración y resultado.
3. **Los mutantes** y qué invariante mata cada uno.
4. **Lo que la suite no prueba**: las acciones que el handler no tiene, las cuentas que no usa,
   lo que forge no puede hacer sin mover el reloj.

```markdown
## Fuzzing de invariantes (semana 24)

| Invariante | Qué dice |
| ---------- | -------- |
| `activeWithinCapacity` | `activeCount <= capacity` |
| ... | ... |

| Motor | Versión | Campaña | Resultado |
| ----- | ------- | ------- | --------- |
| forge (`invariant_`) | Foundry v1.9.0 | 256 secuencias de 500 llamadas, `fail-on-revert` | ... |
| Medusa | 1.5.0 | `testLimit` 100 000, 4 workers | ... |

| Mutante (`mutants.sh`) | Lo mata |
| ---------------------- | ------- |
| `retire` no resta `activeCount` | `activeMatchesRetired` |
| ... | ... |

Lo que esta suite **no** prueba: ...
```

Si la suite encuentra un fallo en tu protocolo, es un hallazgo: H-04, con el formato de los
anteriores, su secuencia encogida como prueba y su corrección. Si no encuentra ninguno, escríbelo
así: "sin hallazgos nuevos", con lo que sí se probó.

## Ejemplos de adaptación

| Dominio | Una invariante propia |
| ------- | --------------------- |
| Biblioteca | Ningún socio tiene prestados más libros que su límite, y cada libro prestado tiene un único socio |
| Tienda en línea | El saldo de cada tienda es lo vendido menos lo retirado, y la suma de saldos es el ETH del contrato |
| Cine | Ninguna sesión vende más butacas que su sala, y cada butaca vendida es de una sola entrada |

## Criterios de calidad (no automatizables)

- Cada acción se intenta también cuando el protocolo debe rechazarla, o el informe dice por qué no.
- Las variables fantasma se actualizan solo cuando la acción sale bien.
- Ninguna invariante copia el código que comprueba: dice lo que el protocolo promete.
- El informe dice qué no prueba la suite.

## Entrega

1. `bash test.sh` acaba sin error: tests e invariantes, `forge lint`, Slither, detector, Medusa y
   mutantes en verde.
2. `week-24/audit/README.md` con la sección de fuzzing.
3. Commit y pull request:

   ```bash
   git add week-24
   git commit -m "test(week-24): add invariant suite with handler, Medusa and mutants"
   git push -u origin week-24
   ```

   Abre el pull request `week-24` → `main` y fusiónalo cuando esté en verde.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Medusa](../2-practicas/ejercicio-03-medusa/README.md) | **Proyecto — Invariantes de tu protocolo** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
