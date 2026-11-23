#!/usr/bin/env bash
# ¿Qué? Tests del proyecto: los de contracts/test, que despliegan el protocolo con tus scripts y
#   lo actualizan a V2 y a V3 con un price feed falso. Después, una compilación sin warnings.
# ¿Para qué? Ver los tests en rojo mientras haya `TODO`: sus `revert` hacen que solc avise de
#   código inalcanzable (`Unreachable code`) en Registry, y con `--deny warnings` ni compilaría.
#   `--no-lint`: los avisos de `forge lint` se revisan aparte, como en las semanas anteriores.
# Uso: bash test.sh   (termina con código 0 solo si todo pasa, sin warnings)
cd "$(dirname "$0")/contracts" || exit 1
forge test || exit 1
forge build --force --no-lint --deny warnings >/dev/null || { forge build --force --no-lint --deny warnings; exit 1; }
