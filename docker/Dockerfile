# ¿Qué? Imagen de desarrollo del bootcamp: Ubuntu 24.04 + Foundry (forge, cast, anvil, chisel) + solc.
# ¿Para qué? Que todos los aprendices compilen, prueben y desplieguen con las mismas versiones,
#            sin instalar nada en su máquina.
# ¿Impacto? Si un ejercicio pasa aquí, pasa en la corrección. Las herramientas que llegan
#           más adelante (pnpm, uv, PostgreSQL) se añaden en la semana que las introduce.
FROM ubuntu:24.04

ARG FOUNDRY_VERSION=v1.9.0
ARG SOLC_VERSION=0.8.38
ARG FORGE_STD_VERSION=v1.17.0
ARG OZ_VERSION=v5.7.0
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

# ¿Qué? anvil escucha en todas las interfaces dentro del contenedor.
# ¿Para qué? Que el puerto 8545 publicado con `-p 8545:8545` llegue desde tu máquina.
ENV ANVIL_IP_ADDR=0.0.0.0
EXPOSE 8545

CMD ["bash"]
