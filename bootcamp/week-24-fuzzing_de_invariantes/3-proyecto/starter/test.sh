#!/usr/bin/env bash
# ¿Qué? Todos los controles del proyecto, en orden:
#   1. Los tests de contracts/test, con las invariantes de test/invariant, y una compilación
#      sin warnings de solc.
#   2. `forge lint` sobre src/ y Slither, sin ningún hallazgo (semana 23).
#   3. Los tests de tu detector propio, con pytest sobre el Python de Slither de la imagen.
#   4. Una campaña de Medusa sobre las mismas propiedades (contracts/medusa.json).
#   5. La prueba de mutantes: cada fallo de mutants.sh tiene que romper alguna invariante.
# ¿Para qué? Que el protocolo siga haciendo lo que debe, que cada hallazgo de las herramientas
#   esté corregido o justificado, y que las invariantes de verdad atrapen fallos.
# Uso: bash test.sh   (termina con código 0 solo si todo pasa)
cd "$(dirname "$0")" || exit 1
(
  cd contracts || exit 1
  forge test || exit 1
  forge build --force --no-lint --deny warnings >/dev/null || { forge build --force --no-lint --deny warnings; exit 1; }
  forge lint --deny warnings src || exit 1
  slither . || exit 1
) || exit 1
"$SLITHER_PYTHON" -m pytest -q -p no:cacheprovider -W error detectors/tests || exit 1
(cd contracts && medusa fuzz --config medusa.json --no-color) || exit 1
bash mutants.sh
