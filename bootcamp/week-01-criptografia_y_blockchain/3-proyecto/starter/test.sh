#!/usr/bin/env bash
# ¿Qué? Tests del proyecto de la semana 01. Comprueban propiedades, no valores fijos:
#       cada aprendiz tiene su dominio y su índice.
# ¿Para qué? Que la ficha sea coherente: cuenta derivada, hash, firma y cadena correctos.
# Uso: bash test.sh   (termina con código 0 solo si los 8 tests pasan)
cd "$(dirname "$0")" || exit 1
source ./ficha.sh

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

address=$(account_address 2>&1)
expected=$(cast wallet address --mnemonic "$MNEMONIC" --mnemonic-index "$INDEX")
check "account_address deriva el índice INDEX" "$(is "$address" "$expected")"

if [[ "$INDEX" =~ ^[3-9]$ ]]; then index_ok=ok; else index_ok="INDEX debe estar entre 3 y 9, es '$INDEX'"; fi
check "INDEX está entre 3 y 9" "$index_ok"

check "private_key controla la cuenta" \
  "$(is "$(cast wallet address --private-key "$(private_key 2>&1)" 2>&1)" "$expected")"

card=$(card_text 2>&1)
expected_card=$(printf '%s\n' "Protocolo: $PROTOCOL" "Recurso: $RESOURCE" "Regla: $RULE" "Cuenta: $expected")
check "card_text tiene las cuatro líneas" "$(is "$card" "$expected_card")"

check "card_hash es el keccak256 de la ficha" "$(is "$(card_hash 2>&1)" "$(cast keccak "$expected_card")")"

signature=$(card_signature 2>&1)
if cast wallet verify --address "$expected" "$expected_card" "$signature" >/dev/null 2>&1; then sig_ok=ok
else sig_ok="la firma no verifica con la cuenta del protocolo"; fi
check "card_signature firma la ficha con la cuenta del protocolo" "$sig_ok"

check "verify_card acepta la ficha y rechaza una alterada" \
  "$(is "$(verify_card "$expected_card" "$signature" 2>&1) $(verify_card "${expected_card}." "$signature" 2>&1)" "válida inválida")"

previous=$(cast hash-zero)
expected_ledger=""
for record in "${RECORDS[@]}"; do
  previous=$(cast keccak "$(cast concat-hex "$previous" "$(cast from-utf8 "$record")")")
  expected_ledger+="$previous"$'\n'
done
check "ledger encadena los tres registros" "$(is "$(ledger 2>&1)" "${expected_ledger%$'\n'}")"

echo "$passed de $((passed + failed)) tests correctos"
[[ "$failed" -eq 0 ]]
