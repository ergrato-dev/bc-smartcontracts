#!/usr/bin/env bash
# ¿Qué? Tests del ejercicio: instala las dependencias, ejecuta los tests de `test/` con el
#   runner de Node y comprueba los tipos.
# ¿Para qué? Saber qué pasos están bien con un solo comando.
# Uso: bash test.sh   (termina con código 0 solo si todo pasa)
cd "$(dirname "$0")" || exit 1

# ¿Qué? Dependencias desde el almacén de la imagen, exactamente las del pnpm-lock.yaml.
pnpm install --offline --frozen-lockfile >/dev/null || exit 1

# ¿Qué? La dirección del nodo para la red de anvil de la configuración.
# ¿Impacto? Conectar y cambiar de red no llegan al nodo: este ejercicio no arranca anvil.
export RPC_URL=http://127.0.0.1:8546

node --test --test-concurrency=1 --test-reporter=spec "test/*.test.ts"; tests=$?

# ¿Qué? TypeScript revisa los tipos de `src/` y `test/`. Node solo quita los tipos al
#   ejecutar: sin este paso, un error de tipos no se vería.
echo "Tipos:"
pnpm exec tsc && echo "✔ sin errores de tipos" || tests=1
exit "$tests"
