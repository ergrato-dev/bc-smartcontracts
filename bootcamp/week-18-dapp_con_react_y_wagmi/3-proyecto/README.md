# Proyecto — La dApp del protocolo

> La página de tu protocolo pasa a React y wagmi, y firma con la wallet de quien la usa:
> conecta, avisa si la wallet está en otra red, da de alta y retira con cada estado de la
> transacción a la vista, explica los errores y sigue la actividad en vivo. En anvil y en
> Sepolia.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de esta semana; tu `week-17/` en `main`; una wallet de
pruebas en un perfil propio del navegador, con la red de anvil y la cuenta 1
([teoría 03](../1-teoria/03-conectar-la-wallet.md#preparar-una-wallet-para-anvil)).

## Capa que se añade y por qué ahora

En la semana 17, la página firmaba con una cuenta desbloqueada de anvil: en Sepolia solo podía
leer. Ahora firma la **wallet** de la persona, así que la misma página escribe en anvil y en
Sepolia sin que ninguna clave pase por tu código. Y con React y wagmi, la página se refresca sola
al confirmarse cada transacción y al cambiar la cuenta o la red en la wallet.

Como en la semana 17, escribes la capa que habla con la cadena, ahora como hooks:
`web/src/hooks.ts`. La interfaz (`App.tsx`) viene hecha y solo pinta lo que devuelven.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-18
   ```

2. Copia el starter en `week-18/` y pon tus contratos de la semana 17 en `contracts/`:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-18-dapp_con_react_y_wagmi/3-proyecto/starter week-18
   cp -r week-17/contracts/src week-17/contracts/script week-18/contracts/
   ls -l week-18/contracts/lib
   ```

   **Verifica**: `lib -> /opt/lib`.

3. Entra al contenedor publicando los puertos de anvil y de Vite, y genera la ABI:

   ```bash
   cd week-18
   docker run --rm -it -p 8545:8545 -p 5173:5173 -v "$PWD":/workspace bc-smartcontracts-dev
   cd web && pnpm install --offline --frozen-lockfile && pnpm abi && cd ..
   ```

4. Mira el rojo:

   ```bash
   bash test.sh
   ```

**Verifica**: `ℹ pass 0` y `ℹ fail 9`, cada uno con `TODO: <hook>`, y
`✔ tsc y vite build sin errores`.

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/` | Tu proyecto Foundry: `src/`, `script/`, `foundry.toml` y `lib` |
| `web/src/hooks.ts` | **Tu trabajo**: nueve funciones con `// TODO:` y su pista. Arriba, los tipos, `toActivity` y `txStatus`, hechos |
| `web/src/App.tsx` | La interfaz, hecha: un componente por sección |
| `web/src/main.tsx` | La configuración de wagmi (`injected()`, la red de `VITE_CHAIN`) y los proveedores |
| `web/src/abi.ts`, `web/src/registry-abi.ts` | Las ABI, como en la semana 17 |
| `web/vite.config.ts` | Vite con el plugin de React |
| `web/test/render.ts` | Monta tus hooks con una wallet `mock` sobre happy-dom. **No lo modifiques** |
| `web/test/hooks.test.ts` | 9 tests de `hooks.ts` contra el protocolo desplegado. **No lo modifiques** |
| `test.sh` | Despliega en un anvil propio (puerto 8546), ejecuta los tests, `tsc` y `vite build` |

## Requisitos

| # | Función | Qué hace |
| - | ------- | -------- |
| 1 | `useWallet` | Cuenta conectada, `wrongChain` y cómo conectar, desconectar y volver a la red de la página |
| 2 | `useStatus` | Versión, capacidad, plazas libres, tasa y pausa, en una llamada |
| 3 | `usePoints` | La dirección del token del registro y, con ella, los puntos de la cuenta conectada |
| 4 | `useItems` | `idsOf` de la cuenta conectada y un `getItem` por id |
| 5 | `errorText` | Firma cancelada, nombre del custom error o resumen de viem |
| 6 | `useTransaction` | Simula, pide la firma, espera el recibo, da el estado e invalida la caché |
| 7 | `useRegister` | Lee la tasa del contrato, da de alta con `useTransaction` y saca el id del evento |
| 8 | `useRetire` | Retira con `useTransaction` |
| 9 | `useActivity` | Altas y bajas desde un bloque; cada evento nuevo vuelve a pedir la lista |

Toda simulación lleva el `chainId` de la red de la página: con la wallet en otra red, `mutate`
se niega a firmar (teoría 03).

## Cómo verificar

### Los tests

```bash
bash test.sh
```

**Verifica**: los nueve `✔`, `ℹ pass 9`, `ℹ fail 0` y `✔ tsc y vite build sin errores`.

### La página en anvil

Dentro del contenedor, desde `week-18/`:

```bash
anvil --silent &
export ETHERSCAN_API_KEY=
forge script --root contracts contracts/script/DeployProtocol.s.sol --rpc-url anvil --broadcast --slow \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
REGISTRY=$(jq -r '.transactions[] | select(.transactionType == "CREATE" and .contractName == "ERC1967Proxy") | .contractAddress' \
  contracts/broadcast/DeployProtocol.s.sol/31337/run-latest.json)
printf 'VITE_RPC_URL=http://127.0.0.1:8545\nVITE_REGISTRY=%s\n' "$REGISTRY" > web/.env.local
cd web && pnpm dev
```

Ya no hay `VITE_ACCOUNT`: la cuenta la pone la wallet. Si reiniciaste anvil desde la última vez,
borra los datos de actividad de la cuenta en tu wallet (teoría 03, trucos).

Abre `http://localhost:5173` en el perfil del navegador que tiene la wallet de pruebas y
comprueba, por orden:

1. **Sin conectar**: el estado se lee igual (`Versión 1 · 50 plazas libres de 50 · Tasa 0.01
   ETH`) y hay un botón *Conectar* por cada wallet.
2. **Conectar**: la wallet pregunta; al aceptar, `Cuenta: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8`
   y aparecen *Alta* y *Tus recursos*.
3. **Alta**: escribe una etiqueta y pulsa *Dar de alta*. La página dice `Firma en tu wallet…` y la
   wallet enseña la llamada al registro con un valor de 0.01 ETH. Firma: `✅ Confirmada Alta #1`,
   el recurso en *Tus recursos* con 10 puntos y en *Actividad* `Bloque 6: alta #1 …`.
4. **Rechazar**: da otra alta y pulsa *Rechazar* en la wallet:
   `❌ Cancelaste la firma en la wallet`.
5. **Error con nombre**: *Dar de alta* con la etiqueta vacía: `❌ InvalidLabel`, sin que se abra
   la wallet.
6. **Retirar**: el recurso pasa a `Retirado` y *Actividad* muestra la baja.
7. **Otra red**: cambia la wallet a cualquier otra red. *Alta* y *Tus recursos* desaparecen y sale
   `⚠️ Tu wallet está en otra red` con el botón *Cambiar a Foundry*. Púlsalo y la wallet vuelve a
   anvil.
8. **En vivo**: desde otra terminal del contenedor (`docker exec -it <contenedor> bash`), la
   cuenta 2 da un alta:

   ```bash
   cast send "$REGISTRY" "register(string)" "Desde cast" --value 0.01ether \
     --from 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC --unlocked --rpc-url anvil
   ```

   *Actividad* la muestra en un segundo, sin recargar.
9. **V2**: actualiza el registro (semana 16) y recarga la página:

   ```bash
   REGISTRY="$REGISTRY" forge script --root contracts contracts/script/UpgradeToV2.s.sol --rpc-url anvil \
     --broadcast --slow --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
   ```

   El estado dice `Versión 2`. Con tres recursos activos de tu cuenta, la cuarta alta da
   `❌ TooManyItems` sin abrir la wallet.

### La página en Sepolia

Tu registro de la semana 16 está en `week-16/broadcast/DeployProtocol.s.sol/11155111/run-latest.json`.
Saca el proxy y el bloque del despliegue como en la semana 17 y escribe otro `web/.env.local`:

```bash
VITE_CHAIN=sepolia
VITE_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
VITE_REGISTRY=<tu proxy en Sepolia>
VITE_FROM_BLOCK=<bloque del despliegue, en decimal>
```

Reinicia `pnpm dev`. Ahora la página también escribe en Sepolia, con la cuenta de pruebas con la
que desplegaste en la semana 16 (impórtala en la wallet del perfil de pruebas; nunca una cuenta
con fondos de mainnet). Comprueba:

1. `Red: Sepolia`, `Versión 2` y tu alta de la semana 16 en *Actividad*.
2. Con la wallet en anvil, la página avisa de la red y *Cambiar a Sepolia* la cambia.
3. Un alta real: `Firma en tu wallet…`, después `Esperando el bloque…` unos segundos (ahora sí se
   ve) y `✅ Confirmada`. Paga 0.01 ETH de Sepolia más el gas.

Si *Actividad* se queda vacía y la consola del navegador (F12) muestra
`exceed maximum block range: 50000`, tu `VITE_FROM_BLOCK` está a más de 50 000 bloques de hoy:
como en la semana 17, déjalo anotado en el pull request.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna:

| Dominio | Texto del botón | Mensaje mientras firma | Error que la página traduce |
| ------- | --------------- | ---------------------- | --------------------------- |
| Biblioteca | *Sacar carné* | "Confirma la cuota en tu wallet…" | `RegistryFull`: "No quedan carnés" |
| Tienda en línea | *Darme de alta como vendedor* | "Firma el alta en tu wallet…" | `WrongFee`: "La cuota cambió; recarga" |
| Cine | *Reservar butaca* | "Confirma la reserva en tu wallet…" | `TooManyItems`: "Máximo 3 butacas por persona" |

## Criterios de calidad (no automatizables)

- Los textos de tu dominio de la semana 17 (título, botones, estados, errores) están en
  `App.tsx`, `TX_TEXT` incluido. Los errores frecuentes salen con un texto para personas.
- Ningún texto de la cadena pasa por `dangerouslySetInnerHTML`: con la etiqueta `<b>hola</b>`, la
  página muestra los caracteres.
- El botón de alta y el de retirar están desactivados mientras una transacción firma o confirma.
- Ninguna clave en `week-18/web`: `git grep -n "0xac0974\|0x59c699\|PRIVATE" week-18/web` no
  encuentra nada.
- `web/.env.local`, `web/node_modules/` y `web/dist/` no están en el commit.
- Sabes explicar por qué la página ya no necesita `VITE_ACCOUNT` y qué hace la wallet que antes
  hacía anvil.
- Sabes explicar qué pasaría sin `chainId` en la simulación con la wallet en otra red.
- Sin `TODO` restantes en `hooks.ts`.

## Entrega

```bash
git add week-18
git status --short week-18 | grep -E 'env\.local|node_modules|dist/' && echo "¡Para! Sobra algo en el commit"
git commit -m "feat(week-18): add the protocol dApp with React and wagmi"
git push -u origin week-18
```

Abre un pull request `week-18` → `main` en tu repositorio. En la descripción pega la salida de
`bash test.sh` y tres capturas: la página en anvil con un alta confirmada y un `TooManyItems`, el
aviso de otra red y un alta confirmada en Sepolia.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Hooks de React](../2-practicas/ejercicio-03-hooks-de-react/README.md) | **Proyecto — La dApp del protocolo** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
