#!/usr/bin/env bash
# ¿Qué? Prueba cada starter/ de una semana dentro del contenedor bc-smartcontracts-dev.
#   Hay cuatro tipos de starter:
#   - Foundry (trae foundry.toml): `forge test`.
#   - Terminal (trae test.sh): `bash test.sh`, que comprueba los comandos de pasos.sh.
#   - TypeScript (trae test.sh y package.json, desde la semana 17): `bash test.sh`, que
#     comprueba los tipos y ejecuta los tests de Node.
#   - Python (trae test.sh y pyproject.toml, desde la semana 19): `bash test.sh`, que ejecuta
#     pytest.
# ¿Para qué? Garantizar dos cosas de cada ejercicio y proyecto:
#   1. Tal cual se publica, compila y sus tests FALLAN (el aprendiz tiene trabajo).
#   2. Con los pasos resueltos (líneas `//> ` o `#> ` descomentadas y marcas
#      `revert("TODO: Paso N")`, `throw new Error("TODO: Paso N")`,
#      `raise NotImplementedError("TODO: Paso N")` y `todo "Paso N"`
#      quitadas), los tests PASAN sin warnings.
# ¿Impacto? Un starter que no cumple las dos cosas no se publica.
# Uso: ./scripts/compilar-starters.sh week-01
set -euo pipefail

week="${1:?Uso: $0 week-NN}"
root="$(cd "$(dirname "$0")/.." && pwd)"
dir=$(find "$root/bootcamp" -maxdepth 1 -type d -name "${week}-*" | head -n1)
[[ -n "$dir" ]] || { echo "No existe bootcamp/${week}-*"; exit 1; }

image=bc-smartcontracts-dev
docker image inspect "$image" >/dev/null 2>&1 || docker build -q -t "$image" "$root/docker" >/dev/null

run() { # $1 = carpeta del proyecto; resto = comando dentro del contenedor
  local project="$1"; shift
  docker run --rm -v "$project":/workspace "$image" "$@" >/tmp/starter-$$.log 2>&1
}
check() { # $1 = carpeta; $2 = estricto (sin warnings) o no
  if [[ -f "$1/foundry.toml" ]]; then
    if [[ "$2" == strict ]]; then run "$1" forge test --deny warnings; else run "$1" forge test; fi
  else
    run "$1" bash test.sh
  fi
}

fail=0
while IFS= read -r starter; do
  name="${starter#"$dir"/}"
  tmp=$(mktemp -d)
  cp -r "$starter"/. "$tmp"/
  chmod -R a+rwX "$tmp"

  if [[ -f "$tmp/foundry.toml" ]] && ! run "$tmp" forge build; then
    echo "❌ $name: no compila tal cual"; tail -n 20 /tmp/starter-$$.log; fail=1; rm -rf "$tmp"; continue
  fi
  # Un starter sin pasos (solo lectura) lleva NO_STEPS.
  if [[ ! -f "$starter/NO_STEPS" ]] && check "$tmp" loose; then
    echo "❌ $name: los tests ya pasan sin resolver nada"; fail=1
  fi

  if [[ "$name" == 3-proyecto/* ]]; then
    # El proyecto no trae la solución: se prueba con la del instructor si está clonada al lado.
    solution="$root/../bc-instructor/bc-smartcontracts/$(basename "$dir")/3-proyecto"
    if [[ ! -d "$solution" ]]; then
      echo "⚠️  $name: falla como debe; sin solución del instructor en $solution"; rm -rf "$tmp"; continue
    fi
    cp -r "$solution"/. "$tmp"/
  else
    find "$tmp" -type f \( -name '*.sol' -o -name '*.sh' -o -name '*.ts' -o -name '*.py' \) -not -path '*/out/*' -not -path '*/node_modules/*' -not -path '*/.venv/*' -print0 \
      | xargs -0 sed -i -E '/(revert|throw new Error)\("TODO: Paso [0-9]+"\);/d; /^[[:space:]]*todo "Paso [0-9]+"$/d; /^[[:space:]]*raise NotImplementedError\("TODO: Paso [0-9]+"\)$/d; s#^([[:space:]]*)(//|\#)> ?#\1#'
  fi
  if check "$tmp" strict; then
    echo "✅ $name"
  else
    echo "❌ $name: con los pasos resueltos los tests no pasan"; tail -n 20 /tmp/starter-$$.log; fail=1
  fi
  rm -rf "$tmp"
done < <(find "$dir" -type d -name starter -not -path '*/out/*' -not -path '*/node_modules/*' -not -path '*/.venv/*' | sort)

rm -f /tmp/starter-$$.log
exit "$fail"
