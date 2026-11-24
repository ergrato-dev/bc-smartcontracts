# Proyecto — Informe de auditoría final

> Cierras la fase de seguridad: el modelo de amenazas de tu protocolo, cada amenaza con su
> prueba, los tests de las que nadie había probado, y el informe de las semanas 21 a 25 convertido
> en un informe de auditoría completo, con resumen, alcance fijado en un commit y revisión de
> correcciones.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 25 en
`main`.

## Capa que se añade y por qué ahora

Desde la semana 21, tu `audit/README.md` ha ido creciendo una sección por semana: clases de
vulnerabilidad, ataques económicos, análisis estático, invariantes, verificación formal. Cada
sección mira el código con una técnica. Ninguna mira **a quién** le confía tu protocolo cada
poder, ni qué pasa si una de esas claves cae en malas manos.

Esta semana haces el modelo de amenazas (teoría 02) y lo usas para dos cosas: encontrar lo que las
técnicas anteriores no ven, y dar a cada afirmación del informe un test que la respalda. Después
reescribes el informe con la estructura de la teoría 04. Es el documento que leerá el aprendiz que
audite tu protocolo en la semana 34.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-26
   ```

2. Copia el starter en `week-26/` y pon encima tus contratos, tus pruebas y tu informe de la
   semana 25:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-26-auditoria/3-proyecto/starter week-26
   cp -r week-25/contracts/src week-25/contracts/script week-26/contracts/
   cp -r week-25/contracts/test/invariant week-25/contracts/test/formal week-26/contracts/test/
   cp week-25/detectors/unpaused_register.py week-26/detectors/
   cp -r week-25/audit week-26/
   ls -l week-26/contracts/lib
   ```

   **Verifica**: `lib -> /opt/lib`. Tus `src/`, `script/`, `test/invariant/`, `test/formal/` y tu
   detector son los de la semana 25, y `week-26/audit/README.md`, tu informe.

3. Apunta el commit que vas a auditar: el de `main`, con la semana 25 ya fusionada.

   ```bash
   git rev-parse main
   ```

   Esos 40 caracteres van en el alcance del informe. Durante esta semana tus contratos no
   cambian: si encuentras algo que corregir, la corrección va en un commit aparte y en la revisión
   de correcciones.

4. Entra al contenedor y mira el rojo:

   ```bash
   cd week-26
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   bash test.sh
   ```

**Verifica**: `test.sh` se para en lo primero que comprueba, el informe. Con el informe de la
semana 25 de la solución de referencia:

```text
❌ falta la sección ## Resumen
❌ falta la sección ## Modelo de amenazas
❌ el alcance no fija ningún commit (hash de 40 caracteres)
```

Y `forge test`, dentro de `contracts/`, da `27 tests passed, 4 failed`: los cuatro de
`test/audit/ThreatModel.t.sol`, con su `TODO`.

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/`, `contracts/script/`, `contracts/test/` (salvo `audit/`) | Los de la solución de la semana 25: tu referencia. Tú usas los tuyos |
| `contracts/test/audit/ThreatModel.t.sol` | **Tu trabajo**: los tests de las amenazas que ningún test cubría. `setUp` y `_signOrder` hechos; cuatro tests con su `// TODO` |
| `check-report.sh` | Comprueba el informe: secciones, commit, hallazgos con estado y que cada prueba citada existe. **No lo modifiques** |
| `mutants.sh` | Los diez mutantes de la semana 25 y dos nuevos para el modelo de amenazas. **No lo modifiques** |
| `test.sh` | `check-report.sh` primero y después todo lo de la semana 25 |
| `detectors/` | El detector de la semana 23; pon encima el tuyo |

## El modelo de amenazas

Escríbelo antes de tocar ningún test, en `week-26/audit/README.md`, con las cuatro partes de la
teoría 02:

1. **Actores**: cada rol de tu protocolo (`PAUSER_ROLE`, `TREASURER_ROLE`, `DEFAULT_ADMIN_ROLE` y
   los propios de tu dominio), los usuarios, los relayers, el hook y el price feed. Para cada uno,
   qué puede hacer y cuánto se confía en él.
2. **Activos**: el ETH de las tasas, las altas y sus certificados, los puntos, la disponibilidad y
   el control del proxy.
3. **Fronteras de confianza**: dónde entra algo de fuera.
4. **Amenazas**: una tabla `Id | Amenaza | Defensa | Prueba`. En la columna **Prueba** van los
   nombres completos, entre comillas invertidas, de los tests, invariantes y specs que ya tienes
   (`test_RevertWhen_StrangerCallsPrivileged`, `check_retireOnlyByHolder`...). `check-report.sh`
   comprueba que cada nombre citado existe.

Cuando la tengas, mira qué filas se quedan sin prueba. Con la solución de referencia son cuatro, y
son los cuatro tests del starter.

## Los tests de las amenazas

| # | Test | Amenaza que prueba |
| - | ---- | ------------------ |
| 1 | `test_PauserCannotEscalate` | La clave del pauser se filtra: quien la tiene pausa, y nada más. Ni reanuda, ni cobra, ni cambia el hook, ni da roles, ni actualiza |
| 2 | `test_AdminRevokesCompromisedPauser` | El pauser comprometido deja el registro parado: el administrador le quita el rol, reanuda, y el registro vuelve a dar altas |
| 3 | `test_TreasurerCannotEscalate` | La clave del tesorero se filtra: cobra las tasas (es su trabajo) y nada más |
| 4 | `test_RevertWhen_SignedOrderFromOtherChain` | Una orden firmada para esta cadena se envía en otra: el dominio EIP-712 lleva el `chainId` y la firma no vale |

Cada error que esperas lleva la cuenta y el rol exactos: `_unauthorized(cuenta, rol)` lo construye.
Para cambiar de cadena, `vm.chainId(10)`. Si tu protocolo tiene más roles, cada uno lleva su test
de clave filtrada.

Puede que un test no pase la primera vez y el fallo esté en tu contrato, no en el test: es un
hallazgo, H-05 o el número que te toque. Escríbelo, corrígelo en un commit aparte y llévalo a la
revisión de correcciones.

## El hallazgo que no está en el código

Con el modelo de amenazas delante, fíjate en el actor de confianza total. ¿Quién tiene
`DEFAULT_ADMIN_ROLE` en tu protocolo? Mira `initialize` y tu script de despliegue. En la solución
de referencia es la cuenta que despliega, sin timelock ni multisig: una sola clave actualiza el
código en una transacción. Eso es **riesgo de centralización** (teoría 02) y se escribe como
hallazgo, aunque el código haga justo lo que dice. Su estado es **Reconocido**: en la semana 31 el
protocolo pasa a gobernarse con `Governor` y timelock. Si tu protocolo ya da el rol a un timelock o
a un multisig, la amenaza tiene defensa, y la prueba es el test que lo comprueba.

## El informe final

Reorganiza `week-26/audit/README.md` así:

1. `## Resumen`: el párrafo y la tabla de severidades con encontrados, corregidos y reconocidos.
2. `## Alcance`: contratos con sus líneas (`wc -l contracts/src/*.sol`), el commit del paso 3 y lo
   que queda fuera.
3. `## Modelo de amenazas`: lo que escribiste arriba.
4. `## Metodología`: las técnicas y herramientas, con sus versiones.
5. Las secciones de las semanas 21 a 25, tal como estaban.
6. `## Hallazgos`: la tabla y una sección `### H-NN — Título` por hallazgo, cada una con su
   `**Estado**`.
7. `## Revisión de correcciones`: para cada hallazgo, la corrección, el test que la comprueba y si
   está ya en el proxy.
8. `## Limitaciones`: qué no cubre la auditoría, incluido que la hace el propio equipo.

## Cómo verificar

```bash
bash test.sh
```

**Verifica**, en este orden:

- `✅ informe: secciones, commit, hallazgos y N pruebas citadas`. Con la solución de referencia,
  N es 27.
- `31 tests passed`.
- Halmos: `Symbolic test result: 5 passed; 0 failed`.
- `forge lint` sin avisos y Slither con `0 result(s) found`.
- `2 passed` en los tests del detector.
- Medusa: `Test summary: 13 test(s) passed, 0 test(s) failed`.
- `mutants.sh`, los doce muertos. Los dos últimos los matan tus tests del modelo de amenazas:

  ```text
  ✅ el pauser reanuda: muerto
  ✅ el pauser cobra las tasas: muerto
  ```

  Si `el pauser reanuda` sobrevive, `test_PauserCannotEscalate` no comprueba `unpause` con el rol
  exacto que falta.

`test.sh` tarda unos cuatro minutos.

## Ejemplos de adaptación

| Dominio | Una amenaza propia |
| ------- | ------------------ |
| Biblioteca | La clave de quien da de alta libros se filtra: ¿puede también prestar o cobrar multas? |
| Tienda en línea | El rol que fija precios se filtra: ¿puede bajar un precio a 0 y comprar todo el stock en el mismo bloque? |
| Cine | Una entrada firmada para una sesión se presenta en otra sesión, o en el mismo contrato desplegado en otra red |

## Criterios de calidad (no automatizables)

- Cada amenaza está escrita desde el atacante y dice qué no debe pasar, no qué hace el código.
- Cada actor de confianza parcial tiene su amenaza de clave filtrada.
- Cada severidad separa impacto y probabilidad.
- El resumen se entiende sin leer el resto del informe.
- Las limitaciones dicen qué no se revisó, sin prometer que no queden fallos.

## Entrega

1. `bash test.sh` acaba sin error: informe, tests, specs, `forge lint`, Slither, detector, Medusa
   y mutantes en verde.
2. `week-26/audit/README.md` con la estructura del informe final.
3. Commit y pull request:

   ```bash
   git add week-26
   git commit -m "docs(week-26): add threat model and final audit report"
   git push -u origin week-26
   ```

   Abre el pull request `week-26` → `main` y fusiónalo cuando esté en verde.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — CTF local](../2-practicas/ejercicio-03-ctf-local/README.md) | **Proyecto — Informe de auditoría final** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
