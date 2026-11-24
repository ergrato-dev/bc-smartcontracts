# 📖 Glosario — Semana 31

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Abstención (*abstain*) | Voto que cuenta para el quórum pero no para el resultado | `castVote(id, 2)` |
| Ballena (*whale*) | Cuenta con una parte tan grande de los votos que decide sola | `alice` con 100 de 130 puntos en el proyecto |
| Checkpoint | Los votos de un delegado desde un bloque, guardados en una lista ordenada | `Checkpoint(100, 1000 ether)` |
| Delegado (*delegatee*) | Cuenta que vota con el saldo de otras que delegaron en ella | `token.delegate(alice)` |
| DAO (*decentralized autonomous organization*) | Organización que decide con votaciones en un contrato, que ejecuta lo aprobado | Un Governor con su timelock |
| ERC-5805 | Estándar de los votos con delegación: `delegate`, `getVotes`, `getPastVotes` | `ERC20Votes` de OpenZeppelin |
| ERC-6372 | Estándar del reloj de un contrato: `clock()` y `CLOCK_MODE()` | `mode=blocknumber&from=default` |
| Foto (*snapshot*) | Bloque cuyos votos cuentan en una propuesta | `proposalSnapshot(id)` |
| Governor | Contrato que recibe propuestas, cuenta los votos y ejecuta lo aprobado | `ProtocolGovernor` |
| Guardián (*guardian*) | Cuenta con un poder pequeño y rápido para frenar a la DAO: pausar o cancelar | `PAUSER_ROLE` en el proyecto |
| Módulo de recuento | Extensión del Governor que decide cómo se cuenta un voto, el quórum y quién gana | `GovernorCountingSimple` |
| Periodo de votación (*voting period*) | Cuánto dura la votación, en unidades del reloj del token | 50 400 bloques |
| Propuesta (*proposal*) | Lista de llamadas (destino, valor y `calldata`) que se ejecuta si se aprueba | `Treasury.pay(dave, 1 ether)` |
| Quórum | Votos mínimos que tienen que participar para que una propuesta cuente | 4 % de las shares |
| Retraso de votación (*voting delay*) | Tiempo entre proponer y la foto | 7200 bloques |
| Test diferencial | Test que compara dos implementaciones con las mismas entradas | `testFuzz_Paso5_MatchesOpenZeppelin` |
| Umbral de propuesta (*proposal threshold*) | Votos mínimos para poder proponer | 1 voto en el proyecto |
| Vote escrow | Votos que solo tienen los tokens bloqueados durante un tiempo | Bloquear tokens meses a cambio de votos |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 32 — Account abstraction →](../../week-32-account_abstraction/README.md) |
