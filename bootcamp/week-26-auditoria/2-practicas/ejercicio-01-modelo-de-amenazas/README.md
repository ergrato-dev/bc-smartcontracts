# Ejercicio 01 — Modelo de amenazas

> Al terminar habrás convertido el modelo de amenazas de un escrow en cinco tests, uno por
> amenaza, y uno de ellos habrá destapado un fallo que corriges con una línea.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 01 — Metodología de auditoría](../../1-teoria/01-metodologia-de-auditoria.md)
y [Teoría 02 — Modelado de amenazas](../../1-teoria/02-modelado-de-amenazas.md) leídas.

## Contexto

Proyecto Foundry. `Escrow` guarda ETH entre una compradora y un vendedor: Alice deposita, Bob
entrega, Alice libera el pago. Si Bob no entrega, Alice recupera el ETH tras el plazo; si no se
ponen de acuerdo, cualquiera de los dos abre una disputa dentro del plazo y la decide el árbitro.

| Archivo | Qué es |
| ------- | ------ |
| `src/Escrow.sol` | El contrato auditado. Paso 5 |
| `test/Threats.t.sol` | Un test por amenaza: tu trabajo, pasos 1 a 4. `test_OpenAndRelease` es el modelo |

En el `setUp`, Alice abre un trato de 1 ETH para Bob con un plazo de 7 días.

El modelo de amenazas que vas a probar, el de la teoría 02:

| Id | Amenaza | Test |
| -- | ------- | ---- |
| T-01 | Alguien de fuera mueve el ETH de un trato | `test_Paso1_RevertWhen_StrangerMovesFunds` |
| T-02 | Un trato se paga dos veces | `test_Paso2_RevertWhen_PaidTwice` |
| T-03 | Alice recupera el ETH después de recibir lo comprado | `test_Paso3_DeadlineRules` |
| T-04 | Bob bloquea el trato disputando tarde | `test_Paso3_DeadlineRules` |
| T-05 | El árbitro se lleva el ETH de una disputa | `test_Paso4_RevertWhen_ArbiterPaysThirdParty` |

## Paso 0: Entrar, ver el rojo y contar las puertas

```bash
cd bootcamp/week-26-auditoria/2-practicas/ejercicio-01-modelo-de-amenazas/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

**Verifica**: `1 passed; 4 failed`. `test_OpenAndRelease` en verde; los otros cuatro fallan con su
`TODO: Paso N`. El compilador avisa cuatro veces de que una función podría ser `pure`: es cada
test con solo su `revert`, y el aviso desaparece al resolverlo.

Ahora saca la superficie de ataque:

```bash
forge inspect Escrow methodIdentifiers
```

**Verifica**: ocho funciones. Tres son getters (`ARBITER`, `deals`, `nextId`); las cinco que
cambian estado son `open`, `release`, `refund`, `dispute` y `resolve`. Con el contrato abierto,
apunta para cada una quién puede llamarla según su código. Lo vas a necesitar en el paso 4.

## Paso 1: Alguien de fuera (T-01)

**Por qué**: el actor sin confianza es el primero. Mallory puede llamar a cualquier función con
cualquier dato. El test prueba las cuatro funciones que tocan un trato existente y comprueba que
el ETH sigue dentro. `open` no entra: crea un trato nuevo con el ETH de quien llama.

```solidity
vm.startPrank(mallory);
vm.expectRevert(Escrow.NotBuyer.selector);
escrow.release(id);
vm.expectRevert(Escrow.NotBuyer.selector);
escrow.refund(id);
vm.expectRevert(Escrow.NotParty.selector);
escrow.dispute(id);
vm.expectRevert(Escrow.NotArbiter.selector);
escrow.resolve(id, mallory);
vm.stopPrank();
assertEq(address(escrow).balance, 1 ether);
```

**Abre** `test/Threats.t.sol`, borra el `revert` de `test_Paso1_RevertWhen_StrangerMovesFunds` y
descomenta sus líneas. Ejecuta `forge test`.

**Verifica**: `2 passed; 3 failed`, con el test del paso 1 en verde. Cada función rechaza a
Mallory con su error: la defensa existe.

## Paso 2: Pagar dos veces (T-02)

**Por qué**: un trato pasa por estados (`Funded`, `Disputed`, `Closed`). Una amenaza clásica es
llamar a una función en un estado en que no tiene sentido: liberar dos veces, o liberar y además
recuperar. Alice libera; después lo intenta todo otra vez, incluido `refund` pasado el plazo.

```solidity
vm.startPrank(alice);
escrow.release(id);
vm.expectRevert(Escrow.WrongStatus.selector);
escrow.release(id);
vm.expectRevert(Escrow.WrongStatus.selector);
escrow.dispute(id);
vm.warp(deadline + 1);
vm.expectRevert(Escrow.WrongStatus.selector);
escrow.refund(id);
vm.stopPrank();
assertEq(bob.balance, 1 ether);
assertEq(alice.balance, 9 ether);
```

**Abre** `test/Threats.t.sol` y resuelve `test_Paso2_RevertWhen_PaidTwice`.

**Verifica**: `3 passed; 2 failed`. Bob tiene su 1 ETH y Alice sus 9: nadie cobró dos veces.
`_pay` pone el trato en `Closed` antes de enviar, y cada función comprueba el estado.

## Paso 3: El plazo (T-03 y T-04)

**Por qué**: las amenazas de tiempo viven en el límite. Alice no debe recuperar el ETH antes del
plazo (Bob aún puede entregar) ni durante una disputa (el árbitro aún no ha decidido). Bob no debe
poder disputar pasado el plazo: bloquearía para siempre el `refund` de Alice. El test prueba las
tres cosas, la última con un segundo trato.

```solidity
vm.prank(alice);
vm.expectRevert(Escrow.TooEarly.selector);
escrow.refund(id);

vm.prank(bob);
escrow.dispute(id);
vm.warp(deadline + 1);
vm.prank(alice);
vm.expectRevert(Escrow.WrongStatus.selector);
escrow.refund(id);

vm.prank(alice);
uint256 late = escrow.open{value: 1 ether}(bob, uint64(block.timestamp + 1 days));
vm.warp(block.timestamp + 1 days + 1);
vm.prank(bob);
vm.expectRevert(Escrow.TooLate.selector);
escrow.dispute(late);
vm.prank(alice);
escrow.refund(late);
assertEq(alice.balance, 9 ether);
```

**Abre** `test/Threats.t.sol` y resuelve `test_Paso3_DeadlineRules`.

**Verifica**: `4 passed; 1 failed`. Alice acaba con 9 ETH: 10 menos el ETH del primer trato, en
disputa, y con el ETH del segundo ya recuperado.

Fíjate en lo que **no** prueba: que Bob pueda cobrar si Alice nunca libera. Si Bob entrega y Alice
desaparece, a Bob solo le queda disputar antes del plazo. Es un **riesgo aceptado** del diseño, y
en un informe se escribe así, no como hallazgo.

## Paso 4: El árbitro (T-05)

**Por qué**: el árbitro es de confianza para **decidir** entre Alice y Bob, no para quedarse el
ETH. Repasa tu nota del paso 0: ¿qué comprueba `resolve` sobre `to`? El test lo intenta: Bob
disputa y el árbitro resuelve a su favor... a favor del propio árbitro.

```solidity
vm.prank(bob);
escrow.dispute(id);
vm.startPrank(arbiter);
vm.expectRevert(Escrow.NotParty.selector);
escrow.resolve(id, arbiter);
escrow.resolve(id, bob);
vm.stopPrank();
assertEq(bob.balance, 1 ether);
assertEq(arbiter.balance, 0);
```

**Abre** `test/Threats.t.sol` y resuelve `test_Paso4_RevertWhen_ArbiterPaysThirdParty`.

**Verifica**: `4 passed; 1 failed`, ahora con otro motivo:

```text
[FAIL: next call did not revert as expected] test_Paso4_RevertWhen_ArbiterPaysThirdParty() (gas: 91555)
```

`resolve(id, arbiter)` no revirtió: le envió el ETH al árbitro. Has encontrado un hallazgo con su
prueba. En un informe sería "El árbitro puede enviar el ETH de una disputa a cualquier dirección":
impacto alto (se pierde el trato entero), probabilidad baja (hace falta la clave del árbitro),
severidad media con la matriz de la teoría 03.

## Paso 5: Corregir

**Por qué**: la defensa es una comprobación en la frontera: `to` tiene que ser una de las dos
partes del trato.

```solidity
if (to != deal.buyer && to != deal.seller) revert NotParty();
```

**Abre** `src/Escrow.sol` y descomenta la línea de `resolve`.

**Verifica**: `5 passed; 0 failed`. El test del paso 4 se queda como test de regresión: si alguien
borra esa línea, vuelve a fallar.

## Para pensar

- El árbitro sigue pudiendo decidir mal entre Alice y Bob. ¿Por qué eso no es un hallazgo y
  enviar el ETH a un tercero sí?
- ¿Qué cambiaría en el modelo si el árbitro fuera un contrato que otro puede actualizar?

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Informe y divulgación](../../1-teoria/04-informe-y-divulgacion.md) | **Ejercicio 01 — Modelo de amenazas** | [Ejercicio 02 — Hallazgos con PoC →](../ejercicio-02-hallazgos-con-poc/README.md) |
