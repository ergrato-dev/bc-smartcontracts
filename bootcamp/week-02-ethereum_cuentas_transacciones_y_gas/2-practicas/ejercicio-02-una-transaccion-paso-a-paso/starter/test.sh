#!/usr/bin/env bash
# ¿Qué? Tests del ejercicio 02: ejecuta cada paso de pasos.sh y compara su salida.
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

expect 1 0x02f874827a6980843b9aca0084773594008252089470997970c51812dc3a010c7d01b50e0d17dc79c8880de0b6b3a764000080c080a074128fd7d42631897474d93692787a2e56b813754468caaca4993c641c986a37a06d5a3b027177cc2841199b70400fece0a29ac5eabee2fa9cbf9b6aa213716c48
expect 2 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
expect 3 0x7d4c13ed95c0cee830d7457ec5a5976db1fc301cfa7a23fef0039a7ccf6aea87
expect 4 0x1
expect 5 42000000000000
expect 6 "9998.999958000000000000 10001.000000000000000000"

echo "$passed de $((passed + failed)) pasos correctos"
[[ "$failed" -eq 0 ]]
