#!/usr/bin/env bash
# ¿Qué? Los pasos del ejercicio 03, uno por función (step1, step2...).
# ¿Para qué? Que test.sh ejecute cada paso por separado y compare su salida con la esperada.
# Uso: con anvil en marcha (`anvil --silent &`), bash pasos.sh 1

todo() { echo "TODO: $1" >&2; exit 1; }

# ¿Qué? Cuenta 0 de prueba (envía) y cuenta 1 de prueba (recibe).
# ¿Impacto? Claves públicas a propósito. Nunca reciben fondos reales.
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ADDR=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
TO=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

# PASO 1: estimar el gas de una transferencia simple de 1 wei a TO.
# Borra la línea todo y descomenta las líneas que empiezan con `#> `.
step1() {
  todo "Paso 1"
  #> cast estimate "$TO" --value 1
}

# PASO 2: estimar la misma transferencia con 4 bytes de datos: primero ceros, luego no ceros.
step2() {
  todo "Paso 2"
  #> echo "$(cast estimate "$TO" 0x00000000) $(cast estimate "$TO" 0x11111111)"
}

# PASO 3: minar un bloque con una transferencia y leer la base fee del bloque siguiente (pending).
step3() {
  todo "Paso 3"
  #> cast send --private-key "$PK" "$TO" --value 1 >/dev/null
  #> cast base-fee pending
}

# PASO 4: dos transferencias con la misma propina (2 gwei) y distinto tope (5 y 2 gwei).
# Imprime el precio efectivo del gas de cada una.
step4() {
  todo "Paso 4"
  #> local first second
  #> first=$(cast send --private-key "$PK" "$TO" --value 1 \
  #>   --gas-price 5gwei --priority-gas-price 2gwei --json | jq -r .effectiveGasPrice)
  #> second=$(cast send --private-key "$PK" "$TO" --value 1 \
  #>   --gas-price 2gwei --priority-gas-price 2gwei --json | jq -r .effectiveGasPrice)
  #> echo "$(cast to-dec "$first") $(cast to-dec "$second")"
}

# PASO 5: enviar una transacción con nonce 1 cuando la cuenta todavía está en 0.
# Imprime el nonce de la cuenta y cuántas transacciones esperan en cola.
step5() {
  todo "Paso 5"
  #> cast send --async --private-key "$PK" "$TO" --value 1 --nonce 1 >/dev/null
  #> echo "$(cast nonce "$ADDR") $(cast rpc txpool_status | jq -r .queued)"
}

# PASO 6: rellenar el hueco del paso 5 con la transacción de nonce 0 y leer el nonce final.
step6() {
  todo "Paso 6"
  #> step5 >/dev/null
  #> cast send --private-key "$PK" "$TO" --value 1 >/dev/null
  #> cast nonce "$ADDR"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then "step${1:?Uso: bash pasos.sh N}"; fi
