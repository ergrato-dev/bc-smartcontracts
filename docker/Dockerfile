# ¿Qué? Imagen de desarrollo del bootcamp: Ubuntu 24.04 + Foundry (forge, cast, anvil, chisel) + solc.
# ¿Para qué? Que todos los aprendices compilen, prueben y desplieguen con las mismas versiones,
#            sin instalar nada en su máquina.
# ¿Impacto? Si un ejercicio pasa aquí, pasa en la corrección. Las herramientas que llegan
#           más adelante (Node y pnpm, uv y PostgreSQL, Slither, Medusa) se añaden en la semana que las introduce.
FROM ubuntu:24.04

ARG FOUNDRY_VERSION=v1.9.0
ARG SOLC_VERSION=0.8.38
ARG FORGE_STD_VERSION=v1.17.0
ARG OZ_VERSION=v5.7.0
ARG NODE_VERSION=v24.22.2
ARG PNPM_VERSION=11.28.12
ARG UV_VERSION=0.13.8
ARG CHAINLINK_VERSION=1.4.0
ARG CHAINLINK_SHA512=4a93422744cf388ea96b697bd365a4e1620ff1c730e4045c44fd44fd94ea6857df5cda19785d375a1b152fc7f797739344503d678d0ee4a719ce626665092814
ARG KUBO_VERSION=v0.43.0
ARG SLITHER_VERSION=0.11.5
ARG CRYTIC_COMPILE_VERSION=0.3.11
ARG PYTEST_VERSION=9.1.1
ARG SLITHER_EXCLUDE_NEWER=2026-11-16T00:00:00Z
ARG MEDUSA_VERSION=v1.5.0
ARG MEDUSA_SHA256=c5c333d4380d150f76bd7e796a0d2ce62e85713d335c3ddd53718ac202eec8ef
# ¿Qué? Arquitectura que Docker inyecta al construir (amd64 o arm64).
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git jq \
    && rm -rf /var/lib/apt/lists/*

# ¿Qué? Binarios oficiales de Foundry desde su release de GitHub, verificados con su sha256.
# ¿Para qué? Fijar la versión exacta; `foundryup` sin versión instalaría la última.
RUN arch="${TARGETARCH:-amd64}" \
    && base="https://github.com/foundry-rs/foundry/releases/download/${FOUNDRY_VERSION}" \
    && file="foundry_${FOUNDRY_VERSION}_linux_${arch}.tar.gz" \
    && curl -fsSL -o "/tmp/${file}" "${base}/${file}" \
    && curl -fsSL "${base}/foundry_${FOUNDRY_VERSION}_linux_${arch}.sha256" -o /tmp/foundry.sha256 \
    && (cd /tmp && grep "${file}" foundry.sha256 | sha256sum -c -) \
    && tar -xzf "/tmp/${file}" -C /usr/local/bin \
    && rm /tmp/foundry*

# ¿Qué? forge-std (biblioteca de tests de Foundry) en /opt/lib, compartida por todos los starters.
# ¿Para qué? Los starters no copian la biblioteca ni dependen de submódulos de git:
#            su foundry.toml la busca aquí con `libs = ["/opt/lib"]`.
# ¿Impacto? Los proyectos de los starters solo compilan dentro del contenedor.
RUN git clone -q --depth 1 --branch "${FORGE_STD_VERSION}" \
        https://github.com/foundry-rs/forge-std /opt/lib/forge-std \
    && rm -rf /opt/lib/forge-std/.git

# ¿Qué? OpenZeppelin Contracts (contratos estándar auditados) en /opt/lib, desde la semana 11.
# ¿Para qué? Lo mismo que forge-std: los starters lo importan como `@openzeppelin/contracts/...`
#            con un remapping, sin `forge install` ni submódulos en cada carpeta.
RUN git clone -q --depth 1 --branch "${OZ_VERSION}" \
        https://github.com/OpenZeppelin/openzeppelin-contracts /opt/lib/openzeppelin-contracts \
    && rm -rf /opt/lib/openzeppelin-contracts/.git

# ¿Qué? OpenZeppelin Contracts Upgradeable, la misma versión, desde la semana 15.
# ¿Para qué? Las versiones con `initialize` en vez de constructor, para contratos detrás de un proxy.
# ¿Impacto? Importa `@openzeppelin/contracts/...` para las interfaces: tiene que ser la misma versión.
RUN git clone -q --depth 1 --branch "${OZ_VERSION}" \
        https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable /opt/lib/openzeppelin-contracts-upgradeable \
    && rm -rf /opt/lib/openzeppelin-contracts-upgradeable/.git

# ¿Qué? Node.js oficial desde nodejs.org, verificado con su sha256, desde la semana 17.
# ¿Para qué? Ejecutar TypeScript (Node 24 quita los tipos al cargar un `.ts`) y viem.
# ¿Impacto? `corepack` (incluido en Node 24) instala pnpm a la versión fija del `packageManager`.
RUN arch="$([ "${TARGETARCH:-amd64}" = arm64 ] && echo arm64 || echo x64)" \
    && file="node-${NODE_VERSION}-linux-${arch}.tar.xz" \
    && curl -fsSL -o "/tmp/${file}" "https://nodejs.org/dist/${NODE_VERSION}/${file}" \
    && curl -fsSL "https://nodejs.org/dist/${NODE_VERSION}/SHASUMS256.txt" -o /tmp/node.sha256 \
    && (cd /tmp && grep " ${file}$" node.sha256 | sha256sum -c -) \
    && apt-get update && apt-get install -y --no-install-recommends xz-utils && rm -rf /var/lib/apt/lists/* \
    && tar -xJf "/tmp/${file}" -C /usr/local --strip-components=1 --exclude CHANGELOG.md --exclude README.md --exclude LICENSE \
    && rm /tmp/node* \
    && corepack enable pnpm

# ¿Qué? Python 3.12 y PostgreSQL 16 de Ubuntu 24.04, y uv desde su release de GitHub, verificado
#   con su sha256, desde la semana 19.
# ¿Para qué? El indexador: FastAPI y psycopg corren sobre ese Python, y cada test arranca su propio
#   PostgreSQL con `initdb`. Sin servicio de sistema: no arranca nada al abrir el contenedor.
# ¿Impacto? Ubuntu publica las correcciones de seguridad de los dos paquetes dentro de la misma
#   versión mayor; uv no descarga otro Python (`UV_PYTHON_DOWNLOADS=never`).
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 postgresql-16 \
    && rm -rf /var/lib/apt/lists/* \
    && arch="$([ "${TARGETARCH:-amd64}" = arm64 ] && echo aarch64 || echo x86_64)" \
    && file="uv-${arch}-unknown-linux-gnu.tar.gz" \
    && base="https://github.com/astral-sh/uv/releases/download/${UV_VERSION}" \
    && curl -fsSL -o "/tmp/${file}" "${base}/${file}" \
    && curl -fsSL -o /tmp/uv.sha256 "${base}/${file}.sha256" \
    && (cd /tmp && sha256sum -c uv.sha256) \
    && tar -xzf "/tmp/${file}" -C /usr/local/bin --strip-components=1 \
    && rm /tmp/uv*
ENV PATH="/usr/lib/postgresql/16/bin:${PATH}" \
    UV_PYTHON_DOWNLOADS=never \
    UV_LINK_MODE=copy \
    PYTHONDONTWRITEBYTECODE=1

# ¿Qué? Los contratos de Chainlink (interfaces de price feeds, VRF y sus mocks) en /opt/lib, desde
#   la semana 20. Del paquete de npm `@chainlink/contracts`, verificado con su sha512.
# ¿Para qué? Lo mismo que OpenZeppelin: los starters los importan como
#   `@chainlink/contracts/src/v0.8/...`, la ruta de la documentación de Chainlink, sin pnpm ni red.
# ¿Impacto? Solo se copia `src/`: el paquete trae además ABIs y dependencias de npm que Solidity no usa.
RUN curl -fsSL -o /tmp/chainlink.tgz \
        "https://registry.npmjs.org/@chainlink/contracts/-/contracts-${CHAINLINK_VERSION}.tgz" \
    && echo "${CHAINLINK_SHA512}  /tmp/chainlink.tgz" | sha512sum -c - \
    && mkdir -p /opt/lib/chainlink-contracts \
    && tar -xzf /tmp/chainlink.tgz -C /opt/lib/chainlink-contracts --strip-components=1 package/src \
    && rm /tmp/chainlink.tgz

# ¿Qué? kubo, el nodo de IPFS de referencia (comando `ipfs`), desde su release de GitHub,
#   verificado con su sha512, desde la semana 20.
# ¿Para qué? Calcular el CID de un archivo, guardarlo en un nodo propio y leerlo por su gateway,
#   todo sin conectarse a la red de IPFS (`--offline`).
RUN arch="${TARGETARCH:-amd64}" \
    && file="kubo_${KUBO_VERSION}_linux-${arch}.tar.gz" \
    && base="https://github.com/ipfs/kubo/releases/download/${KUBO_VERSION}" \
    && curl -fsSL -o "/tmp/${file}" "${base}/${file}" \
    && curl -fsSL -o /tmp/kubo.sha512 "${base}/${file}.sha512" \
    && (cd /tmp && sha512sum -c kubo.sha512) \
    && tar -xzf "/tmp/${file}" -C /usr/local/bin --strip-components=1 kubo/ipfs \
    && rm /tmp/kubo*

# ¿Qué? Slither, el analizador estático de Trail of Bits, como herramienta de uv con su propio
#   entorno de Python en /opt/uv-tools, desde la semana 23. Con pytest en el mismo entorno.
# ¿Para qué? `slither` en el PATH para cualquier proyecto Foundry, y `$SLITHER_PYTHON` para los
#   detectores propios, que importan `slither` como biblioteca y se prueban con pytest.
# ¿Impacto? `--exclude-newer` impide versiones con menos de una semana también en las
#   dependencias indirectas (web3, eth-abi...), como el `exclude-newer` de `py/pyproject.toml`.
RUN UV_TOOL_DIR=/opt/uv-tools UV_TOOL_BIN_DIR=/usr/local/bin uv tool install --quiet \
        "slither-analyzer==${SLITHER_VERSION}" \
        --with "crytic-compile==${CRYTIC_COMPILE_VERSION}" \
        --with "pytest==${PYTEST_VERSION}" \
        --exclude-newer "${SLITHER_EXCLUDE_NEWER}" \
    && rm -rf /root/.cache/uv
ENV SLITHER_PYTHON=/opt/uv-tools/slither-analyzer/bin/python

# ¿Qué? Medusa, el fuzzer de Trail of Bits, desde su release de GitHub, verificado con su sha256,
#   desde la semana 24. Compila con `crytic-compile`, que ya trae el entorno de Slither.
# ¿Para qué? Fuzzing de invariantes con otro motor que el de forge, sobre el mismo proyecto.
# ¿Impacto? Medusa solo publica binarios para linux-x64: en arm64 no se instala.
RUN ln -s /opt/uv-tools/slither-analyzer/bin/crytic-compile /usr/local/bin/crytic-compile \
    && if [ "${TARGETARCH:-amd64}" = amd64 ]; then \
        curl -fsSL -o /tmp/medusa.tgz \
            "https://github.com/crytic/medusa/releases/download/${MEDUSA_VERSION}/medusa-linux-x64.tar.gz" \
        && echo "${MEDUSA_SHA256}  /tmp/medusa.tgz" | sha256sum -c - \
        && tar -xzf /tmp/medusa.tgz -C /usr/local/bin medusa \
        && rm /tmp/medusa.tgz; \
    fi

# ¿Qué? Usuario sin privilegios `ubuntu` (UID 1000), que ya trae la imagen base.
# ¿Impacto? Los archivos que crea forge en el volumen montado no quedan como root.
USER ubuntu
WORKDIR /workspace

# ¿Qué? Descarga solc dentro de la imagen compilando un contrato vacío.
# ¿Impacto? `forge build` funciona sin red y no descarga el compilador en cada contenedor.
RUN mkdir /tmp/warm && cd /tmp/warm \
    && printf '// SPDX-License-Identifier: MIT\npragma solidity %s;\ncontract W {}\n' "${SOLC_VERSION}" > W.sol \
    && forge build --use "${SOLC_VERSION}" --contracts . >/dev/null \
    && cd / && rm -rf /tmp/warm

# ¿Qué? pnpm a la versión fija y su almacén con las dependencias web del bootcamp (viem,
#   TypeScript, Vite), las de `web/pnpm-lock.yaml`.
# ¿Para qué? Que `pnpm install --offline` funcione en cada starter sin red y con las mismas
#   versiones exactas, sin descargar nada en cada contenedor.
# ¿Impacto? El almacén vive en la imagen y el proyecto en el volumen: sin enlaces duros entre los
#   dos, pnpm copia los paquetes (`package_import_method=copy`) en vez de crear otro almacén.
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    pnpm_config_store_dir=/home/ubuntu/.local/share/pnpm/store \
    pnpm_config_package_import_method=copy
COPY --chown=ubuntu web /tmp/web
RUN corepack install -g "pnpm@${PNPM_VERSION}" \
    && cd /tmp/web && pnpm fetch --frozen-lockfile >/dev/null \
    && cd / && rm -rf /tmp/web

# ¿Qué? La caché de uv con las dependencias de Python del bootcamp, las de `py/uv.lock`.
# ¿Para qué? Lo mismo que el almacén de pnpm: `uv sync --offline --frozen` instala en cada starter
#   sin red. `UV_LINK_MODE=copy` copia de la caché al volumen en vez de intentar enlaces duros.
COPY --chown=ubuntu py /tmp/py
RUN cd /tmp/py && uv sync --frozen --quiet \
    && cd / && rm -rf /tmp/py

# ¿Qué? anvil escucha en todas las interfaces dentro del contenedor.
# ¿Para qué? Que el puerto 8545 publicado con `-p 8545:8545` llegue desde tu máquina. Los demás
#   puertos: 5173 para Vite, 8000 para la API del indexador y 8080 para el gateway de IPFS.
ENV ANVIL_IP_ADDR=0.0.0.0
EXPOSE 8545 5173 8000 8080

CMD ["bash"]
