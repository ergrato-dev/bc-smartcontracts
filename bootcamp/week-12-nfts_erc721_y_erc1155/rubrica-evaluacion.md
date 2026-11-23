# Rúbrica de evaluación — Semana 12: NFTs, ERC-721 y ERC-1155

## 📊 Distribución de evidencias

| Tipo | Peso | Instrumento |
| ---- | ---- | ----------- |
| Conocimiento 🧠 | 30 % | Cuestionario de autoevaluación (10 preguntas) |
| Desempeño 💪 | 40 % | Ejercicios 01, 02 y 03 |
| Producto 📦 | 30 % | Proyecto: certificado de recurso en tu repositorio |

**Nota mínima para aprobar**: 70 % en **cada** tipo de evidencia, no en el promedio.

---

## 🧠 Conocimiento (30 %)

Responde por escrito, sin mirar la teoría. Las respuestas están al final, plegadas.

| # | Pregunta | Puntos |
| - | -------- | ------ |
| 1 | ¿Qué guarda un contrato ERC-721 para cada token? ¿Dónde está la imagen de un NFT? | 10 |
| 2 | ¿Qué diferencia hay entre `approve(spender, tokenId)` y `setApprovalForAll(operator, true)`? ¿Cuándo se borra cada uno? | 10 |
| 3 | En un log de `Transfer` con topic 0 `0xddf252ad…`, ¿cómo sabes si es de un ERC-20 o de un ERC-721? | 10 |
| 4 | ¿Qué hace `safeTransferFrom` que no hace `transferFrom`, y qué pasa si el destino es una cuenta sin código? | 10 |
| 5 | Un contrato apunta un depósito cada vez que se ejecuta su `onERC721Received`. ¿Qué dos errores puede cometer al hacerlo? | 10 |
| 6 | `claim()` marca `claimed[msg.sender] = true` después de `_safeMint(msg.sender, id)`. ¿Qué puede hacer un contrato, y cómo se arregla? | 10 |
| 7 | Compara la metadata en un servidor, en IPFS y on-chain: ¿quién puede cambiarla en cada caso? | 10 |
| 8 | Un contrato pega en su JSON el apodo que escribió el usuario. ¿Qué puede hacer el usuario, y qué lo impide? | 10 |
| 9 | ¿Cómo guarda ERC-1155 los saldos? ¿Cuándo es fungible un `id` y cuándo es un NFT? | 10 |
| 10 | ¿Por qué un contrato que solo implementa `onERC1155Received` no puede recibir un `_mintBatch`? | 10 |

**Total**: 100 puntos → 30 % de la nota.

<details>
<summary>Respuestas</summary>

1. Un dueño por `tokenId` (`ownerOf`), un contador por dueño (`balanceOf`) y los permisos.
   La imagen no está en el contrato: `tokenURI` devuelve una URI a un JSON, y el JSON trae
   otra URI a la imagen (o la incrusta como `data:`).
2. `approve` da permiso sobre un token a una cuenta, una a la vez, y se borra cuando el token
   cambia de dueño. `setApprovalForAll` da permiso sobre todos los tokens de la colección,
   también los futuros, hasta que el dueño lo revoque con `false`.
3. Por el número de topics: ERC-721 indexa el `tokenId` y tiene cuatro, con `data` vacío;
   ERC-20 tiene tres y la cantidad en `data`.
4. Después de mover el token, si el destino tiene código le llama `onERC721Received` y
   exige que devuelva `0x150b7a02`; si no, revierte con `ERC721InvalidReceiver`. Con una
   cuenta sin código no comprueba nada.
5. No comprobar que `msg.sender` es la colección (cualquiera llama a la función y apunta
   depósitos falsos), y apuntar `operator` en vez de `from` como dueño.
6. `_safeMint` llama a `onERC721Received` del contrato, que vuelve a llamar a `claim()`
   antes de la marca, y emite varios. Se arregla apuntando antes de llamar: la marca y
   después `_safeMint`.
7. En un servidor, su dueño (y si cae, desaparece). En IPFS, la URI es el hash del contenido:
   no se puede cambiar sin cambiar la URI, aunque alguien tiene que mantener el archivo. On-chain,
   solo el código del contrato, que la construye con su estado.
8. Meter una comilla y escribir campos nuevos (un segundo `description` que gana al
   original). Lo impide `Strings.escapeJSON` antes de pegar el texto.
9. Como `balances[id][cuenta]`: un ERC-20 por cada `id` dentro del mismo contrato. Es un NFT
   si solo existe una unidad y el contrato no permite emitir más; si no, es fungible.
10. Porque `_mintBatch` llama a `onERC1155BatchReceived`, que no existe, y el envío revierte
    con `ERC1155InvalidReceiver`.

</details>

---

## 💪 Desempeño (40 %)

| Ejercicio | Criterio | Puntos |
| --------- | -------- | ------ |
| 01 — Colección ERC-721 | `forge test --deny warnings`: 9 de 9 | 15 |
| | Emite, lee el `tokenURI` decodificado y revoca en anvil; explica cómo distingue `_update` mint, burn y transferencia | 15 |
| 02 — Receptor de NFTs | `forge test --deny warnings`: 9 de 9 | 20 |
| | Explica la comprobación de `msg.sender`, por qué apunta `from` y por qué existe `rescue` | 15 |
| 03 — Multi-token ERC-1155 | `forge test --deny warnings`: 10 de 10 | 20 |
| | Lee en anvil los dos eventos de un horneado y explica por qué se quema antes de emitir | 15 |

**Total**: 100 puntos → 40 % de la nota.

---

## 📦 Producto (30 %)

| Criterio | Puntos |
| -------- | ------ |
| Carpeta `week-12/` en tu repositorio, sin `out/` ni `cache/`, con tus pruebas de la semana 09, y pull request `week-12` → `main` | 10 |
| `forge test --deny warnings`: 88 tests en verde y el de fork saltado | 30 |
| El alta emite el certificado con el estado ya escrito, `retire` mira `ownerOf` y solo el registro emite | 20 |
| `tokenURI` construido on-chain, con la etiqueta escapada; el `vm.assume` nuevo del fuzzing, explicado en un comentario | 15 |
| Desplegado en anvil: certificado transferido, `NotRegistrant` para el registrante original, recurso retirado por el nuevo dueño y `tokenURI` en `Retired`; test de fork en verde | 15 |
| `.gas-snapshot` regenerado, `forge snapshot --fuzz-seed 1 --check` en verde, y la elección de `_mint` explicada en el pull request | 10 |

**Total**: 100 puntos → 30 % de la nota.

---

## 🏅 Bandas

| Banda | Rango |
| ----- | ----- |
| Sobresaliente | 90-100 |
| Notable | 80-89 |
| Aprobado | 70-79 |
| No aprobado | < 70 en alguna evidencia |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Proyecto — Certificado de recurso](3-proyecto/README.md) | **Rúbrica de evaluación** | [Ebooks gratuitos →](4-recursos/ebooks-free/README.md) |
