# 🌐 Webgrafía — Semana 02

| Recurso | Descripción |
| ------- | ----------- |
| [ethereum.org — Cuentas](https://ethereum.org/es/developers/docs/accounts/) | Documentación oficial, en español: EOA, contratos y los cuatro campos de una cuenta |
| [ethereum.org — Transacciones](https://ethereum.org/es/developers/docs/transactions/) | Campos, ciclo de vida y tipos de transacción, en español |
| [ethereum.org — Gas y comisiones](https://ethereum.org/developers/docs/gas/) | Base fee, propina, gas limit y ejemplos de cálculo |
| [ethereum.org — La EVM](https://ethereum.org/developers/docs/evm/) | Estado, transiciones y ejecución de bytecode |
| [ethereum.org — API JSON-RPC](https://ethereum.org/developers/docs/apis/json-rpc/) | Todos los métodos `eth_*` con sus parámetros y ejemplos con `curl` |
| [ethereum.org — Redes](https://ethereum.org/developers/docs/networks/) | Mainnet, testnets y redes locales; para qué sirve cada una |
| [Foundry — anvil](https://getfoundry.sh/anvil/overview) | Documentación oficial de anvil |
| [Referencia de opciones de anvil](https://getfoundry.sh/reference/anvil/anvil/) | Todas las opciones: `--balance`, `--block-time`, `--port`... |
| [EIP-1559](https://eips.ethereum.org/EIPS/eip-1559) | Base fee, propina y quema; incluye la fórmula de ajuste de la base fee |
| [EIP-155](https://eips.ethereum.org/EIPS/eip-155) | El chain id dentro de la firma, contra la repetición entre redes |
| [EIP-7623](https://eips.ethereum.org/EIPS/eip-7623) | El precio mínimo de los datos de una transacción |
| [evm.codes](https://www.evm.codes/) | Cada opcode con su gas, y un entorno para ejecutar bytecode paso a paso |

- Empieza por las cuatro páginas de ethereum.org (cuentas, transacciones, gas y EVM): son
  la versión oficial de las Teorías 02, 04, 06 y 07.
- Los EIP son la fuente primaria: léelos cuando una explicación secundaria no cuadre con lo
  que ves en anvil.
- En evm.codes, pega `602a60005260206000f3` en el *Playground* y ejecútalo paso a paso:
  es el contrato de la Teoría 07.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Videografía](../videografia/README.md) | **Webgrafía** | [Glosario →](../../5-glosario/README.md) |
