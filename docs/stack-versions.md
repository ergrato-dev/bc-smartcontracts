# 📌 Versiones del stack

Toda herramienta y dependencia se fija a una **versión exacta**. Nunca `latest`, nunca
rangos (`^0.8.0`), nunca ramas. Una versión flotante cambia sin avisar y rompe un
starter que compilaba ayer; en un contrato, además, cambia el bytecode que se despliega.

## Toolchain

| Herramienta | Versión | Dónde se fija | Por qué esta |
| ----------- | ------- | ------------- | ------------ |
| Imagen base | `ubuntu:24.04` | `docker/Dockerfile` | LTS con soporte hasta 2029 |
| Foundry (forge, cast, anvil, chisel) | `v1.9.0` | `ARG FOUNDRY_VERSION` | Última estable con más de dos semanas publicada |
| Solidity (solc) | `0.8.38` | `ARG SOLC_VERSION`, `solc_version` en `foundry.toml` y `pragma solidity 0.8.38;` | Última estable con más de dos semanas publicada |
| forge-std | `v1.17.0` | `ARG FORGE_STD_VERSION` (en `/opt/lib` de la imagen) | Alineada con Foundry 1.9 |
| Node.js | `v24.22.2` | `ARG NODE_VERSION` | LTS 24, anterior a la última (24.22.3, parche de seguridad del 2026-11-10); subir cuando salga la siguiente |
| pnpm | `11.28.12` | `ARG PNPM_VERSION` y `packageManager` en `docker/web/package.json` | Rama 11 estable con más de una semana publicada; la instala `corepack` |
| Python | `3.12` (paquete de Ubuntu 24.04) | `apt-get install python3` en el `Dockerfile` y `requires-python` en `docker/py/pyproject.toml` | El Python de la imagen base; Ubuntu publica sus parches de seguridad dentro de la 3.12 |
| uv | `0.13.8` | `ARG UV_VERSION` | Con más de una semana publicada y anterior a la última (0.13.9) |
| PostgreSQL | `16` (paquete de Ubuntu 24.04) | `apt-get install postgresql-16` en el `Dockerfile` | La versión mayor de Ubuntu 24.04; Ubuntu publica sus parches de seguridad dentro de la 16 |
| OpenZeppelin Contracts | `v5.7.0` | `ARG OZ_VERSION` (en `/opt/lib` de la imagen) y remapping `@openzeppelin/contracts/` | Última estable con más de dos semanas publicada; sin avisos de seguridad abiertos |
| Chainlink Contracts | `1.4.0` (paquete de npm `@chainlink/contracts`) | `ARG CHAINLINK_VERSION` y `ARG CHAINLINK_SHA512` (solo `src/`, en `/opt/lib/chainlink-contracts`) | Anterior a la última estable (1.5.0); trae `AggregatorV3Interface`, VRF v2.5 y sus mocks. Se instala sin pnpm, verificado con el sha512 de npm |
| kubo (`ipfs`) | `v0.43.0` | `ARG KUBO_VERSION` | Anterior a la última (v0.43.1); verificado con su sha512 |

## Dependencias por semana

Cada dependencia se añade a esta tabla **en la semana que la introduce**, con la versión
verificada ese día. Hasta entonces no se fija nada.

| Biblioteca | Versión | Desde la semana | Uso |
| ---------- | ------- | --------------- | --- |
| OpenZeppelin Contracts | `v5.7.0` | 11 | `ERC20`, `ERC20Burnable`, `ERC20Capped`, `SafeERC20`; en la imagen, no en cada proyecto |
| OpenZeppelin Contracts Upgradeable | `v5.7.0` | 15 | `Initializable`, `UUPSUpgradeable` y las bases `*Upgradeable`; en la imagen (`ARG OZ_VERSION`, la misma que Contracts) y remapping `@openzeppelin/contracts-upgradeable/` |
| viem | `2.57.20` | 17 | Clientes, lecturas, escrituras y eventos desde TypeScript |
| TypeScript | `6.0.3` | 17 | `tsc` revisa tipos; no la 7.0.2, que es la última publicada |
| Vite | `8.3.7` | 17 | Servidor de desarrollo y `vite build` de la página |
| @types/node | `24.19.2` | 17 | Tipos de `node:test` y `process` para `tsc` |
| React y React DOM | `19.3.0` | 18 | Componentes de la página; no la 19.3.1, la última, que solo cambia React Server Components |
| wagmi | `3.7.10` | 18 | Hooks de React sobre viem: wallet, lecturas en caché y escrituras |
| @wagmi/core | `3.6.8` | 18 | Las acciones de wagmi sin React (ejercicios 01 y 02); la versión que pide wagmi 3.7.10 |
| @tanstack/react-query | `5.107.1` | 18 | La caché de consultas que usa wagmi |
| @vitejs/plugin-react | `6.2.1` | 18 | JSX y recarga en caliente en Vite |
| @types/react, @types/react-dom | `19.2.18`, `19.2.7` | 18 | Tipos de React para `tsc` |
| @testing-library/react, @testing-library/dom | `16.3.2`, `10.4.1` | 18 | `renderHook` y `waitFor` para probar hooks |
| happy-dom, @happy-dom/global-registrator | `21.0.3` | 18 | DOM falso en Node para los tests de hooks |

| FastAPI | `0.163.1` | 19 | Rutas, validación y modelos de la API del indexador; no la 0.165.0, la última |
| uvicorn | `0.53.0` | 19 | Servidor de la API; no la 0.54.0, la última |
| psycopg (`binary`) | `3.3.8` | 19 | Conector de PostgreSQL; no la 3.3.9, la última |
| httpx2 | `2.16.0` | 19 | Cliente HTTP para JSON-RPC y para el `TestClient` de FastAPI, que avisa de que `httpx` queda obsoleto; no la 2.16.2, la última |
| pytest | `9.1.1` | 19 | Tests de los starters de Python; no la 9.2.0, la última |
| Chainlink Contracts | `1.4.0` | 20 | `AggregatorV3Interface`, `MockV3Aggregator`, `VRFConsumerBaseV2Plus` y `VRFCoordinatorV2_5Mock`; en la imagen, con el remapping `@chainlink/contracts/` |

Las de TypeScript están en `docker/web/package.json` y su `pnpm-lock.yaml`, que fija también las
dependencias indirectas. La imagen descarga ese lockfile (`pnpm fetch`) y **todos** los starters
de TypeScript llevan una copia exacta del lockfile y de las dependencias, de cualquier semana.
pnpm verifica cada lockfile contra su política de cadena de suministro antes de instalar, y sin
red solo pasa el que la imagen verificó al construirse: un lockfile distinto falla con
`ERR_PNPM_NO_OFFLINE_META`. Al cambiar `docker/web/`, se copian los dos archivos a todos los
starters (en los proyectos, solo `dependencies` y `devDependencies` del `package.json`).

Las de Python están en `docker/py/pyproject.toml` y su `uv.lock`, que fija las indirectas.
`exclude-newer` impide a uv elegir versiones con menos de una semana, también las indirectas: al
cambiar una dependencia se mueve esa fecha a hace una semana y se ejecuta `uv lock`. La imagen
descarga el lockfile en la caché de uv (`uv sync --frozen`) y cada starter de Python lleva una
copia exacta de los dos archivos: `test.sh` instala con `uv sync --offline --frozen`.

## Política

1. **Cómo se elige una versión**: la última estable publicada hace al menos dos semanas
   (deja tiempo a que salgan los parches urgentes). Se consulta el release oficial en
   GitHub, nunca un blog.
2. **Cómo se cambia**: en un solo commit `chore(deps): ...` que actualiza esta tabla,
   el `Dockerfile`, la plantilla `docs/plantillas/starter-foundry/` y **todos** los
   starters, y que pasa `./scripts/compilar-starters.sh` en cada semana publicada.
3. **Seguridad**: antes de fijar una versión se revisan sus avisos de seguridad (GitHub
   Security Advisories y la [lista de bugs de solc](https://docs.soliditylang.org/en/latest/bugs.html)).
   Con un fallo abierto que afecte al bootcamp no se fija.
