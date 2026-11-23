#!/usr/bin/env bash
# ¿Qué? Tests del ejercicio: instala las dependencias, comprueba los tipos, despliega el
#   Token en un anvil propio y ejecuta los tests de `test/` con el runner de Node.
# ¿Para qué? Saber qué pasos están bien con un solo comando, siempre sobre la misma cadena.
# Uso: bash test.sh   (termina con código 0 solo si todo pasa)
cd "$(dirname "$0")" || exit 1

# ¿Qué? Dependencias desde el almacén de la imagen, exactamente las del pnpm-lock.yaml.
pnpm install --offline --frozen-lockfile >/dev/null || exit 1

# ¿Qué? Un anvil propio en el puerto 8546, recién creado.
# ¿Para qué? Que los tests empiecen siempre en el bloque 3 con los mismos saldos, sin tocar
#   el anvil que tengas abierto en el 8545.
export RPC_URL=http://127.0.0.1:8546
anvil --port 8546 --silent & ANVIL_PID=$!
trap 'kill "$ANVIL_PID" 2>/dev/null; wait "$ANVIL_PID" 2>/dev/null' EXIT
for _ in $(seq 100); do cast chain-id --rpc-url "$RPC_URL" >/dev/null 2>&1 && break; sleep 0.05; done

# ¿Qué? Despliega con la cuenta 0 de anvil, cuya clave es pública. Con `--slow`, cada
#   transacción espera a la anterior y va en su propio bloque: 1, 2 y 3.
forge script --root contrato contrato/script/DeployToken.s.sol --rpc-url "$RPC_URL" --broadcast --slow \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 >/dev/null || exit 1
TOKEN=$(jq -r '.transactions[0].contractAddress' contrato/broadcast/DeployToken.s.sol/31337/run-latest.json)
export TOKEN

# ¿Qué? Un archivo de tests detrás de otro: todos usan la misma cadena.
node --test --test-concurrency=1 --test-reporter=spec "test/*.test.ts"; tests=$?

# ¿Qué? TypeScript revisa los tipos de `src/` y `test/`. Node solo quita los tipos al
#   ejecutar: sin este paso, un error de tipos no se vería.
# ¿Impacto? Mientras un paso devuelve solo el `throw`, su tipo es `never` o `void` y los
#   tests que usan su resultado dan error de tipos: desaparece al resolver el paso.
echo "Tipos:"
pnpm exec tsc && echo "✔ sin errores de tipos" || tests=1
exit "$tests"
