# 🌐 Webgrafía — Semana 13

| Recurso | Descripción |
| ------- | ----------- |
| [EIP-173: Contract Ownership Standard](https://eips.ethereum.org/EIPS/eip-173) | El estándar de `owner()`, `transferOwnership` y `OwnershipTransferred` que sigue `Ownable` |
| [OpenZeppelin — API Access](https://docs.openzeppelin.com/contracts/5.x/api/access) | Referencia de `Ownable`, `Ownable2Step`, `AccessControl` y sus extensiones |
| [OpenZeppelin — API Governance](https://docs.openzeppelin.com/contracts/5.x/api/governance) | Referencia de `TimelockController`: roles, estados y errores |
| [OpenZeppelin — API Utils](https://docs.openzeppelin.com/contracts/5.x/api/utils) | Referencia de `Pausable` |
| [ethereum.org — Seguridad de contratos inteligentes](https://ethereum.org/developers/docs/smart-contracts/security/) | La sección de control de acceso, con `Ownable` y multisigs |
| [OWASP Smart Contract Top 10](https://owasp.org/www-project-smart-contract-top-10/) | Las vulnerabilidades más comunes; los fallos de control de acceso encabezan la lista |
| [SWC-105: Unprotected Ether Withdrawal](https://swcregistry.io/docs/SWC-105/) | Una retirada de ETH sin control de acceso, con ejemplos |
| [Parity — postmortem del multisig](https://www.parity.io/blog/a-postmortem-on-the-parity-multi-sig-library-self-destruct/) | 2017: una función sin proteger en la librería de un multisig congeló los fondos de cientos de carteras |
| [Foundry — arbitrary-send-eth](https://getfoundry.sh/forge/linting/arbitrary-send-eth) | El aviso del linter del proyecto, que reconoce `onlyOwner` pero no `onlyRole` |
| [Foundry — require-revert-in-loop](https://getfoundry.sh/forge/linting/require-revert-in-loop) | El aviso del constructor del multisig, y cuándo un `revert` en un bucle es lo que quieres |
| [Foundry — vm.warp](https://getfoundry.sh/reference/cheatcodes/warp/) | El cheatcode con el que los tests adelantan el reloj del timelock |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Videografía](../videografia/README.md) | **Webgrafía** | [Glosario →](../../5-glosario/README.md) |
