# Ejercicio 03 — Corregir y revisar

> Al terminar habrás corregido los tres hallazgos del ejercicio 02, cada uno con su test de
> regresión, y habrás revisado la corrección: el cuarto fallo, que no estaba en el informe, lo
> encuentra un test que mira lo que la corrección cambia.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 03 — Corregir hallazgos](../../1-teoria/03-corregir-hallazgos.md) leída
y el [ejercicio 02](../ejercicio-02-auditar-codigo-ajeno/README.md) en verde.

## Contexto

Ahora eres la autora. Te ha llegado el informe del ejercicio 02 y `src/RewardPool.sol` es tu
código, con las correcciones marcadas.

| Archivo | Qué es |
| ------- | ------ |
| `src/RewardPool.sol` | El pool del ejercicio 02 con `_updateGlobal` separado de `_update` y la constante `PRECISION`: pasos 1 a 4 |
| `test/MockToken.sol` | El ERC-20 de los tests |
| `test/Fixes.t.sol` | Tus dos tests de siempre, un test de regresión por hallazgo, un fuzz y el test de la revisión. No lo cambies |

Cada test de regresión es el PoC del ejercicio 02 con la conclusión al revés: el mismo ataque,
y lo que se comprueba es que ya no funciona.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-34-proyecto_integrador/2-practicas/ejercicio-03-corregir-y-revisar/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `2 tests passed, 5 failed`. Pasan los dos de siempre. Los demás fallan con el número
del ataque:

```text
[FAIL: next call did not revert as expected] test_Paso1_RevertWhen_StrangerSetsTheRate() (gas: 145325)
[FAIL: Paso 2: bob acaba de llegar: 43200000000000000000000 != 0] test_Paso2_LateStakerEarnsOnlyFromJoining() (gas: 210219)
[FAIL: Paso 3: el atacante ya no borra nada: 0 != 86400000000000000000000] test_Paso3_PokingEveryBlockKeepsTheRewards() (gas: 412900038)
```

El fuzz `testFuzz_Paso3_EarningsFollowStakeAndTime` también falla, con un contraejemplo distinto
en cada ejecución: forge elige otra semilla.

## Paso 1: Cerrar H-01

**Por qué**: la corrección es una palabra. El test de regresión no comprueba la palabra: repite
el ataque del PoC (el atacante fija un ritmo enorme) y espera que revierta con el error de
`Ownable`.

**Abre** `src/RewardPool.sol`. En `setRewardRate`, borra la línea que acaba en `// <- Paso 1` y
descomenta la de debajo:

```solidity
function setRewardRate(uint256 rate) external onlyOwner {
```

**Verifica**: `3 tests passed, 4 failed`.

## Paso 2: Cerrar H-02

**Por qué**: `stake` cambia el saldo de quien deposita y `totalStaked`: lo ganado hasta ahora se
tiene que apuntar antes, con el saldo y el total de antes, como ya hacen `withdraw` y `claim`.

**Descomenta** la línea de `// PASO 2`, la primera de `stake`:

```solidity
_update(msg.sender);
```

**Verifica**: `4 tests passed, 3 failed`. bob llega con 0 y gana la mitad del segundo día; alice
conserva su primer día entero y la otra mitad del segundo: 129 600. Ahora falla el redondeo:

```text
[FAIL: Paso 3: el atacante ya no borra nada: 0 != 86400000000000000000000] test_Paso3_PokingEveryBlockKeepsTheRewards() (gas: 412910679)
```

## Paso 3: Cerrar H-03

**Por qué**: el problema no es redondear, es redondear **antes** de multiplicar por el saldo.
Con `PRECISION = 1e18`, `rewardPerTokenStored` guarda 18 decimales más: en 12 segundos, una unidad
gana `12e18 * 1e18 / 100e18` = 0,12e18, y no 0. `earned` deshace la escala al final, después de
multiplicar por el saldo. Lo que se pierde ahora es menos de una unidad de `rewardPerTokenStored`
por tramo: con 100 tokens depositados, menos de 100 unidades del token de recompensa (1e-16
tokens).

**Borra** las dos líneas que acaban en `// <- Paso 3` (en `rewardPerToken` y en `earned`) y
descomenta las de debajo:

```solidity
return rewardPerTokenStored + rewardRate * (block.timestamp - lastUpdate) * PRECISION / totalStaked;
```

```solidity
return rewards[account] + balanceOf[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / PRECISION;
```

**Verifica**: `6 tests passed, 1 failed`. Las 7200 llamadas del atacante ya no cambian nada: alice
gana sus 86 400. Y el fuzz pasa: con dos depósitos y un tiempo cualesquiera, cada uno gana su parte
con un error de menos de 1000 unidades, y entre los dos nunca más de lo repartido.

Las tres correcciones del informe están hechas. Falta revisarlas:

```text
[FAIL: Paso 4: el primer dia, al ritmo de antes: 172800000000000000000000 != 86400000000000000000000] test_Paso4_RateChangeIsNotRetroactive() (gas: 181985)
```

## Paso 4: Revisar la corrección de H-01

**Por qué**: revisar una corrección no es ver que el PoC ya no pasa: es mirar qué hace ahora el
código que se ha tocado. `setRewardRate` es solo del dueño, pero cambia el ritmo sin cerrar lo
acumulado. `rewardPerToken` calcula todo el tiempo desde `lastUpdate` con el ritmo **nuevo**: si el
dueño lo dobla tras un día sin que nadie haya tocado el pool, ese día ya pagado a una por segundo
pasa a pagar dos. Si el dueño lo baja, alice pierde lo que ya había ganado. Con el ritmo muy alto,
el pool debe más de lo que tiene.

Es la misma clase de fallo que H-02 (cambiar algo sin `_update` antes) en otra función. El
ejercicio 02 no lo encontró porque el PoC de H-01 lo explotaba un extraño, y con eso ya era
crítico.

**Descomenta** la línea de `// PASO 4`, la primera de `setRewardRate`:

```solidity
_updateGlobal();
```

`_updateGlobal` y no `_update`: el dueño no deposita, no hay ninguna cuenta que apuntar, solo el
acumulado global.

**Verifica**: `7 tests passed, 0 failed`. Con `forge test --deny warnings`, sin warnings. El primer
día, 86 400; el segundo, al nuevo ritmo, 172 800 más.

## Para la respuesta al informe

La autora responde cada hallazgo con su estado y la prueba:

| Id | Estado | Corrección | Test de regresión |
| -- | ------ | ---------- | ----------------- |
| H-01 | Corregido | `onlyOwner` en `setRewardRate` | `test_Paso1_RevertWhen_StrangerSetsTheRate` |
| H-02 | Corregido | `_update` en `stake` | `test_Paso2_LateStakerEarnsOnlyFromJoining` |
| H-03 | Corregido | `PRECISION` en `rewardPerToken` y `earned` | `test_Paso3_PokingEveryBlockKeepsTheRewards`, `testFuzz_Paso3_EarningsFollowStakeAndTime` |
| H-04 | Corregido (encontrado en la revisión) | `_updateGlobal` en `setRewardRate` | `test_Paso4_RateChangeIsNotRetroactive` |

## Para pensar

- El fuzz del paso 3 compara con `RATE * together * stake / total`. ¿Por qué no podía ser un
  `assertEq`? ¿De dónde sale el margen de 1000?
- ¿Habría encontrado el fuzz el fallo del paso 4 si también llamara a `setRewardRate`? ¿Qué
  tendría que comprobar?
- El dueño sigue pudiendo fijar un ritmo que el pool no puede pagar. ¿Lo corriges con un `require`
  o lo dejas como suposición de confianza en el informe? ¿Qué hace `notifyRewardAmount` de
  Synthetix?
- Un PoC que se convierte en test de regresión, ¿debería estar en el repositorio de la autora o en
  el del auditor? ¿Quién lo mantiene después?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Auditar código ajeno](../ejercicio-02-auditar-codigo-ajeno/README.md) | **Ejercicio 03 — Corregir y revisar** | [Proyecto — La entrega final →](../../3-proyecto/README.md) |
