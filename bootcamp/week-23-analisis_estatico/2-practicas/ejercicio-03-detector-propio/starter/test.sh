#!/usr/bin/env bash
# ¿Qué? Los tests del detector con pytest, sobre el Python de Slither de la imagen.
# ¿Para qué? Comprobar cada función del detector contra los casos de contracts/src/Treasury.sol.
#   `-W error`: un warning de Python es un error, y sin caché de pytest en tu carpeta.
# Uso: bash test.sh   (termina con código 0 solo si todo pasa)
cd "$(dirname "$0")" || exit 1
"$SLITHER_PYTHON" -m pytest -q -p no:cacheprovider -W error tests
