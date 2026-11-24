# Ejercicio 03 — Optimizar sin romper

> Al terminar habrás arreglado cinco optimizaciones que ahorran gas y rompen algo: un tipo que
> trunca, un `unchecked` sin comprobación, un valor cacheado que deja entrar una reentrancy, una
> máscara de bitmap mal escrita y un contador que da la vuelta. Cada arreglo mantiene el ahorro.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 04 — Cuándo no optimizar](../../1-teoria/04-cuando-no-optimizar.md)
leída y el [ejercicio 02](../ejercicio-02-codigo-barato/README.md) en verde.

## Contexto

Proyecto Foundry. `TipJar` es un bote de propinas en ETH: cualquiera da propina a una cuenta,
cada cuenta retira lo suyo, y hay insignias numeradas que se reclaman una vez. Alguien lo
"optimizó" sin tests de borde: el saldo cabe en un `uint96` junto a la fecha, la resta va en
`unchecked`, el saldo se lee una vez a una variable local, las insignias van en un bitmap y el
bucle de `tipMany` usa un contador de 8 bits. Cada optimización tiene un fallo.

| Archivo | Qué es |
| ------- | ------ |
| `src/TipJar.sol` | El contrato: tu trabajo, pasos 1 a 5 |
| `test/TipJar.t.sol` | Un test de comportamiento normal, en verde desde el principio, uno por paso que provoca su fallo, y `Reenterer`, un atacante que vuelve a entrar en `withdraw`. No lo cambies |

En el `setUp`, `alice` da 5 ether de propina a `bob`: es lo que un fallo podría llevarse del bote.
Como en los ejercicios anteriores, cada paso borra las líneas que acaban en `// <- Paso N` (si las
hay) y descomenta las suyas.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-29-optimizacion_de_gas/2-practicas/ejercicio-03-optimizar-sin-romper/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `1 tests passed, 5 failed`. El que pasa, `test_TipAndWithdraw`, es el uso normal:
dar, retirar una parte, mirar el saldo. Con él solo, el bote parecería correcto.

## Paso 1: El `uint96` que trunca

**Por qué**: `uint96(amount)` no revierte si `amount` no cabe en 96 bits: se queda con los 96 bits
bajos (semana 04). Una propina de 2⁹⁶ wei suma 0 al saldo y el ETH se queda en el bote para
nadie. 2⁹⁶ wei son unos 79 000 millones de ether: no es un caso real hoy, pero el mismo fallo con
un `uint64` o un `uint32` sí lo sería. La suma `+=` sí está comprobada; la conversión, no.

**Abre** `src/TipJar.sol` y resuelve `_credit`:

```solidity
if (amount > type(uint96).max) revert TooLarge(amount);
account.balance += uint96(amount);
```

El empaquetado se queda: lo que cambia es que nada entra en el `uint96` sin caber.

**Verifica**: `2 tests passed, 4 failed`. `test_Paso1_RevertWhen_TipTooLarge` fallaba con
`next call did not revert as expected`; ahora espera `TooLarge` con el importe.

## Paso 2: El `unchecked` sin comprobación

**Por qué**: en `withdraw`, `balance - uint96(amount)` va dentro de `unchecked` para ahorrar la
comprobación. Pero nada comprueba antes que `amount` no pase del saldo: con 1 ether de saldo,
retirar 2 envía 2 ether, del dinero de `bob`, y deja un saldo de casi 2⁹⁶.

**Abre** `src/TipJar.sol` y descomenta la comprobación de `withdraw`, debajo de `PASO 2`:

```solidity
if (amount > balance) revert InsufficientBalance(amount, balance);
```

Con ella, el `unchecked` vuelve a ser seguro: la resta ya no puede bajar de cero (teoría 03).

**Verifica**: `3 tests passed, 3 failed`.

## Paso 3: El saldo cacheado y la reentrancy

**Por qué**: `withdraw` lee el saldo una vez a `balance`, envía el ETH y **después** escribe
`balance - amount`. Leer una vez es buena idea (teoría 02); escribir después de la llamada, no.
`Reenterer` retira 1 ether y, al recibirlo, vuelve a llamar a `withdraw`: el saldo de storage
sigue siendo 1 ether, la comprobación del paso 2 pasa y recibe otro. Es la reentrancy de la
semana 21:

```text
[FAIL: assertion failed: 2000000000000000000 != 1000000000000000000] test_Paso3_ReentrancyCannotDrain()
```

**Abre** `src/TipJar.sol` y mueve la escritura antes de la llamada: borra las tres líneas del
`unchecked` del final, que acaban en `// <- Paso 3`, y descomenta las de debajo de `PASO 3`:

```solidity
unchecked {
    account.balance = balance - uint96(amount);
}
```

Sigue siendo una lectura y una escritura: el ahorro no cambia, solo el orden
(checks-effects-interactions, semana 21).

**Verifica**: `4 tests passed, 2 failed`. La segunda entrada encuentra el saldo a 0 y revierte con
`InsufficientBalance`; el atacante se queda con su ether y el bote, con los 5 de `bob`.

## Paso 4: La máscara del bitmap

**Por qué**: `claimBadge` guarda 256 insignias por palabra: la palabra es `badge >> 8` y el bit,
los 8 bits bajos, `badge & 0xff`. Con `badge & 0x7f` solo mira 7 bits: la insignia 128 usa el
mismo bit que la 0, y quien reclama la 0 deja la 128 "reclamada":

```text
[FAIL: BadgeTaken(128)] test_Paso4_BadgesDoNotCollide()
```

**Abre** `src/TipJar.sol` y resuelve la máscara:

```solidity
uint256 bit = 1 << (badge & 0xff);
```

**Verifica**: `5 tests passed, 1 failed`. El test reclama la 0 y la 128, de la misma palabra, y
comprueba que la 128 no se puede reclamar dos veces.

## Paso 5: El contador de 8 bits

**Por qué**: `tipMany` recorre `to` con `uint8 i` y `unchecked { ++i; }`, para que el contador
"ocupe menos" y el incremento no se compruebe. En la pila todo ocupa una palabra de 32 bytes
(semana 27): un `uint8` no ahorra nada, y con más de 255 destinatarios, `++i` pasa de 255 a 0 y el bucle vuelve
a empezar. No acaba nunca:

```text
[FAIL: EvmError: Revert] test_Paso5_TipManyPaysEveryone() (gas: 1056947240)
```

El test repartió entre 300 cuentas y gastó más de mil millones de gas antes de quedarse sin él.

**Abre** `src/TipJar.sol` y cambia el tipo del contador:

```solidity
for (uint256 i = 0; i < to.length;) {
```

**Verifica**: `6 tests passed, 0 failed`. Las 300 cuentas reciben 0,01 ether cada una.

## Para pensar

- Ninguno de los cinco fallos lo detecta `test_TipAndWithdraw`. ¿Qué tienen en común los cinco
  tests que sí los detectan?
- En el paso 5, el `unchecked { ++i; }` se queda. ¿Puede dar la vuelta un `uint256` que empieza en
  0 y avanza de uno en uno hasta la longitud de un array? ¿Qué hace solc con un `for` normal desde
  la 0.8.22 (teoría 03)?
- ¿Qué invariante de la semana 24 habría encontrado los pasos 2 y 3 sin escribir un test para cada
  uno?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Código barato](../ejercicio-02-codigo-barato/README.md) | **Ejercicio 03 — Optimizar sin romper** | [Proyecto — Un alta más barata →](../../3-proyecto/README.md) |
