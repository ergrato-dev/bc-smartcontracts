#!/usr/bin/env bash
# ¿Qué? Tests del ejercicio 03: ejecuta cada paso de pasos.sh y compara su salida.
# ¿Para qué? Saber qué pasos están bien sin comparar hashes y saldos a ojo.
# Uso: bash test.sh   (termina con código 0 solo si todos los pasos pasan)
cd "$(dirname "$0")" || exit 1

# ¿Qué? Un anvil propio en el puerto 8546, recién creado antes de cada paso.
# ¿Para qué? Que cada paso empiece en el mismo estado (bloque 0, saldos iniciales) y la salida
#   sea siempre la misma, sin tocar el anvil que tengas abierto en el 8545.
export ETH_RPC_URL=http://localhost:8546
ANVIL_PID=""
stop_chain() { [[ -n "$ANVIL_PID" ]] && kill "$ANVIL_PID" 2>/dev/null && wait "$ANVIL_PID" 2>/dev/null; ANVIL_PID=""; }
fresh_chain() {
  stop_chain
  anvil --port 8546 --silent & ANVIL_PID=$!
  for _ in $(seq 100); do cast chain-id >/dev/null 2>&1 && return; sleep 0.05; done
}
trap stop_chain EXIT

passed=0
failed=0
# ¿Qué? Ejecuta el paso $1 en una cadena nueva y compara su salida con el texto esperado $2.
# ¿Impacto? timeout corta un paso que espera una transacción que nunca se mina.
expect() {
  local got
  fresh_chain
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

expect 1 21000
expect 2 "21040 21160"
expect 3 875175000
expect 4 "3000000000 2000000000"
expect 5 "0 0x1"
expect 6 2

echo "$passed de $((passed + failed)) pasos correctos"
[[ "$failed" -eq 0 ]]
