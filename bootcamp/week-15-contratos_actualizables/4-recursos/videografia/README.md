# 🎬 Videografía — Semana 15

| Título | Canal | Duración | Enlace |
| ------ | ----- | -------- | ------ |
| Wrong Way To Write an Upgradeable Proxy - Transparent Upgradeable Proxy - Part 1 \| Solidity 0.8 | Smart Contract Programmer | 9:08 | https://www.youtube.com/watch?v=xluCHy_HB-4 |
| Admin and User Interface - Transparent Upgradeable Proxy - Part 4 \| Solidity 0.8 | Smart Contract Programmer | 9:58 | https://www.youtube.com/watch?v=CLhPUrxwP7k |
| Proxy Admin - Transparent Upgradeable Proxy - Part 5 \| Solidity 0.8 | Smart Contract Programmer | 12:03 | https://www.youtube.com/watch?v=EUOERNErbyI |
| Unsafe Delegatecall (part 2) \| Hack Solidity (0.6) | Smart Contract Programmer | 14:00 | https://www.youtube.com/watch?v=oinniLm5gAM |
| Upgrading your Smart Contracts \| A Tutorial & Introduction | Patrick Collins | 30:17 | https://www.youtube.com/watch?v=bdXJmWajZRY |
| Solidity Proxy Contract Example | James Bachini | 10:54 | https://www.youtube.com/watch?v=m6V6HqEuYLQ |
| Deploying More Efficient Upgradeable Contracts | OpenZeppelin | 40:54 | https://www.youtube.com/watch?v=kWUDTZhxKZI |
| Solidity Tutorial - Como actualizar o modificar un Smart Contract - Ethereum | Programación, Negocios y Noticias Crypto | 57:57 | https://www.youtube.com/watch?v=Dy6QeJVuAq8 |

- **Proxy a mano**: la serie de Smart Contract Programmer (2022) construye un proxy
  transparent paso a paso, empezando por el error de guardar la implementación en el slot 0.
  Es el camino del ejercicio 01, hasta el `ProxyAdmin` del ejercicio 02.
- **Colisiones**: *Unsafe Delegatecall (part 2)* (2020, Solidity 0.6) es la colisión de storage
  de la teoría 02 vista como ataque.
- **Panorama**: el de Patrick Collins (2021) explica cómo se montan proxies con `delegatecall` para actualizar; el de
  James Bachini (2024) es un ejemplo corto de UUPS con OpenZeppelin.
- **UUPS**: el taller de OpenZeppelin (2021) presenta UUPS frente al transparent, cuando salió.
  Es de la versión 4: los nombres cambian (`upgradeTo` ya no existe, ahora es
  `upgradeToAndCall`), la idea no.
- **En español**: el de 2020 usa herramientas y versiones antiguas de OpenZeppelin; míralo
  para la idea de separar estado y lógica, no para copiar código.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ebooks gratuitos](../ebooks-free/README.md) | **Videografía** | [Webgrafía →](../webgrafia/README.md) |
