#!/usr/bin/env bash
# ¿Qué? Los pasos del ejercicio 02, uno por función (step1, step2...).
# ¿Para qué? Que test.sh ejecute cada paso por separado y compare su salida con la esperada.
# Uso: con anvil en marcha (`anvil --silent &`), bash pasos.sh 1
cd "$(dirname "$0")" || exit 1

todo() { echo "TODO: $1" >&2; exit 1; }

# ¿Qué? Red a la que se envía: la de test.sh (8546) o, a mano, tu anvil (8545).
RPC="${ETH_RPC_URL:-http://127.0.0.1:8545}"

# ¿Qué? Clave privada de la cuenta 3 de prueba de anvil: la que se guarda cifrada en el keystore.
# ¿Impacto? Clave pública a propósito, la conoce todo el mundo. Nunca recibe fondos reales.
PK=0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6

# ¿Qué? Carpeta temporal para los keystores y archivo con la contraseña, nuevos en cada ejecución.
# ¿Para qué? No tocar ~/.foundry/keystores y empezar siempre sin keystores.
# ¿Impacto? Una contraseña en un archivo solo vale para pruebas: el tuyo de Sepolia la pide al firmar.
KEYSTORES=$(mktemp -d)
PASSWORD_FILE="$KEYSTORES/password.txt"
printf 'solo-pruebas-en-anvil' >"$PASSWORD_FILE"
trap 'rm -rf "$KEYSTORES"' EXIT

# PASO 1: guardar la clave en un keystore llamado dev e imprimir su dirección leyéndola de él.
# Borra la línea todo y descomenta las líneas que empiezan con `#> `.
step1() {
  todo "Paso 1"
  #> cast wallet import dev --private-key "$PK" --keystore-dir "$KEYSTORES" \
  #>   --unsafe-password "$(cat "$PASSWORD_FILE")" >/dev/null
  #> cast wallet address --keystore "$KEYSTORES/dev" --password-file "$PASSWORD_FILE"
}

# PASO 2: mirar qué guarda el keystore: el algoritmo que deriva la clave de cifrado, el
# cifrado, y cuántas veces aparece la clave privada en claro.
step2() {
  todo "Paso 2"
  #> step1 >/dev/null
  #> jq -r '.crypto.kdf + " " + .crypto.cipher' "$KEYSTORES/dev"
  #> grep -c "${PK#0x}" "$KEYSTORES/dev"
}

# PASO 3: intentar abrir el keystore con otra contraseña.
step3() {
  todo "Paso 3"
  #> step1 >/dev/null
  #> cast wallet address --keystore "$KEYSTORES/dev" --password otra 2>&1 | grep -o "Mac Mismatch"
}

# PASO 4: simular el script sin --broadcast: imprime el nonce de la cuenta después y cuántas
# transacciones quedaron en el archivo de la simulación.
step4() {
  todo "Paso 4"
  #> local me
  #> me=$(step1)
  #> forge script --root contrato contrato/script/DeployBox.s.sol --rpc-url "$RPC" \
  #>   --keystore "$KEYSTORES/dev" --password-file "$PASSWORD_FILE" >/dev/null
  #> echo "$(cast nonce "$me" --rpc-url "$RPC")" \
  #>   "$(jq '.transactions | length' contrato/broadcast/DeployBox.s.sol/31337/dry-run/run-latest.json)"
}

# PASO 5: emitir con --broadcast: imprime el nonce de la cuenta y el número guardado en la Box.
step5() {
  todo "Paso 5"
  #> local me box
  #> me=$(step1)
  #> forge script --root contrato contrato/script/DeployBox.s.sol --rpc-url "$RPC" \
  #>   --keystore "$KEYSTORES/dev" --password-file "$PASSWORD_FILE" --broadcast >/dev/null
  #> box=$(jq -r '.transactions[0].contractAddress' contrato/broadcast/DeployBox.s.sol/31337/run-latest.json)
  #> echo "$(cast nonce "$me" --rpc-url "$RPC") $(cast call "$box" "value()(uint256)" --rpc-url "$RPC")"
}

# PASO 6: emitir con INITIAL_VALUE=42 y leer del registro de la ejecución el tipo de cada
# transacción, su función y el estado de cada recibo.
step6() {
  todo "Paso 6"
  #> step1 >/dev/null
  #> INITIAL_VALUE=42 forge script --root contrato contrato/script/DeployBox.s.sol --rpc-url "$RPC" \
  #>   --keystore "$KEYSTORES/dev" --password-file "$PASSWORD_FILE" --broadcast >/dev/null
  #> jq -r '.transactions[] | "\(.transactionType) \(.function // .contractName) \(.arguments | join(","))"' \
  #>   contrato/broadcast/DeployBox.s.sol/31337/run-latest.json
  #> jq -r '[.receipts[].status] | join(" ")' contrato/broadcast/DeployBox.s.sol/31337/run-latest.json
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then "step${1:?Uso: bash pasos.sh N}"; fi
