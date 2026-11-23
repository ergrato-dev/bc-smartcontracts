# Ejercicio 03 — Multi-token ERC-1155

> Al terminar tendrás una panadería en un solo contrato ERC-1155: el dueño reparte harina y
> azúcar en lote, cada cuenta hornea tartas quemando sus ingredientes, y cada tipo tiene su
> URI. Y verás en un recibo los dos eventos de ERC-1155.

**Duración estimada**: 2 h
**Prerrequisitos**: [Teoría 04](../../1-teoria/04-erc1155.md) leída y
[ejercicio 02](../ejercicio-02-receptor-de-nfts/README.md) terminado.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Owned.sol` | El dueño fijo de la semana 08. Terminado |
| `src/Bakery.sol` | La panadería: `FLOUR` (0), `SUGAR` (1) y `CAKE` (2) en un `ERC1155`. Aquí trabajas |
| `test/Bakery.t.sol` | Los tests de cada paso, y `SingleOnly`, un receptor que no sabe recibir lotes. No lo modifiques |

Una tarta cuesta `FLOUR_PER_CAKE` (3) de harina y `SUGAR_PER_CAKE` (1) de azúcar. El
constructor pasa una URI vacía a `ERC1155`: el paso 3 escribe una propia.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-12-nfts_erc721_y_erc1155/2-practicas/ejercicio-03-multi-token-erc1155/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con warnings `(5667)` y `(2018)`.

**Verifica**: `2 tests passed, 8 failed, 0 skipped (10 total tests)`. Pasan
`test_Step1_RevertWhen_StrangerSupplies` (`onlyOwner`) y `test_Inherited_SupportsInterface`.

## Paso 1: Repartir en lote

**Por qué**: un envío de harina y azúcar es una sola llamada a `_mintBatch` y un solo evento
`TransferBatch`. Antes, el bucle comprueba cada id: si `supply` aceptara `CAKE`, el dueño
crearía tartas sin hornear. `_mintBatch` ya comprueba que `ids` y `amounts` tienen la misma
longitud (teoría 04).

**Abre** `src/Bakery.sol`, en `supply`, borra el `revert` y descomenta:

```solidity
for (uint256 i = 0; i < ids.length; i++) {
    if (ids[i] != FLOUR && ids[i] != SUGAR) revert NotAnIngredient(ids[i]);
}
_mintBatch(to, ids, amounts, "");
```

**Verifica**: `5 tests passed, 5 failed`. Mira `test_Step1_RevertWhen_ReceiverWithoutBatch`:
`SingleOnly` tiene `onERC1155Received` pero no `onERC1155BatchReceived`, y un lote para él
revierte con `ERC1155InvalidReceiver`. Un envío suelto le llegaría; un lote, nunca.

## Paso 2: Hornear

**Por qué**: hornear es quemar dos ids y emitir otro. Los arrays se construyen en `memory`
con tamaño fijo (semana 06). `_burnBatch` revierte con `ERC1155InsufficientBalance` si falta
algo, así que no hace falta comprobar los saldos a mano. Se quema **antes** de emitir:
`_mint` avisa a `msg.sender` si es un contrato, y para entonces los ingredientes ya tienen
que haberse gastado (teoría 04).

```solidity
if (cakes == 0) revert NothingToBake();
uint256[] memory ids = new uint256[](2);
uint256[] memory amounts = new uint256[](2);
(ids[0], ids[1]) = (FLOUR, SUGAR);
(amounts[0], amounts[1]) = (FLOUR_PER_CAKE * cakes, SUGAR_PER_CAKE * cakes);
_burnBatch(msg.sender, ids, amounts);
_mint(msg.sender, CAKE, cakes, "");
```

**Verifica**: `8 tests passed, 2 failed`. `test_Step2_RevertWhen_NotEnoughFlour` hornea 4
tartas con 10 de harina y espera
`ERC1155InsufficientBalance(alice, 10, 12, 0)`: tiene 10, hacen falta 12, del id 0.

## Paso 3: Una URI por id

**Por qué**: la plantilla `{id}` de la teoría 04 sirve para cualquier número, también para
los que no existen. Aquí hay tres tipos, y una URI propia permite decir que el 3 no existe.
`uri` es `pure`: no lee el estado, solo el argumento.

```solidity
if (id > CAKE) revert UnknownItem(id);
return string.concat("https://bakery.example/items/", id.toString(), ".json");
```

**Verifica**:

```bash
forge test --deny warnings
```

`10 tests passed, 0 failed, 0 skipped (10 total tests)`, sin warnings.

## Paso 4: En anvil

**Por qué**: ver que un horneado es una transacción con dos eventos, uno por cada operación.

Este paso no tiene código. Arranca anvil, despliega desde la cuenta 0 y dale ingredientes a la 1:

```bash
anvil --silent &
M="test test test test test test test test test test test junk"
PK0=$(cast wallet private-key "$M" 0); PK1=$(cast wallet private-key "$M" 1); A1=$(cast wallet address "$PK1")
forge create src/Bakery.sol:Bakery --private-key "$PK0" --broadcast
B=0x5FbDB2315678afecb367f032d93F642f64180aa3
cast send $B "supply(address,uint256[],uint256[])" $A1 "[0,1]" "[10,5]" --private-key "$PK0"
cast send $B "bake(uint256)" 3 --private-key "$PK1" --json | jq -c '.logs[] | .topics[0]'
```

```
"0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb"
"0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62"
```

Primero `TransferBatch` (la quema de los dos ingredientes, hacia `address(0)`) y después
`TransferSingle` (la emisión de las tartas): son los topics de la teoría 04.

**Verifica**:

```bash
cast call $B "balanceOfBatch(address[],uint256[])(uint256[])" "[$A1,$A1,$A1]" "[0,1,2]"
cast call $B "uri(uint256)(string)" 2
cast send $B "bake(uint256)" 1 --private-key "$PK1"
```

`[1, 2, 3]` (quedan 1 de harina y 2 de azúcar, y hay 3 tartas),
`"https://bakery.example/items/2.json"`, y la cuarta tarta revierte con
`ERC1155InsufficientBalance(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 1, 3, 0)`.

## ✅ Criterios de éxito

- `forge test --deny warnings` pasa los 10 tests.
- Explicas por qué `supply` rechaza `CAKE` y qué permitiría si no lo hiciera.
- Explicas por qué `bake` quema antes de emitir.
- Explicas por qué `SingleOnly` recibe envíos sueltos y no lotes.
- Explicas por qué estos tres tipos van en un ERC-1155 y no en tres contratos.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Receptor de NFTs](../ejercicio-02-receptor-de-nfts/README.md) | **Ejercicio 03 — Multi-token ERC-1155** | [Proyecto — Certificado de recurso →](../../3-proyecto/README.md) |
