# Teoría 02 — Unidades y variables globales

## 🎯 Objetivos

- Escribir cantidades de ETH con `wei`, `gwei` y `ether`, y plazos con `minutes`, `hours` y
  `days`.
- Convertir unidades en la terminal con `cast`.
- Usar `msg.sender`, `msg.value`, `block.timestamp`, `block.number` y `block.chainid`.
- Saber por qué `tx.origin` no sirve para autorizar y por qué `block.timestamp` no es
  exacto.

---

## 1. Qué problema resuelve

Esta semana tu contrato empieza a mover dinero y a tener plazos. Dos preguntas que hasta
ahora no tenías:

- **¿Cuánto es "0,01 ETH" para el contrato?** La EVM no tiene decimales: todo importe es un
  entero en la unidad más pequeña.
- **¿Qué hora es? ¿Quién paga?** El contrato no tiene reloj ni sabe nada que no le llegue en
  la transacción o en el bloque. Solidity te lo da en variables globales.

## 2. Unidades de ETH

La unidad mínima de ETH es el **wei**. Un ether son 10^18 wei; un **gwei**, 10^9 wei (es la
unidad en que se suele expresar el precio del gas, semana 02). Solidity tiene sufijos para
escribirlo sin contar ceros:

| Literal | Valor en wei |
| ------- | ------------ |
| `1 wei` | 1 |
| `1 gwei` | 1 000 000 000 |
| `1 ether` | 1 000 000 000 000 000 000 |
| `0.01 ether` | 10 000 000 000 000 000 |

`0.01 ether` es un literal válido porque el resultado es un entero. Un `uint256` que
guarda un importe guarda **wei**, siempre.

En la terminal, `cast` convierte en las dos direcciones:

```bash
cast to-wei 1
cast to-wei 1 gwei
cast from-wei 1500000000000000
cast to-unit 1500000000000000 gwei
```

```
1000000000000000000
1000000000
0.001500000000000000
1500000
```

Y `cast balance` da el saldo de una cuenta en wei, o en ether con `--ether`:

```bash
cast balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --ether
```

```
9999.999848220999848221
```

(La cuenta 0 de anvil empieza con 10 000 ETH de prueba; la diferencia es el gas que ya
gastó desplegando. Tu número dependerá de lo que hayas hecho.)

Al dividir, se pierde lo que no llega a una unidad entera: `1500 gwei / 1 ether` es `0`.
Para pasar wei a gwei, divide por `1 gwei`; para el resto, guarda siempre wei.

## 3. Unidades de tiempo

Los plazos se cuentan en **segundos**. Los sufijos `seconds`, `minutes`, `hours`, `days` y
`weeks` multiplican: `1 days` es `86400`, `36 hours` es `129600`. No hay `months` ni
`years`: no todos duran lo mismo.

Compruébalo con este contrato, `src/Globals.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.38;

contract Globals {
    function context()
        external
        view
        returns (address sender, address origin, uint256 number, uint256 timestamp, uint256 chainId)
    {
        return (msg.sender, tx.origin, block.number, block.timestamp, block.chainid);
    }

    function units() external pure returns (uint256 oneEther, uint256 oneGwei, uint256 oneDay) {
        return (1 ether, 1 gwei, 1 days);
    }
}
```

Con anvil recién arrancado:

```bash
PK=$(cast wallet private-key "test test test test test test test test test test test junk" 0)
forge create src/Globals.sol:Globals --private-key "$PK" --broadcast
C=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast call $C "units()(uint256,uint256,uint256)"
```

```
1000000000000000000 [1e18]
1000000000 [1e9]
86400 [8.64e4]
```

## 4. Variables globales

Solidity da acceso a la transacción y al bloque en curso:

| Variable | Tipo | Qué es |
| -------- | ---- | ------ |
| `msg.sender` | `address` | Quién llama a **esta** función: una cuenta o un contrato |
| `msg.value` | `uint256` | Cuántos wei llegan con la llamada (teoría 03) |
| `msg.data` | `bytes` | Los datos completos de la llamada |
| `msg.sig` | `bytes4` | Los 4 primeros bytes de `msg.data`: el selector de la función |
| `tx.origin` | `address` | La cuenta que firmó la transacción, al principio de la cadena de llamadas |
| `block.timestamp` | `uint256` | Segundos desde 1970 (hora Unix) del bloque en curso |
| `block.number` | `uint256` | Número del bloque en curso |
| `block.chainid` | `uint256` | Identificador de la red: `31337` en anvil, `1` en Ethereum |
| `address(this).balance` | `uint256` | Saldo en wei de este contrato |

Pide el contexto haciéndote pasar por la cuenta 1 (`--from` en una llamada de lectura):

```bash
cast call $C "context()(address,address,uint256,uint256,uint256)" --from 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

```
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
0x70997970C51812dc3A010C7d01b50e0d17dc79C8
1
1795343601 [1.795e9]
31337 [3.133e4]
```

La hora será la tuya. `msg.sender` y `tx.origin` coinciden porque la cuenta llama
directamente al contrato. Si una cuenta llama a un contrato A y A llama a B, en B
`msg.sender` es A y `tx.origin` sigue siendo la cuenta.

## 5. Antipatrones y riesgos

- **Autorizar con `tx.origin`**: `if (tx.origin != OWNER) revert` parece igual que con
  `msg.sender`, pero no lo es. Si el dueño llama a un contrato malicioso, ese contrato
  puede llamar al tuyo y `tx.origin` sigue siendo el dueño: pasa la guarda. Autoriza
  siempre con `msg.sender`. La semana 21 lo demuestra con un ataque.
- **Plazos al segundo con `block.timestamp`**: lo fija quien produce el bloque, dentro de
  un margen de unos segundos. Sirve para "cierra en 7 días", no para "el primero que llegue
  en este segundo gana".
- **Números "aleatorios" del bloque**: `block.timestamp`, `block.number` y similares los
  conoce o los influye quien produce el bloque. Un sorteo basado en ellos se puede
  predecir. La aleatoriedad segura llega en la semana 20.
- **Mezclar unidades**: guardar un importe en ether "porque es más legible" y compararlo
  con `msg.value`, que está en wei, da errores de 10^18. Todo importe en wei, y los sufijos
  solo al escribir literales.

## 6. Trucos

- Escribe `0.01 ether` y `7 days`, no `10000000000000000` ni `604800`: se lee y no te
  equivocas de ceros.
- Para un plazo relativo al despliegue, guárdalo en una `immutable` en el constructor:
  `CLOSES_AT = block.timestamp + duration;`.
- `cast to-wei` y `cast from-wei` antes de escribir un `--value` a mano.

## ✅ Checklist

- [ ] Escribo importes con `ether` y `gwei` y sé que el contrato los ve en wei.
- [ ] Convierto entre wei, gwei y ether con `cast`.
- [ ] Uso `block.timestamp` con sufijos de tiempo para un plazo.
- [ ] Explico la diferencia entre `msg.sender` y `tx.origin` y por qué se autoriza con el
      primero.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 01 — Eventos y logs](01-eventos-y-logs.md) | **Teoría 02 — Unidades y variables globales** | [Teoría 03 — Recibir ETH →](03-recibir-ether.md) |
