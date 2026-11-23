# Proyecto — Certificado de recurso

> Duodécima capa del protocolo de tu dominio: cada recurso registrado recibe un certificado
> ERC-721 con su mismo id. El certificado se ve en una wallet, se puede transferir, su
> metadata sale del propio registro, y quien lo tiene es quien puede retirar el recurso.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana terminados y tu proyecto de la
semana 11 en `main`.

## Capa que se añade y por qué ahora

Hasta ahora, un recurso era de quien lo registró, para siempre: `retire` miraba
`registrant`, un campo que nadie puede cambiar. Con un NFT, la titularidad pasa a ser algo
que se transfiere. Esta semana:

- **`Certificate`**, la colección de tu dominio, hecha con `ERC721` de OpenZeppelin. Solo el
  registro emite (`mint`), y el `tokenId` de cada certificado es el id del recurso.
- **El registro despliega la colección** en el constructor, como el token de la semana 11, y
  la guarda en `CERTIFICATE`.
- **Cada alta emite su certificado** para quien registra, por `register`,
  `registerBatch` y `registerWithPoints`.
- **`retire` mira el certificado**: puede retirar quien tiene `CERTIFICATE.ownerOf(id)`, no
  quien registró. Vender el certificado es vender el recurso.
- **`tokenURI` on-chain**: el JSON se construye al llamar, con la etiqueta y el estado que
  tiene el recurso en el registro. Al retirarlo, la metadata cambia sola.

En la semana 13 llega el control de acceso con roles: quién puede hacer qué en el protocolo,
más allá de un único dueño.

**El dominio te lo asigna el instructor.** Usa los nombres y la tasa de tus semanas
anteriores, y dale a la colección un nombre y un símbolo de tu dominio.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-12
   ```

2. Copia el starter entero, con su `.gitignore`, en una carpeta `week-12/` (ajusta la ruta a
   donde clonaste el bootcamp). Después trae tus pruebas de la semana 09 y el
   `.gas-snapshot` de la 11:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-12-nfts_erc721_y_erc1155/3-proyecto/starter week-12
   cp week-11/test/RegistryFuzz.t.sol week-11/test/RegistryFork.t.sol week-12/test/
   cp week-11/.gas-snapshot week-12/
   ```

3. Pon los nombres de tu dominio: en `week-12/src/Registry.sol`, los del registro y la
   tasa; en `week-12/src/LoyaltyToken.sol`, el nombre y el símbolo de tu token; en
   `week-12/src/Certificate.sol`, los de la colección (primer `// TODO:`). El resto de
   `src/` es tu semana 11: si cambiaste algo allí, cópialo también.

4. Entra al contenedor y mira el rojo:

   ```bash
   cd week-12
   docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
   forge test
   ```

**Verifica**: `79 tests passed, 9 failed, 1 skipped (89 total tests)`. Fallan los nueve de
`RegistryCertificate.t.sol` que necesitan `mint`, `tokenURI` o el cambio de `retire`; pasa
el que comprueba nombre, símbolo e interfaces.

## Qué hay en el starter

| Archivo | Qué es |
| ------- | ------ |
| `foundry.toml`, `.gitignore` | Con el remapping de OpenZeppelin. No los cambies |
| `src/Certificate.sol` | La colección, con `REGISTRY`, el error y los imports ya escritos, y sus `// TODO:` |
| `src/Registry.sol` | Tu registro de la semana 11, que ya despliega `CERTIFICATE` en el constructor; dos `// TODO:` |
| `src/LoyaltyToken.sol` | Tu token de la semana 11, sin el nombre |
| `src/` (resto) | `IRegistry`, `Owned`, `Openable`, `LabelLib`, `IERC165` e `IRegistrationHook`, sin cambios |
| `test/Registry.t.sol`, `test/RegistryHook.t.sol`, `test/RegistryMulticall.t.sol`, `test/RegistryLoyalty.t.sol` | Los de la semana 11. **No los modifiques** |
| `test/RegistryCertificate.t.sol` | 10 tests del certificado. **No lo modifiques** |

## Requisitos

1. **`Certificate.mint(to, id)`**: revierte con `NotRegistry(msg.sender)` si no llama el
   registro y, si no, emite `id` para `to` con `_mint`.
2. **`Certificate.tokenURI(id)`**: revierte con `ERC721NonexistentToken(id)` si no existe
   (`_requireOwned`). Si existe, lee el recurso con `REGISTRY.getItem(id)` y devuelve
   `data:application/json;base64,` seguido del JSON en Base64, **exactamente** así (los
   tests lo comparan byte a byte):

   ```
   {"name":"<etiqueta>","description":"Certificate #<id>","attributes":[{"trait_type":"status","value":"<Active o Retired>"},{"trait_type":"registeredAt","display_type":"date","value":<registeredAt>}]}
   ```

   La etiqueta pasa por `Strings.escapeJSON`: la escribió quien registró (teoría 03).
3. **El alta emite**: al final de `_register`, con el recurso ya escrito,
   `CERTIFICATE.mint(msg.sender, id)`.
4. **`retire` mira el certificado**: `NotRegistrant(msg.sender, id)` si
   `CERTIFICATE.ownerOf(id) != msg.sender`. El resto de `retire` no cambia.
5. **Tus propiedades de fuzzing siguen siendo ciertas** (más abajo), `.gas-snapshot`
   actualizado y `forge snapshot --fuzz-seed 1 --check` en verde.
6. **Desplegado en anvil** desde la cuenta de tu `INDEX`, con un certificado transferido y
   su recurso retirado por el nuevo dueño. El test de fork pasa contra ese despliegue.

## Por qué `_mint` y no `_safeMint`

El linter de forge avisa:

```
warning[unsafe-oz-erc721-mint]: `ERC721._mint` does not check that the recipient can receive the token; use `_safeMint`
```

Aquí `_mint` es la decisión correcta, y el aviso se silencia con un comentario que lo diga:

```solidity
        // forge-lint: disable-next-line(unsafe-oz-erc721-mint)
        _mint(to, id);
```

Con `_safeMint`, cada alta llamaría a `onERC721Received` de quien registra si es un contrato:
le daría el control a mitad de `register`, con `count` ya subido y el hook sin avisar
(teoría 02). Y un contrato registrante sin receptor no podría registrar. Quien registra
eligió registrar desde esa dirección: si no sabe guardar NFTs, el problema es suyo, y el
recurso sigue siendo retirable mientras nadie mueva el certificado.

Por el mismo motivo, el `_register` de un lote llama a `CERTIFICATE.mint` dentro de un
bucle, y el linter avisa con `calls-loop`. Añade `calls-loop` al
`forge-lint: disable-next-item(...)` que ya tiene `_register`: la colección es tuya, se
desplegó con el registro y no llama a nadie.

## Cómo verificar

```bash
forge test
```

Con todo hecho, el fuzzing encuentra un caso que antes no existía:

```
[FAIL: ERC721InvalidReceiver(0x0000000000000000000000000000000000000000); counterexample: calldata=0x9c426b55... args=[0x0000000000000000000000000000000000000000, ...]] testFuzz_RegisterStoresItem(address,string,uint256) (runs: 0, μ: 0, ~: 0)
```

Tu propiedad de la semana 09 decía "cualquier cuenta puede registrar", y `hoax` probó con
`address(0)`. Ahora el alta emite un NFT, y `_mint` no acepta `address(0)` como destino. No
es un fallo del registro: ninguna transacción la firma `address(0)`. La propiedad era más
amplia que la red, y se ajusta en el test, con un comentario que lo explique:

```solidity
        // Desde la semana 12 el alta emite un NFT, y no se puede emitir para address(0). Ninguna
        // transacción la firma address(0): la propiedad era más amplia que la red.
        vm.assume(registrant != address(0));
```

**Verifica**: `88 tests passed, 0 failed, 1 skipped (89 total tests)`, sin warnings
(`forge test --deny warnings`). Fíjate en `test_TokenURIEscapesLabel`: registra la etiqueta
`x","description":"fake` y comprueba que queda entera, escapada, dentro de `name`.

### Lo que cuesta la capa nueva

```bash
forge snapshot --fuzz-seed 1 --diff
```

A diferencia de la semana 11, ahora el alta sí cuesta más: emitir un NFT es una llamada a
otro contrato con dos escrituras en su storage (el dueño y el saldo) y un evento:

```
↑ RegistryTest::test_RegisterStoresItem() (gas: 248526 → 299333 | 50807 20.443%)
↑ RegistryTest::test_RegisterBatch() (gas: 570687 → 698664 | 127977 22.425%)
```

Tus números serán otros. Después regenera y comprueba:

```bash
forge snapshot --fuzz-seed 1
forge snapshot --fuzz-seed 1 --check
```

### En anvil, y sobre su fork

Con `anvil --silent &` recién arrancado y la clave de tu `INDEX` (aquí `3`, capacidad `50`
y tasa `0.01 ether`, los de los ejemplos), y la cuenta siguiente como compradora:

```bash
M="test test test test test test test test test test test junk"
PK=$(cast wallet private-key "$M" 3); ME=$(cast wallet address "$PK")
PK2=$(cast wallet private-key "$M" 4); BUYER=$(cast wallet address "$PK2")
forge create src/Registry.sol:Registry --private-key "$PK" --broadcast --constructor-args 50
REGISTRY=0x057ef64E23666F000b34aE31332854aCBd1c8544   # tu "Deployed to"
CERT=$(cast call $REGISTRY "CERTIFICATE()(address)")
echo $CERT
cast compute-address $REGISTRY --nonce 2
```

```
0x94fFf89F1Bd236b709Ef01729Db481258015F8bf
0x94fFf89F1Bd236b709Ef01729Db481258015F8bf
```

El token de fidelidad es el primer contrato que crea el registro (nonce 1); la colección,
el segundo. Pon el hook de la semana 11 y registra tres recursos:

```bash
cast send $REGISTRY "setHook(address)" $(cast call $REGISTRY "LOYALTY()(address)") --private-key "$PK"
cast send $REGISTRY "registerBatch(string[])" "[north,south,east]" --value 0.03ether --private-key "$PK"
cast call $CERT "balanceOf(address)(uint256)" $ME
cast call $CERT "tokenURI(uint256)(string)" 2 | tr -d '"' | sed 's/^data:application\/json;base64,//' | base64 -d | jq -c .
```

```
3
{"name":"south","description":"Certificate #2","attributes":[{"trait_type":"status","value":"Active"},{"trait_type":"registeredAt","display_type":"date","value":1795405758}]}
```

Pasa el certificado 2 a la compradora e intenta retirar el recurso tú:

```bash
cast send $CERT "transferFrom(address,address,uint256)" $ME $BUYER 2 --private-key "$PK"
cast send $REGISTRY "retire(uint256)" 2 --private-key "$PK"
```

```
Error: Failed to estimate gas: server returned an error response: error code 3: execution reverted: custom error 0x0e5151a0: ..., data: "0x0e5151a0...": NotRegistrant(0x90F79bf6EB2c4f870365E785982E1f101E93b906, 2)
```

Ya no es tuyo. Lo retira la compradora, y la metadata cambia sin que nadie la toque:

```bash
cast send $REGISTRY "retire(uint256)" 2 --private-key "$PK2"
cast call $CERT "tokenURI(uint256)(string)" 2 | tr -d '"' | sed 's/^data:application\/json;base64,//' | base64 -d | jq -c .
cast call $REGISTRY "getItem(uint256)((uint256,address,uint8,uint256,string))" 2
```

```
{"name":"south","description":"Certificate #2","attributes":[{"trait_type":"status","value":"Retired"},{"trait_type":"registeredAt","display_type":"date","value":1795405758}]}
(2, 0x90F79bf6EB2c4f870365E785982E1f101E93b906, 2, 1795405758 [1.795e9], "south")
```

`getItem` sigue diciendo que el `registrant` eres tú (`0x90F7…`): el registro guarda quién
registró, y la colección, de quién es ahora. Son dos datos distintos.

Y el test de fork, sin cambios, contra este despliegue:

```bash
FORK_URL=http://127.0.0.1:8545 REGISTRY="$REGISTRY" forge test --match-path test/RegistryFork.t.sol
```

`[PASS] test_Fork_RegistersOnACopy()`.

## Ejemplos de adaptación

Tres dominios que el instructor **no** asigna:

| Dominio | El certificado | Qué significa transferirlo |
| ------- | -------------- | -------------------------- |
| Biblioteca | `Donation Certificate` (`DON`) por cada libro donado | Ceder a otra persona el derecho a retirar el libro |
| Tienda en línea | `Listing Deed` (`LST`) por cada producto publicado | Vender el puesto con su producto |
| Cine | `Screen Deed` (`SCD`) por cada sala registrada | Traspasar la sala a otro exhibidor |

## Criterios de calidad (no automatizables)

- Sabes explicar por qué `retire` mira el certificado y no `registrant`, y qué datos dejan de
  coincidir después de una transferencia (`idsOf`, `registrant`).
- Sabes explicar por qué el certificado usa `_mint` y no `_safeMint`, y qué riesgo tiene esa
  elección.
- Sabes explicar por qué la etiqueta pasa por `escapeJSON` y el id y la fecha no.
- Sabes explicar por qué el `vm.assume` nuevo no esconde un fallo del registro.
- Sin `TODO` restantes, y el nombre y el símbolo de la colección son de tu dominio.

## Entrega

```bash
git add week-12
git commit -m "feat(week-12): add resource certificates as ERC-721"
git push -u origin week-12
```

Abre un pull request `week-12` → `main` en tu repositorio. En la descripción pega la salida
de `forge test`, la línea de `--diff` de `test_RegisterStoresItem`, y los dos `tokenURI`
decodificados de anvil, antes y después de retirar.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — Multi-token ERC-1155](../2-practicas/ejercicio-03-multi-token-erc1155/README.md) | **Proyecto — Certificado de recurso** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
