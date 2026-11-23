# 🌐 Webgrafía — Semana 10

| Recurso | Descripción |
| ------- | ----------- |
| [Contract ABI Specification](https://docs.soliditylang.org/en/v0.8.38/abi-spec.html) | La especificación de la codificación ABI: tipos estáticos y dinámicos, offsets, selectores y `encodePacked` |
| [Members of Address Types](https://docs.soliditylang.org/en/v0.8.38/types.html) | En *Types*, los miembros de `address`: `call`, `staticcall`, `delegatecall`, `code` y sus advertencias |
| [Control Structures](https://docs.soliditylang.org/en/v0.8.38/control-structures.html) | Llamadas externas, `try`/`catch`, `new` y `new {salt: …}` |
| [ABI Encoding and Decoding Functions](https://docs.soliditylang.org/en/v0.8.38/units-and-global-variables.html) | En *Units and Global Variables*, todas las funciones `abi.*` y `bytes.concat` |
| [EIP-1014: Skinny CREATE2](https://eips.ethereum.org/EIPS/eip-1014) | La propuesta que añadió `CREATE2`, con la fórmula de la dirección y ejemplos |
| [EIP-150: Gas cost changes for IO-heavy operations](https://eips.ethereum.org/EIPS/eip-150) | De aquí sale la regla de los 63/64 del gas que recibe una llamada |
| [EIP-165: Standard Interface Detection](https://eips.ethereum.org/EIPS/eip-165) | La forma estándar de preguntar a un contrato qué interfaz cumple, con el tope de 30 000 de gas que usa `_isHook` |
| [cast calldata](https://getfoundry.sh/cast/reference/calldata) | Referencia del comando que codifica una llamada. En el índice de la izquierda, `calldata-decode`, `abi-decode` y `decode-error` |
| [cast compute-address](https://getfoundry.sh/cast/reference/compute-address) | Calcula la dirección de un contrato con `CREATE` o, con `--salt`, con `CREATE2` |
| [computeCreateAddress](https://getfoundry.sh/reference/cheatcodes/compute-create-address) y [computeCreate2Address](https://getfoundry.sh/reference/cheatcodes/compute-create2-address) | Las fórmulas de `CREATE` y `CREATE2` en los tests |
| [Forge linting](https://getfoundry.sh/forge/linting) | Qué avisa el linter de forge, cada aviso con su explicación, y cómo silenciarlo con `forge-lint: disable-next-item` |
| [evm.codes](https://www.evm.codes/) | Referencia interactiva de las instrucciones de la EVM: `CALL`, `STATICCALL`, `DELEGATECALL`, `CREATE` y `CREATE2`, con su gas |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Videografía](../videografia/README.md) | **Webgrafía** | [Glosario →](../../5-glosario/README.md) |
