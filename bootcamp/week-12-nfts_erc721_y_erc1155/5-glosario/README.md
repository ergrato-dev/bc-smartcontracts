# 📖 Glosario — Semana 12

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| `_baseURI` | Función interna de `ERC721` cuyo resultado, seguido del `tokenId`, es el `tokenURI` por defecto | `"https://tickets.example/meta/"` |
| Base64 | Codificación de bytes en texto, la que usan las URI `data:` | `Base64.encode(bytes(json))` |
| Colección | El contrato de un ERC-721: cada `tokenId` es un token de la colección | `Ticket`, `Certificate` |
| `data:` (URI) | URI que lleva el contenido dentro, en vez de una dirección donde buscarlo | `data:application/json;base64,eyJ...` |
| ERC-721 | Estándar de token no fungible: un dueño por `tokenId` | `ownerOf(1)` |
| ERC-1155 | Estándar multi-token: muchos tipos (`id`) en un contrato, con saldos por tipo y envíos en lote | `balanceOf(alice, 0)` |
| `escapeJSON` | Función de `Strings` que escapa comillas y barras para meter un texto en un JSON | `Strings.escapeJSON(item.label)` |
| Metadata | El JSON con nombre, descripción, imagen y atributos de un token | `{"name":"Badge #1",...}` |
| NFT | *Non-fungible token*: token en el que cada unidad es única | La entrada 1 del concierto |
| `onERC721Received` | Función que llama `safeTransferFrom` en el destino si es un contrato; tiene que devolver su selector | `0x150b7a02` |
| Operador | Cuenta con permiso sobre todos los tokens de un dueño en una colección (`setApprovalForAll`) | Un mercado |
| `_safeMint` | Emitir y, si el destino es un contrato, llamar a `onERC721Received` | `_safeMint(to, id)` en `GuildPass` |
| `safeTransferFrom` | Transferencia que comprueba que el destino sabe recibir el token | `ticket.safeTransferFrom(alice, holder, 1)` |
| `setApprovalForAll` | Da o quita a un operador el permiso sobre todos tus tokens de la colección | `setApprovalForAll(market, true)` |
| Soulbound | Token que no se puede transferir: solo se emite y se quema | `GuildPass` |
| `tokenId` | El identificador de un token dentro de su colección | `1` en `ownerOf(1)` |
| `tokenURI` | Función que devuelve la URI de la metadata de un token | `tokenURI(1)` |
| `TransferSingle` / `TransferBatch` | Eventos de ERC-1155 para un envío de un `id` o de varios | `0xc3d58168…` / `0x4a39dc06…` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 13 →](../../week-13-control_de_acceso/README.md) |
