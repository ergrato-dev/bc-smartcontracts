#!/usr/bin/env bash
# ¿Qué? Los tests de Foundry de contracts/test, una compilación sin warnings de solc y Slither con slither.config.json.
# ¿Para qué? Que cada corrección haga lo que debe (los tests) y que no quede ningún hallazgo de
#   impacto bajo o mayor sin corregir o sin justificar (Slither).
# Uso: bash test.sh   (termina con código 0 solo si todo pasa)
cd "$(dirname "$0")/contracts" || exit 1
forge test || exit 1
forge build --force --no-lint --deny warnings >/dev/null || { forge build --force --no-lint --deny warnings; exit 1; }
slither . || exit 1
