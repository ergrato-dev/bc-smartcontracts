# 🌐 Webgrafía — Semana 29

| Recurso | Descripción |
| ------- | ----------- |
| [Solidity — The Optimizer](https://docs.soliditylang.org/en/latest/internals/optimizer.html) | Qué hace el optimizador de solc, sus etapas y qué significa `runs` |
| [Solidity — Layout of State Variables in Storage](https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html) | Las reglas de empaquetado de variables y structs de la teoría 02 |
| [Foundry — Gas tracking](https://getfoundry.sh/forge/gas-tracking/overview) | Informe de gas, `forge snapshot` y snapshots con nombre |
| [EIP-2929: Gas cost increases for state access opcodes](https://eips.ethereum.org/EIPS/eip-2929) | Accesos fríos y calientes: de aquí salen los 2100 y los 100 |
| [EIP-2200: Structured Definitions for Net Gas Metering](https://eips.ethereum.org/EIPS/eip-2200) | Cuánto cuesta cada `SSTORE` según el valor original y el actual |
| [EIP-3529: Reduction in refunds](https://eips.ethereum.org/EIPS/eip-3529) | El tope de un quinto del reembolso que encarece el cerrojo de 0 y 1 |
| [EIP-170: Contract code size limit](https://eips.ethereum.org/EIPS/eip-170) | El límite de 24 576 bytes del bytecode desplegado |
| [evm.codes](https://www.evm.codes/) | El gas de cada opcode, con calculadora para los que dependen del estado |

- Empieza por **Foundry — Gas tracking**: es la referencia de todo lo que usas para medir.
- Los **EIP** explican el porqué de cada precio. Cuando un número te sorprenda, búscalo en la
  calculadora de evm.codes antes de dudar de tu medición.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Videografía](../videografia/README.md) | **Webgrafía** | [Glosario →](../../5-glosario/README.md) |
