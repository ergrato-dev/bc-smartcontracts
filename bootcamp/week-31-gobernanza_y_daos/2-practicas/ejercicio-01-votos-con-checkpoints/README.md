# Ejercicio 01 — Votos con checkpoints

> Al terminar habrás escrito a mano lo que hace `ERC20Votes`: delegar, mover votos con cada
> transferencia, guardar un checkpoint por bloque y encontrar los votos de un bloque pasado con
> una búsqueda binaria. Y un test diferencial lo comparará con el de OpenZeppelin.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 01 — Votos con ERC20Votes](../../1-teoria/01-votos-con-erc20votes.md)
leída.

## Contexto

Proyecto Foundry. `VotesToken` es un ERC-20 de OpenZeppelin con los votos escritos a mano. El
reloj son los números de bloque, como en `ERC20Votes` por defecto.

| Archivo | Qué es |
| ------- | ------ |
| `src/VotesToken.sol` | El token: tu trabajo, pasos 1 a 5 |
| `test/VotesToken.t.sol` | Los tests, con `VotesHarness` (tu token con `mint` y `burn` abiertos) y `OzVotes` (el `ERC20Votes` de OpenZeppelin, para comparar). No lo cambies |

Ya escritas: `getVotes` (los votos del último checkpoint), `getPastVotes` y `getPastTotalSupply`
(revierten con un bloque que no ha acabado y llaman a `_upperLookup`), y `_moveVotes`, que resta
votos a un delegado, se los suma a otro y emite `DelegateVotesChanged`. `address(0)` es "nadie":
no tiene checkpoints.

En el `setUp`, en el bloque 100, `alice` recibe 100 tokens y `bob` 50. Nadie ha delegado.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-31-gobernanza_y_daos/2-practicas/ejercicio-01-votos-con-checkpoints/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `2 tests passed, 9 failed`. Pasan `test_HoldingIsNotVoting` (100 tokens, 0 votos:
nadie ha delegado) y `test_RevertWhen_LookingAtTheCurrentBlock`. Casi todos los demás delegan
primero:

```text
[FAIL: TODO: Paso 1] test_Paso1_DelegateToSelfGivesVotes() (gas: 38902)
[FAIL: TODO: Paso 4] test_Paso5_PastTotalSupply() (gas: 142529)
```

## Paso 1: Delegar

**Por qué**: delegar es elegir quién vota con tu saldo. Los votos de todo tu saldo pasan del
delegado que tenías (o de nadie) al nuevo. El evento `DelegateChanged` es lo que leen las
interfaces para saber quién representa a quién.

**Abre** `src/VotesToken.sol` y resuelve `delegate`:

```solidity
address previous = delegates[msg.sender];
delegates[msg.sender] = delegatee;
emit DelegateChanged(msg.sender, previous, delegatee);
_moveVotes(previous, delegatee, balanceOf(msg.sender));
```

**Verifica**: `4 tests passed, 7 failed`. `alice` delega en sí misma y tiene 100 votos; delega en
`carol` y `carol` vota con 100 sin tener ningún token. Pero:

```text
[FAIL: tres cambios en el bloque 100, un checkpoint: 3 != 1] test_Paso2_OneCheckpointPerBlock() (gas: 329088)
```

## Paso 2: Un checkpoint por bloque

**Por qué**: `_push` añade un checkpoint cada vez que cambian los votos. Tres cambios en el mismo
bloque dejan tres, y solo el último dice cuántos votos había al acabar el bloque: los otros dos
son `storage` pagado para nada. Si el último checkpoint es de este bloque, se sobrescribe.

**Abre** `src/VotesToken.sol`, borra la línea de `_push` que acaba en `// <- Paso 2` y descomenta
las de debajo:

```solidity
uint256 n = ckpts.length;
if (n > 0 && ckpts[n - 1].fromBlock == block.number) {
    ckpts[n - 1].votes = SafeCast.toUint208(votes);
} else {
    ckpts.push(Checkpoint(SafeCast.toUint48(block.number), SafeCast.toUint208(votes)));
}
```

`SafeCast` de OpenZeppelin revierte si el número no cabe en el tipo pequeño, en vez de cortarlo.
`uint48` y `uint208` suman 256: el checkpoint ocupa un slot (semana 27).

**Verifica**: `5 tests passed, 6 failed`. Los de transferencias siguen en rojo:

```text
[FAIL: assertion failed: 100000000000000000000 != 70000000000000000000] test_Paso3_TransferMovesVotes() (gas: 255836)
```

## Paso 3: Los votos siguen a los tokens

**Por qué**: `alice` envió 30 tokens, pero sigue con 100 votos: los votos no se mueven con la
transferencia. Todo mint, burn y transferencia pasa por `_update`, así que es ahí donde los votos
pasan del delegado de quien envía al delegado de quien recibe. Si quien recibe no ha delegado, los
votos se pierden: sus tokens no votan.

**Abre** `src/VotesToken.sol`, borra en `_update` la línea que acaba en `// <- Paso 3` y descomenta
las de debajo:

```solidity
super._update(from, to, value);
_moveVotes(delegates[from], delegates[to], value);
```

**Verifica**: `7 tests passed, 4 failed`. `alice` queda con 70 votos y el delegado de `bob` gana
30. Los de bloques pasados fallan con `TODO: Paso 4`.

## Paso 4: Los votos de un bloque pasado

**Por qué**: es la pregunta de toda gobernanza. Los checkpoints están ordenados por bloque, así que
el que vale en el bloque N es el último con `fromBlock <= N`, y se encuentra partiendo la lista
por la mitad cada vez. `high` acaba en el primer checkpoint **posterior** a N: el que buscas es
el anterior. Si no hay ninguno, la cuenta tenía 0.

**Abre** `src/VotesToken.sol` y resuelve `_upperLookup`:

```solidity
uint256 low = 0;
uint256 high = ckpts.length;
while (low < high) {
    uint256 mid = Math.average(low, high);
    if (ckpts[mid].fromBlock > blockNumber) {
        high = mid;
    } else {
        low = mid + 1;
    }
}
return high == 0 ? 0 : ckpts[high - 1].votes;
```

`Math.average` de OpenZeppelin calcula la media sin desbordar.

**Verifica**: `9 tests passed, 2 failed`. En `test_Paso4_PastVotesAreFrozen`, `alice` tenía 100
votos en los bloques 100 a 109, 40 en el 110 y 0 desde el 120: lo que haga después no los cambia.
Y en `test_Paso4_FlashLoanGivesNoPastVotes`, `carol` recibe un millón de tokens, delega y los
devuelve, todo en el bloque 200: tiene un millón de votos mientras dura, y 0 en el 199 y en el
200 en cuanto el bloque acaba.

## Paso 5: El total de cada bloque

**Por qué**: el quórum es un porcentaje de los votos que existían en la foto, así que también hace
falta el total de cada bloque. Solo cambia con un mint o un burn: una transferencia mueve tokens,
pero no crea ni destruye ninguno.

**Abre** `src/VotesToken.sol` y descomenta la última línea de `_update`:

```solidity
if (from == address(0) || to == address(0)) _push(_totalCheckpoints, totalSupply());
```

Va después de `super._update`, que ya actualizó `totalSupply`.

**Verifica**: `11 tests passed, 0 failed`. `testFuzz_Paso5_MatchesOpenZeppelin` hace doce
operaciones al azar (delegar, transferir, emitir y quemar) en tu token y en el `ERC20Votes` de
OpenZeppelin, y compara los votos de las tres cuentas y el total en cada bloque pasado: 256 veces,
con semillas distintas. Es un **test diferencial**: no dice qué número debe salir, sino que dos
implementaciones dan el mismo.

## Para pensar

- `delegate` mueve `balanceOf(msg.sender)`. ¿Qué pasaría si `alice` delegara, después recibiera
  tokens y `_update` no moviera votos? ¿Por qué el paso 3 arregla también eso?
- El test de flash loan pregunta por el bloque 200 desde el 201. ¿Qué devolvería
  `getPastVotes(carol, 200)` si se pudiera preguntar desde el propio bloque 200, a mitad del
  préstamo?
- La búsqueda binaria lee `log2(n)` checkpoints. `ERC20Votes` de OpenZeppelin mira primero los
  últimos antes de partir la lista. ¿Por qué esperas que los bloques que se consultan sean casi
  siempre recientes?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Ataques a la gobernanza](../../1-teoria/04-ataques-a-la-gobernanza.md) | **Ejercicio 01 — Votos con checkpoints** | [Ejercicio 02 — Un Governor →](../ejercicio-02-un-governor/README.md) |
