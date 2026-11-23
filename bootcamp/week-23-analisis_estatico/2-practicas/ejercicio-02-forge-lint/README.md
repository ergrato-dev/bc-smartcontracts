# Ejercicio 02 — forge lint

> Al terminar habrás corregido un contrato de staking hasta que `forge lint` no tenga nada que
> decir, habrás comparado lo que ve con lo que ve Slither, y habrás encontrado el fallo que no ve
> ninguno de los dos.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 03 — forge lint](../../1-teoria/03-forge-lint.md) leída y el
[ejercicio 01](../ejercicio-01-slither/README.md) terminado.

## Contexto

`Staking` guarda tokens y paga ETH en proporción a cuántos dejas y durante cuánto tiempo, un 10 %
anual: 1 token rinde 0,1 ETH al año. Cualquiera aporta el ETH de las recompensas enviándolo al
contrato. Cada cuenta tiene una posición, `amount` y `since`, empaquetada en un slot de storage
(semana 04) con un `uint96` y un `uint64`.

`test.sh` ejecuta los tests de Foundry, compila sin warnings de solc y pasa
`forge lint --deny warnings src`: falla con cualquier aviso del linter sobre `src/`.

| Archivo | Qué es |
| ------- | ------ |
| `src/Staking.sol` | El staking. Pasos 1 a 4 |
| `src/Token.sol` | ERC-20 de prueba. Hecho |
| `test/Staking.t.sol` | Los tests. **No lo modifiques** |

Como en el ejercicio 01, las líneas que acaban en `// <- Paso N` se sustituyen por las `//> ` que
las siguen.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-23-analisis_estatico/2-practicas/ejercicio-02-forge-lint/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: `0 passed; 4 failed`. Ahora el linter, solo sobre `src/`:

```bash
forge lint src
```

**Verifica**: 5 avisos, todos `warning`: 1 `unchecked-call`, 3 `unsafe-typecast` y 1
`divide-before-multiply`. Cada uno señala la columna exacta:

```text
warning[unchecked-call]: low-level call does not check the success return value
   ╭▸ src/Staking.sol:77:9
   │
77 │         payable(msg.sender).call{value: reward}(""); // <- Paso 1
   │         ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Y Slither, con los mismos filtros que la configuración del ejercicio 01:

```bash
slither . --exclude-dependencies --exclude-informational --exclude-optimization
```

**Verifica**: `6 result(s) found`. Coinciden en dos: `divide-before-multiply` y la llamada sin
comprobar (`unchecked-lowlevel` en Slither). Slither no tiene detector de conversiones que
truncan. Y añade cuatro que forge lint no da: `arbitrary-send-eth` (envía ETH a `msg.sender`, que
cobra lo suyo), y `incorrect-equality` y dos `timestamp` sobre `amount == 0` y
`positions[msg.sender].amount != 0`. Esos tres los da porque `amount` comparte struct con `since`,
un timestamp: no hay ninguna comparación con el tiempo. Son falsos positivos.

## Paso 1: Una llamada que nadie comprueba

**Por qué**: `call` devuelve `false` si quien recibe revierte, y no revierte por sí sola. Si la
cuenta no acepta ETH, `claim` adelanta `since` y la recompensa se pierde sin un error. Hasta solc
avisa: `Warning (9302): Return value of low-level calls not used.`

```solidity
(bool ok,) = payable(msg.sender).call{value: reward}("");
if (!ok) revert TransferFailed();
```

**Abre** `src/Staking.sol` y, en `_sendReward`, sustituye la línea `// <- Paso 1` por las dos de
debajo.

**Verifica**: `1 passed; 3 failed`. `test_Paso1_RevertWhen_RewardIsRejected` en verde: un contrato
sin `receive` llama a `claim` y recibe `TransferFailed()`. `forge lint src` da 4 avisos.

## Paso 2: Dividir antes de multiplicar

**Por qué**: `elapsed / YEAR` es 0 para cualquier posición de menos de un año, y 0 por lo que sea
es 0 (teoría 04 de la semana 22). Todas las divisiones van al final, en una.

```solidity
return elapsed * position.amount * RATE_BPS / (YEAR * BPS);
```

**Abre** `Staking.sol` y, en `earned`, sustituye la línea `// <- Paso 2`.

**Verifica**: `2 passed; 2 failed`. `test_Paso2_RewardAfterThirtyDays` en verde: 100 tokens durante
30 días generan `0.821917808219178082 ether` (10 ETH × 30 / 365). Antes, 0. Quedan 3 avisos, los
tres `unsafe-typecast`.

## Paso 3: Conversiones que truncan

**Por qué**: `uint96(amount)` se queda con los 96 bits bajos sin avisar. Un token con billones de
unidades (los hay) supera `type(uint96).max`: el staking guarda una cantidad truncada, en el test
0, y se queda con los tokens. `SafeCast` (semana 21) revierte si el valor no cabe. El
`uint64(block.timestamp)` no se desborda hasta dentro de miles de millones de años, pero con
`SafeCast` el linter deja de avisar y no hace falta justificarlo.

```solidity
positions[msg.sender] = Position(amount.toUint96(), block.timestamp.toUint64());
```

```solidity
positions[msg.sender].since = block.timestamp.toUint64();
```

**Abre** `Staking.sol` y sustituye las dos líneas `// <- Paso 3`, en `stake` y en `claim`.

**Verifica**: `3 passed; 1 failed`. `test_Paso3_RevertWhen_AmountDoesNotFit` en verde: apostar
`type(uint96).max + 1` revierte con `SafeCastOverflowedUintDowncast(96, cantidad)`. `forge lint src`
ya no da ningún aviso. Pero `test_Paso4_UnstakePaysReward` sigue en rojo.

## Paso 4: Lo que ninguna herramienta ve

**Por qué**: Alice deja 100 tokens un año y llama a `unstake`. Recupera sus tokens y **pierde** sus
10 ETH: `unstake` borra la posición sin pagar lo generado. El código es correcto como Solidity, no
repite ningún patrón peligroso, y ni forge lint ni Slither dicen nada. Lo encuentra un test que
compruebe lo que el contrato promete.

La recompensa se calcula antes de borrar la posición y se envía al final, después de devolver los
tokens: checks-effects-interactions.

```solidity
uint256 reward = earned(msg.sender);
delete positions[msg.sender];
TOKEN.safeTransfer(msg.sender, amount);
_sendReward(reward);
```

**Abre** `Staking.sol` y, en `unstake`, descomenta las dos líneas `//> ` del paso 4.

**Verifica**: `bash test.sh` termina sin error: `4 passed` y `forge lint` sin avisos.

## Para pensar

- En el paso 4, ¿qué pasa si en vez de calcular `reward` y enviarlo al final llamas a una función
  pública `claim()` al principio de `unstake`? Pruébalo en una copia y pasa `forge lint src`.
- En este contrato, forge lint dio un aviso discutible (el `uint64` del timestamp) y Slither,
  cuatro falsos positivos. En el ejercicio
  01, ¿cuál de los dos habría dado más? Pasa `forge lint src` en `contracts/` del ejercicio 01.
- ¿Qué cambiarías en `Staking` si las recompensas se pagaran en un ERC-20 en vez de en ETH?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Slither](../ejercicio-01-slither/README.md) | **Ejercicio 02 — forge lint** | [Ejercicio 03 — Detector propio →](../ejercicio-03-detector-propio/README.md) |
