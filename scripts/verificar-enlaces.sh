#!/usr/bin/env bash
# ¿Qué? Verifica la integridad estructural del bootcamp.
#   1. Nombres de carpeta week-NN-slug bien formados.
#   2. Enlaces relativos de markdown que resuelven a una ruta real.
#   3. Tabla de navegación (Anterior | Actual | Siguiente) al pie de todo .md de bootcamp/.
#   4. SVG con XML válido, fondo, sin degradados y enlazados desde algún .md.
#   5. Nada prohibido: solution/, docs/dominios.md, out/ o cache/ versionado.
#   6. Ni voseo ni herramientas vetadas (npm, pip, MySQL) en la prosa.
# ¿Para qué? Que un fallo de forma no llegue a publicarse.
# Uso: ./scripts/verificar-enlaces.sh   (exit 1 si hay al menos un problema)
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0
bad() { echo "$1"; fail=1; }

echo "== 1. Nombres de carpeta =="
while IFS= read -r d; do
  [[ "$(basename "$d")" =~ ^week-[0-9]{2}-[a-z0-9_]+$ ]] || bad "NOMBRE INVALIDO: $d"
done < <(find bootcamp -mindepth 1 -maxdepth 1 -type d -name 'week-*')

echo "== 2. Enlaces relativos =="
# ponytail: no parsea markdown, solo quita bloques ``` y busca "](...)". Falsos positivos
# conocidos: URLs con paréntesis anidados.
while IFS= read -r f; do
  while IFS= read -r link; do
    clean="${link%%#*}"; clean="${clean%% *}"
    [ -z "$clean" ] && continue
    case "$clean" in http*|mailto:*|/*) continue ;; esac
    [ -e "$(dirname "$f")/$clean" ] || bad "ENLACE ROTO: $f -> $link"
  done < <(awk '/^```/{c=!c; next} !c' "$f" | grep -oE '\]\([^)]+\)' | sed -E 's/^\]\(//;s/\)$//')
done < <(find . -name '*.md' -not -path './.git/*' -not -path '*/out/*' \
           -not -path './.claude/*' -not -path './.github/*')  # .github lleva rutas de ejemplo

echo "== 3. Navegación al pie =="
while IFS= read -r f; do
  tail -n 8 "$f" | grep -q '^| Anterior | Actual | Siguiente |' || bad "SIN NAVEGACION AL PIE: $f"
done < <(find bootcamp -mindepth 2 -name '*.md' -not -path '*/out/*')

echo "== 4. SVG =="
while IFS= read -r svg; do
  python3 -I -c "import xml.dom.minidom,sys; xml.dom.minidom.parse(sys.argv[1])" "$svg" 2>/dev/null \
    || bad "SVG MAL FORMADO: $svg"
  grep -q 'Gradient' "$svg" && bad "SVG CON DEGRADADO: $svg"
  grep -q 'fill="#0d1117"' "$svg" || bad "SVG SIN FONDO #0d1117: $svg"
  grep -q 'role="img"' "$svg" || bad "SVG SIN role=img: $svg"
  grep -rqF "$(basename "$svg")" --include='*.md' . || bad "SVG HUERFANO: $svg"
done < <(find bootcamp assets -name '*.svg')

echo "== 5. Prohibidos =="
while IFS= read -r d; do bad "CARPETA PROHIBIDA: $d"; done < <(find bootcamp -type d -name solution)
[ -e docs/dominios.md ] && bad "PROHIBIDO: docs/dominios.md (el catálogo vive en bc-dominios)"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r f; do bad "ARTEFACTO VERSIONADO: $f"; done < <(git ls-files bootcamp | grep -E '/(out|cache|broadcast)/')
fi

echo "== 6. Voseo y herramientas vetadas =="
# Palabras de voseo frecuentes; ampliar la lista cuando aparezca una nueva.
voseo='\b(vos|tenés|podés|querés|sabés|hacé|usá|mirá|fijate|abrí|escribí|ejecutá|corré|probá|agregá|seguí|decí|poné)\b'
while IFS= read -r hit; do bad "VOSEO: $hit"; done < <(grep -rnwiE "$voseo" --include='*.md' bootcamp docs README.md 2>/dev/null)
while IFS= read -r hit; do bad "HERRAMIENTA VETADA: $hit"; done < <(
  grep -rnE '\b(npm (i|install|run|ci)|npx |pip3? install|mysql)\b' --include='*.md' --include='*.sol' --include='*.sh' --include='*.toml' --include='*.yaml' \
    bootcamp docs docker 2>/dev/null)

[ "$fail" -eq 0 ] && echo "OK: sin problemas detectados."
exit "$fail"
