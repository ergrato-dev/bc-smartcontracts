# Proyecto — La DAO del protocolo

> Desde la semana 13, una sola cuenta puede cambiar todo tu protocolo, y en la semana 26 lo
> escribiste como hallazgo. Esta semana lo corriges: las shares de tu vault de puntos pasan a ser
> votos, un Governor los cuenta, un timelock de dos días ejecuta lo aprobado, y un script traspasa
> el registro a la DAO y deja a quien lo desplegó sin ningún poder.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 30 en
`main`.

## Capa que se añade y por qué ahora

Tu registro tiene un administrador con `DEFAULT_ADMIN_ROLE`: actualiza el código, cambia el hook y
el price feed, da roles y reanuda. Es una sola clave, sin espera: el hallazgo H-04 de tu informe,
**reconocido** desde la semana 26 a la espera de esta.

La capa de gobernanza tiene tres piezas:

- **Los votos.** Son las shares de tu `PointsVault` (semana 30), que gana `ERC20Votes` (teoría 01).
  Quien guarda sus puntos en el protocolo lo gobierna, en proporción a lo que guarda. Las altas no
  cambian: el bonus llega al vault como activo, no como shares, así que tu gas guardado de la
  semana 30 sigue valiendo.
- **El Governor.** `ProtocolGovernor`, el Governor de OpenZeppelin con recuento simple, quórum y
  timelock (teoría 02).
- **El traspaso.** `HandOverToDao.s.sol` despliega el timelock y el Governor, da al timelock el
  rol de administrador del registro, deja a un **guardián** solo la pausa y hace que quien firma
  renuncie (teoría 03).

Ahora es cuando tienes todo lo necesario: los roles y el timelock de la semana 13, el proxy de la
15, los scripts de la 16, los flash loans de la 22, el modelo de amenazas y el hallazgo de la 26,
los mutantes de la 24 y el vault de la 30.

Dos decisiones de diseño:

- **El traspaso va aparte.** `DeployProtocol` sigue dejando a quien firma como administrador:
  después vienen las actualizaciones a V2 y V3 de tus scripts, que necesitan esa cuenta. El
  traspaso es el último paso de la puesta en marcha, y no tiene vuelta atrás.
- **El umbral para proponer es 1 voto.** Con el offset de 6, lo que vale una share depende del
  bonus que llegó al vault antes del primer depósito: en los tests, 100 puntos dan unos diez
  millones de unidades de share, no `100e24`. Un umbral de "10 puntos en shares" sería otro número
  en cada despliegue. Con 1, proponer exige tener shares delegadas.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-31
   ```

2. Copia el starter en `week-31/` y pon encima tus contratos, tus pruebas, tu gas guardado y tu
   informe de la semana 30:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-31-gobernanza_y_daos/3-proyecto/starter week-31
   cp -r week-30/contracts/src week-30/contracts/script week-30/contracts/snapshots week-31/contracts/
   cp -r week-30/contracts/test/invariant week-30/contracts/test/formal week-30/contracts/test/audit week-30/contracts/test/evm week-30/contracts/test/asm week-30/contracts/test/gas week-30/contracts/test/defi week-31/contracts/test/
   cp week-30/detectors/unpaused_register.py week-31/detectors/
   cp -r week-30/audit week-31/
   ls -l week-31/contracts/lib week-31/contracts/src/ProtocolGovernor.sol week-31/contracts/script/HandOverToDao.s.sol
   ```

   **Verifica**: `lib -> /opt/lib`, y los dos archivos nuevos existen: son los del starter, porque
   tu semana 30 no los tenía. Tu `PointsVault.sol` es el tuyo, sin votos.

3. Entra al contenedor y mira el rojo:

   ```bash
   cd week-31
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   cd contracts
   forge test
   ```

**Verifica**: no compila. El Governor necesita un token con votos, y los tests delegan:

```text
Error (9553): Invalid type for argument in function call. Invalid implicit conversion from contract PointsVault to contract IVotes requested.
  --> script/HandOverToDao.s.sol:54:45:
```

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/src/`, `contracts/script/`, `contracts/test/` (salvo `dao/`) | Los de la solución de la semana 30: tu referencia. Tú usas los tuyos |
| `contracts/src/PointsVault.sol` | El vault de referencia con los votos ya puestos, marcados `Semana 31` |
| `contracts/src/ProtocolGovernor.sol` | El Governor, con los parámetros en su `// TODO (semana 31)` |
| `contracts/script/HandOverToDao.s.sol` | El traspaso, con los roles del registro en su `// TODO (semana 31)` |
| `contracts/test/dao/Governance.t.sol` | Los ocho tests de la gobernanza. **No los modifiques** |
| `contracts/foundry.toml` | El de la semana 30 con `ignored_warnings_from` (teoría 01): úsalo tal cual |
| `mutants.sh` | Los veinticuatro mutantes de la semana 30 y cuatro nuevos, de la DAO. **No lo modifiques** |
| `test.sh`, `check-report.sh` | Los de la semana 30 |
| `detectors/` | El detector de la semana 23; pon encima el tuyo |

## Las shares votan

**Abre** tu `contracts/src/PointsVault.sol` y, al lado, el del starter. Añade a tu vault lo que el
del starter marca como de la semana 31:

```solidity
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract PointsVault is ERC4626, ERC20Votes {
    constructor(IERC20 points) ERC20("Staked Points", "sPTS") ERC4626(points) EIP712("Staked Points", "1") {}

    function decimals() public view override(ERC20, ERC4626) returns (uint8) {
        return super.decimals();
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }
    // ... y tu _decimalsOffset de la semana 30, sin cambios.
}
```

El nombre de `EIP712` es el de tus shares: si tu vault se llama de otra forma, usa ese. `decimals`
existe en `ERC20` y en `ERC4626`, y `_update`, en `ERC20` y en `ERC20Votes`: Solidity exige decir
cuál gana, y `super` llama a los dos en orden.

**Verifica**: `forge test` compila. `54 tests passed, 7 failed`: los 53 de la semana 30 siguen en
verde, y de la gobernanza solo pasa `test_FlashDepositCannotVote`. Los demás fallan por lo que
queda:

```text
[FAIL: el timelock administra el registro] test_HandOverLeavesNoAdmin() (gas: 28414)
[FAIL: delego a tiempo: 0 != 1920048] test_VotingDelayLetsHoldersDelegate() (gas: 970994)
```

## Los parámetros del Governor

**Abre** `contracts/src/ProtocolGovernor.sol` y resuelve el `TODO`: los cuatro parámetros que pide
el comentario. Con los del starter, la foto es el bloque de la propuesta (por eso `carol`, que
delega en el bloque siguiente, vota con 0), se vota un solo bloque, cualquiera propone y no hay
quórum.

```solidity
uint48 public constant VOTING_DELAY = 7200;
uint32 public constant VOTING_PERIOD = 50_400;
uint256 public constant PROPOSAL_THRESHOLD = 1;
uint256 public constant QUORUM_PERCENT = 4;
```

El resto del contrato es el Governor de la teoría 02: las extensiones de OpenZeppelin y las
funciones que solo resuelven la herencia múltiple.

## El traspaso

**Abre** `contracts/script/HandOverToDao.s.sol`. El timelock y el Governor ya se despliegan: el
script calcula la dirección del Governor antes de crearlo (`vm.computeCreateAddress`, como el proxy
de tu `DeployProtocol`) para darle `PROPOSER_ROLE` en el constructor del timelock, y crea el
timelock sin administrador. Resuelve el `TODO`:

```solidity
registry.grantRole(registry.DEFAULT_ADMIN_ROLE(), address(dao.timelock));
registry.grantRole(registry.PAUSER_ROLE(), guardian);
registry.renounceRole(registry.DEFAULT_ADMIN_ROLE(), deployer);
```

El orden importa: después de renunciar, quien firma ya no puede dar ningún rol. El guardián es la
variable de entorno `GUARDIAN`, o quien firma si no existe: en una red pública, un multisig.

**Verifica**:

```bash
forge test --mc GovernanceTest
```

`8 tests passed`. Y `forge test`, `61 tests passed, 0 failed`: los 53 de la semana 30 y los ocho de
la DAO. `FORGE_SNAPSHOT_CHECK=true forge test --mc RegisterGasTest` sigue en verde: las altas no
cambian de gas.

## El informe

**Abre** `week-31/audit/README.md` y añade la DAO:

- En **Resumen**, H-04 pasa de reconocido a corregido, y el riesgo principal cambia: ya no es una
  clave, sino quién reúne los votos.
- En **Alcance**, `ProtocolGovernor`, las líneas nuevas de `PointsVault` y `HandOverToDao.s.sol`:
  este script sí entra, porque los roles que deja son la defensa.
- En **Actores**, el delegado de la DAO y el guardián; el administrador pasa a ser el timelock. En
  **Activos**, los votos. En **Fronteras de confianza**, votantes → timelock.
- En **Amenazas**, T-11 ya tiene defensa y prueba, y cuatro filas nuevas:

  | Id | Amenaza | Defensa | Prueba |
  | -- | ------- | ------- | ------ |
  | T-16 | Alguien vota con puntos prestados en la misma transacción | Votos de la foto | `test_FlashDepositCannotVote` |
  | T-17 | Una propuesta aprobada se ejecuta antes de que nadie reaccione | Timelock de 2 días; el guardián pausa | `test_RevertWhen_ExecuteBeforeTheDelay`, `test_DaoUnpausesAfterTheGuardian` |
  | T-18 | Una minoría aprueba porque casi nadie vota | Quórum del 4 %; un día para delegar | `test_DefeatedWithoutQuorum`, `test_VotingDelayLetsHoldersDelegate` |
  | T-19 | Quien tiene la mayoría de las shares en la foto aprueba lo que quiera | Ninguna en el código: riesgo aceptado | `test_DaoUnpausesAfterTheGuardian` |

- Una sección `## Gobernanza (semana 31)`, antes de `## Hallazgos`, con: cómo es el traspaso, por
  qué votan las shares, los parámetros y por qué, quién tiene cada rol del timelock, qué puede el
  guardián, qué prueba cada test, qué mutante mata cada uno, y lo que no hiciste.
- En H-04, el **Estado** pasa a corregido, con la corrección; y su fila de **Revisión de
  correcciones** dice qué la comprueba y que llega al proxy con `HandOverToDao.s.sol`.

T-19 es un riesgo aceptado, y el informe tiene que decir por qué: es la definición de una DAO. En
los tests, `alice` tiene 100 de 130 puntos y aprueba sola. Lo que la limita es el plazo del
timelock (dos días para retirar los puntos antes de que se ejecute) y el guardián. Escribe qué
pasaría en tu dominio si una cuenta reuniera la mayoría, y qué añadirías si eso no basta.

## Cómo verificar

```bash
cd /workspace
bash test.sh
```

Tarda unos minutos: Medusa y los mutantes son lo más lento. Al final:

```text
✅ quien despliega sigue de admin: muerto
✅ el timelock no espera: muerto
✅ sin quórum: muerto
✅ la foto es el bloque de la propuesta: muerto
```

y el código de salida es 0. Por el camino, `check-report.sh` dice `✅ informe: secciones, commit,
hallazgos, gas y N pruebas citadas`, con tu N; `forge test`, `61 tests passed`; Halmos,
`Symbolic test result: 5 passed`; Slither, `0 result(s) found`; Medusa, `13 test(s) passed`; y
los veintiocho mutantes, muertos.

## Ejemplos de adaptación

| Dominio | Quién vota | Qué decide la DAO |
| ------- | ---------- | ----------------- |
| Biblioteca | Los socios que guardan sus puntos de lectura en el fondo común | Actualizar el catálogo, cambiar la tasa del préstamo, quitarle la pausa a un bibliotecario |
| Tienda en línea | Los clientes del "monedero premium" | La comisión, el oráculo de precios, el hook de recompensas |
| Cine | Los espectadores del club | El precio de la entrada en dólares, la versión del registro de sesiones |

En los tres, el Governor y el script son los mismos: cambian los nombres, el guardián (el
bibliotecario de guardia, el equipo de soporte, el gerente del cine) y, si tu dominio lo pide, los
plazos.

## Criterios de calidad (no automatizables)

- Después del traspaso, ninguna cuenta puede cambiar el registro sin una propuesta: ni quien lo
  desplegó, ni el guardián, ni nadie con un rol en el timelock que no sea el Governor.
- Cada amenaza nueva tiene defensa y prueba, o dice por qué se acepta.
- El informe explica los parámetros con argumentos de tu dominio, no solo "porque el starter lo
  dice".
- Los nombres del Governor y de las shares son de tu dominio.
- Ningún test del starter ni ningún mutante modificado para que pase.

## Entrega

1. Comprueba que `week-31/` no tiene `out/`, `cache/` ni `crytic-export/` y que sí tiene
   `contracts/snapshots/RegisterGasTest.json`.
2. Haz commit y sube la rama:

   ```bash
   git add week-31
   git commit -m "feat(week-31): hand the registry over to a DAO"
   git push -u origin week-31
   ```

3. Abre un pull request `week-31` → `main` y pega en la descripción la salida final de
   `bash test.sh`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Una DAO con timelock](../2-practicas/ejercicio-03-una-dao-con-timelock/README.md) | **Proyecto — La DAO del protocolo** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
