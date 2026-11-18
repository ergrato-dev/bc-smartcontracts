#!/usr/bin/env bash
# ¿Qué? Los pasos del ejercicio 02, uno por función (step1, step2...).
# ¿Para qué? Que test.sh ejecute cada paso por separado y compare su salida con la esperada.
# Uso: bash pasos.sh 1   (ejecuta solo el paso 1 y muestra lo que imprime)

todo() { echo "TODO: $1" >&2; exit 1; }

# ¿Qué? Frase semilla y clave privada de la cuenta 0 de prueba de Foundry.
# ¿Impacto? Son públicas: cualquiera puede usarlas. Nunca reciben fondos reales.
MNEMONIC="test test test test test test test test test test test junk"
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# PASO 1: dirección de la cuenta a partir de su clave privada.
# Borra la línea todo y descomenta las líneas que empiezan con `#> `.
step1() {
  todo "Paso 1"
  #> cast wallet address --private-key "$PK"
}

# PASO 2: clave pública (64 bytes) de la misma clave privada.
step2() {
  todo "Paso 2"
  #> cast wallet public-key --private-key "$PK"
}

# PASO 3: la dirección a mano: últimos 20 bytes del keccak256 de la clave pública,
# con checksum EIP-55. Debe coincidir con el paso 1.
step3() {
  todo "Paso 3"
  #> local hash
  #> hash=$(cast keccak "$(step2)")
  #> cast to-check-sum-address "0x${hash: -40}"
}

# PASO 4: dirección del índice 2 de la frase semilla, sin mostrar su clave privada.
step4() {
  todo "Paso 4"
  #> cast wallet address --mnemonic "$MNEMONIC" --mnemonic-index 2
}

# PASO 5: clave privada del índice 1 de la frase semilla.
step5() {
  todo "Paso 5"
  #> cast wallet private-key --mnemonic "$MNEMONIC" --mnemonic-index 1
}

# PASO 6: recuperar el checksum de una dirección copiada en minúsculas.
step6() {
  local lowercase=0x70997970c51812dc3a010c7d01b50e0d17dc79c8
  todo "Paso 6"
  #> cast to-check-sum-address "$lowercase"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then "step${1:?Uso: bash pasos.sh N}"; fi
