#!/usr/bin/env bash
# ¿Qué? Escribe en src/registry-abi.ts la ABI de RegistryV2 que da el compilador.
# ¿Para qué? Que la página use la ABI exacta de tus contratos, con todas sus funciones,
#   eventos y errores (también los heredados de OpenZeppelin), sin copiarla a mano.
# ¿Impacto? `as const` deja los nombres y tipos como literales: así TypeScript sabe qué
#   devuelve cada función. Repítelo cada vez que cambie una firma en ../contracts.
# Uso: pnpm abi
set -euo pipefail
cd "$(dirname "$0")/.."
abi=$(forge inspect --root ../contracts RegistryV2 abi --json)
printf '// Generado por `pnpm abi` desde ../contracts (RegistryV2). No lo edites a mano.\nexport const registryAbi = %s as const;\n' "$abi" > src/registry-abi.ts
