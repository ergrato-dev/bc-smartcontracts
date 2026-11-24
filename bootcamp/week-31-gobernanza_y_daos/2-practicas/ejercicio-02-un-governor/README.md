# Ejercicio 02 — Un Governor

> Al terminar habrás montado un Governor de OpenZeppelin con el recuento escrito a mano: quién vota
> y cuántas veces, qué cuenta para el quórum y cuándo gana una propuesta. Y lo habrás llevado de la
> propuesta al pago, con plazos de verdad.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 02 — El Governor](../../1-teoria/02-el-governor.md) leída y el
[ejercicio 01](../ejercicio-01-votos-con-checkpoints/README.md) en verde.

## Contexto

Proyecto Foundry. `MyGovernor` hereda de `Governor`, `GovernorSettings`, `GovernorVotes` y
`GovernorVotesQuorumFraction` de OpenZeppelin, pero no de `GovernorCountingSimple`: el recuento lo
escribes tú. Sin timelock: lo aprobado lo ejecuta el propio Governor, que es el dueño de la
tesorería.

| Archivo | Qué es |
| ------- | ------ |
| `src/MyGovernor.sol` | El Governor: tu trabajo, pasos 1 a 4 |
| `src/GovToken.sol` | Un `ERC20Votes` con un millón de tokens |
| `src/Treasury.sol` | Una tesorería con ETH que solo paga su dueño |
| `test/MyGovernor.t.sol` | Los tests de cada paso y uno de comportamiento. No lo cambies |

En el `setUp`, `alice` tiene 400 000 tokens (40 %), `bob` 300 000 (30 %) y `carol` 20 000 (2 %),
los tres delegados en sí mismos. El quórum es el 4 %: 40 000 votos. Todas las propuestas piden
que la tesorería pague 1 ETH a `dave`.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-31-gobernanza_y_daos/2-practicas/ejercicio-02-un-governor/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `1 tests passed, 9 failed`. Pasa `test_ProposalIdIsTheHashOfItsContent`: proponer
no necesita el recuento, y el id es el hash del contenido (teoría 02). Los que votan fallan en el
paso 1, y los de los plazos, porque el starter tiene plazos de juguete:

```text
[FAIL: TODO: Paso 1] test_Paso1_CountsEachOption() (gas: 146064)
[FAIL: un dia de bloques de 12 s: 0 != 7200] test_Paso4_SettingsInBlocks() (gas: 11617)
```

## Paso 1: Anotar un voto

**Por qué**: `castVote` del Governor comprueba que la propuesta está `Active`, calcula el peso
(los votos de la cuenta en la foto) y llama a `_countVote`. Lo que queda es tuyo: que cada cuenta
vote una vez y que cada voto sume en su opción. Un `support` que no es 0, 1 ni 2 es un error, no
una abstención.

**Abre** `src/MyGovernor.sol` y resuelve `_countVote`:

```solidity
ProposalVote storage pv = _proposalVotes[proposalId];
if (pv.hasVoted[account]) revert GovernorAlreadyCastVote(account);
pv.hasVoted[account] = true;
if (support == uint8(VoteType.Against)) {
    pv.againstVotes += weight;
} else if (support == uint8(VoteType.For)) {
    pv.forVotes += weight;
} else if (support == uint8(VoteType.Abstain)) {
    pv.abstainVotes += weight;
} else {
    revert GovernorInvalidVoteType();
}
return weight;
```

Los dos errores son de `IGovernor`: las interfaces de las DAO los reconocen.

**Verifica**: `5 tests passed, 5 failed`. Los votos se cuentan, pero cualquier propuesta gana:

```text
[FAIL: 2 % a favor no llega: 4 != 3] test_Paso2_DefeatedWithoutQuorum() (gas: 248373)
```

El 4 es `Succeeded` y el 3, `Defeated`: el starter dice que siempre hay quórum y que siempre gana
el sí.

## Paso 2: El quórum

**Por qué**: si solo vota `carol`, con el 2 %, decide por todos. El quórum pide que participe un
mínimo, y la abstención cuenta: quien se abstiene participa. Se mide en la foto, como los votos.

**Abre** `src/MyGovernor.sol`, borra en `_quorumReached` la línea que acaba en `// <- Paso 2` y
descomenta las de debajo:

```solidity
ProposalVote storage pv = _proposalVotes[proposalId];
return quorum(proposalSnapshot(proposalId)) <= pv.forVotes + pv.abstainVotes;
```

**Verifica**: `6 tests passed, 4 failed`. `carol` sola no llega a 40 000: `Defeated`. Con `bob`
absteniéndose, sí: `Succeeded`, aunque solo `carol` vote a favor.

## Paso 3: Quién gana

**Por qué**: con quórum, el starter aprueba aunque gane el no. Gana el sí solo si tiene **más**
votos que el no: un empate pierde, porque cambiar algo tiene que convencer a más de los que se
oponen.

**Abre** `src/MyGovernor.sol`, borra en `_voteSucceeded` la línea que acaba en `// <- Paso 3` y
descomenta las de debajo:

```solidity
ProposalVote storage pv = _proposalVotes[proposalId];
return pv.forVotes > pv.againstVotes;
```

**Verifica**: `8 tests passed, 2 failed`. 300 000 a favor contra 300 000 en contra: `Defeated`.

## Paso 4: Los plazos

**Por qué**: el starter tiene `votingDelay` 0 (la foto es el bloque de la propuesta: nadie llega
a delegar), `votingPeriod` 1 (un bloque para votar) y umbral 0 (cualquiera propone, también una
cuenta con un token). En bloques de 12 s, un día son 7200 y una semana, 50 400. El umbral, 10 000
votos, es el 1 % del suministro.

**Abre** `src/MyGovernor.sol`, borra en el constructor la línea que acaba en `// <- Paso 4` y
descomenta la de debajo:

```solidity
GovernorSettings(7200, 50_400, 10_000 ether)
```

**Verifica**: `10 tests passed, 0 failed`. Con 9999 votos, `dave` no puede proponer:
`GovernorInsufficientProposerVotes(dave, 9999 ether, 10000 ether)`. Y
`test_Paso4_TheWholeLifecycle` recorre la propuesta entera: `Active` hasta el último bloque del
periodo incluido, `Succeeded` en el siguiente y `Executed` tras `execute`, con `dave` cobrando
1 ETH de la tesorería.

## Para pensar

- `test_Paso4_TheWholeLifecycle` ejecuta en cuanto acaba la votación. ¿Qué podría hacer alguien
  que votó en contra si la propuesta fuera "dar la tesorería a alice"? ¿Cuánto tiempo tiene?
- `GovernorSettings` deja cambiar los plazos con una propuesta (`setVotingPeriod`). ¿Qué
  propuesta harías tú, con el 40 %, para que la siguiente votación dure un solo bloque? ¿Qué te
  lo impediría?
- El quórum se calcula sobre el total de la foto. Si la mitad de los tokens nunca delega, ¿qué
  porcentaje de los votos que sí participan es el 4 % del total?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Votos con checkpoints](../ejercicio-01-votos-con-checkpoints/README.md) | **Ejercicio 02 — Un Governor** | [Ejercicio 03 — Una DAO con timelock →](../ejercicio-03-una-dao-con-timelock/README.md) |
