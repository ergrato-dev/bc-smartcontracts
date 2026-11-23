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
| OpenZeppelin Contracts | `v5.7.0` | `ARG OZ_VERSION` (en `/opt/lib` de la imagen) y remapping `@openzeppelin/contracts/` | Última estable con más de dos semanas publicada; sin avisos de seguridad abiertos |

## Dependencias por semana

Cada dependencia se añade a esta tabla **en la semana que la introduce**, con la versión
verificada ese día. Hasta entonces no se fija nada.

| Biblioteca | Versión | Desde la semana | Uso |
| ---------- | ------- | --------------- | --- |
| OpenZeppelin Contracts | `v5.7.0` | 11 | `ERC20`, `ERC20Burnable`, `ERC20Capped`, `SafeERC20`; en la imagen, no en cada proyecto |

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
