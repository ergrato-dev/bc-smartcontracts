#!/usr/bin/env bash
# ¿Qué? Tests del proyecto: despliega el protocolo de contracts/ en un anvil propio, arranca un
#   PostgreSQL vacío y ejecuta los tests de indexer/tests con pytest.
# ¿Para qué? Comprobar con un comando que el indexador sigue bien a tus contratos, reorgs
#   incluidos.
# Uso: bash test.sh   (termina con código 0 solo si todo pasa)
cd "$(dirname "$0")" || exit 1

(cd indexer && uv sync --offline --frozen --quiet) || exit 1

# ¿Qué? Un anvil propio en el puerto 8546, recién creado: el protocolo siempre en las
#   mismas direcciones y sin altas, sin tocar el anvil que tengas abierto en el 8545.
export RPC_URL=http://127.0.0.1:8546
anvil --port 8546 --silent & ANVIL_PID=$!

# ¿Qué? Un PostgreSQL vacío en una carpeta temporal del contenedor, solo por el socket de /tmp.
export PGDATA=$(mktemp -d)
initdb --auth=trust --username=postgres >/dev/null || exit 1
pg_ctl --options "-k /tmp -c listen_addresses=''" --log "$PGDATA/log" --wait start >/dev/null || exit 1
export DATABASE_URL="host=/tmp user=postgres dbname=postgres"
trap 'pg_ctl --mode fast stop >/dev/null; kill "$ANVIL_PID" 2>/dev/null; wait "$ANVIL_PID" 2>/dev/null' EXIT
for _ in $(seq 100); do cast chain-id --rpc-url "$RPC_URL" >/dev/null 2>&1 && break; sleep 0.05; done

# ¿Qué? Despliega con la cuenta 0 de anvil, cuya clave es pública. `ETHERSCAN_API_KEY`
#   vacía porque foundry.toml la nombra; aquí no se verifica nada.
ETHERSCAN_API_KEY="" forge script --root contracts contracts/script/DeployProtocol.s.sol --rpc-url "$RPC_URL" \
  --broadcast --slow --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 >/dev/null || exit 1
# ¿Qué? Los eventos salen del proxy: es la dirección que se indexa, la misma tras un upgrade.
REGISTRY=$(jq -r '.transactions[] | select(.transactionType == "CREATE" and .contractName == "ERC1967Proxy") | .contractAddress' \
  contracts/broadcast/DeployProtocol.s.sol/31337/run-latest.json)
export REGISTRY

cd indexer && uv run --offline --frozen pytest -v --no-header
