#!/usr/bin/env bash
# ¿Qué? Primeras transacciones del protocolo: la cuenta del protocolo paga en ETH y cada pago
#       deja un informe con su nonce, su gas y su costo.
# ¿Para qué? Segunda capa del proyecto hilo conductor: mover valor y saber leer qué pasó.
# ¿Impacto? Es el mismo flujo (firmar, enviar, leer el recibo) que usarás para desplegar y
#           llamar a tus contratos desde la semana 03.
# Uso: con anvil en marcha (`anvil --silent &`), bash transacciones.sh <función> [argumentos]

todo() { echo "TODO: $1" >&2; exit 1; }

# ¿Qué? Frase semilla pública de las cuentas de prueba de anvil. Nunca recibe fondos reales.
MNEMONIC="test test test test test test test test test test test junk"

# TODO: el nombre de tu protocolo y el mismo INDEX que elegiste en la semana 01.
PROTOCOL="Item Registry"
INDEX=3

# TODO: tres pagos de tu dominio, en orden. Formato: "<índice> <ether> <concepto>".
#   <índice>: cuenta de anvil que recibe (0-9, distinta de INDEX).
#   <ether>: cantidad entre 0.01 y 1, con punto decimal.
#   <concepto>: frase corta en español que explica el pago.
PAYMENTS=(
  "0 0.1 Depósito por el alta de Item 1"
  "1 0.25 Reembolso de Item 2"
  "2 0.05 Comisión por la baja de Item 1"
)

# TODO: account_address — imprime la dirección del índice INDEX de MNEMONIC.
# Pista: la misma función de tu semana 01.
account_address() {
  todo "account_address"
}

# TODO: private_key — imprime la clave privada del índice INDEX.
# Pista: la misma función de tu semana 01.
private_key() {
  todo "private_key"
}

# TODO: recipient_address N — imprime la dirección de la cuenta de anvil de índice N.
# Pista: como account_address, con "$1" en lugar de "$INDEX".
recipient_address() {
  todo "recipient_address"
}

# TODO: pay DIRECCIÓN ETHER — envía ETHER ether desde la cuenta del protocolo a DIRECCIÓN,
# espera a que se mine e imprime solo el hash de la transacción.
# Pista: Ejercicio 03, paso 4 (cast send ... --json) y jq -r .transactionHash.
pay() {
  todo "pay"
}

# TODO: tx_cost HASH — imprime en wei lo que pagó la transacción HASH.
# Pista: Ejercicio 02, paso 5.
tx_cost() {
  todo "tx_cost"
}

# TODO: tx_report HASH — imprime exactamente cinco líneas:
#   Hash: <hash>
#   Nonce: <nonce de la transacción>
#   Gas usado: <gas usado>
#   Precio efectivo: <precio efectivo del gas> wei
#   Costo: <tx_cost> wei
# Pista: cast tx HASH nonce; cast receipt HASH gasUsed; printf '%s\n' línea1 línea2 ...
tx_report() {
  todo "tx_report"
}

# TODO: run_payments — ejecuta los pagos de PAYMENTS en orden con pay e imprime un hash por línea.
# Pista: for payment in "${PAYMENTS[@]}"; do read -r index amount concept <<<"$payment"; ...; done
run_payments() {
  todo "run_payments"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then "${1:?Uso: bash transacciones.sh <función>}" "${@:2}"; fi
