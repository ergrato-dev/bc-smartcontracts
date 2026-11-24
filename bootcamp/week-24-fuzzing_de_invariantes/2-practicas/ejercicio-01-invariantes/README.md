# Ejercicio 01 — Invariantes

> Al terminar habrás escrito tres invariantes para un contrato cuyos tests unitarios pasan, habrás
> corregido los dos fallos que encuentran, y sabrás leer una secuencia encogida y la tabla de
> llamadas de forge.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 01](../../1-teoria/01-de-fuzz-a-invariantes.md) y
[Teoría 02](../../1-teoria/02-invariantes-en-foundry.md) leídas.

## Contexto

`Seats` son las diez butacas numeradas de una sala. Cualquiera reserva una libre (`book`), cancela
la suya (`cancel`) o se la pasa a otra cuenta (`transferSeat`). Nadie tiene más de dos. Lleva dos
contadores: `booked`, las butacas reservadas, y `seatsOf[cuenta]`, las de cada cuenta.

| Archivo | Qué es |
| ------- | ------ |
| `src/Seats.sol` | El contrato. Pasos 2 y 4 |
| `test/Seats.t.sol` | Cinco tests unitarios, en verde desde el principio. **No lo modifiques** |
| `test/SeatsInvariants.t.sol` | Las invariantes. Pasos 1, 3 y 5 |

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-24-fuzzing_de_invariantes/2-practicas/ejercicio-01-invariantes/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `SeatsTest` pasa entero, `5 passed`, y `SeatsInvariantsTest` falla en
`setUp() (gas: 0)` con `TODO: Paso 1`. Los tests unitarios no ven ningún fallo.

## Paso 1: La primera invariante

**Por qué**: `booked` cuenta las butacas reservadas, y eso se puede calcular: las que tienen
dueño. Si los dos números no coinciden después de alguna secuencia, el contador miente. El
fuzzer llama solo a `Seats` (`targetContract`) y desde tres cuentas fijas (`targetSender`): con
cuentas aleatorias, la que reserva casi nunca es la que después pasa la butaca.

```solidity
targetContract(address(seats));
targetSender(makeAddr("alice"));
targetSender(makeAddr("bob"));
targetSender(makeAddr("carol"));
```

```solidity
function invariant_BookedMatchesHolders() public view {
    uint256 held;
    for (uint256 seat = 0; seat < seats.CAPACITY(); seat++) {
        if (seats.holderOf(seat) != address(0)) held++;
    }
    assertEq(seats.booked(), held);
}
```

**Abre** `test/SeatsInvariants.t.sol`. En `setUp`, borra el `revert("TODO: Paso 1")` y descomenta
las cuatro líneas; en `invariant_BookedMatchesHolders`, descomenta el cuerpo.

**Verifica**: `forge test --mc SeatsInvariants` falla, y la invariante del paso 1 trae una
secuencia de dos llamadas desde la misma cuenta:

```text
[FAIL: assertion failed: 2 != 1] invariant_BookedMatchesHolders
	[Sequence] (original: 5, shrunk: 2)
		sender=0xA4d4c1f8a763Ef6a0140D04291eCEef913Ffc272 addr=[src/Seats.sol:Seats]0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f calldata=book(uint256) args=[0]
		sender=0xA4d4c1f8a763Ef6a0140D04291eCEef913Ffc272 addr=[src/Seats.sol:Seats]0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f calldata=transferSeat(uint256,address) args=[0, 0x0000000000000000000000000000000000000000]
```

Tu butaca, tus valores (`2 != 1`) y tu dirección de `sender` pueden ser otros: la semilla es
aleatoria. La secuencia es la misma: reservar y pasar la butaca a `address(0)`. Para
`holderOf`, `address(0)` significa "libre"; para `booked`, la butaca sigue reservada.

## Paso 2: Una butaca no se pasa a nadie

**Por qué**: `address(0)` no es una cuenta, es la marca de "libre". `transferSeat` tiene que
rechazarla.

```solidity
if (to == address(0)) revert ZeroAddress();
```

**Abre** `src/Seats.sol` y, en `transferSeat`, descomenta la línea del paso 2.

**Verifica**: `[PASS] invariant_BookedMatchesHolders`. La primera ejecución repite antes la
secuencia guardada en `cache/invariant/failures/`, que ahora pasa. Las otras dos invariantes
siguen con su `TODO`.

## Paso 3: El contador de cada cuenta

**Por qué**: `seatsOf[cuenta]` cuenta las butacas de cada cuenta, y también se puede calcular. Por
cada butaca con dueño, cuenta cuántas tiene ese dueño y compáralo.

```solidity
function invariant_SeatsOfMatchesHolders() public view {
    for (uint256 seat = 0; seat < seats.CAPACITY(); seat++) {
        address holder = seats.holderOf(seat);
        if (holder == address(0)) continue;
        uint256 held;
        for (uint256 other = 0; other < seats.CAPACITY(); other++) {
            if (seats.holderOf(other) == holder) held++;
        }
        assertEq(seats.seatsOf(holder), held);
    }
}
```

**Abre** `SeatsInvariants.t.sol` y, en `invariant_SeatsOfMatchesHolders`, borra el `revert` y
descomenta el cuerpo.

**Verifica**: `[FAIL: assertion failed: 0 != 1] invariant_SeatsOfMatchesHolders`. Lee la secuencia:
una cuenta reserva y pasa la butaca a otra. `holderOf` cambia; `seatsOf` de las dos, no. Quien
recibe tiene una butaca que su contador no ve, así que podría reservar dos más.

## Paso 4: El contador sigue a la butaca

**Por qué**: cada función que cambia `holderOf` mantiene los dos contadores. Y si quien recibe ya
tiene `MAX_PER_HOLDER`, no puede recibir otra: el límite vale por cualquier camino, no solo en
`book`.

```solidity
if (seatsOf[to] >= MAX_PER_HOLDER) revert TooManySeats(to);
holderOf[seat] = to;
seatsOf[msg.sender]--;
seatsOf[to]++;
```

**Abre** `Seats.sol` y descomenta las tres líneas del paso 4 en `transferSeat`.

**Verifica**: `invariant_BookedMatchesHolders` y `invariant_SeatsOfMatchesHolders` en verde; la del
paso 5 sigue con su `TODO`.

## Paso 5: El límite por cuenta

**Por qué**: la promesa del contrato es "nadie tiene más de dos butacas". Escrita como
invariante:

```solidity
function invariant_HolderWithinMax() public view {
    for (uint256 seat = 0; seat < seats.CAPACITY(); seat++) {
        address holder = seats.holderOf(seat);
        if (holder != address(0)) assertLe(seats.seatsOf(holder), seats.MAX_PER_HOLDER());
    }
}
```

**Abre** `SeatsInvariants.t.sol` y, en `invariant_HolderWithinMax`, borra el `revert` y descomenta
el cuerpo.

**Verifica**: `forge test` sin error: `5 passed` en `SeatsTest` y las tres invariantes en verde.

```text
 SeatsInvariantsTest invariants (runs: 256, calls: 128000, reverts: 122874)
| Seats    | book         | 42552 | 39879   | 0        |
| Seats    | cancel       | 42476 | 40842   | 0        |
| Seats    | transferSeat | 42972 | 42153   | 0        |
```

## Paso 6: Lo que el fuzzer no alcanza

Sin escribir nada que se entregue: borra en `transferSeat` la línea
`if (seatsOf[to] >= MAX_PER_HOLDER) revert TooManySeats(to);` y vuelve a ejecutar
`forge test --mc SeatsInvariants`.

**Verifica**: las tres invariantes **siguen en verde**, aunque ahora una cuenta puede recibir una
tercera butaca. Para encontrarlo, el fuzzer tendría que elegir como `to` justo una de las tres
cuentas, y con direcciones aleatorias no lo hace. Mira además la tabla: más del 95 % de las
llamadas revierten. El ejercicio 02 arregla las dos cosas con un handler.

Devuelve la línea a su sitio antes de seguir.

## Para pensar

- ¿Por qué los cinco tests unitarios pasaban con los dos fallos? ¿Qué test unitario habrías
  tenido que escribir para cada uno?
- `invariant_HolderWithinMax` lee `seatsOf`. Si el paso 4 no hubiera corregido `seatsOf`, ¿habría
  servido de algo? ¿Cómo la escribirías sin depender de él?
- Escribe como test unitario la secuencia del paso 6: alice reserva dos butacas, bob reserva una
  y se la pasa a alice. ¿Qué línea de `transferSeat` hace que revierta?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Medusa](../../1-teoria/04-medusa.md) | **Ejercicio 01 — Invariantes** | [Ejercicio 02 — Handlers →](../ejercicio-02-handlers/README.md) |
