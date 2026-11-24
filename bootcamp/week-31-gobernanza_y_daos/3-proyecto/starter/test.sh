#!/usr/bin/env bash
# ¿Qué? Todos los controles del proyecto, en orden:
#   0. El informe de audit/README.md: secciones, commit y pruebas citadas (check-report.sh).
#   1. Los tests de gas de test/gas con FORGE_SNAPSHOT_CHECK=true: si algún número de
#      contracts/snapshots/RegisterGasTest.json ya no es el del código, falla. Va antes que
#      `forge test`, que reescribe ese archivo. Después, todos los tests de contracts/test, con
#      las invariantes de test/invariant, las amenazas de test/audit, el mapa de storage de
#      test/evm, la llamada en assembly de test/asm, el vault de puntos de test/defi y la
#      gobernanza de test/dao.
#   2. Las specs de Halmos de test/formal: cada `check_` tiene que pasar para todas sus entradas.
#   3. Una compilación sin warnings de solc, `forge lint` sobre src/ y Slither, sin ningún
#      hallazgo (semana 23).
#   4. Los tests de tu detector propio, con pytest sobre el Python de Slither de la imagen.
#   5. Una campaña de Medusa sobre las propiedades de test/invariant (contracts/medusa.json).
#   6. La prueba de mutantes: cada fallo de mutants.sh tiene que romper alguna invariante o spec.
# ¿Para qué? Que el informe solo cite pruebas que existen, que el protocolo siga haciendo lo que
#   debe, que cada hallazgo de las herramientas esté corregido o justificado, y que las
#   invariantes y las specs de verdad atrapen fallos.
# Uso: bash test.sh   (termina con código 0 solo si todo pasa)
cd "$(dirname "$0")" || exit 1
bash check-report.sh || exit 1
(
  cd contracts || exit 1
  FORGE_SNAPSHOT_CHECK=true forge test --mc RegisterGasTest || exit 1
  forge test || exit 1
  halmos --no-status --match-contract RegistrySpec || exit 1
  forge build --force --no-lint --deny warnings >/dev/null || { forge build --force --no-lint --deny warnings; exit 1; }
  forge lint --deny warnings src || exit 1
  slither . || exit 1
) || exit 1
"$SLITHER_PYTHON" -m pytest -q -p no:cacheprovider -W error detectors/tests || exit 1
(cd contracts && medusa fuzz --config medusa.json --no-color) || exit 1
bash mutants.sh
