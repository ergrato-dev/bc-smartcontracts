#!/usr/bin/env bash
# ¿Qué? Los pasos del ejercicio 03, uno por función (step1, step2...).
# ¿Para qué? Que test.sh ejecute cada paso por separado y compare su salida con la esperada.
# Uso: con anvil en marcha (`anvil --silent &`), bash pasos.sh 1
cd "$(dirname "$0")" || exit 1

todo() { echo "TODO: $1" >&2; exit 1; }

# ¿Qué? Clave privada de la cuenta 0 de prueba de anvil: la que despliega y envía.
# ¿Impacto? Clave pública a propósito. Nunca recibe fondos reales.
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# PASO 1: desplegar Config pasando 100 al constructor e imprimir su dirección.
# Borra la línea todo y descomenta las líneas que empiezan con `#> `.
step1() {
  todo "Paso 1"
  #> forge create --root contrato src/Config.sol:Config \
  #>   --private-key "$PK" --broadcast --json --constructor-args 100 2>/dev/null | jq -r .deployedTo
}

# PASO 2: desplegar y leer con los getters automáticos el límite y el dueño.
step2() {
  todo "Paso 2"
  #> local config
  #> config=$(step1)
  #> echo "$(cast call "$config" "limit()(uint256)") $(cast call "$config" "OWNER()(address)")"
}

# PASO 3: listar las variables que ocupan storage, según el compilador.
step3() {
  todo "Paso 3"
  #> forge inspect --root contrato Config storageLayout --json | jq -r '[.storage[].label] | join(" ")'
}

# PASO 4: desplegar y leer la variable privada `secret` directamente del slot 1.
step4() {
  todo "Paso 4"
  #> local config
  #> config=$(step1)
  #> cast storage "$config" 1 | cast to-dec
}

# PASO 5: desplegar y contar cuántas veces aparece la dirección del dueño en el código.
step5() {
  todo "Paso 5"
  #> local config
  #> config=$(step1)
  #> cast code "$config" | grep -o f39fd6e51aad88f6f4ce6ab8827279cfffb92266 | wc -l
}

# PASO 6: desplegar y comparar el gas de leer la constante y la variable de estado.
step6() {
  todo "Paso 6"
  #> local config
  #> config=$(step1)
  #> echo "$(cast estimate "$config" "MAX_LIMIT()") $(cast estimate "$config" "limit()")"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then "step${1:?Uso: bash pasos.sh N}"; fi
