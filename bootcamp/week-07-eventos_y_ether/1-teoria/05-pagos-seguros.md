# Teoría 05 — Pagos seguros

## 🎯 Objetivos

- Distinguir pagos *push* (el contrato envía) de pagos *pull* (cada uno retira lo suyo).
- Explicar por qué un receptor que revierte puede bloquear un bucle de pagos.
- Llevar la contabilidad de lo que se debe en un mapping, no en el saldo del contrato.
- Saber que a un contrato le puede llegar ETH sin pasar por ninguna de sus funciones.

---

## 1. Qué problema resuelve

Ya sabes recibir (teoría 03) y enviar (teoría 04). Falta decidir **quién inicia** cada
pago y **cómo sabe** el contrato cuánto debe. Un error aquí no se arregla con un `if`: un
diseño de pagos equivocado puede bloquear el dinero de todos por culpa de una sola cuenta.

## 2. Push: el contrato paga a todos

Un repartidor que divide su saldo entre varias cuentas en un bucle, `src/Splitter.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract PushSplitter {
    address payable[] public payees;

    error TransferFailed(address to, uint256 amount);

    constructor(address payable[] memory accounts) payable {
        payees = accounts;
    }

    function payAll() external {
        uint256 share = address(this).balance / payees.length;
        for (uint256 i = 0; i < payees.length; i++) {
            (bool ok,) = payees[i].call{value: share}("");
            if (!ok) revert TransferFailed(payees[i], share);
        }
    }
}
```

Comprueba cada envío, como pide la teoría 04. Pero mira qué pasa si uno de los destinos es
un contrato que no acepta ETH. Con anvil recién arrancado, despliega la `Shop` de la teoría
03 (no tiene `receive`) y un repartidor de 2 ETH entre la cuenta 1 y la tienda:

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 0)
forge create src/Shop.sol:Shop --private-key "$PK" --broadcast
SHOP=0x5FbDB2315678afecb367f032d93F642f64180aa3
A1=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
forge create src/Splitter.sol:PushSplitter --private-key "$PK" --broadcast --value 2ether --constructor-args "[$A1,$SHOP]"
PUSH=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
cast send $PUSH "payAll()" --private-key "$PK"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x1c43b976: ...: TransferFailed(0x5FbDB2315678afecb367f032d93F642f64180aa3, 1000000000000000000 [1e18])
```

La tienda rechaza su parte, `payAll` revierte y **la cuenta 1 tampoco cobra**. Nunca:
cada vez que alguien lo intente, la tienda volverá a rechazar. Un solo destino que revierte
(por error o a propósito) bloquea el pago de todos. Es una denegación de servicio (DoS).

Quitar el `revert` tampoco arregla nada: la parte de la tienda se quedaría en el contrato
sin que nadie la tenga apuntada.

## 3. Pull: cada uno retira lo suyo

El contrato no envía: **apunta** cuánto le debe a cada cuenta, y cada cuenta retira cuando
quiere:

```solidity
contract PullSplitter {
    mapping(address => uint256) public owed;

    error NothingToClaim();
    error TransferFailed(address to, uint256 amount);

    constructor(address payable[] memory accounts) payable {
        uint256 share = msg.value / accounts.length;
        for (uint256 i = 0; i < accounts.length; i++) {
            owed[accounts[i]] += share;
        }
    }

    function claim() external {
        uint256 amount = owed[msg.sender];
        if (amount == 0) revert NothingToClaim();
        owed[msg.sender] = 0;
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        if (!ok) revert TransferFailed(msg.sender, amount);
    }
}
```

Añádelo al mismo archivo, despliégalo con los mismos destinos y retira desde la cuenta 1:

```bash
forge create src/Splitter.sol:PullSplitter --private-key "$PK" --broadcast --value 2ether --constructor-args "[$A1,$SHOP]"
PULL=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
PK1=$(cast wallet private-key "test test test test test test test test test test test junk" 1)
cast send $PULL "claim()" --private-key "$PK1"
cast call $PULL "owed(address)(uint256)" $A1
cast call $PULL "owed(address)(uint256)" $SHOP
```

`status 1 (success)`, y después:

```
0
1000000000000000000 [1e18]
```

La cuenta 1 cobró. La parte de la tienda sigue apuntada: si la tienda no puede cobrar, el
problema es solo suyo. Cada retiro es independiente, y `claim` sigue el orden CEI de la
teoría 04.

| | Push | Pull |
| - | ---- | ---- |
| Quién inicia | El contrato, en un bucle | Cada cuenta, cuando quiere |
| Un destino que revierte | Bloquea a todos | Solo se bloquea a sí mismo |
| Gas | Crece con el número de destinos | Fijo por retiro |
| Contabilidad | Implícita (el saldo) | Explícita (`owed`) |

**Prefiere pull.** Push solo es razonable con un único destino que tú controlas, como el
dueño retirando las tasas a su propia cuenta.

## 4. El saldo no es la contabilidad

`address(this).balance` dice cuánto ETH tiene el contrato, pero **no** cuánto ETH llegó a
través de sus funciones. Hay formas de enviar ETH a un contrato sin ejecutar su código:
la recompensa de un bloque puede ir a cualquier dirección, y el opcode `selfdestruct` envía
el saldo de un contrato a otro sin llamarlo.

Pruébalo con la tienda, que rechaza todo ETH sin datos:

```bash
cast send $SHOP --value 1ether --private-key "$PK"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted, data: "0x"
```

Ahora un contrato que se autodestruye nada más nacer, `src/Bomb.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Bomb {
    constructor(address payable target) payable {
        selfdestruct(target);
    }
}
```

El compilador avisa de que `selfdestruct` está obsoleto (`Warning (5159)`); aquí solo lo
usas para ver el efecto. Despliégalo con 1 ETH apuntando a la tienda:

```bash
forge create src/Bomb.sol:Bomb --private-key "$PK" --broadcast --value 1ether --constructor-args $SHOP
cast balance $SHOP --ether
```

```
1.000000000000000000
```

La tienda tiene 1 ETH que nunca aceptó. Consecuencias:

- **Lleva tu propia cuenta** (`totalDeposits`, `owed`) y úsala para saber cuánto debes.
- **Nunca compares el saldo con `==`**: `address(this).balance == totalDeposits` se rompe
  en cuanto alguien fuerza 1 wei. Si quieres comprobar que puedes pagar, usa `>=`.

## 5. Antipatrones y riesgos

- **Pagar en un bucle a destinos que no controlas**: un destino que revierte bloquea a
  todos, y un bucle largo puede superar el gas del bloque (semana 06). Pull.
- **Decidir con `address(this).balance`**: "si el saldo es exactamente X, abre el premio"
  se rompe con ETH forzado. Usa tu contabilidad.
- **Retiro sin CEI**: un `claim` que pone `owed` a 0 después del envío es reentrable
  (teoría 04).
- **Olvidar el ETH sobrante**: dividir `2 ether` entre 3 deja wei sin repartir que nadie
  puede reclamar. Decide a quién van los restos o haz que no queden.

## 6. Trucos

- Llama a la función de retiro `withdraw` o `claim`, y emite un evento con quién y cuánto.
- Un mapping `owed[cuenta]` más un total (`totalOwed`) te deja comprobar la solvencia con
  `address(this).balance >= totalOwed`.
- Si un destino no puede cobrar, que lo resuelva él: no lo intentes "arreglar" saltándolo
  en un bucle.

## ✅ Checklist

- [ ] Explico por qué un receptor que revierte bloquea un pago push.
- [ ] Escribo un retiro pull con su mapping de deudas y en orden CEI.
- [ ] Sé dos formas de que un contrato reciba ETH sin ejecutar su código.
- [ ] Compruebo la solvencia con `>=` y mi propia contabilidad, nunca con `==`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Enviar ETH](04-enviar-ether.md) | **Teoría 05 — Pagos seguros** | [Ejercicio 01 — Eventos →](../2-practicas/ejercicio-01-eventos/README.md) |
