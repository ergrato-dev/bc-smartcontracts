# Ejercicio 03 — Gas y nonce

> Al terminar habrás medido el gas de una transferencia con y sin datos, habrás visto bajar
> la base fee, habrás comprobado cómo el tope limita el precio efectivo y habrás dejado un
> hueco de nonce en el mempool para rellenarlo después.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 02](../ejercicio-02-una-transaccion-paso-a-paso/README.md)
terminado; [Teorías 05 y 06](../../1-teoria/05-el-nonce.md) leídas.

## Contexto

Mismo formato y mismas variables (`PK`, `ADDR`, `TO`) que el ejercicio 02. Cada paso de
`test.sh` parte de un anvil nuevo: base fee 1 gwei y todas las cuentas con nonce 0. Para
probar a mano los pasos 3 a 6, reinicia tu anvil antes de cada uno (`kill %1` y
`anvil --silent &`).

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-02-ethereum_cuentas_transacciones_y_gas/2-practicas/ejercicio-03-gas-y-nonce/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
anvil --silent &
bash test.sh
```

**Verifica**: seis `❌` y `0 de 6 pasos correctos`.

## Paso 1: El gas de una transferencia

**Por qué**: el coste base de cualquier transacción. Es la referencia con la que comparas
todo lo demás.

```bash
step1() {
  cast estimate "$TO" --value 1
}
```

**Verifica**: `✅ Paso 1` con `21000`.

## Paso 2: Los datos cuestan

**Por qué**: una llamada a un contrato viaja en el campo `input`, y cada byte se paga.
Comparar ceros con no ceros muestra que no todos los bytes cuestan lo mismo.

```bash
step2() {
  echo "$(cast estimate "$TO" 0x00000000) $(cast estimate "$TO" 0x11111111)"
}
```

El segundo argumento de `cast estimate`, cuando empieza por `0x`, son los datos en crudo.

**Verifica**: `✅ Paso 2` con `21040 21160`: 4 × 10 gas por los ceros y 4 × 40 por los
no ceros (Teoría 06, sección 3).

## Paso 3: La base fee baja

**Por qué**: comprobar la regla del EIP-1559: un bloque casi vacío abarata el siguiente.

```bash
step3() {
  cast send --private-key "$PK" "$TO" --value 1 >/dev/null
  cast base-fee pending
}
```

`pending` pide la base fee del bloque que todavía no existe: la que pagará la próxima
transacción.

**Verifica**: `✅ Paso 3` con `875175000`. El bloque 1 usó 21 000 gas de un objetivo de
15 000 000, así que la base fee bajó casi un 12,5 % desde 1 gwei.

## Paso 4: El tope manda

**Por qué**: el precio efectivo es mínimo(tope, base fee + propina). Con la misma propina
y distinto tope, el precio cambia.

```bash
step4() {
  local first second
  first=$(cast send --private-key "$PK" "$TO" --value 1 \
    --gas-price 5gwei --priority-gas-price 2gwei --json | jq -r .effectiveGasPrice)
  second=$(cast send --private-key "$PK" "$TO" --value 1 \
    --gas-price 2gwei --priority-gas-price 2gwei --json | jq -r .effectiveGasPrice)
  echo "$(cast to-dec "$first") $(cast to-dec "$second")"
}
```

`--json` imprime el recibo en JSON, donde los números van en hex; por eso `cast to-dec`.

**Verifica**: `✅ Paso 4` con `3000000000 2000000000`.

| Transacción | Base fee | Cálculo | Precio efectivo |
| ----------- | -------- | ------- | --------------- |
| Primera (bloque 1) | 1 gwei | mínimo(5, 1 + 2) | 3 gwei |
| Segunda (bloque 2) | 0,875 gwei | mínimo(2, 0,875 + 2) | 2 gwei: la propina real se queda en 1,125 gwei |

## Paso 5: Un hueco de nonce

**Por qué**: ver que el nodo acepta una transacción adelantada pero no la ejecuta: la deja
en cola esperando las anteriores.

```bash
step5() {
  cast send --async --private-key "$PK" "$TO" --value 1 --nonce 1 >/dev/null
  echo "$(cast nonce "$ADDR") $(cast rpc txpool_status | jq -r .queued)"
}
```

`--async` devuelve el hash sin esperar al recibo; sin él, `cast` esperaría para siempre
(`test.sh` corta a los 20 segundos).

**Verifica**: `✅ Paso 5` con `0 0x1`: la cuenta sigue en nonce 0 y hay una transacción en
cola.

## Paso 6: Rellenar el hueco

**Por qué**: en cuanto llega la transacción que falta, el nodo ejecuta también la que
esperaba, en orden.

```bash
step6() {
  step5 >/dev/null
  cast send --private-key "$PK" "$TO" --value 1 >/dev/null
  cast nonce "$ADDR"
}
```

`cast send` sin `--nonce` pide al nodo el nonce de la cuenta (0): justo el que falta.

**Verifica**: `✅ Paso 6` con `2` y `6 de 6 pasos correctos`. Se ejecutaron las dos
transacciones: la de nonce 0 y la de nonce 1 que estaba en cola.

## ✅ Criterios de éxito

- `bash test.sh` termina con `6 de 6 pasos correctos`.
- Calculas a mano el `875175000` del paso 3 con la fórmula de la Teoría 06.
- Explicas qué pasaría en una red real si nunca enviaras la transacción de nonce 0 del
  paso 6.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Una transacción paso a paso](../ejercicio-02-una-transaccion-paso-a-paso/README.md) | **Ejercicio 03 — Gas y nonce** | [Proyecto — Primeras transacciones →](../../3-proyecto/README.md) |
