#!/usr/bin/env bash
# ¿Qué? Los tests de forge, una compilación sin warnings de solc y las specs de Halmos.
# Uso: bash test.sh   (termina con código 0 solo si todo pasa)
cd "$(dirname "$0")" || exit 1
forge test || exit 1
forge build --force --no-lint --deny warnings >/dev/null || { forge build --force --no-lint --deny warnings; exit 1; }
halmos --no-status
