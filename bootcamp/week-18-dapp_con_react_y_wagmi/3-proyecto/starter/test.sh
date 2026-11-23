#!/usr/bin/env bash
# ¿Qué? Tests del proyecto: despliega el protocolo de ../contracts en un anvil propio,
#   ejecuta los tests de web/test, revisa los tipos y construye la página con Vite.
# ¿Para qué? Comprobar con un comando que la capa de la página habla bien con tus contratos.
# Uso: bash test.sh   (termina con código 0 solo si todo pasa)
cd "$(dirname "$0")" || exit 1

(cd web && pnpm install --offline --frozen-lockfile >/dev/null) || exit 1

# ¿Qué? Un anvil propio en el puerto 8546, recién creado: el protocolo siempre en las
#   mismas direcciones y sin altas, sin tocar el anvil que tengas abierto en el 8545.
export RPC_URL=http://127.0.0.1:8546
anvil --port 8546 --silent & ANVIL_PID=$!
trap 'kill "$ANVIL_PID" 2>/dev/null; wait "$ANVIL_PID" 2>/dev/null' EXIT
for _ in $(seq 100); do cast chain-id --rpc-url "$RPC_URL" >/dev/null 2>&1 && break; sleep 0.05; done

# ¿Qué? Despliega con la cuenta 0 de anvil, cuya clave es pública. `ETHERSCAN_API_KEY`
#   vacía porque foundry.toml la nombra; aquí no se verifica nada.
ETHERSCAN_API_KEY="" forge script --root contracts contracts/script/DeployProtocol.s.sol --rpc-url "$RPC_URL" \
  --broadcast --slow --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 >/dev/null || exit 1
REGISTRY=$(jq -r '.transactions[] | select(.transactionType == "CREATE" and .contractName == "ERC1967Proxy") | .contractAddress' \
  contracts/broadcast/DeployProtocol.s.sol/31337/run-latest.json)
export REGISTRY

cd web || exit 1
node --test --test-concurrency=1 --test-reporter=spec "test/*.test.ts"; tests=$?

# ¿Qué? `pnpm build` revisa los tipos con tsc y construye la página en dist/.
# ¿Impacto? Un error de tipos en App.tsx, main.tsx o hooks.ts hace fallar el proyecto.
echo "Tipos y build:"
pnpm build >/dev/null && echo "✔ tsc y vite build sin errores" || { pnpm exec tsc; tests=1; }
exit "$tests"
