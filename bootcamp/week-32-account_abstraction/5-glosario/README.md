# 📖 Glosario — Semana 32

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Abstracción de cuentas (*account abstraction*) | Que la cuenta sea un contrato que decide qué firma vale, quién paga y qué se ejecuta | Una cuenta con passkey en vez de clave ECDSA |
| Autorización (EIP-7702) | Tupla firmada por una EOA (red, contrato, nonce) que le pone código | `vm.signAndAttachDelegation(impl, aliceKey)` |
| Bundler | Nodo que junta UserOperations y las envía al EntryPoint en una transacción | `bundler` en los tests |
| Depósito | ETH de una cuenta o un paymaster guardado en el EntryPoint para pagar gas | `entryPoint.balanceOf(paymaster)` |
| Designador | Código de 23 bytes de una EOA delegada: `0xef0100` y la dirección del contrato | `0xef01005fbd...0aa3` |
| Dirección contrafactual | Dirección de una cuenta que todavía no está desplegada, calculada con CREATE2 | `factory.getAddress(owner, 7)` |
| EntryPoint | Contrato único de ERC-4337 que valida, ejecuta y cobra las UserOperations | `EntryPoint` v0.8.0 |
| ERC-7562 | Reglas que los bundlers aplican a la validación: opcodes, storage y stake | Sin `block.timestamp` en la validación |
| Fábrica (*factory*) | Contrato que despliega una cuenta desde el `initCode` de su primera operación | `WalletFactory` |
| `initCode` | Fábrica y llamada que despliegan la cuenta en su primera operación | `abi.encodePacked(factory, createWallet(...))` |
| Paymaster | Contrato que paga el gas de operaciones de otros, con sus reglas | `RegistrationPaymaster` |
| Prefund | ETH que la cuenta manda al EntryPoint antes de ejecutar, para cubrir el gas máximo | `missingAccountFunds` |
| Stake | ETH bloqueado en el EntryPoint con un plazo, fianza de fábricas y paymasters | `addStake{value: 0.1 ether}(1 days)` |
| UserOperation | Lo que firma el usuario en ERC-4337: quién, qué llamada y cuánto gas | `PackedUserOperation` |
| `userOpHash` | Hash EIP-712 de la operación, con el EntryPoint y la red: lo que se firma | `entryPoint.getUserOpHash(op)` |
| `validationData` | Lo que devuelve la validación: firma buena o mala y un plazo | `_packValidationData(false, validUntil, 0)` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 33 — L2 y cross-chain →](../../week-33-l2_y_cross_chain/README.md) |
