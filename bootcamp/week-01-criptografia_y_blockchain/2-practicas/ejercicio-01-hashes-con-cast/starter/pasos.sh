#!/usr/bin/env bash
# ¿Qué? Los pasos del ejercicio 01, uno por función (step1, step2...).
# ¿Para qué? Que test.sh ejecute cada paso por separado y compare su salida con la esperada.
# Uso: bash pasos.sh 1   (ejecuta solo el paso 1 y muestra lo que imprime)

# ¿Qué? Marca de paso sin resolver: avisa y termina el paso con error.
todo() { echo "TODO: $1" >&2; exit 1; }

# ¿Qué? Hash de un bloque simplificado: keccak256(hash anterior + bytes del texto).
# ¿Para qué? Los pasos 5 y 6 la usan; es la fórmula de la Teoría 06, apartado 3.
block() { cast keccak "$(cast concat-hex "$1" "$(cast from-utf8 "$2")")"; }

# PASO 1: hash keccak256 del texto "hola".
# Borra la línea todo y descomenta las líneas que empiezan con `#> `.
step1() {
  todo "Paso 1"
  #> cast keccak "hola"
}

# PASO 2: hash SHA-256 de los 4 bytes de "hola", solo el hash (sin el "  -" final).
step2() {
  todo "Paso 2"
  #> printf 'hola' | sha256sum | cut -d ' ' -f 1
}

# PASO 3: efecto avalancha. Hash keccak256 de "Hola" (con mayúscula).
step3() {
  todo "Paso 3"
  #> cast keccak "Hola"
}

# PASO 4: convertir "hola" a bytes y hashear los bytes. Debe coincidir con el paso 1.
step4() {
  todo "Paso 4"
  #> local bytes
  #> bytes=$(cast from-utf8 "hola")
  #> cast keccak "$bytes"
}

# PASO 5: hash del bloque 0: hash anterior a cero + "Ana paga 5 a Luis", a mano.
step5() {
  todo "Paso 5"
  #> cast keccak "$(cast concat-hex "$(cast hash-zero)" "$(cast from-utf8 "Ana paga 5 a Luis")")"
}

# PASO 6: detectar una alteración. El bloque 1 original guardaba "Eva paga 2 a Raúl"
# y su hash era STORED. Recalcula con el dato alterado e imprime "intacto" o "alterado".
step6() {
  local stored=0xed68955907020f56007bca4fd8c55e23438f0191b094064d056313a94269fd54
  todo "Paso 6"
  #> local recalculated
  #> recalculated=$(block "$(step5)" "Eva paga 9 a Raúl")
  #> if [[ "$recalculated" == "$stored" ]]; then echo "intacto"; else echo "alterado"; fi
}

# ¿Qué? Si ejecutas `bash pasos.sh N`, corre el paso N. Si test.sh carga el archivo, no hace nada.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then "step${1:?Uso: bash pasos.sh N}"; fi
