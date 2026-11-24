# Proyecto — La entrega final

> Tu protocolo está completo: registro actualizable, puntos, certificados, vault, DAO, altas
> patrocinadas y una L2. Esta semana lo cierras. Compruebas cada despliegue con un script que solo
> lee, auditas el protocolo de otra persona y ella audita el tuyo, corriges lo que te encuentre y
> lo presentas como un proyecto de portfolio, con su versión `v1.0.0`.

**Duración estimada**: 4 h, más la auditoría cruzada repartida en la semana (ver el calendario)
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 33 en
`main`; la pareja de auditoría que te asigna el instructor.

## Capa que se añade y por qué ahora

Durante 33 semanas has añadido capas y las has probado tú. Faltan dos cosas que solo tienen
sentido al final:

- **Comprobar lo desplegado.** Tus scripts despliegan y traspasan; ninguno mira lo que dejan. Un
  despliegue malo casi nunca falla: las altas funcionan, los puntos se acuñan, y quien desplegó
  sigue de administrador sin que nada lo diga (teoría 01). `CheckDeployment.s.sol` lo comprueba
  con lecturas, en L1 y en la L2, y se ejecuta contra cualquier red.
- **Que te audite otra persona.** Tu informe de auditoría lo escribiste tú, que conoces las
  intenciones del código, y por eso ves menos lo que hace sin querer (lo dice su sección
  `## Limitaciones`). Otra persona lee el código sin esas intenciones (teoría 02). Y tú haces lo
  mismo con el suyo.

La capa tiene cuatro piezas:

- **La comprobación.** `CheckDeployment.s.sol`, con `runL1()` y `runL2()`, como el
  `CheckDeployment` del ejercicio 01 con los contratos de tu protocolo.
- **Un hallazgo de ejemplo.** H-06, el que una auditoría cruzada encontró en el protocolo de
  referencia de la semana 33: `SequencerAwareFeed` acepta un feed de disponibilidad sin inicializar.
  Tu protocolo tiene el mismo feed, así que también te afecta.
- **La auditoría cruzada.** `audit/auditoria-cruzada.md`, tu informe del protocolo de tu pareja; y
  en `audit/README.md` y `contracts/test/cross/`, los hallazgos que te lleguen, cada uno con su
  respuesta y su test.
- **La presentación.** El `README.md` de tu repositorio, una demo de diez minutos y la etiqueta
  `v1.0.0` en `main`.

Ahora es cuando tienes todo lo necesario: el protocolo entero, el informe de las semanas 21 a 33
y los tres ejercicios de esta semana, que son esto mismo en pequeño.

## El calendario de la auditoría cruzada

La auditoría cruzada necesita a otra persona y días de margen. Empiézala el primer día de la
semana, antes de nada más:

| Día | Tú | Tu pareja |
| --- | -- | --------- |
| 1 | Le envías la URL de tu repositorio, el hash del commit de `main` que audita y tu `audit/README.md` | Lo mismo contigo |
| 2-4 | Auditas su commit: lectura, PoC de cada hallazgo, `auditoria-cruzada.md` | Audita el tuyo |
| 4 | Le entregas tu informe como issue en su repositorio, con el enlace al archivo | Te entrega el suyo |
| 5 | Discutes con tu pareja las severidades, en el issue | |
| 5-7 | Corriges lo que te encontró, con un test por hallazgo, y respondes en el issue | Lo mismo |

El commit no cambia durante la auditoría: tú sigues trabajando en tu rama `week-34`, y lo que
corrijas después es lo que tu pareja revisa al final (teoría 03).

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-34
   ```

2. Copia el starter en `week-34/` y pon encima tus contratos, tus pruebas, tu gas guardado y tu
   informe de la semana 33:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-34-proyecto_integrador/3-proyecto/starter week-34
   cp -r week-33/contracts/src week-33/contracts/script week-33/contracts/snapshots week-34/contracts/
   cp -r week-33/contracts/test/invariant week-33/contracts/test/formal week-33/contracts/test/audit week-33/contracts/test/evm week-33/contracts/test/asm week-33/contracts/test/gas week-33/contracts/test/defi week-33/contracts/test/dao week-33/contracts/test/aa week-33/contracts/test/l2 week-34/contracts/test/
   cp week-33/detectors/unpaused_register.py week-34/detectors/
   cp -r week-33/audit week-34/
   cp ../bc-smartcontracts/bootcamp/week-34-proyecto_integrador/3-proyecto/starter/contracts/src/SequencerAwareFeed.sol week-34/contracts/src/
   ls -l week-34/contracts/lib week-34/contracts/script/CheckDeployment.s.sol
   ```

   **Verifica**: `lib -> /opt/lib`, y `CheckDeployment.s.sol` existe: es el del starter, porque tu
   semana 33 no lo tenía. La última copia pone encima el `SequencerAwareFeed` del starter, que es
   el tuyo de la semana 33 con el error `UptimeFeedNotStarted` declarado y un `TODO`. Si cambiaste
   algo en el tuyo, vuelve a ponerlo.

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-34
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   cd contracts
   forge test --mc 'FinalTest|ReceivedFindingsTest'
   ```

**Verifica**: `6 tests passed, 10 failed`. Pasan los dos despliegues buenos (`CheckDeployment` aún
no comprueba casi nada), el recorrido de punta a punta, H-07, el de otro vault, que mira una
conexión que el starter ya trae, y el de H-06 con el feed ya inicializado. Lo primero en rojo:

```text
[FAIL: next call did not revert as expected] test_RevertWhen_TheUptimeFeedHasNotStarted() (gas: 635001)
```

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/`, `contracts/script/`, `contracts/test/` (salvo `final/` y `cross/`) | Los de la solución de la semana 33: tu referencia. Tú usas los tuyos |
| `contracts/src/SequencerAwareFeed.sol` | El de la semana 33 con `UptimeFeedNotStarted` y su `// TODO (semana 34)` |
| `contracts/script/CheckDeployment.s.sol` | La comprobación de L1 y de la L2, con tres `// TODO (semana 34)` |
| `contracts/test/final/Final.t.sol` | Catorce tests: los dos despliegues buenos, diez estropeados, H-07 y uno de punta a punta. **No los modifiques** |
| `contracts/test/cross/ReceivedFindings.t.sol` | Los dos tests de H-06. Aquí añades los de tus hallazgos |
| `mutants.sh` | Los treinta y ocho mutantes de la semana 33 y cinco nuevos, de la entrega. **No lo modifiques** |
| `check-report.sh` | El de la semana 33, que ahora comprueba también `audit/auditoria-cruzada.md` |
| `test.sh`, `detectors/` | Los de la semana 33 |

`Final.t.sol` despliega como `OnL2.t.sol`: L1 con tus scripts hasta `HandOverToDao`, la L2 con
`DeployToL2` y el timelock de L1 como `l1Dao`. Cada test negativo estropea una sola cosa con
`vm.prank` (el timelock da un rol de más, el ejecutor pone otro feed) y espera el error que la
nombra.

## H-06: el feed sin inicializar

**Abre** `contracts/src/SequencerAwareFeed.sol` y resuelve el `TODO` de `_checkSequencer`, entre
la comprobación del estado y la del plazo de gracia:

```solidity
if (statusSince == 0) revert UptimeFeedNotStarted();
```

Es la pregunta de "Para pensar" del ejercicio 01 de la semana 33. La documentación de Chainlink
dice que en Arbitrum `startedAt` es 0 mientras el feed no está inicializado; con 0,
`block.timestamp - 0` es enorme y el plazo de gracia se da por cumplido.

**Verifica**: `forge test --mc ReceivedFindingsTest` da `2 tests passed`. Y los nueve de
`OnL2Test` siguen en verde: sus feeds sí están inicializados.

## La comprobación del registro

**Abre** `contracts/script/CheckDeployment.s.sol`. `_checkRegistry` es lo común a L1 y a la L2:
solo cambia quién tiene que ser el administrador (el timelock o el ejecutor). Sustituye su `TODO`
y la línea `(registry, admin, deployer, guardian);` por:

```solidity
if (registry.version() != VERSION) revert WrongVersion(registry.version());
bytes32 adminRole = registry.DEFAULT_ADMIN_ROLE();
if (!registry.hasRole(adminRole, admin)) revert NotAdmin(address(registry), admin);
if (registry.hasRole(adminRole, deployer)) revert DeployerStillAdmin(address(registry));
if (!registry.hasRole(registry.PAUSER_ROLE(), guardian)) revert NotPauser(guardian);
```

**Verifica**: `forge test --mc FinalTest` da `9 tests passed, 5 failed`. Quedan el timelock y la L2:

```text
[FAIL: next call did not revert as expected] test_RevertWhen_TheDeployerAdministersTheTimelock() (gas: 124025)
```

## La comprobación del timelock

**Por qué**: `HandOverToDao` crea el timelock sin administrador aparte y con el Governor como único
proponente. Si quien despliega tuviera `DEFAULT_ADMIN_ROLE` en el timelock, se daría
`PROPOSER_ROLE` y `EXECUTOR_ROLE` y cambiaría el registro sin votación. Si tuviera `PROPOSER_ROLE`,
lo mismo con dos días de espera.

**Resuelve** el `TODO` de `checkL1`:

```solidity
if (d.timelock.hasRole(d.timelock.DEFAULT_ADMIN_ROLE(), d.deployer)) {
    revert DeployerStillAdmin(address(d.timelock));
}
if (!d.timelock.hasRole(d.timelock.PROPOSER_ROLE(), address(d.governor))) {
    revert NotProposer(address(d.governor));
}
if (d.timelock.hasRole(d.timelock.PROPOSER_ROLE(), d.deployer)) revert DeployerStillProposer();
if (d.timelock.getMinDelay() < MIN_DELAY) revert DelayTooShort(d.timelock.getMinDelay());
```

**Verifica**: `12 tests passed, 2 failed`. Queda la L2:

```text
[FAIL: next call did not revert as expected] test_RevertWhen_TheExecutorObeysAnotherDao() (gas: 59537)
[FAIL: next call did not revert as expected] test_RevertWhen_TheL2ReadsTheRawFeed() (gas: 102774)
```

## La comprobación de la L2

**Resuelve** el `TODO` de `checkL2`:

```solidity
if (d.executor.l1Dao() != d.l1Dao) revert WrongWiring("executor.l1Dao", d.executor.l1Dao());
if (address(d.executor.messenger()) != address(d.messenger)) {
    revert WrongWiring("executor.messenger", address(d.executor.messenger()));
}
if (address(d.registry.priceFeed()) != address(d.feed)) {
    revert WrongWiring("registry.priceFeed", address(d.registry.priceFeed()));
}
```

**Verifica**: `forge test --mc FinalTest` da `14 tests passed`. Y `forge test`, `95 tests passed,
0 failed`: los 79 de la semana 33 y los dieciséis de esta. `test_FromAnL1RegistrationToANewL2Fee`
recorre el protocolo: carol da de alta en L1 y recibe certificado y puntos, la DAO cambia la tasa
de la L2, carol da de alta allí con la tasa nueva, y al final los dos despliegues siguen pasando
la comprobación.

`mutants.sh` busca estas líneas tal cual: si escribes la misma comprobación de otra forma, el
mutante dice "la expresión no cambia" y cuenta como superviviente.

## La auditoría cruzada

### La que haces tú

Crea `audit/auditoria-cruzada.md` en **tu** repositorio con el informe del protocolo de tu pareja,
en el formato de la teoría 02 y del ejercicio 02:

- `## Resumen`: qué es el protocolo, cuántos hallazgos por severidad y la conclusión en dos frases.
- `## Alcance`: la URL de su repositorio (`https://github.com/...`), el hash de 40 caracteres del
  commit, qué contratos entran y qué no, y cómo auditaste.
- `## Hallazgos`: una tabla con `| C-01 |`, `| C-02 |`... y, por cada uno, una sección `### C-01 — título`
  con **Severidad** (con el impacto y la probabilidad que la justifican), **Descripción**,
  **Prueba de concepto** (el test, en un bloque de código, que pasa en su commit sin cambiar su
  código) y **Recomendación**.
- Al final, cuando te responda, `## Respuesta del autor`: la severidad acordada y el estado de cada
  uno, y si comprobaste su corrección.

Los PoC los escribes en una copia de su repositorio, en una carpeta de tests propia: así los
ejecutas con su `foundry.toml` y sus scripts. En tu informe va el código; en su repositorio, si
lo acepta, el test.

`check-report.sh` comprueba las secciones, la URL, el commit y que cada `C-NN` de la tabla tenga su
sección con **Severidad** y **Prueba de concepto**. Que los hallazgos sean ciertos, no: eso lo ve
tu pareja al ejecutarlos.

Si no encuentras ningún hallazgo con impacto, el informe lo dice, con lo que revisaste y cómo. Un
informe sin hallazgos es válido; uno sin método, no. Escribe entonces al menos un hallazgo
informativo (una suposición sin escribir, un test que falta) con su PoC.

### La que recibes

Por cada hallazgo de tu pareja, en tu `audit/README.md`:

- Una fila nueva en la tabla de `## Hallazgos` (H-07, H-08... después de H-06) y su sección
  `### H-NN` con la severidad acordada, la descripción, el impacto, la prueba y el **Estado**:
  corregido, reconocido (no se corrige, y por qué) o en disputa (no estás de acuerdo, y por qué).
- Si es corregido, su test de regresión en `contracts/test/cross/ReceivedFindings.t.sol`, con el id
  en un comentario: el PoC de tu pareja con la conclusión al revés (ejercicio 03). Y una fila en
  `## Revisión de correcciones`.
- Antes de cerrarlo, revisa tu corrección como en el paso 4 del ejercicio 03: qué más hace ahora el
  código que tocaste.

H-06 es el ejemplo: ponlo con los tuyos, con sus dos tests.

## El informe

**Abre** `week-34/audit/README.md` y cierra la auditoría:

- En **Resumen**, la semana 34 y lo que encontró la auditoría cruzada; actualiza la tabla de
  severidades.
- En **Alcance**, `CheckDeployment` (sus comprobaciones son una defensa) y las líneas nuevas de
  `SequencerAwareFeed`.
- En **Amenazas**, dos filas nuevas:

  | Id | Amenaza | Defensa | Prueba |
  | -- | ------- | ------- | ------ |
  | T-30 | Un despliegue deja un rol a quien despliega, o un contrato apuntando a otro equivocado | `CheckDeployment` comprueba versión, roles y conexiones en L1 y en la L2 | `test_ChecksTheL1Deployment`, `test_ChecksTheL2Deployment`, `test_RevertWhen_TheDeployerIsStillAdminOnL1`, `test_RevertWhen_TheDeployerIsStillAdminOnL2`, `test_RevertWhen_TheL2ReadsTheRawFeed` |
  | T-31 | El feed de disponibilidad aún no tiene rondas y se toma por "en marcha" | `UptimeFeedNotStarted` con `startedAt` = 0 (H-06) | `test_RevertWhen_TheUptimeFeedHasNotStarted` |

- Una sección `## La entrega (semana 34)`, antes de `## Hallazgos`, con: qué comprueba
  `CheckDeployment` y cómo se ejecuta, qué estropea cada test, qué mutante mata cada uno, la tabla
  de la auditoría cruzada (su id, el tuyo, la severidad propuesta, la acordada y la respuesta), un
  enlace a tu `auditoria-cruzada.md` y lo que no hiciste.
- En `## Limitaciones`, lo que cambia ahora que te ha revisado otra persona, y lo que no.

## La presentación

Tu repositorio es lo que enseñarás cuando alguien te pregunte qué sabes hacer. Escribe su
`README.md` en la raíz (fuera de `week-NN/`), con:

- **Qué es**: el dominio, qué problema resuelve y para quién, en un párrafo.
- **Arquitectura**: los contratos de L1 y de la L2, quién administra cada uno y cómo se habla
  entre ellos (un SVG como los del bootcamp, o una tabla).
- **Cómo probarlo**: `bash test.sh` dentro del contenedor, y qué comprueba.
- **Despliegues**: las direcciones de Sepolia (semana 16) y de la L2 si la usaste, con enlaces a
  los exploradores y la salida de `CheckDeployment`.
- **Seguridad**: enlace al informe y a la auditoría cruzada, y los riesgos aceptados en una lista.
- **Limitaciones**: lo que no está hecho y lo que harías antes de mover dinero real.

Y prepara una demo de diez minutos para tu cohorte: el problema (1 minuto), la arquitectura (2),
un alta en vivo en anvil o en Sepolia y una propuesta de la DAO (4), y un hallazgo, el tuyo o el
recibido, con su PoC y su corrección (3). La teoría 04 explica cómo prepararla.

## Cómo verificar

```bash
cd /workspace
bash test.sh
```

Tarda unos minutos: Medusa y los mutantes son lo más lento. Al final:

```text
✅ no mira si quien despliega sigue de admin: muerto
✅ no mira la pausa del guardián: muerto
✅ no mira si quien despliega propone: muerto
✅ no mira el feed de la L2: muerto
✅ acepta el feed sin inicializar: muerto
```

y el código de salida es 0. Por el camino, `check-report.sh` dice `✅ informe: secciones, commit,
hallazgos, gas, auditoría cruzada y N pruebas citadas`, con tu N; `forge test`, `95 tests passed`
más los tests de regresión que hayas añadido; Halmos, `Symbolic test result: 5 passed`; Slither,
`0 result(s) found`; Medusa, `13 test(s) passed`; y los cuarenta y tres mutantes, muertos.

## En una red (opcional)

Si desplegaste en Sepolia (semana 16) o en OP Sepolia (semana 33), comprueba ese despliegue. Sin
`--broadcast`, `forge script` solo simula y no firma nada:

```bash
REGISTRY=0x... VAULT=0x... TIMELOCK=0x... GOVERNOR=0x... DEPLOYER=<tu cuenta> GUARDIAN=0x... \
  forge script script/CheckDeployment.s.sol --sig "runL1()" --rpc-url sepolia
```

**Verifica**: la salida acaba en `L1 comprobado`. Si falla, el error dice qué: un
`DeployerStillAdmin` en Sepolia es un hallazgo, y va al informe con su corrección (otra
transacción de traspaso) antes de la presentación. Con `--sig "runL2()"`, `EXECUTOR`, `FEED` y
`L1_DAO`, lo mismo en la L2.

## Ejemplos de adaptación

| Dominio | Qué comprueba además `CheckDeployment` | Un hallazgo típico de la auditoría cruzada |
| ------- | -------------------------------------- | ------------------------------------------ |
| Biblioteca | Que la capacidad del registro sea la del catálogo | Un socio con préstamos activos puede retirar su depósito |
| Tienda en línea | Que el tesorero, si existe, sea la multifirma de la tienda | La devolución del exceso de pago a un contrato que lo rechaza bloquea pedidos |
| Cine | Que el límite de reservas por cuenta sea el de la sala | Reservas en lote que se saltan el límite por cuenta |

En los tres, el script, el calendario y el formato del informe son los mismos: cambian las
conexiones que tu dominio añadió y lo que tu pareja encuentre.

## Criterios de calidad (no automatizables)

- `CheckDeployment` falla con un despliegue malo en cada cosa que comprueba, y su error dice qué.
- Cada hallazgo de tu `auditoria-cruzada.md` tiene un PoC que tu pareja pudo ejecutar en su commit
  y una severidad justificada con impacto y probabilidad.
- Cada hallazgo recibido tiene respuesta: corregido con su test, reconocido o en disputa con su
  porqué.
- El `README.md` de la raíz se entiende sin haber hecho el bootcamp.
- Ningún test del starter ni ningún mutante modificado para que pase.

## Entrega

1. Comprueba que `week-34/` no tiene `out/`, `cache/` ni `crytic-export/`, que sí tiene
   `contracts/snapshots/RegisterGasTest.json` y que no tiene `.env`.
2. Haz commit y sube la rama:

   ```bash
   git add week-34 README.md
   git commit -m "feat(week-34): check deployments and close the cross audit"
   git push -u origin week-34
   ```

3. Abre un pull request `week-34` → `main`, pega en la descripción la salida final de
   `bash test.sh` y enlaza el issue de la auditoría cruzada.
4. Cuando lo fusiones, etiqueta la versión:

   ```bash
   git switch main
   git pull
   git tag -a v1.0.0 -m "Protocolo completo y auditado"
   git push origin v1.0.0
   ```

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Corregir y revisar](../2-practicas/ejercicio-03-corregir-y-revisar/README.md) | **Proyecto — La entrega final** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
