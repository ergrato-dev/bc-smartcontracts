#!/usr/bin/env bash
# ¿Qué? Los tests de Foundry, una compilación sin warnings de solc y después `forge lint` sobre src/, sin ningún aviso.
# ¿Para qué? Que cada corrección haga lo que debe (los tests) y que no quede ningún hallazgo del
#   linter sin corregir o sin justificar.
# Uso: bash test.sh   (termina con código 0 solo si todo pasa)
cd "$(dirname "$0")" || exit 1
forge test || exit 1
forge build --force --no-lint --deny warnings >/dev/null || { forge build --force --no-lint --deny warnings; exit 1; }
forge lint --deny warnings src || exit 1
