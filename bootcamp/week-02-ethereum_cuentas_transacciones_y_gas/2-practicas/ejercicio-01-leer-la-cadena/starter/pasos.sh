#!/usr/bin/env bash
# ¿Qué? Los pasos del ejercicio 01, uno por función (step1, step2...).
# ¿Para qué? Que test.sh ejecute cada paso por separado y compare su salida con la esperada.
# Uso: con anvil en marcha (`anvil --silent &`), bash pasos.sh 1

todo() { echo "TODO: $1" >&2; exit 1; }

# ¿Qué? URL del nodo. cast la lee sola de ETH_RPC_URL; curl la necesita explícita.
# ¿Impacto? test.sh arranca su propio anvil en el puerto 8546 y exporta ETH_RPC_URL;
# tú, a mano, usas el anvil del puerto 8545 por defecto.
RPC=${ETH_RPC_URL:-http://localhost:8545}

# ¿Qué? Cuenta 0 de prueba de anvil. Pública a propósito: nunca recibe fondos reales.
ADDR=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# PASO 1: pedir el chain id al nodo con curl, en JSON-RPC puro.
# Borra la línea todo y descomenta las líneas que empiezan con `#> `.
step1() {
  todo "Paso 1"
  #> curl -s -X POST -H 'Content-Type: application/json' \
  #>   --data '{"jsonrpc":"2.0","id":1,"method":"eth_chainId","params":[]}' "$RPC"
}

# PASO 2: el mismo dato con cast, ya convertido a decimal.
step2() {
  todo "Paso 2"
  #> cast chain-id
}

# PASO 3: el saldo de la cuenta 0 con curl; imprime solo el campo result.
step3() {
  todo "Paso 3"
  #> curl -s -X POST -H 'Content-Type: application/json' \
  #>   --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_getBalance\",\"params\":[\"$ADDR\",\"latest\"]}" \
  #>   "$RPC" | jq -r .result
}

# PASO 4: convertir el saldo hexadecimal del paso 3 a decimal (wei).
step4() {
  todo "Paso 4"
  #> cast to-dec "$(step3)"
}

# PASO 5: el saldo de la cuenta 0 en ether, con cast.
step5() {
  todo "Paso 5"
  #> cast balance --ether "$ADDR"
}

# PASO 6: nonce y código de la cuenta 0, separados por un espacio.
step6() {
  todo "Paso 6"
  #> echo "$(cast nonce "$ADDR") $(cast code "$ADDR")"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then "step${1:?Uso: bash pasos.sh N}"; fi
