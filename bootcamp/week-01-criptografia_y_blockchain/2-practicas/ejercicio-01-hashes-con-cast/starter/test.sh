#!/usr/bin/env bash
# ¿Qué? Tests del ejercicio 01: ejecuta cada paso de pasos.sh y compara su salida.
# ¿Para qué? Saber qué pasos están bien sin comprobar hashes a ojo.
# Uso: bash test.sh   (termina con código 0 solo si todos los pasos pasan)
cd "$(dirname "$0")" || exit 1
source ./pasos.sh

passed=0
failed=0
# ¿Qué? Compara la salida del paso $1 con el texto esperado $2.
expect() {
  local got
  got=$("step$1" 2>&1)
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

expect 1 0x8aca9664752dbae36135fd0956c956fc4a370feeac67485b49bcd4b99608ae41
expect 2 b221d9dbb083a7f33428d7c2a3c3198ae925614d70210e28716ccaa7cd4ddb79
expect 3 0x98d72beb4bd8117253d41e6075451e4c62e8f4cb6538536ef1fc13333c7a4085
expect 4 0x8aca9664752dbae36135fd0956c956fc4a370feeac67485b49bcd4b99608ae41
expect 5 0xb1795d5e11efa5e4692dda990a774fe0fbb61421c77b7536682ee9d3b8993b3c
expect 6 alterado

echo "$passed de $((passed + failed)) pasos correctos"
[[ "$failed" -eq 0 ]]
