#!/usr/bin/env bash
# ¿Qué? Ficha criptográfica del protocolo: su cuenta, su ficha firmada y su primer registro encadenado.
# ¿Para qué? Primera capa del proyecto hilo conductor: identidad e integridad antes de escribir contratos.
# ¿Impacto? La cuenta que derivas aquí es la que despliega tus contratos en anvil desde la semana 03.
# Uso: bash ficha.sh <función>   (por ejemplo: bash ficha.sh card_text)

todo() { echo "TODO: $1" >&2; exit 1; }

# ¿Qué? Frase semilla pública de las cuentas de prueba de Foundry. Nunca recibe fondos reales.
MNEMONIC="test test test test test test test test test test test junk"

# TODO: adapta estos datos a tu dominio. INDEX es el índice de la cuenta de tu protocolo:
# elige uno entre 3 y 9 (los índices 0-2 ya los usaron los ejercicios).
PROTOCOL="Item Registry"
RESOURCE="Item"
RULE="Cada Item queda registrado una sola vez"
INDEX=3

# TODO: tres registros (hechos) de tu dominio, en orden. Cada uno será un bloque.
# Pista: frases cortas en español con el recurso, por ejemplo "Alta de Item 1".
RECORDS=(
  "Alta de Item 1"
  "Alta de Item 2"
  "Baja de Item 1"
)

# TODO: account_address — imprime la dirección (con checksum) del índice INDEX de MNEMONIC.
# Pista: Ejercicio 02, paso 4.
account_address() {
  todo "account_address"
}

# TODO: private_key — imprime la clave privada del índice INDEX.
# Pista: Ejercicio 02, paso 5. Solo existe porque es una cuenta de prueba pública.
private_key() {
  todo "private_key"
}

# TODO: card_text — imprime la ficha del protocolo, una línea por dato y exactamente:
#   Protocolo: <PROTOCOL>
#   Recurso: <RESOURCE>
#   Regla: <RULE>
#   Cuenta: <dirección de account_address>
# Pista: printf '%s\n' "línea 1" "línea 2" ... imprime una línea por argumento.
card_text() {
  todo "card_text"
}

# TODO: card_hash — imprime el keccak256 del texto de la ficha.
card_hash() {
  todo "card_hash"
}

# TODO: card_signature — imprime la firma de la ficha hecha con private_key.
# Pista: Ejercicio 03, paso 1, con "$(card_text)" como mensaje.
card_signature() {
  todo "card_signature"
}

# TODO: verify_card MENSAJE FIRMA — imprime "válida" si FIRMA es de account_address
# sobre MENSAJE, o "inválida" si no.
# Pista: Ejercicio 03, paso 3. Los argumentos llegan en "$1" y "$2".
verify_card() {
  todo "verify_card"
}

# TODO: ledger — imprime el hash de cada uno de los tres RECORDS encadenados, uno por línea.
# El primero usa como hash anterior `cast hash-zero`; cada siguiente, el hash del anterior.
# Pista: la función block del Ejercicio 01 y un bucle `for record in "${RECORDS[@]}"; do ... done`.
ledger() {
  todo "ledger"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then "${1:?Uso: bash ficha.sh <función>}" "${@:2}"; fi
