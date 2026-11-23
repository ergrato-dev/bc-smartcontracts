# 📖 Glosario — Semana 14

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Datos tipados (*typed data*) | Mensaje con forma de struct y tipos, que la wallet muestra campo a campo al firmar | `Vote(address voter,uint256 option,...)` |
| Digest | El hash final de 32 bytes que se firma | `_hashTypedDataV4(structHash)` |
| *Domain separator* | El hash del dominio, fijo para cada despliegue | `DOMAIN_SEPARATOR()` |
| Dominio (*domain*) | En EIP-712, los datos que atan una firma a una aplicación: nombre, versión, red y contrato | `EIP712("Poll", "1")` |
| ECDSA | Algoritmo de firma con curvas elípticas que usa Ethereum, sobre la curva secp256k1 | `ECDSA.recover(digest, sig)` |
| `ecrecover` | Precompilado que devuelve la dirección que firmó un hash, o `address(0)` | `ecrecover(hash, v, r, s)` |
| EIP-191 | Formato de datos firmados `0x19 ‖ versión ‖ datos`, que nunca coincide con una transacción | `toEthSignedMessageHash(hash)` |
| EIP-712 | Estándar para firmar datos tipados con un dominio | `cast wallet sign --data` |
| `eip712Domain` | Función de ERC-5267 que devuelve el dominio de un contrato | `cast call $P "eip712Domain()(...)"` |
| *Front-running* | Enviar antes una transacción ajena, o sus datos, que se vio en el mempool | Enviar al token un permit copiado |
| *Griefing* | Ataque que no roba nada pero hace fallar la operación de otro | Gastar el nonce de un permit ajeno |
| Maleabilidad | Propiedad de ECDSA: de una firma válida sale otra distinta e igual de válida | `(r, N - s, v')` |
| Nonce (de firma) | Contador por cuenta que hace que cada orden firmada valga una sola vez | `_useNonce(voter)` |
| *Off-chain* (fuera de la cadena) | Lo que ocurre sin transacción ni gas, en la máquina de cada uno | Firmar una orden |
| Permit | Autorización de gasto de un ERC-20 firmada fuera de la cadena (ERC-2612) | `permit(owner, spender, value, deadline, v, r, s)` |
| Precompilado | Contrato que viene con la red, en una dirección fija, escrito en el cliente | `ecrecover` en `0x01` |
| Relayer | Cuenta que envía firmas ajenas y paga el gas | El patrocinador de `registerBySig` |
| *Replay* | Usar otra vez una firma válida donde quien firmó no quería | El mismo cupón canjeado dos veces |
| Struct hash | El hash de un struct de EIP-712: typehash y campos con `abi.encode` | `keccak256(abi.encode(TYPEHASH, ...))` |
| Typehash | El keccak256 del tipo de un struct escrito como texto, sin espacios | `keccak256("Note(address author,string text,uint256 nonce)")` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 15 — Contratos actualizables →](../../week-15-contratos_actualizables/README.md) |
