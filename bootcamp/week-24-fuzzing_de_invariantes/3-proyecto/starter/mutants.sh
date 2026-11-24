#!/usr/bin/env bash
# ¿Qué? Prueba de mutantes: mete a mano un fallo pequeño en src/, pasa las invariantes y
#   devuelve el archivo a como estaba. Cada mutante tiene que hacer fallar alguna invariante.
# ¿Para qué? Que una suite de invariantes en verde signifique algo. Si un mutante sobrevive,
#   ninguna invariante mira lo que ese cambio rompe.
# Uso: bash mutants.sh   (termina con código 0 solo si ningún mutante sobrevive)
cd "$(dirname "$0")/contracts" || exit 1
# Los fallos que encuentre forge aquí no se guardan con los de `forge test`.
FOUNDRY_INVARIANT_FAILURE_PERSIST_DIR="$(mktemp -d)"
export FOUNDRY_INVARIANT_FAILURE_PERSIST_DIR
survivors=0

# mutant <archivo> <expresión de sed> <qué rompe>
mutant() {
  local file=$1 expr=$2 what=$3
  cp "$file" "$file.orig"
  sed -i "$expr" "$file"
  if cmp -s "$file" "$file.orig"; then
    echo "❌ $what: la expresión no cambia $file. ¿Cambiaste esa línea?"
    survivors=$((survivors + 1))
  elif forge test --mc RegistryInvariantsTest >/dev/null 2>&1; then
    echo "❌ $what: sobrevive, ninguna invariante falla"
    survivors=$((survivors + 1))
  else
    echo "✅ $what: muerto"
  fi
  mv "$file.orig" "$file"
}

mutant src/Registry.sol 's/^\(\s*\)activeCount--;/\1\/\/ activeCount--;/' "retire no resta el activo"
mutant src/Registry.sol 's/if (excess == 0) return;/return;/' "no se devuelve lo pagado de más"
mutant src/Registry.sol 's/^\(\s*\)\(loyalty.burnFrom(msg.sender, POINTS_PRICE);\)/\1\/\/ \2/' "el alta con puntos no quema"
mutant src/RegistryV2.sol 's/length >= maxPerAccount/length > maxPerAccount/' "una alta de más por cuenta"

[ "$survivors" -eq 0 ] || { echo "$survivors mutante(s) sin matar"; exit 1; }
