# Teoría 06 — Gas y EIP-1559

## 🎯 Objetivos

- Explicar qué es el gas y por qué cada operación tiene un precio.
- Distinguir gas usado, gas limit y precio del gas.
- Calcular lo que cuesta una transacción con base fee y propina (EIP-1559).
- Predecir cómo cambia la base fee de un bloque al siguiente.
- Reconocer los errores de gas más comunes y su causa.

---

## 1. Qué problema resuelve el gas

Cada nodo de la red ejecuta cada transacción. Si ejecutar fuera gratis, alguien podría
enviar un programa con un bucle infinito y bloquear a todos los nodos a la vez, o llenar
los bloques de basura sin coste.

El **gas** es la unidad que mide el trabajo de ejecutar una transacción. Cada operación
tiene un coste fijo en gas, y quien envía la transacción paga ese gas en ETH. Así el
trabajo de la red tiene precio, y un bucle infinito se detiene cuando se acaba el gas que
se pagó.

## 2. Tres números distintos

| Número | Qué es | Quién lo decide |
| ------ | ------ | --------------- |
| **Gas usado** (`gasUsed`) | Cuánto trabajo costó de verdad | Las reglas de la EVM, según lo que se ejecutó |
| **Gas limit** (`gas`) | El máximo que aceptas gastar | Tú, en la transacción |
| **Precio del gas** | Cuántos wei pagas por cada unidad de gas | Tú (con un mínimo, sección 4) |

Una transferencia simple de ETH cuesta siempre **21 000 gas**: es el coste base de toda
transacción (*intrinsic gas*, gas intrínseco). `cast estimate` pregunta al nodo cuánto gas
usaría una transacción, sin enviarla:

**Dónde**: en el contenedor, con anvil recién arrancado (`anvil --silent &`).

```bash
cast estimate 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 --value 1ether
```

```
21000
```

El gas limit es un **techo**, no un pago. Lo que no se usa no se cobra:

```bash
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
TO=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
H=$(cast send --private-key "$PK" "$TO" --value 1 --gas-limit 100000 --json | jq -r .transactionHash)
cast tx "$H" gas
cast receipt "$H" gasUsed
```

```
100000
21000
```

## 3. Los datos también cuestan

El campo `input` (Teoría 04) cuesta gas por cada byte: más por los bytes distintos de cero
que por los ceros. Con 4 bytes de datos:

```bash
cast estimate "$TO" 0x00000000
cast estimate "$TO" 0x11111111
```

```
21040
21160
```

Son 21 000 más 10 gas por byte cero (4 × 10) o 40 por byte no cero (4 × 40). Es la regla
de precio mínimo de los datos del [EIP-7623](https://eips.ethereum.org/EIPS/eip-7623), que
manda cuando una transacción lleva datos pero apenas ejecuta código. Con contratos, la
ejecución también suma (Teoría 07).

## 4. El precio: base fee y propina (EIP-1559)

Cada bloque tiene una **base fee**: el precio mínimo por unidad de gas para entrar en ese
bloque. No la elige nadie: la calcula la red (sección 5). La base fee se **quema**: ese ETH
desaparece, no lo cobra nadie.

Encima, quien envía ofrece una **propina** (*priority fee*) por unidad de gas para quien
construye el bloque, que elige primero las transacciones que más pagan.

La transacción lleva dos topes (Teoría 04):

| Campo | `cast send` | Qué es |
| ----- | ----------- | ------ |
| `maxFeePerGas` | `--gas-price` | Lo máximo que pagas por unidad de gas, en total |
| `maxPriorityFeePerGas` | `--priority-gas-price` | Lo máximo que das de propina |

Lo que pagas de verdad por unidad de gas, el **precio efectivo**:

```
precio efectivo = mínimo(maxFeePerGas, base fee + maxPriorityFeePerGas)
costo           = gasUsed × precio efectivo
```

![Desglose de lo que paga una transacción según EIP-1559: el precio efectivo es la base fee más la propina, sin pasar del tope maxFeePerGas; la parte de la base fee se quema y la propina va a quien construye el bloque; el costo total es el gas usado por el precio efectivo](../0-assets/04-comisiones-eip-1559.svg)

Compruébalo. Reinicia anvil (`kill %1` y `anvil --silent &`), vuelve a definir `PK` y `TO`
y envía con tope 5 gwei y propina 2 gwei, en un bloque con base fee 1 gwei:

```bash
H=$(cast send --private-key "$PK" "$TO" --value 1 \
  --gas-price 5gwei --priority-gas-price 2gwei --json | jq -r .transactionHash)
cast block 1 --field baseFeePerGas
cast receipt "$H" effectiveGasPrice
cast balance 0x0000000000000000000000000000000000000000
```

```
1000000000
3000000000
42000000000000
```

| Concepto | Cálculo | wei |
| -------- | ------- | --- |
| Precio efectivo | mínimo(5 gwei, 1 + 2 gwei) | 3 000 000 000 |
| Costo total | 21 000 × 3 gwei | 63 000 000 000 000 |
| Quemado | 21 000 × 1 gwei (base fee) | 21 000 000 000 000 |
| Propina | 21 000 × 2 gwei | 42 000 000 000 000 |

La propina llegó a quien construyó el bloque: en anvil es la dirección cero, y su saldo es
exactamente `42000000000000`. Los 2 gwei de tope que sobraron no se cobran.

Antes de ejecutar, el nodo exige que tu saldo cubra el **peor caso**: `gas limit ×
maxFeePerGas + value`.

## 5. La base fee se ajusta sola

Cada bloque tiene un **gas limit de bloque** (30 000 000 en anvil) y un **objetivo**: la
mitad, 15 000 000. Si un bloque usa más gas que el objetivo, la base fee del siguiente
sube; si usa menos, baja. Como mucho, un 12,5 % (1/8) por bloque:

```
base fee siguiente = base fee × (1 + (gas usado − objetivo) / objetivo / 8)
```

El bloque 1 de antes usó 21 000 gas, casi nada:

```bash
cast base-fee pending
```

```
875175000
```

`pending` es el bloque que todavía no se ha minado. La cuenta:
1 000 000 000 × (1 − 14 979 000 / 15 000 000 / 8) = 875 175 000. Con bloques vacíos la base
fee baja; con bloques llenos sube, hasta que la demanda se modera. Por eso en mainnet el
precio del gas cambia según la hora y la congestión.

## 6. Errores de gas

| Comando | Error | Causa |
| ------- | ----- | ----- |
| `--gas-limit 20000` | `intrinsic gas too low` | El límite no cubre ni los 21 000 de base |
| `--gas-price 1 --priority-gas-price 1` | `max fee per gas less than block base fee` | El tope es menor que la base fee |
| `--gas-price 1gwei --priority-gas-price 2gwei` | `max priority fee per gas (2000000000) cannot exceed max fee per gas (1000000000)` | La propina supera el tope; lo detecta el propio `cast` |
| `--value 20000ether` | `Insufficient funds for gas * price + value` | El saldo no cubre el peor caso |

Las tres que vienen del nodo llegan como `Error: server returned an error response: error
code ...` seguido del mensaje; dos de ellas, precedidas de `Failed to estimate gas:`,
porque `cast send` estima el gas antes de firmar y el nodo ya la rechaza ahí.

## 7. Antipatrones y riesgos

- ❌ **Poner un gas limit justo.** Si la ejecución necesita un poco más, la transacción
  se queda sin gas (*out of gas*), falla y **cobra todo el gas limit**. Deja margen; lo que no se usa no se cobra.
- ❌ **Fijar `maxFeePerGas` muy alto "por si acaso".** Te protege de pagar de más solo
  hasta ese tope: si la base fee se dispara, pagas hasta el tope. Ponlo a conciencia.
- ❌ **Tope por debajo de la base fee en una red real.** La transacción se queda en el
  mempool sin minarse y bloquea las siguientes de tu cuenta (Teoría 05).
- ❌ **Escribir contratos que hacen bucles sin límite.** Si el bucle crece con los datos,
  un día no cabrá en el gas de un bloque y la función quedará inservible. Semana 21.

## 8. Trucos

- `cast gas-price` da un precio sugerido; `cast base-fee` la base fee del último bloque.
- `costo en ether = gasUsed × effectiveGasPrice`, luego `cast from-wei`.
- Para ver cuánto cuesta algo sin gastar nada: `cast estimate`.

## ✅ Checklist

- [ ] Explico qué problema resuelve el gas.
- [ ] Distingo gas usado, gas limit y precio del gas.
- [ ] Calculo precio efectivo, costo, parte quemada y propina de una transacción.
- [ ] Calculo la base fee del bloque siguiente a partir del gas usado.
- [ ] Reconozco los cuatro errores de gas de la tabla y sé corregirlos.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 05 — El nonce](05-el-nonce.md) | **Teoría 06 — Gas y EIP-1559** | [Teoría 07 — La EVM y los contratos →](07-la-evm-y-los-contratos.md) |
