#!/usr/bin/env bash
# ¿Qué? Tests del ejercicio: instala las dependencias de Python, despliega el Token en un anvil
#   propio y ejecuta los tests de `tests/` con pytest.
# ¿Para qué? Saber qué pasos están bien con un solo comando, siempre sobre la misma cadena.
# Uso: bash test.sh   (termina con código 0 solo si todo pasa)
cd "$(dirname "$0")" || exit 1

# ¿Qué? Dependencias desde la caché de uv de la imagen, exactamente las de uv.lock.
uv sync --offline --frozen --quiet || exit 1

# ¿Qué? Un anvil propio en el puerto 8546, recién creado: el Token en la misma dirección y sus
#   tres eventos `Transfer` en los bloques 1, 2 y 3, sin tocar el anvil de tu puerto 8545.
export RPC_URL=http://127.0.0.1:8546
anvil --port 8546 --silent & ANVIL_PID=$!
trap 'kill "$ANVIL_PID" 2>/dev/null; wait "$ANVIL_PID" 2>/dev/null' EXIT
for _ in $(seq 100); do cast chain-id --rpc-url "$RPC_URL" >/dev/null 2>&1 && break; sleep 0.05; done

# ¿Qué? Despliega con la cuenta 0 de anvil, cuya clave es pública.
forge script --root contrato contrato/script/DeployToken.s.sol --rpc-url "$RPC_URL" --broadcast --slow \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 >/dev/null || exit 1
TOKEN=$(jq -r '.transactions[0].contractAddress' contrato/broadcast/DeployToken.s.sol/31337/run-latest.json)
export TOKEN

uv run --offline --frozen pytest -v --no-header
