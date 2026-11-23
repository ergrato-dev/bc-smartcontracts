# 📖 Glosario — Semana 11

| Término | Definición | Ejemplo |
| ------- | ---------- | ------- |
| Allowance (asignación) | Cantidad de tus tokens que has permitido mover a otra cuenta o contrato | `allowance[alice][shop] = 5 ether` |
| `approve` | Función ERC-20 que fija la allowance de un spender. Sustituye el valor anterior, no lo suma | `coin.approve(address(shop), 5 ether)` |
| `burn` / `burnFrom` | Destruir tokens propios, o de otro gastando su allowance (`ERC20Burnable`) | `LOYALTY.burnFrom(msg.sender, POINTS_PRICE)` |
| Carrera de `approve` | Ataque en el que el spender gasta el permiso viejo antes de que se confirme el cambio, y después también el nuevo | `test_ApproveRace`: bob se lleva 150 |
| `decimals` | Cuántos decimales usar al mostrar un token. No cambia lo que guarda el contrato: siempre unidades mínimas | `decimals() == 18` |
| ERC | *Ethereum Request for Comments*: EIP que fija un estándar de aplicación, sin cambiar la red | ERC-20, ERC-721 |
| ERC-20 | Estándar de token fungible: seis funciones y dos eventos | `transfer`, `Transfer` |
| `forge install` | Instala una dependencia de GitHub en `lib/` como submódulo de git y la fija en `foundry.lock` | `forge install OpenZeppelin/openzeppelin-contracts@v5.7.0` |
| Fungible | Cada unidad vale lo mismo que cualquier otra y son intercambiables | Dos tokens `CLS` |
| `_mint` | Función interna de OpenZeppelin que crea tokens y emite `Transfer` desde `address(0)` | `_mint(msg.sender, supply)` |
| OpenZeppelin Contracts | Biblioteca auditada de contratos estándar para heredar | `import {ERC20} from "@openzeppelin/contracts/..."` |
| Remapping | Regla que dice al compilador qué carpeta hay detrás de un prefijo de `import` | `@openzeppelin/contracts/=/opt/lib/openzeppelin-contracts/contracts/` |
| `SafeERC20` | Biblioteca de OpenZeppelin que mueve tokens aceptando los que no devuelven nada y rechazando los que devuelven `false` | `token.safeTransferFrom(from, to, amount)` |
| Spender | Quien gasta una allowance: el `msg.sender` de `transferFrom` | La tienda en `transferFrom(alice, shop, 5)` |
| Submódulo de git | Repositorio dentro de otro, del que el repositorio principal guarda solo la URL y el commit | `lib/openzeppelin-contracts` |
| Token | Contrato que guarda una tabla de saldos y deja moverlos según sus reglas | `Coin`, `LoyaltyToken` |
| Token con comisión (*fee-on-transfer*) | Token que entrega menos de lo pedido en cada transferencia | `FeeToken`: pides 100, llegan 99 |
| `transferFrom` | Función ERC-20 que mueve tokens de otra cuenta gastando la allowance que dio a quien llama | `COIN.transferFrom(msg.sender, address(this), PRICE)` |
| Tope (*cap*) | Máximo de tokens que pueden existir (`ERC20Capped`) | `ERC20ExceededCap(supply, cap)` |
| `_update` | Función interna de OpenZeppelin 5 por la que pasan mint, burn y transfer: el punto de extensión | `override(ERC20, ERC20Capped)` |
| Unidad mínima | La unidad entera que guarda el contrato; con 18 decimales, 1 token son 10¹⁸ | `cast parse-units 1 18` |

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Webgrafía](../4-recursos/webgrafia/README.md) | **Glosario** | [Semana 12 — NFTs: ERC-721 y ERC-1155 →](../../week-12-nfts_erc721_y_erc1155/README.md) |
