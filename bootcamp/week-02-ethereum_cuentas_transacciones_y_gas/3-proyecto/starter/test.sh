#!/usr/bin/env bash
# ¿Qué? Tests del proyecto de la semana 02. Comprueban propiedades, no valores fijos:
#       cada aprendiz tiene su dominio, su índice y sus pagos.
# ¿Para qué? Que cada pago salga de la cuenta del protocolo, mueva la cantidad pedida y que
#       el informe cuente lo que dice el recibo.
# Uso: bash test.sh   (termina con código 0 solo si los 8 tests pasan)
cd "$(dirname "$0")" || exit 1
source ./transacciones.sh

# ¿Qué? Un anvil propio en el puerto 8546, nuevo para cada test, con 5 ETH por cuenta.
# ¿Para qué? Tests independientes, sin tocar el anvil que tengas abierto en el 8545.
# ¿Impacto? Con 5 ETH los saldos en wei caben en un entero de bash (máximo ~9,2 × 10^18),
#           y las restas de saldos son exactas.
export ETH_RPC_URL=http://localhost:8546
ANVIL_PID=""
stop_chain() { [[ -n "$ANVIL_PID" ]] && kill "$ANVIL_PID" 2>/dev/null && wait "$ANVIL_PID" 2>/dev/null; ANVIL_PID=""; }
fresh_chain() {
  stop_chain
  anvil --port 8546 --balance 5 --silent & ANVIL_PID=$!
  for _ in $(seq 100); do cast chain-id >/dev/null 2>&1 && return; sleep 0.05; done
}
trap stop_chain EXIT

passed=0
failed=0
# ¿Qué? Registra un test: $1 = nombre, $2 = "ok" si pasó, otro texto (el motivo) si no.
check() {
  if [[ "$2" == "ok" ]]; then
    echo "✅ $1"
    passed=$((passed + 1))
  else
    echo "❌ $1: $2"
    failed=$((failed + 1))
  fi
}
is() { [[ "$1" == "$2" ]] && echo ok || echo "esperado '$2', obtenido '$1'"; }
# ¿Qué? Ejecuta una función de transacciones.sh con límite de tiempo (una transacción que
#       nunca se mina no bloquea los tests).
run() { timeout 20 bash transacciones.sh "$@" 2>&1; }

if [[ "$INDEX" =~ ^[3-9]$ ]]; then index_ok=ok; else index_ok="INDEX debe estar entre 3 y 9, es '$INDEX'"; fi
check "INDEX está entre 3 y 9" "$index_ok"

protocol=$(cast wallet address --mnemonic "$MNEMONIC" --mnemonic-index "$INDEX")
check "account_address deriva el índice INDEX" "$(is "$(run account_address)" "$protocol")"

# PAYMENTS: tres pagos "<índice> <ether> <concepto>", a cuentas 0-9 distintas de INDEX,
# entre 0.01 y 1 ether.
payments_ok=ok
[[ "${#PAYMENTS[@]}" -eq 3 ]] || payments_ok="hay ${#PAYMENTS[@]} pagos, deben ser 3"
for payment in "${PAYMENTS[@]}"; do
  read -r p_index p_amount p_concept <<<"$payment"
  p_wei=$(cast to-wei "$p_amount" 2>/dev/null || echo 0)
  if [[ ! "$p_index" =~ ^[0-9]$ || "$p_index" == "$INDEX" ]]; then
    payments_ok="'$payment': el índice debe ser 0-9 y distinto de INDEX"
  elif (( p_wei < 10000000000000000 || p_wei > 1000000000000000000 )); then
    payments_ok="'$payment': la cantidad debe estar entre 0.01 y 1 ether"
  elif [[ -z "$p_concept" ]]; then
    payments_ok="'$payment': falta el concepto"
  fi
done
check "PAYMENTS tiene tres pagos válidos" "$payments_ok"

to=$(cast wallet address --mnemonic "$MNEMONIC" --mnemonic-index "$([[ "$INDEX" == 9 ]] && echo 8 || echo 9)")

is_hash() { [[ "$1" =~ ^0x[0-9a-f]{64}$ ]]; }

fresh_chain
before=$(cast balance "$protocol")
hash=$(run pay "$to" 0.3)
if is_hash "$hash"; then
  sent="$(cast tx "$hash" from) $(cast tx "$hash" to) $(cast tx "$hash" value)"
  check "pay envía la cantidad desde la cuenta del protocolo" "$(is "$sent" "$protocol $to 300000000000000000")"
  cost=$(( $(cast receipt "$hash" gasUsed) * $(cast receipt "$hash" effectiveGasPrice) ))
  after=$(cast balance "$protocol")
  check "el saldo del protocolo baja exactamente cantidad + costo" \
    "$(is "$(( before - after ))" "$(( 300000000000000000 + cost ))")"
else
  check "pay envía la cantidad desde la cuenta del protocolo" "pay debe imprimir solo un hash, imprimió '$hash'"
  check "el saldo del protocolo baja exactamente cantidad + costo" "depende de pay"
fi

# ¿Qué? Una transacción enviada por el propio test, para probar tx_cost y tx_report aunque
#       pay todavía no funcione.
fresh_chain
key=$(cast wallet private-key --mnemonic "$MNEMONIC" --mnemonic-index "$INDEX")
hash=$(cast send --private-key "$key" "$to" --value 0.2ether --json | jq -r .transactionHash)
gas=$(cast receipt "$hash" gasUsed)
price=$(cast receipt "$hash" effectiveGasPrice)
cost=$(( gas * price ))
check "tx_cost es gas usado × precio efectivo" "$(is "$(run tx_cost "$hash")" "$cost")"

expected_report=$(printf '%s\n' \
  "Hash: $hash" \
  "Nonce: 0" \
  "Gas usado: $gas" \
  "Precio efectivo: $price wei" \
  "Costo: $cost wei")
check "tx_report resume el recibo en cinco líneas" "$(is "$(run tx_report "$hash")" "$expected_report")"

fresh_chain
mapfile -t hashes < <(run run_payments)
payments_run=ok
if [[ "${#hashes[@]}" -ne "${#PAYMENTS[@]}" ]] || ! is_hash "${hashes[0]}"; then
  payments_run="debe imprimir ${#PAYMENTS[@]} hashes, uno por línea; imprimió '${hashes[*]}'"
else
  for i in "${!PAYMENTS[@]}"; do
    read -r p_index p_amount p_concept <<<"${PAYMENTS[$i]}"
    got="$(cast tx "${hashes[$i]}" nonce 2>/dev/null) $(cast tx "${hashes[$i]}" to 2>/dev/null) $(cast tx "${hashes[$i]}" value 2>/dev/null)"
    want="$i $(cast wallet address --mnemonic "$MNEMONIC" --mnemonic-index "$p_index") $(cast to-wei "$p_amount")"
    [[ "$got" == "$want" ]] || { payments_run="pago $((i + 1)): esperado '$want', obtenido '$got'"; break; }
  done
fi
check "run_payments ejecuta PAYMENTS en orden, con nonces 0, 1 y 2" "$payments_run"

echo "$passed de $((passed + failed)) tests correctos"
[[ "$failed" -eq 0 ]]
