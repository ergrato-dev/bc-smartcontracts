#!/usr/bin/env bash
# ¿Qué? Tests del ejercicio 02: ejecuta cada paso de pasos.sh y compara su salida.
# ¿Para qué? Saber qué pasos están bien sin comparar claves y direcciones a ojo.
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

expect 1 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
expect 2 0x8318535b54105d4a7aae60c08fc45f9687181b4fdfc625bd1a753fa7397fed753547f11ca8696646f2f3acb08e31016afac23e630c5d11f59f61fef57b0d2aa5
expect 3 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
expect 4 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
expect 5 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
expect 6 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

echo "$passed de $((passed + failed)) pasos correctos"
[[ "$failed" -eq 0 ]]
