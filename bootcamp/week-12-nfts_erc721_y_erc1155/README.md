# Semana 12 — NFTs: ERC-721 y ERC-1155

Un ERC-20 cuenta cantidades; esta semana los tokens pasan a identificar cosas únicas. ERC-721
guarda un dueño por cada `tokenId`, con dos niveles de permiso y una transferencia "segura"
que pregunta al destino si sabe recibir NFTs. Su metadata (nombre, imagen, atributos) no
está en las tablas del contrato: `tokenURI` dice dónde está, y puedes construirla en el
propio contrato. ERC-1155 guarda muchos tipos de token en un solo contrato, con envíos en
lote. En el proyecto, cada recurso de tu registro recibe un certificado ERC-721, y quien lo
tiene es quien puede retirarlo.

## 🎯 Objetivos de aprendizaje

- Explicar qué guarda un ERC-721, sus funciones y eventos, y la diferencia entre `approve` y
  `setApprovalForAll`.
- Crear una colección con `ERC721` de OpenZeppelin y extenderla con `_update`.
- Recibir NFTs con `IERC721Receiver` y comprobar quién llama a `onERC721Received`.
- Reconocer la reentrancy que abren `safeTransferFrom` y `_safeMint`, y elegir entre `_mint`
  y `_safeMint`.
- Devolver la metadata desde `tokenURI`: en un servidor, en IPFS o construida on-chain con
  `Strings` y `Base64`, escapando el texto de los usuarios.
- Usar ERC-1155: saldos por id, operaciones en lote y receptores de lotes.
- Reconocer los riesgos: `setApprovalForAll` a quien no conoces, NFTs atrapados en
  contratos, receptores que se fían de cualquiera, JSON inyectado y metadata que cambia.

## 📋 Prerrequisitos

[Semana 11](../week-11-erc20_y_openzeppelin/README.md) terminada: ERC-20, OpenZeppelin en la
imagen, `_update` y `super`, `SafeERC20`. Tu repositorio `bc-smartcontracts-<dominio>` con el
proyecto de la semana 11 en `main`.

## 📚 Contenidos

| # | Recurso | Tiempo |
| - | ------- | ------ |
| 1 | [Teoría 01 — NFTs y ERC-721](1-teoria/01-nfts-y-erc721.md) | 40 min |
| 2 | [Teoría 02 — Transferencias seguras y receptores](1-teoria/02-transferencias-seguras-y-receptores.md) | 50 min |
| 3 | [Teoría 03 — Metadata y tokenURI](1-teoria/03-metadata-y-tokenuri.md) | 50 min |
| 4 | [Teoría 04 — ERC-1155](1-teoria/04-erc1155.md) | 40 min |
| 5 | [Ejercicio 01 — Colección ERC-721](2-practicas/ejercicio-01-coleccion-erc721/README.md) | 2 h |
| 6 | [Ejercicio 02 — Receptor de NFTs](2-practicas/ejercicio-02-receptor-de-nfts/README.md) | 2 h |
| 7 | [Ejercicio 03 — Multi-token ERC-1155](2-practicas/ejercicio-03-multi-token-erc1155/README.md) | 2 h |
| 8 | [Proyecto — Certificado de recurso](3-proyecto/README.md) | 4 h |
| 9 | [Rúbrica de evaluación](rubrica-evaluacion.md) (autoevaluación) | 30 min |
| 10 | [Ebooks](4-recursos/ebooks-free/README.md), [videos](4-recursos/videografia/README.md), [webgrafía](4-recursos/webgrafia/README.md) y [glosario](5-glosario/README.md) | 30 min |

## ⏱️ Distribución del tiempo (14 h)

| Parte | Tiempo |
| ----- | ------ |
| Teoría | 3 h |
| Prácticas | 6 h |
| Proyecto | 4 h |
| Autoevaluación, recursos y glosario | 1 h |

## ✅ Cómo saber que terminaste

- Los tres ejercicios: `forge test --deny warnings` en verde (9, 9 y 10 tests).
- En tu repositorio, `forge test` de `week-12/` pasa 88 tests y salta el de fork; en anvil
  transferiste un certificado, el nuevo dueño retiró el recurso y su `tokenURI` dice
  `Retired`; el test de fork pasa, `.gas-snapshot` está actualizado y hay un pull request
  `week-12` → `main`.
- Respondes las 10 preguntas de la rúbrica sin mirar la teoría.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Glosario de la semana 11](../week-11-erc20_y_openzeppelin/5-glosario/README.md) | **Semana 12 — NFTs: ERC-721 y ERC-1155** | [Teoría 01 — NFTs y ERC-721 →](1-teoria/01-nfts-y-erc721.md) |

← [Volver al índice del bootcamp](../README.md)
