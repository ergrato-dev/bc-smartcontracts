# 📚 Ebooks gratuitos — Semana 14

| Título | Formato | Descripción | Enlace |
| ------ | ------- | ----------- | ------ |
| Mastering Ethereum — Capítulo 4: Cryptography | Web / Markdown (CC BY-SA) | Claves, ECDSA sobre secp256k1 y cómo se recupera la clave pública de una firma | https://github.com/ethereumbook/ethereumbook/blob/develop/src/chapter_4.md |
| Mastering Ethereum — Capítulo 6: Transactions | Web / Markdown (CC BY-SA) | La firma de una transacción, `v`, `r` y `s`, y la protección contra el replay entre redes | https://github.com/ethereumbook/ethereumbook/blob/develop/src/chapter_6.md |
| OpenZeppelin — Utilities | Web (MIT) | La guía de `ECDSA`, `MessageHashUtils`, `EIP712` y `SignatureChecker`, con ejemplos | https://docs.openzeppelin.com/contracts/5.x/utilities |
| Solidity by Example — Verifying Signature | Web (gratuita) | Firmar fuera de la cadena y verificar con `ecrecover`, paso a paso en una página | https://solidity-by-example.org/signature/ |
| Solidity by Example — Signature Replay | Web (gratuita) | El ataque de replay y sus defensas, con un contrato vulnerable y otro corregido | https://solidity-by-example.org/hacks/signature-replay/ |

- **Mastering Ethereum**: del capítulo 4, la parte de ECDSA y de recuperar la clave pública;
  del 6, la firma de transacciones y EIP-155 (el `chainId` en la firma), que es la misma idea
  que el `chainId` del dominio EIP-712.
- **OpenZeppelin**: la sección *Cryptography* de *Utilities* cubre las teorías 01 a 03.
  Fíjate en que la URL diga `5.x`: en la 4.x, `MessageHashUtils` vivía dentro de `ECDSA`.
- **Solidity by Example**: léelos con el ejercicio 01 terminado. El primero firma desde el
  navegador con la wallet; tú lo haces con `cast`. El segundo es el replay de la teoría 02.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Rúbrica de evaluación](../../rubrica-evaluacion.md) | **Ebooks gratuitos** | [Videografía →](../videografia/README.md) |
