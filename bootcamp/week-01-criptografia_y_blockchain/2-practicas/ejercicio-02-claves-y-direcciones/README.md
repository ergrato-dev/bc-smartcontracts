# Ejercicio 02 — Claves y direcciones

> Al terminar derivarás una dirección de Ethereum desde su clave privada de dos formas
> —con un comando y a mano—, sacarás cuentas de una frase semilla y recuperarás el
> checksum de una dirección mal copiada.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 01](../ejercicio-01-hashes-con-cast/README.md) terminado;
[Teoría 04](../../1-teoria/04-claves-y-direcciones.md) leída.

## Contexto

Mismo formato que el ejercicio 01: `pasos.sh` con una función por paso y `test.sh`, que
no se modifica. Al principio de `pasos.sh` hay dos variables ya escritas:

| Variable | Valor | Qué es |
| -------- | ----- | ------ |
| `MNEMONIC` | `test test ... junk` | La frase semilla pública de las cuentas de prueba de Foundry |
| `PK` | `0xac09...ff80` | La clave privada del índice 0 de esa frase |

Las dos son públicas a propósito. Nunca las uses en una red real.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-01-criptografia_y_blockchain/2-practicas/ejercicio-02-claves-y-direcciones/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: seis `❌` y `0 de 6 pasos correctos`.

## Paso 1: De clave privada a dirección

**Por qué**: es la operación que hace toda wallet al importar una clave. Te da la cuenta
que controla esa clave.

```bash
step1() {
  cast wallet address --private-key "$PK"
}
```

**Abre** `pasos.sh`, borra `todo "Paso 1"` y quita el `#> `.

**Verifica**: `✅ Paso 1`. La dirección es `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`.

## Paso 2: La clave pública

**Por qué**: es el paso intermedio entre la clave privada y la dirección. Mide 64 bytes:
128 dígitos hex.

```bash
step2() {
  cast wallet public-key --private-key "$PK"
}
```

**Verifica**: `✅ Paso 2`. Cuenta los dígitos: `bash pasos.sh 2 | wc -c` imprime `131`
(128 dígitos, el `0x` y el salto de línea).

## Paso 3: La dirección a mano

**Por qué**: comprobar que la dirección no es magia: son los últimos 20 bytes del hash
de la clave pública.

```bash
step3() {
  local hash
  hash=$(cast keccak "$(step2)")
  cast to-check-sum-address "0x${hash: -40}"
}
```

| Pieza | Qué hace |
| ----- | -------- |
| `$(step2)` | Llama al paso 2 y usa su salida: la clave pública |
| `cast keccak ...` | Hash de esos 64 bytes (empiezan por `0x`, así que se tratan como bytes) |
| `${hash: -40}` | Los 40 últimos caracteres del hash = 20 bytes. El espacio antes del `-` es obligatorio |
| `cast to-check-sum-address` | Aplica el checksum EIP-55 |

**Verifica**: `✅ Paso 3`, con la misma dirección que el paso 1. Si te sale `❌` con la
dirección en minúsculas, te faltó `cast to-check-sum-address`. Si sale este error:

```
error: invalid value '0x0xc1ffd3cfee2d9e5cd67643f8f39fd6e51aad88f6f4ce6ab8827279cfffb92266' for '[ADDRESS]': invalid string length
```

te falta el espacio de `${hash: -40}`. Sin él, `${hash:-40}` significa otra cosa en bash
("el valor de `hash`, o `40` si está vacía") y se pasa el hash entero.

## Paso 4: Una cuenta de la frase semilla

**Por qué**: de una frase salen muchas cuentas, una por índice. Así trabajan las wallets
y así reparte anvil sus cuentas de prueba.

```bash
step4() {
  cast wallet address --mnemonic "$MNEMONIC" --mnemonic-index 2
}
```

Las comillas en `"$MNEMONIC"` son obligatorias: sin ellas, bash pasaría las 12 palabras
como 12 argumentos separados.

**Verifica**: `✅ Paso 4` con `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC`.

## Paso 5: La clave privada de un índice

**Por qué**: ver que la frase contiene todas las claves. Quien tiene la frase tiene
todas las cuentas.

```bash
step5() {
  cast wallet private-key --mnemonic "$MNEMONIC" --mnemonic-index 1
}
```

**Verifica**: `✅ Paso 5`. Comprueba a mano que esa clave controla la cuenta 1:

```bash
cast wallet address --private-key $(bash pasos.sh 5)
```

Debe imprimir `0x70997970C51812dc3A010C7d01b50e0d17dc79C8`.

## Paso 6: Recuperar el checksum

**Por qué**: muchas herramientas y sitios muestran direcciones en minúsculas. Antes de
usarlas, recupera el checksum: si la copiaste mal, verás que no corresponde a la cuenta
que esperabas.

```bash
step6() {
  local lowercase=0x70997970c51812dc3a010c7d01b50e0d17dc79c8
  cast to-check-sum-address "$lowercase"
}
```

**Verifica**: `✅ Paso 6` y `6 de 6 pasos correctos`.

## ✅ Criterios de éxito

- `bash test.sh` termina con `6 de 6 pasos correctos`.
- Explicas por qué los pasos 1 y 3 coinciden.
- Explicas qué pierde una dirección escrita en minúsculas y cómo se recupera.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Hashes con cast](../ejercicio-01-hashes-con-cast/README.md) | **Ejercicio 02 — Claves y direcciones** | [Ejercicio 03 — Firmar y verificar →](../ejercicio-03-firmar-y-verificar/README.md) |
