# Ejercicio 01 — Slither

> Al terminar habrás pasado Slither por un contrato con fallos, habrás leído cada hallazgo,
> habrás corregido los verdaderos y justificado el que no lo es, hasta dejarlo en 0.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 01 — Qué es el análisis estático](../../1-teoria/01-que-es-el-analisis-estatico.md)
y [Teoría 02 — Slither](../../1-teoria/02-slither.md) leídas.

## Contexto

`Crowdfund` es una campaña de financiación. Se aportan ETH hasta una fecha. Si se llega al
objetivo, el dueño se lleva lo recaudado y cada aportante cobra 100 tokens de recompensa por
cada ETH; si no, cada uno recupera lo suyo. Tiene los fallos de la semana 21, uno detrás de otro,
y Slither los encuentra todos.

El proyecto Foundry está en `contracts/`. `test.sh` ejecuta los tests de Foundry, compila sin
warnings y pasa Slither con `contracts/slither.config.json`:

```json
{
  "exclude_dependencies": true,
  "exclude_informational": true,
  "exclude_optimization": true,
  "fail_on": "low"
}
```

Es decir: no mira OpenZeppelin, ignora los avisos de estilo y de gas, y falla con cualquier
hallazgo de impacto bajo, medio o alto.

| Archivo | Qué es |
| ------- | ------ |
| `contracts/src/Crowdfund.sol` | La campaña. Pasos 1 a 6 |
| `contracts/test/helpers/Helpers.sol` | Un token, un token que devuelve `false`, un atacante y un phisher. Hecho |
| `contracts/test/Crowdfund.t.sol` | Los tests. **No lo modifiques** |
| `contracts/slither.config.json` | La configuración de Slither. **No la modifiques** |

En `Crowdfund.sol`, las líneas que acaban en `// <- Paso N` son las que **sustituyes** en ese
paso: bórralas y descomenta las líneas `//> ` que las siguen.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-23-analisis_estatico/2-practicas/ejercicio-01-slither/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: `0 passed; 6 failed`. `test.sh` se para ahí: con los tests en rojo no llega a
Slither. Ejecútalo tú desde `contracts/`:

```bash
cd contracts
slither .
```

**Verifica**: la última línea es `analyzed (6 contracts with 75 detectors), 8 result(s) found`.
Son 8 hallazgos en 7 detectores: `reentrancy-eth`, `unchecked-transfer`, `incorrect-equality`,
`tx-origin`, `missing-zero-check`, `reentrancy-events` y `timestamp` (dos). El primero:

```text
Detector: reentrancy-eth
Reentrancy in Crowdfund.refund() (src/Crowdfund.sol#72-84):
	External calls:
	- (ok,None) = msg.sender.call{value: amount}() (src/Crowdfund.sol#78)
	State variables written after the call(s):
	- contributed[msg.sender] = 0 (src/Crowdfund.sol#80)
```

Ahora sin la configuración, con todos los detectores y también sobre OpenZeppelin:

```bash
slither . --config-file /dev/null
```

**Verifica**: `21 result(s) found`. Los 13 de más son informativos (versiones de `pragma`,
llamadas de bajo nivel, nombres en mayúsculas) o están en OpenZeppelin. Por eso la configuración
existe. Vuelve con `cd ..` y sigue.

## Paso 1: Reentrancy

**Por qué**: Slither ha visto lo mismo que la semana 21. `refund` envía ETH y después pone el
aporte a 0: quien recibe vuelve a llamar a `refund` y cobra otra vez. Además, `refund` emite su
evento después de la llamada, y eso es el segundo hallazgo, `reentrancy-events`. Checks-effects-
interactions: la llamada va al final.

```solidity
contributed[msg.sender] = 0;
emit Refunded(msg.sender, amount);
(bool ok,) = msg.sender.call{value: amount}("");
if (!ok) revert TransferFailed();
```

**Abre** `contracts/src/Crowdfund.sol`. En `refund`, borra las dos líneas marcadas `// <- Paso 1`
(la llamada y su comprobación) y descomenta las dos `//> ` de debajo.

**Verifica**: `bash test.sh` da `1 passed; 5 failed`, con `test_Paso1_RefundIsNotReentrant` en
verde: `RefundAttacker` aporta 1 ETH, intenta cobrarlo dos veces y solo recupera 1; los 3 ETH de
Alice se quedan en la campaña. Sin la corrección se llevaba 2. En `contracts/`, `slither .` da
`6 result(s) found`: han caído `reentrancy-eth` y `reentrancy-events`.

## Paso 2: Un `transfer` que nadie comprueba

**Por qué**: `IERC20.transfer` devuelve `bool`. Algunos tokens reales no revierten cuando fallan:
devuelven `false`. `claimReward` no lo mira, marca la recompensa como cobrada y el aportante se
queda sin nada. `SafeERC20` (semana 11) revierte si el token devuelve `false`.

```solidity
REWARD.safeTransfer(msg.sender, contributed[msg.sender] * REWARD_PER_WEI);
```

**Abre** `Crowdfund.sol` y, en `claimReward`, sustituye la línea `// <- Paso 2` por la de debajo.

**Verifica**: `2 passed; 4 failed`. `test_Paso2_RevertWhen_RewardTransferFails` en verde: con
`FalseToken`, `claimReward` revierte con `SafeERC20FailedOperation(token)`. Slither:
`5 result(s) found`, sin `unchecked-transfer`.

## Paso 3: Una igualdad con el saldo

**Por qué**: `goalReached` pregunta si el saldo es **exactamente** el objetivo. Basta con aportar
de más, o con enviar ETH forzado (semana 21), para que nunca lo sea. Y después de `withdraw` el
saldo es 0: nadie puede cobrar su recompensa. Slither avisa de toda igualdad estricta con un saldo
(`incorrect-equality`). La cuenta buena es lo aportado, con `>=`.

```solidity
return raised >= GOAL;
```

**Abre** `Crowdfund.sol` y, en `goalReached`, sustituye la línea `// <- Paso 3`.

**Verifica**: `4 passed; 2 failed`. En verde, `test_Paso3_GoalReachedWhenOvershooting` (11 ETH
para un objetivo de 10) y también `test_ReachGoalAndWithdraw`, que fallaba desde el principio con
`GoalNotReached()`: tras el `withdraw`, Alice no podía cobrar sus 600 tokens. Slither:
`4 result(s) found`.

## Paso 4: `tx.origin`

**Por qué**: es el phishing de la semana 21. Si el dueño llama a cualquier contrato, ese contrato
puede llamar a `setOwner` y `tx.origin` sigue siendo el dueño.

```solidity
if (msg.sender != owner) revert NotOwner();
```

**Abre** `Crowdfund.sol` y, en `setOwner`, sustituye la línea `// <- Paso 4` por la primera `//> `
de debajo. La segunda es del paso 5: déjala comentada.

**Verifica**: `5 passed; 1 failed`. `test_Paso4_RevertWhen_OwnerIsPhished` en verde: el dueño
llama a `Phisher.claimGift` y la llamada a `setOwner` revierte con `NotOwner()`. Slither:
`3 result(s) found`.

## Paso 5: La dirección cero

**Por qué**: `missing-zero-check` es de impacto bajo. `setOwner(address(0))` deja la campaña sin
dueño para siempre: lo recaudado no lo saca nadie. No es un ataque, es un error de dedo que no
tiene vuelta atrás, y cuesta una línea evitarlo.

```solidity
if (newOwner == address(0)) revert ZeroAddress();
```

**Abre** `Crowdfund.sol` y descomenta la línea del paso 5 en `setOwner`.

**Verifica**: `6 passed`. Slither: `2 result(s) found`, los dos `timestamp`. `bash test.sh` sigue
fallando: ahora sí llega a Slither, y Slither falla.

## Paso 6: Justificar lo que no se corrige

**Por qué**: `contribute` y `refund` comparan `block.timestamp` con `DEADLINE`. Un validador puede
mover el timestamp unos segundos (semana 07), y Slither avisa de cada comparación. Para una campaña
de días, unos segundos no cambian nada: no es un fallo, es una decisión. Una decisión se escribe
en el código, encima de la línea, con su porqué, y se silencia solo ese aviso en esa línea:

```solidity
// slither-disable-next-line timestamp
if (block.timestamp >= DEADLINE) revert CampaignEnded();
```

**Abre** `Crowdfund.sol` y descomenta los dos `//> // slither-disable-next-line timestamp`, en
`contribute` y en `refund`. Escribe encima de cada uno, con tus palabras, por qué lo aceptas.

**Verifica**: `bash test.sh` termina sin error, y su última línea es
`analyzed (6 contracts with 75 detectors), 0 result(s) found`.

## Para pensar

- ¿Qué habría pasado si en el paso 6 hubieras añadido `"detectors_to_exclude": "timestamp"` a la
  configuración? ¿Qué perderías el día que alguien escriba una comparación con el timestamp que
  sí importa?
- `withdraw` también envía ETH con `call`, y Slither no la marca como reentrancy. ¿Por qué?
  (Pista: ¿qué escribe después de la llamada?)
- Slither encontró los cinco fallos porque son patrones conocidos. Piensa en un fallo de esta
  campaña que ningún detector podría encontrar.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Detectores propios](../../1-teoria/04-detectores-propios.md) | **Ejercicio 01 — Slither** | [Ejercicio 02 — forge lint →](../ejercicio-02-forge-lint/README.md) |
