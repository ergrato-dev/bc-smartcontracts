#!/usr/bin/env bash
# ¿Qué? Todos los controles del proyecto, en orden:
#   1. Los tests de contracts/test (semanas 21 y 22) y una compilación sin warnings de solc.
#   2. `forge lint` sobre src/, sin ningún aviso.
#   3. Slither con contracts/slither.config.json, sin ningún hallazgo de impacto bajo o mayor.
#   4. Los tests de tu detector propio, con pytest sobre el Python de Slither de la imagen.
# ¿Para qué? Que el protocolo siga haciendo lo que debe y que cada hallazgo de las herramientas
#   esté corregido o justificado en el código, con su comentario.
# Uso: bash test.sh   (termina con código 0 solo si todo pasa)
cd "$(dirname "$0")" || exit 1
(
  cd contracts || exit 1
  forge test || exit 1
  forge build --force --no-lint --deny warnings >/dev/null || { forge build --force --no-lint --deny warnings; exit 1; }
  forge lint --deny warnings src || exit 1
  slither . || exit 1
) || exit 1
"$SLITHER_PYTHON" -m pytest -q -p no:cacheprovider -W error detectors/tests
