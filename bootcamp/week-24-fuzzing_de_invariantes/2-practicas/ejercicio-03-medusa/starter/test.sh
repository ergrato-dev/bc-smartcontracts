#!/usr/bin/env bash
# ¿Qué? Los tests de Foundry (unitarios e invariantes), una compilación sin warnings de solc y
#   después una campaña de Medusa con medusa.json.
# ¿Para qué? Que la propiedad y el assert del harness aguanten con los dos fuzzers.
# Uso: bash test.sh   (termina con código 0 solo si todo pasa)
cd "$(dirname "$0")" || exit 1
forge test || exit 1
forge build --force --no-lint --deny warnings >/dev/null || { forge build --force --no-lint --deny warnings; exit 1; }
medusa fuzz --config medusa.json --no-color
