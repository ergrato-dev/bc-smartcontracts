# 🌐 Webgrafía — Semana 27

| Recurso | Descripción |
| ------- | ----------- |
| [Solidity: layout en storage](https://docs.soliditylang.org/en/v0.8.38/internals/layout_in_storage.html) | Las reglas oficiales de la teoría 03: empaquetado, mappings, arrays, strings y transient storage |
| [Solidity: layout en memoria](https://docs.soliditylang.org/en/v0.8.38/internals/layout_in_memory.html) | La zona de trabajo, el puntero de memoria libre y el slot cero de la teoría 02 |
| [Solidity: especificación del ABI](https://docs.soliditylang.org/en/v0.8.38/abi-spec.html) | La codificación de la calldata de la teoría 04, con ejemplos de tipos dinámicos anidados |
| [ethereum.org: la EVM](https://ethereum.org/developers/docs/evm/) | La introducción oficial a la máquina de pila y al estado |
| [evm.codes](https://www.evm.codes/) | Cada opcode con su efecto en la pila y su gas, por hardfork |
| [evm.codes: playground](https://www.evm.codes/playground) | Ejecuta bytecode paso a paso en el navegador. Prueba ahí los programas del ejercicio 01 |
| [Foundry: `forge inspect`](https://getfoundry.sh/reference/forge/inspect) | `storageLayout`, `transientStorageLayout`, `methodIdentifiers` y el bytecode de un contrato |
| [EIP-2929](https://eips.ethereum.org/EIPS/eip-2929) | Accesos fríos y calientes al storage |
| [EIP-3529](https://eips.ethereum.org/EIPS/eip-3529) | El tope de los reembolsos de `SSTORE` |
| [EIP-1153](https://eips.ethereum.org/EIPS/eip-1153) | `TLOAD` y `TSTORE`: el transient storage |
| [EIP-7623](https://eips.ethereum.org/EIPS/eip-7623) | El suelo de gas de la calldata |
| [EIP-1967](https://eips.ethereum.org/EIPS/eip-1967) | Los slots del proxy: el primer test del proyecto |
| [EIP-7201](https://eips.ethereum.org/EIPS/eip-7201) | Los espacios de nombres de storage de OpenZeppelin |
| [RareSkills: storage layout](https://www.rareskills.io/post/evm-solidity-storage-layout) | El layout explicado con muchos ejemplos de slots calculados |
| [noxx: EVM Deep Dives](https://noxx.substack.com/p/evm-deep-dives-the-path-to-shadowy) | Serie de artículos que desmonta un contrato opcode a opcode |

- **La documentación de Solidity** (las tres primeras) es la fuente de verdad: si un slot no te sale,
  la respuesta está en el layout en storage.
- **evm.codes** es la página que vas a tener abierta toda la fase 6, también en las semanas 28 y 29.
- **Los EIP** explican el porqué de cada precio: léelos cuando una cifra de gas te sorprenda.
- **RareSkills y noxx** son los mejores textos de la comunidad sobre la EVM por dentro. Sus cifras
  de gas pueden ser de un hardfork anterior.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Videografía](../videografia/README.md) | **Webgrafía** | [Glosario →](../../5-glosario/README.md) |
