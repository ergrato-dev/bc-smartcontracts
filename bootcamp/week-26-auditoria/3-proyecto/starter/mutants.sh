#!/usr/bin/env bash
# ¿Qué? Prueba de mutantes: mete a mano un fallo pequeño en src/, pasa una suite y devuelve el
#   archivo a como estaba. Los cuatro primeros los tienen que matar las invariantes (semana 24);
#   los seis siguientes, las specs de Halmos de test/formal (semana 25); los dos últimos, los
#   tests del modelo de amenazas de test/audit (semana 26).
# ¿Para qué? Que una suite en verde signifique algo. Si un mutante sobrevive, ninguna
#   invariante ni ninguna spec mira lo que ese cambio rompe.
# Uso: bash mutants.sh   (termina con código 0 solo si ningún mutante sobrevive)
cd "$(dirname "$0")/contracts" || exit 1
# Los fallos que encuentre forge aquí no se guardan con los de `forge test`.
FOUNDRY_INVARIANT_FAILURE_PERSIST_DIR="$(mktemp -d)"
export FOUNDRY_INVARIANT_FAILURE_PERSIST_DIR
survivors=0

run() {
  case "$1" in
    halmos) halmos --no-status --match-contract RegistrySpec ;;
    amenazas) forge test --mc ThreatModelTest ;;
    *) forge test --mc RegistryInvariantsTest ;;
  esac
}

# mutant <suite> <archivo> <expresión de sed> <qué rompe>
#   suite: `invariantes` (forge, RegistryInvariantsTest), `halmos` (RegistrySpec) o `amenazas`
#   (forge, ThreatModelTest).
mutant() {
  local suite=$1 file=$2 expr=$3 what=$4
  cp "$file" "$file.orig"
  sed -i "$expr" "$file"
  if cmp -s "$file" "$file.orig"; then
    echo "❌ $what: la expresión no cambia $file. ¿Cambiaste esa línea?"
    survivors=$((survivors + 1))
  elif run "$suite" >/dev/null 2>&1; then
    echo "❌ $what: sobrevive, ninguna prueba de $suite falla"
    survivors=$((survivors + 1))
  else
    echo "✅ $what: muerto"
  fi
  mv "$file.orig" "$file"
}

mutant invariantes src/Registry.sol 's/^\(\s*\)activeCount--;/\1\/\/ activeCount--;/' "retire no resta el activo"
mutant invariantes src/Registry.sol 's/if (excess == 0) return;/return;/' "no se devuelve lo pagado de más"
mutant invariantes src/Registry.sol 's/^\(\s*\)\(loyalty.burnFrom(msg.sender, POINTS_PRICE);\)/\1\/\/ \2/' "el alta con puntos no quema"
mutant invariantes src/RegistryV2.sol 's/length >= maxPerAccount/length > maxPerAccount/' "una alta de más por cuenta"
mutant halmos src/Registry.sol 's/uint256 excess = msg.value - fee;/uint256 excess = msg.value - fee + 1;/' "devuelve 1 wei de más"
mutant halmos src/Registry.sol 's/^\(\s*\)\(if (certificate.ownerOf(id) != msg.sender)\)/\1\/\/ \2/' "cualquiera retira"
mutant halmos src/RegistryV2.sol 's/^\(\s*\)\(if (_idsOf\[registrant\].length >= maxPerAccount)\)/\1\/\/ \2/' "sin límite por cuenta"
mutant halmos src/RegistryV3.sol 's/^\(\s*\)onlyRole(DEFAULT_ADMIN_ROLE)$/\1/' "cualquiera cambia la tasa"
mutant halmos src/Registry.sol 's/function withdrawFees(address payable to) external onlyRole(TREASURER_ROLE)/function withdrawFees(address payable to) external/' "cualquiera se lleva las tasas"
mutant halmos src/Registry.sol 's/function register(string calldata label) external payable whenNotPaused/function register(string calldata label) external payable/' "se registra en pausa"
mutant amenazas src/Registry.sol 's/function unpause() external onlyRole(DEFAULT_ADMIN_ROLE)/function unpause() external onlyRole(PAUSER_ROLE)/' "el pauser reanuda"
mutant amenazas src/Registry.sol 's/function withdrawFees(address payable to) external onlyRole(TREASURER_ROLE)/function withdrawFees(address payable to) external onlyRole(PAUSER_ROLE)/' "el pauser cobra las tasas"

[ "$survivors" -eq 0 ] || { echo "$survivors mutante(s) sin matar"; exit 1; }
