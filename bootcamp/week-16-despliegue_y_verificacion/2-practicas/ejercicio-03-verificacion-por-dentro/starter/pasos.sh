#!/usr/bin/env bash
# ¿Qué? Los pasos del ejercicio 03, uno por función (step1, step2...).
# ¿Para qué? Que test.sh ejecute cada paso por separado y compare su salida con la esperada.
# Uso: con anvil en marcha (`anvil --silent &`), bash pasos.sh 1
cd "$(dirname "$0")" || exit 1

todo() { echo "TODO: $1" >&2; exit 1; }

RPC="${ETH_RPC_URL:-http://127.0.0.1:8545}"
# ¿Qué? Clave de la cuenta 3 de prueba de anvil. En anvil basta con --private-key; en Sepolia
#   firmas con tu keystore (ejercicio 02).
PK=0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
ME=0x90F79bf6EB2c4f870365E785982E1f101E93b906
RUN=contrato/broadcast/DeployBox.s.sol/31337/run-latest.json

# ¿Qué? Despliega la Box con el script del ejercicio 01. No es un paso: lo usan todos.
deploy() {
  forge script --root contrato contrato/script/DeployBox.s.sol --rpc-url "$RPC" \
    --private-key "$PK" --broadcast >/dev/null
  cast to-check-sum-address "$(jq -r '.transactions[0].contractAddress' "$RUN")"
}

# PASO 1: comparar el código desplegado con el runtime que da el compilador: imprime los dos
# tamaños en caracteres y si son iguales.
# Borra la línea todo y descomenta las líneas que empiezan con `#> `.
step1() {
  todo "Paso 1"
  #> local chain compiled
  #> chain=$(cast code "$(deploy)" --rpc-url "$RPC")
  #> compiled=$(forge inspect --root contrato Box deployedBytecode)
  #> echo "${#chain} ${#compiled}"
  #> [[ "$chain" == "$compiled" ]] && echo iguales || echo distintos
}

# PASO 2: dónde está el immutable OWNER en el código y qué hay ahí en la cadena.
step2() {
  todo "Paso 2"
  #> local chain
  #> chain=$(cast code "$(deploy)" --rpc-url "$RPC")
  #> jq -c '[.deployedBytecode.immutableReferences[][] | .start]' contrato/out/Box.sol/Box.json
  #> echo "${chain:2+157*2:64}"
}

# PASO 3: poner a cero los huecos de los immutables en el código de la cadena y volver a comparar.
step3() {
  todo "Paso 3"
  #> local chain compiled start zeros
  #> chain=$(cast code "$(deploy)" --rpc-url "$RPC")
  #> compiled=$(forge inspect --root contrato Box deployedBytecode)
  #> zeros=$(printf '0%.0s' {1..64})
  #> for start in $(jq -r '.deployedBytecode.immutableReferences[][] | .start' contrato/out/Box.sol/Box.json); do
  #>   chain="${chain:0:2+start*2}${zeros}${chain:2+start*2+64}"
  #> done
  #> [[ "$chain" == "$compiled" ]] && echo iguales || echo distintos
}

# PASO 4: leer los metadatos que solc añade al final: su longitud y la versión del compilador.
step4() {
  todo "Paso 4"
  #> local chain len cbor v
  #> chain=$(cast code "$(deploy)" --rpc-url "$RPC")
  #> len=$((16#${chain: -4}))
  #> cbor=${chain: -$((len * 2 + 4)):$((len * 2))}
  #> v=${cbor: -6}
  #> echo "$len $((16#${v:0:2})).$((16#${v:2:2})).$((16#${v:4:2}))"
}

# PASO 5: los argumentos del constructor van pegados al final de la transacción de creación.
step5() {
  todo "Paso 5"
  #> local hash input
  #> deploy >/dev/null
  #> hash=$(jq -r '.transactions[0].hash' "$RUN")
  #> input=$(cast tx "$hash" input --rpc-url "$RPC")
  #> echo "${input: -64}"
  #> cast abi-encode "constructor(address)" "$ME"
}

# PASO 6: el JSON que forge enviaría al verificador: lenguaje, archivo, EVM y optimizador.
step6() {
  todo "Paso 6"
  #> local box
  #> box=$(deploy)
  #> forge verify-contract --root contrato "$box" src/Box.sol:Box --show-standard-json-input \
  #>   --constructor-args "$(cast abi-encode "constructor(address)" "$ME")" |
  #>   jq -r '[.language, (.sources | keys[0]), .settings.evmVersion, .settings.optimizer.enabled] | join(" ")'
}

# PASO 7: con otros ajustes (el optimizador encendido), el mismo código fuente da otro bytecode.
step7() {
  todo "Paso 7"
  #> local default optimized
  #> default=$(forge inspect --root contrato Box deployedBytecode)
  #> optimized=$(forge inspect --root contrato Box deployedBytecode --optimize)
  #> echo "${#default} ${#optimized}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then "step${1:?Uso: bash pasos.sh N}"; fi
