# 🌐 Webgrafía — Semana 14

| Recurso | Descripción |
| ------- | ----------- |
| [EIP-191: Signed Data Standard](https://eips.ethereum.org/EIPS/eip-191) | El formato `0x19 ‖ versión ‖ datos` y sus tres versiones |
| [EIP-712: Typed structured data hashing and signing](https://eips.ethereum.org/EIPS/eip-712) | Dominio, typehash y reglas de codificación de cada tipo, también arrays y structs anidados |
| [EIP-2612: Permit Extension for EIP-20](https://eips.ethereum.org/EIPS/eip-2612) | `permit`, `nonces` y `DOMAIN_SEPARATOR`, con la sección de seguridad sobre el front-running |
| [EIP-5267: Retrieval of EIP-712 domain](https://eips.ethereum.org/EIPS/eip-5267) | La función `eip712Domain()` y el significado del byte `0x0f` |
| [EIP-2: Homestead Hard-fork Changes](https://eips.ethereum.org/EIPS/eip-2) | Por qué Ethereum solo acepta firmas con `s` en la mitad baja |
| [Solidity — Funciones matemáticas y criptográficas](https://docs.soliditylang.org/en/latest/units-and-global-variables.html) | `ecrecover` y su aviso sobre la maleabilidad, en la documentación oficial |
| [OpenZeppelin — API Cryptography](https://docs.openzeppelin.com/contracts/5.x/api/utils/cryptography) | Referencia de `ECDSA`, `MessageHashUtils` y `EIP712` |
| [OpenZeppelin — API ERC-20](https://docs.openzeppelin.com/contracts/5.x/api/token/erc20) | Referencia de `ERC20Permit`, con la advertencia sobre el `try` |
| [Foundry — vm.sign](https://getfoundry.sh/reference/cheatcodes/sign/) | El cheatcode con el que firman todos los tests de la semana |
| [Foundry — cast wallet sign](https://getfoundry.sh/reference/cast/wallet/sign/) | Firmar mensajes, hashes y datos tipados (`--data --from-file`) |
| [Foundry — block-timestamp](https://getfoundry.sh/forge/linting/block-timestamp) | El aviso del linter del proyecto, y cuándo un plazo con `block.timestamp` es correcto |
| [SWC-117: Signature Malleability](https://swcregistry.io/docs/SWC-117/) | La firma gemela de la teoría 01, con un contrato vulnerable |
| [SWC-121: Missing Protection against Signature Replay Attacks](https://swcregistry.io/docs/SWC-121/) | Las formas de replay de la teoría 02 |
| [Solidity by Example — WETH Permit](https://solidity-by-example.org/hacks/weth-permit/) | Llamar a `permit` en un token que no lo tiene: el `fallback` de WETH lo acepta sin hacer nada |
| [MetaMask — Signing methods](https://docs.metamask.io/wallet/concepts/signing-methods/) | `personal_sign`, `eth_signTypedData_v4` y por qué `eth_sign` está desaconsejado |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Videografía](../videografia/README.md) | **Webgrafía** | [Glosario →](../../5-glosario/README.md) |
