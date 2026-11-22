#!/usr/bin/env bash
# ¿Qué? Los pasos del ejercicio 02, uno por función (step1, step2...).
# ¿Para qué? Que test.sh ejecute cada paso por separado y compare su salida con la esperada.
# Uso: con anvil en marcha (`anvil --silent &`), bash pasos.sh 1

todo() { echo "TODO: $1" >&2; exit 1; }

# ¿Qué? Cuenta 0 de prueba (envía) y cuenta 1 de prueba (recibe).
# ¿Impacto? Claves públicas a propósito. Nunca reciben fondos reales.
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ADDR=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
TO=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

# PASO 1: construir y firmar, sin enviarla, una transacción que manda 1 ether a TO.
# Todos los campos van fijos para que la firma salga siempre igual.
# Borra la línea todo y descomenta las líneas que empiezan con `#> `.
step1() {
  todo "Paso 1"
  #> cast mktx --private-key "$PK" "$TO" --value 1ether \
  #>   --nonce 0 --gas-limit 21000 --gas-price 2gwei --priority-gas-price 1gwei --chain 31337
}

# PASO 2: decodificar la transacción firmada del paso 1 e imprimir quién la firmó.
step2() {
  todo "Paso 2"
  #> cast decode-transaction "$(step1)" | jq -r .signer
}

# PASO 3: el hash de la transacción, calculado antes de enviarla.
step3() {
  todo "Paso 3"
  #> cast decode-transaction "$(step1)" | jq -r .hash
}

# PASO 4: enviar la transacción firmada al nodo e imprimir el estado de su recibo.
step4() {
  todo "Paso 4"
  #> cast publish "$(step1)" | jq -r .status
}

# PASO 5: lo que costó la transacción, en wei: gas usado × precio efectivo del gas.
step5() {
  todo "Paso 5"
  #> local hash
  #> hash=$(cast publish "$(step1)" | jq -r .transactionHash)
  #> echo $(( $(cast receipt "$hash" gasUsed) * $(cast receipt "$hash" effectiveGasPrice) ))
}

# PASO 6: tras enviar la transacción, los saldos en ether de quien envía y de quien recibe.
step6() {
  todo "Paso 6"
  #> cast publish "$(step1)" >/dev/null
  #> echo "$(cast balance --ether "$ADDR") $(cast balance --ether "$TO")"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then "step${1:?Uso: bash pasos.sh N}"; fi
