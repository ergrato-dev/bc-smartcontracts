#!/usr/bin/env bash
# ¿Qué? Los pasos del ejercicio 03, uno por función (step1, step2...).
# ¿Para qué? Que test.sh ejecute cada paso por separado y compare su salida con la esperada.
# Uso: bash pasos.sh 1   (ejecuta solo el paso 1 y muestra lo que imprime)

todo() { echo "TODO: $1" >&2; exit 1; }

# ¿Qué? Cuenta 0 de prueba (firma) y cuenta 1 de prueba (otra persona).
# ¿Impacto? Claves públicas a propósito. Nunca reciben fondos reales.
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
ADDR=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
OTHER=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

# PASO 1: firmar el mensaje "hola" con la cuenta 0.
# Borra la línea todo y descomenta las líneas que empiezan con `#> `.
step1() {
  todo "Paso 1"
  #> cast wallet sign --private-key "$PK" "hola"
}

# PASO 2: verificar la firma del paso 1 con el mensaje y la dirección correctos.
step2() {
  todo "Paso 2"
  #> cast wallet verify --address "$ADDR" "hola" "$(step1)"
}

# PASO 3: convertir el resultado de una verificación en "aceptada" o "rechazada".
# Mensaje alterado: "Hola" con mayúscula.
step3() {
  todo "Paso 3"
  #> if cast wallet verify --address "$ADDR" "Hola" "$(step1)" >/dev/null 2>&1; then
  #>   echo "aceptada"
  #> else
  #>   echo "rechazada"
  #> fi
}

# PASO 4: misma firma y mismo mensaje, pero la dirección de otra cuenta.
step4() {
  todo "Paso 4"
  #> if cast wallet verify --address "$OTHER" "hola" "$(step1)" >/dev/null 2>&1; then
  #>   echo "aceptada"
  #> else
  #>   echo "rechazada"
  #> fi
}

# PASO 5: extraer el byte v (el último) de la firma.
step5() {
  todo "Paso 5"
  #> local sig
  #> sig=$(step1)
  #> echo "0x${sig:130:2}"
}

# PASO 6: el hash EIP-191 que se firmó de verdad, calculado a mano con el prefijo.
# Debe coincidir con `cast hash-message "hola"`.
step6() {
  todo "Paso 6"
  #> local prefix
  #> prefix=$(cast from-utf8 "$(printf '\x19Ethereum Signed Message:\n4')")
  #> cast keccak "$(cast concat-hex "$prefix" "$(cast from-utf8 "hola")")"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then "step${1:?Uso: bash pasos.sh N}"; fi
