# Ejercicio 02 — Una transacción paso a paso

> Al terminar habrás construido y firmado una transacción sin red, la habrás decodificado,
> habrás calculado su hash antes de enviarla, la habrás publicado y habrás comprobado en el
> recibo y en los saldos lo que costó.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 01](../ejercicio-01-leer-la-cadena/README.md) terminado;
[Teoría 04](../../1-teoria/04-transacciones.md) leída.

## Contexto

Mismo formato que el ejercicio 01. `pasos.sh` trae tres variables:

| Variable | Qué es |
| -------- | ------ |
| `PK` | Clave privada de la cuenta 0 de prueba: la que envía |
| `ADDR` | Dirección de la cuenta 0 |
| `TO` | Dirección de la cuenta 1: la que recibe |

Resuelve los pasos **en orden**: del 2 al 6 usan la transacción del paso 1 llamando a
`$(step1)`.

Cada paso de `test.sh` empieza con un anvil nuevo. Si pruebas a mano con `bash pasos.sh N`
sobre tu anvil, los pasos 4 a 6 solo funcionan una vez: la transacción lleva nonce 0 y,
tras publicarla, la cuenta pasa a 1 (`nonce too low`). Reinicia anvil entre prueba y prueba
(`kill %1` y `anvil --silent &`).

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-02-ethereum_cuentas_transacciones_y_gas/2-practicas/ejercicio-02-una-transaccion-paso-a-paso/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
anvil --silent &
bash test.sh
```

**Verifica**: seis `❌` y `0 de 6 pasos correctos`.

## Paso 1: Construir y firmar sin enviar

**Por qué**: separar la firma del envío. Lo que sale es la transacción en bruto: los bytes
que viajarán al nodo.

```bash
step1() {
  cast mktx --private-key "$PK" "$TO" --value 1ether \
    --nonce 0 --gas-limit 21000 --gas-price 2gwei --priority-gas-price 1gwei --chain 31337
}
```

Todos los campos van fijos: `cast` no consulta al nodo y la firma sale siempre igual.

**Verifica**: `✅ Paso 1`. La salida empieza por `0x02f874827a69`: tipo `02` y, un poco
después, el chain id `7a69`.

## Paso 2: ¿Quién firmó?

**Por qué**: la transacción no lleva `from`. Quien envía se recupera de la firma.

```bash
step2() {
  cast decode-transaction "$(step1)" | jq -r .signer
}
```

**Verifica**: `✅ Paso 2` con `0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266`, la cuenta 0
(en minúsculas: `cast decode-transaction` no aplica el checksum).

## Paso 3: El hash antes de enviar

**Por qué**: el hash identifica la transacción y depende solo de sus bytes. Lo conoces
antes de que la red la vea.

```bash
step3() {
  cast decode-transaction "$(step1)" | jq -r .hash
}
```

**Verifica**: `✅ Paso 3` con
`0x7d4c13ed95c0cee830d7457ec5a5976db1fc301cfa7a23fef0039a7ccf6aea87`. Comprueba a mano que
`cast keccak "$(bash pasos.sh 1)"` da el mismo hash.

## Paso 4: Publicar y leer el estado

**Por qué**: enviar los bytes al nodo (`eth_sendRawTransaction`) y confirmar en el recibo
que se ejecutó bien.

```bash
step4() {
  cast publish "$(step1)" | jq -r .status
}
```

**Verifica**: `✅ Paso 4` con `0x1` (éxito).

## Paso 5: Cuánto costó

**Por qué**: el costo real sale del recibo: gas usado × precio efectivo (Teoría 06).

```bash
step5() {
  local hash
  hash=$(cast publish "$(step1)" | jq -r .transactionHash)
  echo $(( $(cast receipt "$hash" gasUsed) * $(cast receipt "$hash" effectiveGasPrice) ))
}
```

| Pieza | Qué hace |
| ----- | -------- |
| `local hash` | Variable que solo existe dentro de la función |
| `cast receipt "$hash" gasUsed` | Un campo del recibo, en decimal |
| `$(( a * b ))` | Aritmética entera de bash; aquí cabe de sobra |

**Verifica**: `✅ Paso 5` con `42000000000000`: 21 000 × 2 gwei. El precio efectivo es
mínimo(tope 2 gwei, base fee 1 gwei + propina 1 gwei) = 2 gwei.

## Paso 6: Los saldos después

**Por qué**: comprobar en el estado lo que dice el recibo. Quien envía pierde el valor
**más** el costo; quien recibe gana solo el valor.

```bash
step6() {
  cast publish "$(step1)" >/dev/null
  echo "$(cast balance --ether "$ADDR") $(cast balance --ether "$TO")"
}
```

**Verifica**: `✅ Paso 6` con `9998.999958000000000000 10001.000000000000000000` y
`6 de 6 pasos correctos`. Los `0.000042` que faltan en la cuenta 0 son los
`42000000000000` wei del paso 5.

## ✅ Criterios de éxito

- `bash test.sh` termina con `6 de 6 pasos correctos`.
- Explicas por qué el hash del paso 3 se conoce antes de enviar la transacción.
- Explicas por qué el saldo de la cuenta 0 no baja exactamente 1 ether.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Leer la cadena](../ejercicio-01-leer-la-cadena/README.md) | **Ejercicio 02 — Una transacción paso a paso** | [Ejercicio 03 — Gas y nonce →](../ejercicio-03-gas-y-nonce/README.md) |
