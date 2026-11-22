#!/usr/bin/env bash
# ¿Qué? Los pasos del ejercicio 03, uno por función (step1, step2...).
# ¿Para qué? Que test.sh ejecute cada paso por separado y compare su salida con la esperada.
# Uso: con anvil en marcha (`anvil --silent &`), bash pasos.sh 1
cd "$(dirname "$0")" || exit 1

todo() { echo "TODO: $1" >&2; exit 1; }

# ¿Qué? Clave privada de la cuenta 0 de prueba de anvil: la que despliega y envía.
# ¿Impacto? Clave pública a propósito. Nunca recibe fondos reales.
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# PASO 1: calcular el selector de la función increment().
# Borra la línea todo y descomenta las líneas que empiezan con `#> `.
step1() {
  todo "Paso 1"
  #> cast sig "increment()"
}

# PASO 2: compilar el proyecto de contrato/ y listar las funciones de su ABI.
step2() {
  todo "Paso 2"
  #> forge build --root contrato --silent
  #> jq -r '[.abi[].name] | join(" ")' contrato/out/Counter.sol/Counter.json
}

# PASO 3: desplegar Counter en anvil e imprimir su dirección.
step3() {
  todo "Paso 3"
  #> forge create --root contrato src/Counter.sol:Counter \
  #>   --private-key "$PK" --broadcast --json 2>/dev/null | jq -r .deployedTo
}

# PASO 4: desplegar y leer el número con una llamada (sin transacción).
step4() {
  todo "Paso 4"
  #> local counter
  #> counter=$(step3)
  #> cast call "$counter" "get()(uint256)"
}

# PASO 5: desplegar, incrementar con una transacción y leer el número y el slot 0 del storage.
step5() {
  todo "Paso 5"
  #> local counter
  #> counter=$(step3)
  #> cast send "$counter" "increment()" --private-key "$PK" >/dev/null
  #> echo "$(cast call "$counter" "get()(uint256)") $(cast storage "$counter" 0)"
}

# PASO 6: guardar 42 con una transacción, simular set(7) con call y volver a leer.
step6() {
  todo "Paso 6"
  #> local counter
  #> counter=$(step3)
  #> cast send "$counter" "set(uint256)" 42 --private-key "$PK" >/dev/null
  #> cast call "$counter" "set(uint256)" 7 >/dev/null
  #> cast call "$counter" "get()(uint256)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then "step${1:?Uso: bash pasos.sh N}"; fi
