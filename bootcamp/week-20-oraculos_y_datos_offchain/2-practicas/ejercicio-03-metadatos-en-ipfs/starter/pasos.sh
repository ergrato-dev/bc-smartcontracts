#!/usr/bin/env bash
# ¿Qué? Los pasos del ejercicio 03, uno por función (step1, step2...).
# ¿Para qué? Que test.sh ejecute cada paso por separado y compare su salida con la esperada.
# Uso: con un repositorio de IPFS creado (`ipfs init`), bash pasos.sh 1

todo() { echo "TODO: $1" >&2; exit 1; }

# PASO 1: el CID de certificado.svg, sin guardarlo en ningún sitio.
# Borra la línea todo y descomenta las líneas que empiezan con `#> `.
step1() {
  todo "Paso 1"
  #> ipfs add --only-hash --cid-version 1 --quiet certificado.svg
}

# PASO 2: el mismo CID a mano: prefijo de versión, códec y hash, más el sha256 del archivo,
#   en base32 con la `b` delante.
step2() {
  todo "Paso 2"
  #> local digest
  #> digest=$(sha256sum certificado.svg | cut -d ' ' -f 1)
  #> python3 -c 'import base64, sys; print("b" + base64.b32encode(bytes.fromhex("01551220" + sys.argv[1])).decode().lower().rstrip("="))' "$digest"
}

# PASO 3: la metadata del certificado $1 (1 si no se indica), en una línea, con la imagen por su CID.
step3() {
  todo "Paso 3"
  #> jq -nc --arg id "${1:-1}" --arg image "ipfs://$(step1)" \
  #>   '{name: "Certificado #\($id)", description: "Certificado de un recurso del protocolo", image: $image}'
}

# PASO 4: una carpeta metadata/ con 1.json y 2.json, guardada en tu nodo; imprime el CID de la carpeta.
step4() {
  todo "Paso 4"
  #> rm -rf metadata && mkdir metadata
  #> for id in 1 2; do step3 "$id" > "metadata/$id.json"; done
  #> ipfs add --recursive --cid-version 1 --quiet metadata | tail -n 1
}

# PASO 5: leer de tu nodo el 2.json por la ruta <CID de la carpeta>/2.json, como lo haría un tokenURI.
step5() {
  todo "Paso 5"
  #> ipfs cat "$(step4)/2.json"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then "step${1:?Uso: bash pasos.sh N}" "${@:2}"; fi
