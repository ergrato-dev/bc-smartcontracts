# 🎬 Videografía — Semana 29

| Título | Canal | Duración | Enlace |
| ------ | ----- | -------- | ------ |
| Simple Trick to Save Gas in Your Smart Contract | Smart Contract Programmer | 4:06 | https://www.youtube.com/watch?v=l2OxNQcb8e8 |
| Storage, Memory and Calldata \| Solidity 0.8 | Smart Contract Programmer | 6:15 | https://www.youtube.com/watch?v=wOCIhzAuhgs |
| Gas Golf \| Solidity 0.8 | Smart Contract Programmer | 6:25 | https://www.youtube.com/watch?v=4r20M9Fr8lY |
| Gas Optimization in Solidity: 10 tips | EatTheBlocks | 8:00 | https://www.youtube.com/watch?v=PYilP2bjtwc |
| Less Gas, More Fun: Optimising Smart Contracts through Yul by Christian Reitwiessner (Devcon4) | Ethereum Foundation | 25:22 | https://www.youtube.com/watch?v=VH4MgZDyZJU |

Todos en inglés: no hay videos en español sobre optimización de gas con este nivel. Todos son
anteriores a Solidity 0.8.22 y a Foundry 1.9: las técnicas siguen valiendo, pero los números no.
Mide con el contenedor.

- **Gas Golf** aplica, una a una, varias técnicas de las teorías 02 y 03 a la misma función, y
  mide cada paso: el mismo método que los ejercicios. Fíjate en qué trucos ya no ahorran con un
  compilador actual, como el `unchecked` del contador del bucle (teoría 03).
- **Storage, Memory and Calldata** repasa en seis minutos lo que hay detrás del paso 1 y el paso 3
  del ejercicio 02.
- **EatTheBlocks** son diez trucos en ocho minutos; compáralos con la tabla de la teoría 04.
- **Christian Reitwiessner** dirigió el equipo de Solidity: su charla explica qué hace el optimizador
  con Yul por dentro, la base de `via_ir`.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ebooks gratuitos](../ebooks-free/README.md) | **Videografía** | [Webgrafía →](../webgrafia/README.md) |
