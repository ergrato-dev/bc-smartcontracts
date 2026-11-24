#!/usr/bin/env bash
# ¿Qué? Comprueba lo comprobable del informe de auditoría (audit/README.md):
#   1. Tiene las secciones del informe final: Resumen, Alcance, Modelo de amenazas y Hallazgos.
#   2. El alcance fija un commit: un hash de 40 caracteres hexadecimales.
#   3. Cada hallazgo de la tabla (H-01, H-02...) tiene su sección `### Id` con su **Estado**.
#   4. Cada test, invariante o spec que el informe cita entre comillas invertidas (`test_...`,
#      `testFuzz_...`, `invariant_...`, `check_...`) existe en contracts/test.
#   5. Cada número de gas de contracts/snapshots/RegisterGasTest.json aparece en el informe, tal
#      cual, sin separador de miles (semana 29).
#   6. La auditoría cruzada que escribes del protocolo de tu pareja (audit/auditoria-cruzada.md,
#      semana 34): sus secciones, el repositorio y el commit auditados, y que cada hallazgo de la
#      tabla (C-01, C-02...) tenga su sección `### Id` con **Severidad** y **Prueba de concepto**.
# ¿Para qué? Que el informe no prometa pruebas que no existen. Lo demás (que cada frase sea
#   cierta) no lo comprueba ningún script: lo revisas tú y quien lea el informe.
# Uso: bash check-report.sh   (termina con código 0 solo si todo cuadra)
cd "$(dirname "$0")" || exit 1
report=audit/README.md
[[ -f "$report" ]] || { echo "❌ falta $report"; exit 1; }
fail=0

for section in "Resumen" "Alcance" "Modelo de amenazas" "Hallazgos"; do
  grep -q "^## $section" "$report" || { echo "❌ falta la sección ## $section"; fail=1; }
done

grep -qE '\b[0-9a-f]{40}\b' "$report" || { echo "❌ el alcance no fija ningún commit (hash de 40 caracteres)"; fail=1; }

# Los ids de la tabla de hallazgos: filas que empiezan con `| H-01 |`.
for id in $(grep -oE '^\| H-[0-9]{2} \|' "$report" | tr -d '| ' | sort -u); do
  section=$(awk -v id="$id" '$0 ~ "^### "id" " {found=1; next} found && /^##/ {exit} found' "$report")
  if [[ -z "$section" ]]; then
    echo "❌ $id está en la tabla y no tiene sección ### $id"; fail=1
  elif ! grep -q '\*\*Estado\*\*' <<<"$section"; then
    echo "❌ la sección de $id no dice su **Estado**"; fail=1
  fi
done

for name in $(grep -oE '`(test|testFuzz|invariant|check)_[A-Za-z0-9_]+`' "$report" | tr -d '`' | sort -u); do
  grep -rqE "function $name\(" contracts/test || { echo "❌ el informe cita $name y no existe en contracts/test"; fail=1; }
done

snapshot=contracts/snapshots/RegisterGasTest.json
if [[ -f "$snapshot" ]]; then
  for gas in $(grep -oE '"[0-9]+"' "$snapshot" | tr -d '"'); do
    grep -q "\b$gas\b" "$report" || { echo "❌ el informe no cita el gas $gas de $snapshot"; fail=1; }
  done
else
  echo "❌ falta $snapshot: ejecuta forge test en contracts/"; fail=1
fi

cross=audit/auditoria-cruzada.md
if [[ -f "$cross" ]]; then
  for section in "Resumen" "Alcance" "Hallazgos"; do
    grep -q "^## $section" "$cross" || { echo "❌ falta la sección ## $section en $cross"; fail=1; }
  done
  grep -qE 'https://github\.com/[^ )]+' "$cross" || { echo "❌ $cross no dice qué repositorio audita"; fail=1; }
  grep -qE '\b[0-9a-f]{40}\b' "$cross" || { echo "❌ $cross no fija ningún commit (hash de 40 caracteres)"; fail=1; }
  for id in $(grep -oE '^\| C-[0-9]{2} \|' "$cross" | tr -d '| ' | sort -u); do
    section=$(awk -v id="$id" '$0 ~ "^### "id" " {found=1; next} found && /^##/ {exit} found' "$cross")
    if [[ -z "$section" ]]; then
      echo "❌ $id está en la tabla de $cross y no tiene sección ### $id"; fail=1
    else
      for field in Severidad "Prueba de concepto"; do
        grep -q "\*\*$field\*\*" <<<"$section" || { echo "❌ la sección de $id no dice su **$field**"; fail=1; }
      done
    fi
  done
else
  echo "❌ falta $cross: la auditoría que escribes del protocolo de tu pareja"; fail=1
fi

[[ $fail == 0 ]] && echo "✅ informe: secciones, commit, hallazgos, gas, auditoría cruzada y $(grep -oE '`(test|testFuzz|invariant|check)_[A-Za-z0-9_]+`' "$report" | sort -u | wc -l) pruebas citadas"
exit "$fail"
