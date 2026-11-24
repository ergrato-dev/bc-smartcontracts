# Teoría 02 — La liquidez de un AMM

## 🎯 Objetivos

- Explicar qué son la **liquidez** y las **LP shares** de un AMM, y quién gana las comisiones.
- Calcular las shares de la primera liquidez y de las siguientes, y lo que devuelve una retirada.
- Explicar para qué sirven las 1000 shares que nadie puede retirar.
- Calcular la **pérdida impermanente** de un proveedor de liquidez cuando el precio cambia.
- Reconocer los riesgos de aportar liquidez: el precio inicial, la aportación desproporcionada y
  el sándwich.

## Qué problema resuelve

Un AMM necesita reservas para funcionar: sin tokens dentro, no hay nada que cambiar. Esas reservas
las ponen los **proveedores de liquidez** (*liquidity providers*, LP): cualquiera que aporte los
dos tokens a la vez. A cambio, el pool les da **LP shares**, un ERC-20 que representa su parte del
pool. Quien tiene el 10 % de las shares puede retirar el 10 % de cada reserva cuando quiera, con
las comisiones que se hayan acumulado.

La pregunta es cuántas shares dar a cada uno para que nadie gane a costa de otro: ni quien llega
primero, ni quien aporta en un momento raro, ni quien retira antes.

## Cómo funciona

### La primera liquidez

Quien abre el pool elige las dos cantidades, y con ellas **el precio inicial**: 100 A y 400 B dicen
que 1 A vale 4 B. Sus shares son la **media geométrica** de las dos cantidades:

```text
shares = √(x · y) = √(100 · 400) = 200
```

La raíz hace que el número de shares no dependa del precio ni de en qué token se mida: si el pool
dobla sus dos reservas, las shares que valen lo mismo también se doblan.

Uniswap V2 da al primer proveedor `√(x · y) − 1000` y envía las otras **1000 shares mínimas**
(`MINIMUM_LIQUIDITY`) a una dirección sin clave, para siempre. Es la defensa contra el ataque de
inflación de la semana 22: sin ellas, el primero podría dejar 1 share en circulación, regalar
tokens al pool y hacer que cada share valga tanto que las aportaciones pequeñas de otros
redondeen a 0 shares. Con 1000 shares bloqueadas, hacer cara una share exige regalar mil veces
más, y ese regalo se queda en el pool. En un pool con 18 decimales, 1000 shares son nada: un
proveedor no lo nota.

### Las siguientes

Después, las shares son proporcionales a lo que aportas frente a lo que hay, con `S` las shares
que existen:

```text
shares = mín(Δx · S / x, Δy · S / y)
```

Si aportas 50 A y 200 B a un pool de 100 A y 400 B con 200 shares, aportas la mitad de cada
reserva y recibes la mitad de las shares que había: 100. Si aportas 50 A y solo 100 B, la parte de
B es una cuarta y la de A, la mitad: cuenta la **menor**, 50 shares, y los 25 A de más se quedan en
el pool, regalados a todos los proveedores. Por eso hay que aportar en la proporción exacta de las
reservas.

### Retirar

Quemar `s` shares devuelve la misma parte de cada reserva:

```text
Δx = s · x / S        Δy = s · y / S
```

Las dos divisiones redondean hacia abajo: el polvo se queda en el pool. Como la comisión hace
crecer las reservas sin crear shares (teoría 01), cada share vale cada vez más tokens. Lo que ganas
como proveedor es tu parte de las comisiones de todos los swaps mientras estuviste dentro.

### La pérdida impermanente

Las comisiones no son toda la historia. Cuando el precio de fuera cambia, el **arbitraje** mueve
las reservas del pool hasta que su precio es el mismo (teoría 01): compra en el pool el token que
ha subido, hasta que queda menos. Tú, como proveedor, acabas con menos del token que sube y más del
que baja. Comparado con haber guardado los tokens sin hacer nada, pierdes valor: es la **pérdida
impermanente** (*impermanent loss*). Se llama así porque desaparece si el precio vuelve a donde
estaba; si retiras con el precio cambiado, es permanente.

Solo depende de cuánto cambió el precio, `r` = precio nuevo / precio de entrada:

```text
pérdida = 2 · √r / (1 + r) − 1
```

## Cómo se escribe

El caso del pool de 100 A y 400 B, cuando A pasa de valer 4 B a valer 9 B (`r` = 2,25).

**Dónde**: en `test/Impermanent.t.sol` de un proyecto Foundry con OpenZeppelin (semana 11):

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

import {Test, console} from "forge-std/Test.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract ImpermanentTest is Test {
    function test_ImpermanentLoss() public pure {
        // Pool de 100 A y 400 B: 1 A vale 4 B. Fuera, A pasa a valer 9 B, y el arbitraje
        // compra A en el pool hasta que el precio del pool, b / a, también es 9.
        uint256 k = 100 ether * 400 ether;
        uint256 a = Math.sqrt(k / 9);
        uint256 b = k / a;
        console.log("reservas", a, b);
        console.log("pool, en B   ", a * 9 + b);
        console.log("guardar, en B", uint256(100 ether) * 9 + 400 ether);
    }
}
```

Sin comisiones, `a · b` sigue siendo `k` y `b / a` es 9: `a = √(k / 9)`. `Math.sqrt` de
OpenZeppelin da la raíz entera, redondeada hacia abajo.

**Ejecuta**:

```bash
forge test --mt test_ImpermanentLoss -vv
```

**Salida**:

```text
[PASS] test_ImpermanentLoss() (gas: 12583)
  reservas 66666666666666666666 600000000000000000006
  pool, en B    1200000000000000000000
  guardar, en B 1300000000000000000000
```

El pool pasa a tener 66,67 A y 600 B. Lo que hay en el pool vale 1200 B; los 100 A y 400 B del
principio, guardados, valdrían 1300 B. La pérdida es de 100 B sobre 1300, un 7,7 %, y es lo que da
la fórmula: `2 · √2,25 / 3,25 − 1 = 2 · 1,5 / 3,25 − 1 = −0,077`. Las comisiones de todos los
swaps que movieron el precio compensan una parte. Si no llegan a compensarla, aportar liquidez
fue peor que no hacer nada.

| El precio de A se multiplica por | Pérdida frente a guardar |
| -------------------------------- | ------------------------ |
| 1,25 | −0,6 % |
| 2 | −5,7 % |
| 4 | −20,0 % |

## Antipatrones y riesgos

- **Abrir el pool con un precio equivocado.** El primer proveedor elige el precio. Si dice que 1 A
  vale 4 B y fuera vale 9, el arbitraje compra todo el A barato en el primer bloque y la
  diferencia la pierde quien abrió el pool. Se abre con la proporción del precio de fuera.
- **Aportar fuera de proporción.** Lo que sobra del token de más se queda en el pool para todos.
  Un **router** (el contrato que usan las páginas) calcula las cantidades exactas con las reservas
  del momento y solo transfiere esas.
- **Aportar sin mínimo.** Un atacante mueve el precio justo antes de tu aportación, tú aportas a un
  precio malo y él lo devuelve después: el sándwich de la semana 22, con liquidez. El router de
  Uniswap V2 recibe un mínimo de cada token (`amountAMin`, `amountBMin`) y un `deadline`.
- **Valorar una LP share con las reservas.** Si otro contrato acepta LP shares como garantía y las
  valora como `x · precio + y`, con las reservas del momento, se puede inflar ese valor con un swap
  dentro de la misma transacción. Se valora con el precio de un oráculo y con `k`, que el swap no
  baja.
- **Redondear la retirada hacia arriba.** Cada retirada se llevaría 1 wei de más y el último en
  retirar no encontraría su parte. Se redondea hacia abajo, siempre a favor del pool.

## Trucos

- Las shares del primer depósito no dependen del precio, pero las 1000 bloqueadas sí cuestan: con
  tokens de pocos decimales o muy caros, 1000 unidades mínimas pueden ser dinero. Por eso el
  primer depósito de un pool así lo hace el propio protocolo.
- Para saber si un pool te ha pagado bien, compara lo que vale tu parte hoy con lo que valdrían tus
  tokens guardados: la diferencia son las comisiones menos la pérdida impermanente.
- Con pares que se mueven juntos (dos dólares, dos versiones del mismo token), `r` se queda cerca
  de 1 y casi no hay pérdida impermanente. Por eso existen AMM con otras curvas para esos pares.

## ✅ Checklist

- [ ] Sé por qué las shares de la primera liquidez son `√(x · y)`.
- [ ] Sé para qué sirven las 1000 shares bloqueadas y a qué ataque responden.
- [ ] Sé calcular las shares de una aportación y qué pasa si no es proporcional.
- [ ] Sé qué devuelve una retirada y por qué redondea hacia abajo.
- [ ] Sé qué es la pérdida impermanente y calcularla con la fórmula.
- [ ] Sé por qué se aporta liquidez con un mínimo y un plazo.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — El AMM de producto constante](01-el-amm-de-producto-constante.md) | **Teoría 02 — La liquidez de un AMM** | [Teoría 03 — Vaults ERC-4626 →](03-vaults-erc-4626.md) |
