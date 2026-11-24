# 🌐 Webgrafía — Semana 28

| Recurso | Descripción |
| ------- | ----------- |
| [Solidity: Yul](https://docs.soliditylang.org/en/v0.8.38/yul.html) | El lenguaje de la teoría 01: sintaxis, objetos y la lista de opcodes del dialecto de la EVM |
| [Solidity: inline assembly](https://docs.soliditylang.org/en/v0.8.38/assembly.html) | Los bloques `assembly` de la teoría 02: variables, `.slot`, `.offset`, convenciones de memoria |
| [Solidity: seguridad de memoria](https://docs.soliditylang.org/en/v0.8.38/assembly.html#memory-safety) | Qué promete `memory-safe` y qué puede hacer el optimizador con esa promesa |
| [Solidity: limpieza de variables](https://docs.soliditylang.org/en/v0.8.38/internals/variable_cleanup.html) | Cuándo limpia solc los bits sucios y cuándo no |
| [evm.codes](https://www.evm.codes/) | Cada opcode con su efecto en la pila y su gas: el nombre en Yul es el mismo en minúsculas |
| [EIP-211](https://eips.ethereum.org/EIPS/eip-211) | `RETURNDATASIZE` y `RETURNDATACOPY`, y por qué revierte copiar fuera de rango |
| [EIP-1014](https://eips.ethereum.org/EIPS/eip-1014) | `CREATE2` y cómo se calcula su dirección |
| [EIP-1153](https://eips.ethereum.org/EIPS/eip-1153) | `TLOAD` y `TSTORE`: el cerrojo del ejercicio 02 |
| [EIP-6780](https://eips.ethereum.org/EIPS/eip-6780) | `SELFDESTRUCT` ya no borra el código de un contrato antiguo: por qué el hook no puede quedarse sin código |
| [ExcessivelySafeCall](https://github.com/nomad-xyz/ExcessivelySafeCall) | Biblioteca de Nomad para llamar sin copiar más de N bytes de la returndata: el patrón del proyecto |
| [Solady](https://github.com/Vectorized/solady) | Biblioteca auditada escrita casi entera en assembly: para leer assembly bien comentado |
| [Solidity by Example: assembly](https://solidity-by-example.org/assembly-variable/) | Ejemplos cortos de cada construcción de assembly |
| [Foundry: `uninitialized-local`](https://getfoundry.sh/forge/linting/uninitialized-local) | El aviso de `forge lint` de la teoría 04 |
| [Halmos](https://github.com/a16z/halmos) | Las demostraciones de equivalencia de la teoría 04 |

- **La documentación de Solidity** (las cuatro primeras) es la fuente de verdad. Si una regla de
  memoria no te cuadra, la respuesta está en seguridad de memoria.
- **Los EIP** explican el porqué de cada comportamiento que tienes que comprobar a mano.
- **ExcessivelySafeCall y Solady** son código real en producción. Léelos después del proyecto:
  reconocerás `returndatacopy` con tope y las máscaras de selector. No copies sus bloques sueltos
  (teoría 04): si los necesitas, usa la biblioteca entera.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Videografía](../videografia/README.md) | **Webgrafía** | [Glosario →](../../5-glosario/README.md) |
