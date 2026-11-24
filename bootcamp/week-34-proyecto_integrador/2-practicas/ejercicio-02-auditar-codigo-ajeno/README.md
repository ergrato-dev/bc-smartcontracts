# Ejercicio 02 — Auditar código ajeno

> Al terminar habrás auditado el pool de recompensas de otra aprendiz: tres hallazgos, cada uno
> con una prueba de concepto que lo demuestra con números, y una sospecha que un test descarta.
> Es lo mismo que harás en el proyecto con el protocolo de tu pareja.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 02 — Auditoría cruzada](../../1-teoria/02-auditoria-cruzada.md) leída.

## Contexto

`RewardPool` reparte recompensas entre quienes depositan: cada segundo, `rewardRate` unidades de
`rewardToken` entre todo lo depositado, en proporción al saldo de cada uno. Es el modelo de
`StakingRewards` de Synthetix, que usan muchos protocolos DeFi:

- `rewardPerTokenStored` es lo que ha ganado **una** unidad depositada desde el principio.
- Cada cuenta guarda cuánto valía eso la última vez que se la tocó (`userRewardPerTokenPaid`) y lo
  que llevaba ganado entonces (`rewards`).
- `earned` = `rewards` + saldo × (lo que vale ahora − lo que valía entonces).
- `_update(cuenta)` pone las dos cosas al día. Hay que llamarla **antes** de cambiar un saldo o el
  ritmo; si no, lo nuevo se aplica a un tiempo en el que no estaba.

| Archivo | Qué es |
| ------- | ------ |
| `src/RewardPool.sol` | El código que auditas. **No lo cambies**: es el commit de la auditoría |
| `test/MockToken.sol` | Un ERC-20 que cualquiera acuña, para los tests |
| `test/Audit.t.sol` | Dos tests de la autora y tus cuatro pruebas de concepto |

En el `setUp`, el dueño llena el pool con 1 000 000 de recompensas y fija el ritmo en una por
segundo. alice, bob y attacker tienen 1000 tokens para depositar y ya han dado el `approve`.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-34-proyecto_integrador/2-practicas/ejercicio-02-auditar-codigo-ajeno/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `2 tests passed, 4 failed`. Los dos de la autora pasan: alice deposita 100, espera
un día y cobra 86 400. El código hace lo que su autora probó. Lo que vas a buscar es lo que no
probó:

```text
[FAIL: TODO: Paso 1] test_Paso1_PoC_AnyoneSetsTheRateAndDrainsThePool() (gas: 188142)
```

Antes de escribir nada, lee `RewardPool.sol` entero y apunta, por cada función externa: quién
puede llamarla, qué cambia y si llama a `_update` antes. Esa tabla de una línea por función ya te
da los dos primeros hallazgos.

## Paso 1: H-01, cualquiera fija el ritmo

**Por qué**: `setRewardRate` no tiene `onlyOwner`. El contrato hereda `Ownable`, y la autora lo
usó en el constructor y se olvidó aquí: los tests del dueño pasan igual. El PoC no se queda en
"cualquiera puede llamarla": calcula el ritmo con el que la parte del atacante en **un segundo** es
el pool entero, y lo cobra.

**Abre** `test/Audit.t.sol`, borra el `revert` del paso 1 y descomenta:

```solidity
uint256 rate = FUNDED * pool.totalStaked() / 1e18;
vm.prank(attacker);
pool.setRewardRate(rate);
vm.warp(block.timestamp + 1);
vm.prank(attacker);
pool.claim();
assertEq(rewardToken.balanceOf(attacker), FUNDED, "H-01: el atacante se lleva todo el pool");
vm.warp(block.timestamp + 1 days);
vm.prank(alice);
vm.expectRevert();
pool.claim();
```

En un segundo, una unidad depositada gana `rate / totalStaked`. El atacante tiene 1e18 unidades:
gana `rate * 1e18 / totalStaked`, que con ese `rate` es `FUNDED`. Después, alice no puede cobrar:
el pool está vacío y la transferencia revierte.

**Verifica**: `3 tests passed, 3 failed`.

```text
[FAIL: TODO: Paso 2] test_Paso2_PoC_LateStakerTakesHalfOfAlicesRewards() (gas: 133848)
```

## Paso 2: H-02, quien llega tarde cobra lo de antes

**Por qué**: `withdraw` y `claim` llaman a `_update`; `stake` no. Si bob deposita sin que se
apunte nada, su `userRewardPerTokenPaid` es 0: para el contrato, bob lleva ahí desde el principio.
Y como `totalStaked` sube sin cerrar lo acumulado, el día de alice se reparte entre los dos.

**Borra** el `revert` del paso 2 y descomenta:

```solidity
_stake(bob, 100e18);
vm.prank(bob);
pool.claim();
assertEq(rewardToken.balanceOf(bob), 43_200e18, "H-02: bob cobra medio dia que no estuvo");
assertEq(pool.earned(alice), 43_200e18, "H-02: alice pierde la mitad");
```

**Verifica**: `4 tests passed, 2 failed`. bob cobra 43 200 en el mismo bloque en que deposita, y
alice pasa de 86 400 a 43 200.

```text
[FAIL: TODO: Paso 3] test_Paso3_PoC_PokingEveryBlockErasesTheRewards() (gas: 114913)
```

## Paso 3: H-03, el redondeo borra las recompensas

**Por qué**: `rewardPerToken` divide `rewardRate * segundos` entre `totalStaked`, sin escala. Con
100e18 depositados y una recompensa por segundo, en 12 segundos (un bloque) una unidad gana
`12e18 / 100e18`, que en enteros es 0. Si nadie toca el pool en un día, gana 864 y no se pierde
nada. Pero `claim` lo puede llamar cualquiera, aunque no tenga nada, y cada llamada pone
`lastUpdate` al día: si alguien la llama en cada bloque, cada tramo redondea a 0.

**Borra** el `revert` del paso 3 y descomenta:

```solidity
for (uint256 i = 0; i < 1 days / 12; i++) {
    vm.warp(block.timestamp + 12);
    vm.prank(attacker);
    pool.claim();
}
assertEq(pool.earned(alice), 0, "H-03: un dia entero y alice no ha ganado nada");
```

**Verifica**: `5 tests passed, 1 failed`. Siete mil doscientas llamadas y alice no ha ganado
nada. El atacante tampoco: no roba, rompe. Eso cambia su severidad (teoría 02).

```text
[FAIL: TODO: Paso 4] test_Paso4_NoOneWithdrawsMoreThanTheirStake() (gas: 188098)
```

## Paso 4: Una sospecha que no es un hallazgo

**Por qué**: `withdraw` no comprueba que `amount` sea como mucho tu saldo. Parece un hallazgo,
pero desde Solidity 0.8 la resta `balanceOf[msg.sender] -= amount` revierte si se pasa de cero
(semana 05). Una sospecha se cierra igual que un hallazgo: con un test. Así no acaba en el
informe, y si alguien añade un `unchecked` mañana, el test lo dice.

**Borra** el `revert` del paso 4 y descomenta:

```solidity
vm.prank(attacker);
vm.expectRevert(stdError.arithmeticError);
pool.withdraw(2e18);
assertEq(stakingToken.balanceOf(address(pool)), 101e18, "el deposito de alice sigue en el pool");
```

**Verifica**: `6 tests passed, 0 failed`. Con `forge test --deny warnings`, sin warnings.

## Para el informe

Con los cuatro tests, los hallazgos se escriben solos. En el formato de la teoría 02:

| Id | Título | Severidad | PoC |
| -- | ------ | --------- | --- |
| H-01 | Cualquiera fija el ritmo y vacía el pool | Crítica | `test_Paso1_PoC_AnyoneSetsTheRateAndDrainsThePool` |
| H-02 | `stake` no apunta lo ganado: quien llega tarde cobra lo de antes | Alta | `test_Paso2_PoC_LateStakerTakesHalfOfAlicesRewards` |
| H-03 | El redondeo deja que cualquiera borre las recompensas | Media | `test_Paso3_PoC_PokingEveryBlockErasesTheRewards` |

H-01 lo explota cualquiera y se lleva todo: crítica. H-02 roba, pero hace falta depositar y solo
se lleva la parte de un tramo: alta. H-03 no da beneficio al atacante y le cuesta gas en cada
bloque, pero deja a todos sin recompensas: media. Si no estás de acuerdo con alguna, apunta por
qué: la severidad se discute con la autora, y el impacto y la probabilidad son los argumentos.

## Para pensar

- El PoC de H-01 calcula el ritmo exacto. ¿Por qué no basta con un PoC que demuestre que
  `setRewardRate` no revierte para un extraño?
- ¿H-03 seguiría ocurriendo si `claim` revirtiera cuando no hay nada que cobrar? ¿Qué otra función
  pública llama a `_update`?
- Con H-01 corregido, ¿puede el dueño hacer algo de lo que hace el atacante del paso 1? ¿Eso es un
  hallazgo o una suposición de confianza que va en el informe?
- Lee otra vez `setRewardRate`: además de quién la llama, ¿qué le falta antes de cambiar el ritmo?
  Lo verás en el ejercicio 03.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Un despliegue que se comprueba](../ejercicio-01-un-despliegue-que-se-comprueba/README.md) | **Ejercicio 02 — Auditar código ajeno** | [Ejercicio 03 — Corregir y revisar →](../ejercicio-03-corregir-y-revisar/README.md) |
