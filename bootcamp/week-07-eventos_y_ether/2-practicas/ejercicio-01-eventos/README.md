# Ejercicio 01 — Eventos

> Al terminar habrás emitido eventos con parámetros `indexed`, emitido un valor antes de
> sobrescribirlo, comprobado que un revert no deja eventos y calculado el identificador de
> un evento.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 01](../../1-teoria/01-eventos-y-logs.md) leída.

## Contexto

| Archivo | Qué es |
| ------- | ------ |
| `src/Noticeboard.sol` | Un tablón de anuncios: cuatro mappings, cuatro eventos y tres errores ya declarados. Aquí trabajas |
| `test/Noticeboard.t.sol` | Cinco tests, uno por paso. **No lo modifiques** |

Los tests usan una pieza nueva de la plantilla: `vm.expectEmit()` seguido de un `emit` con
los valores esperados. Significa "la próxima llamada tiene que emitir este evento, con
estos valores exactos". Si emite otro, o los mismos con un valor distinto, el test falla.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-07-eventos_y_ether/2-practicas/ejercicio-01-eventos/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
forge test
```

Compila con `Warning (2018)` y `Warning (5667)`.

**Verifica**: cinco `FAIL`. Los cuatro primeros con `TODO: Paso 1`: todos publican un
anuncio antes de nada.

## Paso 1: Emitir un evento

**Por qué**: el evento es lo que una dApp lee para mostrar "Alice publicó el anuncio 1".
Va al final, cuando el anuncio ya está guardado.

**Abre** `src/Noticeboard.sol`:

```solidity
function post(string calldata text) external returns (uint256 id) {
    id = ++postCount;
    authorOf[id] = msg.sender;
    textOf[id] = text;
    emit Posted(id, msg.sender, text);
}
```

`Posted` tiene `id` y `author` como `indexed`: una dApp puede pedir "todos los anuncios de
esta cuenta" filtrando por topic. El texto va en `data`, para poder leerlo.

**Verifica**: `[PASS] test_Step1_Post()`.

## Paso 2: El valor viejo, antes de sobrescribirlo

**Por qué**: un evento de cambio cuenta de qué a qué. El valor viejo hay que copiarlo antes
de escribir el nuevo, o ya no existe.

```solidity
function edit(uint256 id, string calldata newText) external {
    if (authorOf[id] != msg.sender) revert NotAuthor(msg.sender, id);
    string memory oldText = textOf[id];
    textOf[id] = newText;
    emit Edited(id, oldText, newText);
}
```

`string memory oldText = textOf[id];` es una **copia** (semana 06): justo lo que quieres,
porque la siguiente línea cambia lo guardado.

**Verifica**: `[PASS] test_Step2_Edit()`.

Rompe a propósito: borra la línea de `oldText`, escribe primero y emite leyendo el storage,
`emit Edited(id, textOf[id], newText);`. Ejecuta `forge test --match-test test_Step2`:

```
[FAIL: Edited param mismatch at param 3: expected=0x0000000000000000000000000000000000000000000000000000000000000004, got=0x0000000000000000000000000000000000000000000000000000000000000005, param 4: expected=0x686f6c6100000000000000000000000000000000000000000000000000000000, got=0x6164696f73000000000000000000000000000000000000000000000000000000] test_Step2_Edit() (gas: 141920)
```

Los parámetros 3 y 4 son la longitud y los bytes del texto viejo: esperaba 4 bytes,
`686f6c61` (`hola`), y llegaron 5, `6164696f73` (`adios`). El evento publicó el texto nuevo
dos veces, y una dApp se lo creería. Vuelve a la versión con `oldText`.

## Paso 3: Un evento con un valor calculado

**Por qué**: el evento puede llevar datos que ahorran trabajo a quien lo lee, como el total
ya actualizado.

```solidity
function like(uint256 id) external {
    if (authorOf[id] == address(0)) revert PostNotFound(id);
    if (hasLiked[id][msg.sender]) revert AlreadyLiked(id);
    hasLiked[id][msg.sender] = true;
    uint256 total = ++likes[id];
    emit Liked(id, msg.sender, total);
}
```

**Verifica**: `[PASS] test_Step3_Like()`. El test da dos "me gusta" y espera `total = 2` en
el segundo.

## Paso 4: Revert y eventos

**Por qué**: si la función revierte, no queda ningún evento. Las guardas van antes del
`emit`, y así un evento solo cuenta lo que de verdad pasó.

```solidity
function remove(uint256 id) external {
    if (authorOf[id] != msg.sender) revert NotAuthor(msg.sender, id);
    delete authorOf[id];
    delete textOf[id];
    emit Removed(id);
}
```

**Verifica**: `[PASS] test_Step4_Remove()`. Bob intenta borrar el anuncio de Alice y
revierte; luego Alice lo borra y se emite `Removed(1)`.

## Paso 5: El identificador del evento

**Por qué**: el topic 0 de cada log es el keccak256 de la firma del evento. Quien filtra
logs lo necesita; en Solidity lo tienes con `.selector`.

```solidity
function postedTopic() external pure returns (bytes32) {
    return Posted.selector;
}
```

**Verifica**: `forge test` termina con
`5 tests passed, 0 failed, 0 skipped (5 total tests)` y sin warnings. El test lo compara
con `keccak256("Posted(uint256,address,string)")`: tipos sin nombres, sin `indexed` y sin
espacios. Compruébalo también con `cast keccak "Posted(uint256,address,string)"`.

## ✅ Criterios de éxito

- `forge test` pasa los 5 tests sin warnings.
- Explicas por qué `Edited` necesita la copia `oldText` y qué publicaba sin ella.
- Explicas por qué `id` y `author` son `indexed` y `text` no.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 05 — Pagos seguros](../../1-teoria/05-pagos-seguros.md) | **Ejercicio 01 — Eventos** | [Ejercicio 02 — Recibir ETH →](../ejercicio-02-recibir-ether/README.md) |
