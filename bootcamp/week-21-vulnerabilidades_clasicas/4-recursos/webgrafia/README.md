# 🌐 Webgrafía — Semana 21

| Recurso | Descripción |
| ------- | ----------- |
| [Solidity — Security Considerations](https://docs.soliditylang.org/en/latest/security-considerations.html) | La documentación oficial sobre reentrancy, límites de gas en bucles, `tx.origin`, enteros y el orden checks-effects-interactions |
| [OpenZeppelin — ReentrancyGuardTransient](https://docs.openzeppelin.com/contracts/5.x/api/utils#ReentrancyGuardTransient) | `nonReentrant` y `nonReentrantView`, y por qué la versión con transient storage sustituye a la de storage |
| [EIP-1153: Transient storage opcodes](https://eips.ethereum.org/EIPS/eip-1153) | `TSTORE` y `TLOAD`: el almacenamiento que se borra al final de la transacción, con el cerrojo de reentrancy como caso de uso |
| [EIP-150: Gas cost changes for IO-heavy operations](https://eips.ethereum.org/EIPS/eip-150) | De aquí sale la regla de 63/64 del gas que recibe una llamada |
| [Solidity by Example — Re-Entrancy](https://solidity-by-example.org/hacks/re-entrancy/) | El ataque y el cerrojo en el mínimo de código, para comparar con el ejercicio 01 |
| [Solidity by Example — Phishing with tx.origin](https://solidity-by-example.org/hacks/phishing-with-tx-origin/) | La cartera, el cebo y el arreglo del ejercicio 02 |
| [Solidity by Example — Denial of Service](https://solidity-by-example.org/hacks/denial-of-service/) | La subasta bloqueada del ejercicio 03 |
| [SWC Registry](https://swcregistry.io/) | Registro clásico de debilidades con número (SWC-107 reentrancy, SWC-115 `tx.origin`, SWC-113 DoS por llamada que falla); ya no se actualiza, pero muchos informes lo citan |
| [OWASP Smart Contract Security Verification Standard](https://scs.owasp.org/SCSVS/) | Lista de comprobaciones por área (acceso, aritmética, llamadas externas) para revisar un contrato de forma ordenada |
| [Ethernaut](https://ethernaut.openzeppelin.com/) | Retos de OpenZeppelin en los que atacas contratos vulnerables: Re-entrancy, Telephone (`tx.origin`), King (DoS) y Denial son de esta semana |

Vale la pena empezar por la documentación de Solidity y la de OpenZeppelin: son las fuentes de
lo que usas. Ethernaut es la mejor práctica extra: cuatro de sus retos son los ataques de esta
semana contra código que no has visto.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Videografía](../videografia/README.md) | **Webgrafía** | [Glosario →](../../5-glosario/README.md) |
