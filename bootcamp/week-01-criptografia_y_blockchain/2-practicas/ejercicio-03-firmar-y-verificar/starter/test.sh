#!/usr/bin/env bash
# ¿Qué? Tests del ejercicio 03: ejecuta cada paso de pasos.sh y compara su salida.
# ¿Para qué? Saber qué pasos están bien sin comparar firmas a ojo.
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

expect 1 0x1b4ae01d5b64ead55d120293ccdf52f9b2e03d383d8574cb28f460bcbeca3df20ffef465a8e5a53c1ea2d123c8cefbdf3f62957dd444d9b23ea4cd926bbaa8941c
expect 2 "Validation succeeded. Address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 signed this message."
expect 3 rechazada
expect 4 rechazada
expect 5 0x1c
expect 6 0x9be0f6be75ef83634b9d09b5c1293a496c4ed0d96e8df7e296fce7a915e28d50

echo "$passed de $((passed + failed)) pasos correctos"
[[ "$failed" -eq 0 ]]
