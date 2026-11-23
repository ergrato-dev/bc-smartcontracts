#!/usr/bin/env bash
# ¿Qué? Tests del proyecto: los de contracts/test, que despliegan el protocolo con tus scripts,
#   lo actualizan a V3 con un price feed falso y lo atacan con los contratos de test/attackers.
#   Después, una compilación sin warnings.
# ¿Para qué? Ver los tests en rojo mientras haya `TODO`: los atacantes sin terminar hacen que
#   solc avise de parámetros sin usar y de funciones que podrían ser `pure`, y con
#   `--deny warnings` ni compilaría. `--no-lint`: los avisos de `forge lint` se revisan aparte.
# Uso: bash test.sh   (termina con código 0 solo si todo pasa, sin warnings)
cd "$(dirname "$0")/contracts" || exit 1
forge test || exit 1
forge build --force --no-lint --deny warnings >/dev/null || { forge build --force --no-lint --deny warnings; exit 1; }
