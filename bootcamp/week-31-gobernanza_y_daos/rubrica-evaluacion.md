# Rúbrica de evaluación — Semana 31: Gobernanza y DAOs

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: la DAO del protocolo |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Por qué una votación no puede contar `balanceOf` en el momento de votar? ¿Qué pregunta hace `ERC20Votes` en su lugar? | 10 |
| 2 | `alice` tiene 1000 tokens y 0 votos. ¿Por qué? ¿Y por qué es así por defecto? | 10 |
| 3 | ¿Por qué `getPastVotes(cuenta, block.number)` revierte? ¿Qué pasaría con un flash loan si no lo hiciera? | 10 |
| 4 | ¿Por qué el id de una propuesta es un hash de su contenido, y qué consecuencia tiene para `execute`? | 10 |
| 5 | ¿Para qué sirve `votingDelay`? ¿Qué rompe un `votingDelay` de 0 en el proyecto? | 10 |
| 6 | ¿Por qué la abstención cuenta para el quórum y no para el resultado? ¿Y por qué un empate pierde? | 10 |
| 7 | Con `GovernorTimelockControl`, ¿quién hace las llamadas de una propuesta? ¿Qué pasa si la tesorería es del Governor? | 10 |
| 8 | ¿Quién debe tener cada rol del `TimelockController` en una DAO, y qué pasa si quien lo despliega no renuncia al de administrador? | 10 |
| 9 | La foto impide votar con un flash loan. ¿Qué ataque no impide, y qué lo limita? | 10 |
| 10 | En el proyecto, ¿por qué el umbral para proponer es 1 voto y no "10 puntos en shares", y por qué T-19 se acepta? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Porque el saldo del momento se puede pedir prestado: con un flash loan, cualquiera tiene la
   mayoría durante una transacción, vota y devuelve (Beanstalk, 2022). `ERC20Votes` pregunta
   cuántos votos tenía la cuenta al acabar un bloque ya cerrado, la foto, anterior a la votación.
2. Porque no ha delegado: los votos son del delegado, y el delegado por defecto es nadie. Es así
   porque mover votos escribe checkpoints en cada transferencia: quien no vota no paga ese gas.
3. Porque los votos del bloque actual todavía pueden cambiar en él. Si se pudiera preguntar, un
   préstamo que empieza y acaba en el bloque contaría a mitad de la transacción con todos sus
   votos, y una gobernanza que leyera ese valor sería del primero que pidiera prestado.
4. No hay contador: el id es `keccak256` de destinos, valores, `calldata` y el hash de la
   descripción. `execute` (y `queue` y `cancel`) recibe el contenido entero y recalcula el hash,
   así que nadie ejecuta algo distinto de lo votado.
5. Da tiempo entre la propuesta y la foto: para delegar, o para vender quien no esté de acuerdo.
   Con 0, la foto es el bloque de la propuesta: quien delega en el bloque siguiente vota con 0
   (`test_VotingDelayLetsHoldersDelegate`), y quien propone elige el momento de la foto.
6. Abstenerse es participar sin tomar partido: cuenta para que la decisión sea de bastantes, pero
   no inclina el resultado. Un empate pierde porque cambiar algo tiene que convencer a más de los
   que se oponen; si no, la mitad decide por la otra mitad.
7. El timelock: `execute` del Governor llama a `executeBatch`, y `msg.sender` en lo gobernado es el
   timelock. Si la tesorería es del Governor, la ejecución revierte con
   `OwnableUnauthorizedAccount(timelock)`: la propuesta aprobada no se puede ejecutar nunca.
8. Proponer: solo el Governor. Cancelar: el Governor y, si se quiere, un guardián. Ejecutar:
   `address(0)`, cualquiera. Administrar: solo el propio timelock. Si quien despliega no renuncia,
   puede darse `PROPOSER_ROLE` y programar lo que quiera sin votar: una puerta trasera que ningún
   test de la votación ve.
9. Pedir los tokens prestados antes de la foto y devolverlos después, durante días: cuesta el
   interés, no el precio. Lo limitan un quórum alto, el timelock y el guardián (tiempo para
   reaccionar y cancelar o pausar), y dar votos solo a tokens bloqueados (vote escrow).
10. Lo que vale una share depende del bonus que llegó al vault antes del primer depósito: 100
    puntos pueden ser unos diez millones de unidades de share o `100e24`, según la historia del
    vault. Un umbral fijo sería otro en cada despliegue; con 1, proponer exige tener shares
    delegadas. T-19 (quien tiene la mayoría decide) es la definición de una DAO: no se corrige en
    el código; lo limitan el timelock (dos días para salir) y el guardián.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Votos con checkpoints | `forge test` sin error: `11 tests passed, 0 failed` | 15 |
| | Explica qué hace la búsqueda binaria de `_upperLookup` con los checkpoints de `test_Paso4_PastVotesAreFrozen` y qué compara el test diferencial | 10 |
| 02 — Un Governor | `forge test` sin error: `10 tests passed, 0 failed` | 15 |
| | Explica por qué con los plazos del starter cualquier cuenta con un token podía proponer y votar en un solo bloque | 10 |
| 03 — Una DAO con timelock | `forge test` sin error: `8 tests passed, 0 failed` | 15 |
| | Explica qué error da cada paso sin resolver y por qué el orden de los roles importa | 15 |
| Todos | Sin tocar `foundry.toml` ni los tests | 20 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-31/` sin `out/`, `cache/` ni `crytic-export/`, con `contracts/snapshots/RegisterGasTest.json`, y pull request `week-31` → `main` | 10 |
| `bash test.sh` sin error: informe, gas con snapshots, 61 tests, specs, `forge lint`, Slither, detector, Medusa y los veintiocho mutantes muertos | 25 |
| Las shares del vault con `ERC20Votes`, el Governor con sus parámetros y el traspaso que deja al timelock de administrador, al guardián solo la pausa y a quien despliega sin roles | 25 |
| Informe: H-04 corregido, alcance, actores, activos, T-16 a T-19 con su prueba, y la sección `## Gobernanza (semana 31)` | 25 |
| Parámetros y T-19 justificados con tu dominio: por qué esos plazos y ese quórum, y qué pasaría si una cuenta reuniera la mayoría | 15 |

**Total**: 100 puntos → 30 % de la nota.

---

## 🏅 Bandas

| Banda | Rango |
| ----- | ----- |
| Sobresaliente | 90-100 |
| Notable | 80-89 |
| Aprobado | 70-79 |
| No aprobado | < 70 en alguna evidencia |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Proyecto — La DAO del protocolo](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
