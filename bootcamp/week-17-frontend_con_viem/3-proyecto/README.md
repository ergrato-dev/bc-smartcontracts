# Proyecto — La página del protocolo

> Tu protocolo tiene su primera página: muestra el estado del registro, tus recursos y tus
> puntos, da de alta y retira, explica cada error con su nombre de Solidity y sigue la
> actividad en vivo. En anvil lee y escribe; en Sepolia lee tu despliegue de la semana 16.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de esta semana; tu `week-16/` en `main`.

## Capa que se añade y por qué ahora

Hasta la semana 16, tu protocolo solo se usaba desde la terminal. Ahora que tiene una dirección
pública y verificada, le hace falta la otra mitad de una dApp: la página. Esta semana escribes
la capa que habla con la cadena, `web/src/protocol.ts`. La interfaz (`main.ts`) viene hecha: es
HTML y DOM, no blockchain, y solo pinta lo que devuelve `protocol.ts`.

En anvil, la página firma con una cuenta desbloqueada del nodo. En Sepolia no hay nodo que
firme por ti: la página solo lee. La semana 18 cambia esa cuenta por la wallet de quien usa la
página y rehace la interfaz con React.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-17
   ```

2. Copia el starter en `week-17/` y pon tus contratos de la semana 16 en `contracts/`:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-17-frontend_con_viem/3-proyecto/starter week-17
   cp -r week-16/src week-16/script week-17/contracts/
   ls -l week-17/contracts/lib
   ```

   **Verifica**: `lib -> /opt/lib`. `contracts/` es tu proyecto Foundry, sin los tests: siguen en
   `week-16/`.

3. Entra al contenedor publicando los puertos de anvil y de Vite, y genera la ABI desde tus
   contratos:

   ```bash
   cd week-17
   docker run --rm -it -p 8545:8545 -p 5173:5173 -v "$PWD":/workspace bc-smartcontracts-dev
   cd web && pnpm install --offline --frozen-lockfile && pnpm abi && cd ..
   ```

   `pnpm abi` reescribe `web/src/registry-abi.ts` con la ABI de tu `RegistryV2`. Los nombres de
   tu dominio son valores de constantes, no firmas: la ABI sale igual que la del starter. Si
   añadiste una función o un error propio, aparece aquí.

4. Mira el rojo:

   ```bash
   bash test.sh
   ```

**Verifica**: `ℹ pass 1` y `ℹ fail 8`. Pasa `createClients`, que viene resuelta (es el paso 5
del ejercicio 02); los otros ocho fallan con `TODO: <función>`. `Tipos y build:` termina sin
errores.

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/` | Tu proyecto Foundry de la semana 16: `src/`, `script/`, `foundry.toml` y `lib` |
| `web/src/protocol.ts` | **Tu trabajo**: ocho funciones con `// TODO:` y su pista |
| `web/src/main.ts` | La interfaz, hecha: llama a `protocol.ts` y pinta con `textContent` |
| `web/src/abi.ts`, `web/src/registry-abi.ts` | La ABI del token de fidelidad (legible) y la del registro (generada) |
| `web/test/protocol.test.ts` | 9 tests de `protocol.ts` contra el protocolo desplegado. **No lo modifiques** |
| `web/scripts/abi.sh` | Lo que ejecuta `pnpm abi` |
| `test.sh` | Despliega en un anvil propio (puerto 8546), ejecuta los tests, `tsc` y `vite build` |

## Requisitos

| # | Función | Qué hace |
| - | ------- | -------- |
| 1 | `readStatus` | Versión, capacidad, plazas libres, tasa y pausa, en paralelo |
| 2 | `pointsOf` | Lee la dirección del token del registro y, con ella, los puntos de la cuenta |
| 3 | `itemsOf` | Los recursos de la cuenta: `idsOf` y un `getItem` por id |
| 4 | `register` | Simula con la tasa como `value`, envía, espera y devuelve el id del `ItemRegistered` |
| 5 | `retire` | Simula, envía y devuelve el recibo |
| 6 | `errorName` | El nombre del custom error de un revert, o `undefined` |
| 7 | `activity` | Altas y bajas desde un bloque, convertidas con `toActivity` |
| 8 | `watchActivity` | Avisa de cada alta o baja nueva y devuelve `unwatch` |

`register` lee la tasa del contrato (`REGISTRATION_FEE`) en lugar de escribir `0.01` en la
página: si la tasa cambia en una versión futura, la página sigue funcionando.

## Cómo verificar

### Los tests

```bash
bash test.sh
```

**Verifica**: los nueve `✔`, `ℹ pass 9`, `ℹ fail 0` y `✔ tsc y vite build sin errores`.

### La página en anvil

Dentro del contenedor, desde `week-17/`. `ETHERSCAN_API_KEY` vacía porque `foundry.toml` la
nombra; aquí no se verifica nada:

```bash
anvil --silent &
export ETHERSCAN_API_KEY=
forge script --root contracts contracts/script/DeployProtocol.s.sol --rpc-url anvil --broadcast --slow \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
REGISTRY=$(jq -r '.transactions[] | select(.transactionType == "CREATE" and .contractName == "ERC1967Proxy") | .contractAddress' \
  contracts/broadcast/DeployProtocol.s.sol/31337/run-latest.json)
echo "$REGISTRY"
printf 'VITE_RPC_URL=http://127.0.0.1:8545\nVITE_REGISTRY=%s\nVITE_ACCOUNT=0x70997970C51812dc3A010C7d01b50e0d17dc79C8\n' \
  "$REGISTRY" > web/.env.local
cd web && pnpm dev
```

`echo` imprime `0xcf7ed3acca5a467e9e704c703e8d87f634fb0fc9`. El filtro de `jq` pide
`transactionType == "CREATE"` porque la llamada a `setHook` también va al proxy y también se
llama `ERC1967Proxy` en el registro.

Abre `http://localhost:5173` en tu navegador y comprueba, por orden:

1. **Estado**: `Versión 1 · 50 plazas libres de 50 · Tasa 0.01 ETH`.
2. **Alta**: escribe una etiqueta y pulsa *Dar de alta*. Sale `✅ Alta #1`, el recurso aparece
   en *Tus recursos* con 10 puntos, y *Actividad* muestra `Bloque 6: alta #1 …`.
3. **Error con nombre**: pulsa *Dar de alta* con la etiqueta vacía: `❌ InvalidLabel`, sin
   enviar nada.
4. **Retirar**: el recurso pasa a `Retirado` y *Actividad* muestra la baja.
5. **En vivo**: abre la página en otra pestaña y da un alta desde la terminal (en otra terminal
   del contenedor, `docker exec -it <contenedor> bash`):

   ```bash
   cast send "$REGISTRY" "register(string)" "Desde cast" --value 0.01ether \
     --from 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 --unlocked --rpc-url anvil
   ```

   Las dos pestañas muestran el alta en un segundo, sin recargar.
6. **V2**: actualiza el registro (semana 16) y recarga la página:

   ```bash
   REGISTRY="$REGISTRY" forge script --root contracts contracts/script/UpgradeToV2.s.sol --rpc-url anvil \
     --broadcast --slow --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
   ```

   El estado dice `Versión 2`. Con tres altas de la cuenta 1, la cuarta da `❌ TooManyItems`: el
   error de V2 llega con nombre porque la ABI es la de `RegistryV2`.

### La página en Sepolia, solo lectura

Tu registro de la semana 16 está en `week-16/broadcast/DeployProtocol.s.sol/11155111/run-latest.json`.
Saca el proxy y el bloque del despliegue con el mismo `jq` (y `.receipts[0].blockNumber`, en
hexadecimal: `cast to-dec` lo pasa a decimal) y escribe otro `web/.env.local`:

```bash
VITE_CHAIN=sepolia
VITE_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
VITE_REGISTRY=<tu proxy en Sepolia>
VITE_FROM_BLOCK=<bloque del despliegue, en decimal>
```

Reinicia `pnpm dev`. La página dice `Red: Sepolia`, muestra `Versión 2` y tu alta real de la
semana 16 en *Actividad*, y no ofrece formulario. Si *Actividad* se queda vacía y la consola del
navegador (F12) muestra `exceed maximum block range: 50000`, tu `VITE_FROM_BLOCK` está a más de
50 000 bloques de hoy: en ese caso deja la actividad en blanco y explícalo en el pull request.
Pedir por tramos es trabajo del indexador de la semana 19.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna:

| Dominio | Estado que muestra la cabecera | Un recurso en *Tus recursos* | Error que la página traduce |
| ------- | ------------------------------ | ---------------------------- | --------------------------- |
| Biblioteca | Carnés libres y cuota de alta | `#3 Ana Pérez — Activo` | `RegistryFull`: "No quedan carnés" |
| Tienda en línea | Plazas de vendedor libres | `#7 Cerámica Sur — Activo` | `WrongFee`: "La cuota de alta cambió; recarga" |
| Cine | Butacas libres y precio | `#12 Fila C, butaca 4 — Retirado` | `TooManyItems`: "Máximo 3 butacas por persona" |

## Criterios de calidad (no automatizables)

- La página usa los nombres de tu dominio: título, botones, estados y mensajes (en `main.ts` y
  en `index.html`). Los errores frecuentes salen con un texto para personas, no solo con el
  nombre de Solidity.
- Todo texto que viene de la cadena se pinta con `textContent`. Con una etiqueta
  `<b>hola</b>`, la página muestra los caracteres, no negrita.
- Ninguna clave en `web/`: `git grep -n "0xac0974\|PRIVATE" week-17/web` no encuentra nada.
- `web/.env.local`, `web/node_modules/` y `web/dist/` no están en el commit.
- Sabes explicar por qué en anvil la página escribe sin clave y en Sepolia no puede.
- Sabes explicar por qué `register` simula antes de enviar y de dónde sale el id que devuelve.
- Sin `TODO` restantes en `protocol.ts`.

## Entrega

```bash
git add week-17
git status --short week-17 | grep -E 'env\.local|node_modules|dist/' && echo "¡Para! Sobra algo en el commit"
git commit -m "feat(week-17): add the protocol web page with viem"
git push -u origin week-17
```

Abre un pull request `week-17` → `main` en tu repositorio. En la descripción pega la salida de
`bash test.sh` y dos capturas de la página: una en anvil después de un alta, una baja y un
`TooManyItems`, y otra leyendo tu registro de Sepolia.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Escuchar eventos](../2-practicas/ejercicio-03-escuchar-eventos/README.md) | **Proyecto — La página del protocolo** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
