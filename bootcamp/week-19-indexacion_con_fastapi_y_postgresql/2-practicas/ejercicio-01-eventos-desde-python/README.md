# Ejercicio 01 — Eventos desde Python

> Al terminar habrás escrito, en Python y sin bibliotecas de Ethereum, lo que un indexador
> necesita de la cadena: llamar al nodo por JSON-RPC, leer un bloque, pedir los logs de un
> evento, convertirlos en datos y recorrer un rango largo por tramos.

**Duración estimada**: 1 h 30 min
**Prerrequisitos**: [Teoría 01 — Por qué indexar](../../1-teoria/01-por-que-indexar.md) leída.

## Contexto

`test.sh` arranca su anvil en el puerto 8546 y despliega el Token de la semana 17 con tres
eventos `Transfer`: la emisión de 1000 BCT a la cuenta 0 (bloque 1), 100 BCT de la cuenta 0 a
la 1 (bloque 2) y 50 BCT de la 0 a la 2 (bloque 3).

| Archivo | Qué es |
| ------- | ------ |
| `src/chain.py` | Los cinco pasos. Aquí trabajas |
| `tests/test_chain.py` | Los tests. **No lo modifiques** |
| `tests/conftest.py` | Las cuentas y el RPC que usan los tests. **No lo modifiques** |
| `pyproject.toml`, `uv.lock` | Las dependencias, copia de las de la imagen |
| `contrato/` | El Token y su despliegue |

Cada paso es una función con `raise NotImplementedError("TODO: Paso N")` en su primera línea y
la solución debajo, en líneas que empiezan por `#> `. Borra el `raise` y descomenta esas líneas
(quita `#> `, respetando la sangría). Escríbelas tú si prefieres: los tests solo miran el
resultado.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-19-indexacion_con_fastapi_y_postgresql/2-practicas/ejercicio-01-eventos-desde-python/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: `5 failed`, cada test con su `NotImplementedError: TODO: Paso N`.

## Paso 1: Llamar al nodo

**Por qué**: todo lo demás es una llamada JSON-RPC. Un error del nodo llega dentro de una
respuesta `200 OK`, en el campo `error`: si no lo conviertes en excepción, tu código sigue con
`None`.

```python
response = httpx2.post(url, json={"jsonrpc": "2.0", "id": 1, "method": method, "params": params})
response.raise_for_status()
body = response.json()
if "error" in body:
    raise RpcError(body["error"]["message"])
return body["result"]
```

`raise_for_status` lanza una excepción si la respuesta HTTP no es 2xx (el nodo caído detrás de
un proxy, por ejemplo).

**Abre** `src/chain.py`, resuelve `rpc` y ejecuta `bash test.sh`.

**Verifica**: `test_paso_1_rpc PASSED`. El test pide `eth_chainId` (`0x7a69`, el 31337 de
anvil), `eth_blockNumber` (`0x3`) y un método que no existe, que tiene que lanzar `RpcError`.

## Paso 2: Un bloque

**Por qué**: el hash de un bloque y el de su padre son lo que te dejará notar un reorg
(teoría 04).

```python
block = rpc(url, "eth_getBlockByNumber", [hex(number), False])
return Block(number=int(block["number"], 16), hash=block["hash"], parent_hash=block["parentHash"])
```

`False` pide el bloque con solo los hashes de sus transacciones, no las transacciones enteras.

**Verifica**: `test_paso_2_bloque PASSED`: el padre del bloque 3 es el hash del bloque 2.

## Paso 3: Los logs de un evento

**Por qué**: el nodo filtra por dirección, por topic0 y por rango: solo te llega lo que vas a
guardar.

```python
return rpc(url, "eth_getLogs", [{
    "address": token,
    "topics": [TRANSFER_TOPIC],
    "fromBlock": hex(from_block),
    "toBlock": hex(to_block),
}])
```

`TRANSFER_TOPIC` está al principio del archivo, sacado de `cast sig-event`.

**Verifica**: `test_paso_3_logs PASSED`: tres logs, en los bloques `0x1`, `0x2` y `0x3`, y el
topic2 del bloque 2 es la cuenta 1 rellenada con ceros hasta 32 bytes.

## Paso 4: De log a datos

**Por qué**: el resto del indexador trabaja con enteros y direcciones, no con texto
hexadecimal.

```python
return Transfer(
    block_number=int(log["blockNumber"], 16),
    block_hash=log["blockHash"],
    tx_hash=log["transactionHash"],
    log_index=int(log["logIndex"], 16),
    sender="0x" + log["topics"][1][-40:],
    recipient="0x" + log["topics"][2][-40:],
    value=int(log["data"], 16),
)
```

`value` no tiene `indexed`: va en `data`. Un entero de Python no tiene tamaño máximo, así que
el `uint256` cabe entero.

**Verifica**: `test_paso_4_decodificar PASSED`: la emisión sale de la dirección cero hacia la
cuenta 0 con `1000 * 10**18`, y la segunda transferencia lleva el hash del bloque 2.

## Paso 5: Por tramos

**Por qué**: un nodo público rechaza un `eth_getLogs` de muchos bloques. El indexador pide
tramos de `chunk` bloques, uno detrás de otro.

```python
transfers = []
for start in range(from_block, to_block + 1, chunk):
    end = min(start + chunk - 1, to_block)
    transfers += [decode_transfer(log) for log in get_transfer_logs(url, token, start, end)]
return transfers
```

Los dos extremos de `eth_getLogs` se incluyen: el tramo siguiente empieza en `end + 1`, nunca
en `end`, o un log se contaría dos veces.

**Verifica**: `5 passed`. El test cuenta las peticiones: de 0 a 3 con `chunk=2` son dos,
`(0, 1)` y `(2, 3)`, y llegan las tres transferencias en orden.

## Qué aprendiste

- JSON-RPC es un `POST` con método y parámetros; los errores llegan en el cuerpo, no en el
  código HTTP.
- Un log se identifica por `(blockNumber, logIndex)`; sus topics llevan lo `indexed` y `data`,
  el resto.
- Las direcciones de los topics son los últimos 40 caracteres; los números, hexadecimal.
- Un rango largo se pide por tramos que no se solapan.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Teoría 04 — Reorgs y confirmaciones](../../1-teoria/04-reorgs-y-confirmaciones.md) | **Ejercicio 01 — Eventos desde Python** | [Ejercicio 02 — Guardar en PostgreSQL →](../ejercicio-02-guardar-en-postgresql/README.md) |
