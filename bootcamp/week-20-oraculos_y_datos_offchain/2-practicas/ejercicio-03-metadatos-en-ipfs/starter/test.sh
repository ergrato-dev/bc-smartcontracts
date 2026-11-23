#!/usr/bin/env bash
# ¿Qué? Tests del ejercicio 03: ejecuta cada paso de pasos.sh y compara su salida.
# ¿Para qué? Saber qué pasos están bien sin comparar CIDs a ojo.
# Uso: bash test.sh   (termina con código 0 solo si todos los pasos pasan)
cd "$(dirname "$0")" || exit 1

# ¿Qué? Un repositorio de IPFS vacío en una carpeta temporal, sin daemon ni red.
# ¿Para qué? Que los pasos no toquen tu ~/.ipfs y que `ipfs add` e `ipfs cat` funcionen igual
#   en cualquier contenedor: el CID solo depende del contenido.
export IPFS_PATH=$(mktemp -d)
trap 'rm -rf "$IPFS_PATH"' EXIT
ipfs init >/dev/null || exit 1

IMAGE=bafkreih7elkzkshno6aj22ct5xuv2sdgxmjyehakqpqegyc6hbeppri6zy
passed=0
failed=0
# ¿Qué? Ejecuta el paso $1 y compara su salida con el texto esperado $2.
expect() {
  local got
  got=$(timeout 20 bash pasos.sh "$1" 2>&1)
  if [[ "$got" == "$2" ]]; then
    echo "✅ Paso $1"
    passed=$((passed + 1))
  else
    echo "❌ Paso $1"
    echo "   esperado: $2"
    echo "   obtenido: $got"
    failed=$((failed + 1))
  fi
}

expect 1 "$IMAGE"
expect 2 "$IMAGE"
expect 3 "{\"name\":\"Certificado #1\",\"description\":\"Certificado de un recurso del protocolo\",\"image\":\"ipfs://$IMAGE\"}"
expect 4 bafybeihcz6noexhgvqk2dlmdvzfmliwyejoygeclgiacwuwv2vt6yyuvzi
expect 5 "{\"name\":\"Certificado #2\",\"description\":\"Certificado de un recurso del protocolo\",\"image\":\"ipfs://$IMAGE\"}"

echo "$passed de $((passed + failed)) pasos correctos"
[[ "$failed" -eq 0 ]]
