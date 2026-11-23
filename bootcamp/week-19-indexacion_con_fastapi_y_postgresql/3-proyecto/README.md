# Proyecto — El indexador del protocolo

> Tu protocolo gana su capa de datos: un indexador en Python que sigue las altas y las bajas
> de tu Registry, las guarda en PostgreSQL, deshace los reorgs y las sirve con una API de
> FastAPI que tu página puede consultar.

**Duración estimada**: 4 h
**Prerrequisitos**: los tres ejercicios de la semana en verde; tu proyecto de la semana 18 en
`main`.

## Capa que se añade y por qué ahora

Tu dApp de la semana 18 sabe enseñar los recursos de la cuenta conectada, porque el contrato
tiene `idsOf`. Lo que no puede es contestar preguntas sobre **todo** el registro: los recursos
activos de todas las cuentas, por páginas; los de otra cuenta; los que se retiraron. El
indexador las contesta leyendo cada evento una vez.

Ahora es el momento porque tu protocolo ya está desplegado y verificado en Sepolia (semana 16):
un indexador que sigue a una red pública tiene que tratar con lo que anvil no hace solo, rangos
de logs limitados y reorgs. Y la semana 20 añadirá un dato de fuera de la cadena: el indexador
es la pieza que lo pondrá al lado de los tuyos.

## Preparar la rama

**Dónde**: en tu terminal, en tu repositorio `bc-smartcontracts-<tu-dominio>`.

1. Parte de `main` actualizado y crea la rama de la semana:

   ```bash
   git switch main
   git pull
   git switch -c week-19
   ```

2. Copia el starter en `week-19/` y pon tus contratos de la semana 18 en `contracts/`:

   ```bash
   cp -r ../bc-smartcontracts/bootcamp/week-19-indexacion_con_fastapi_y_postgresql/3-proyecto/starter week-19
   cp -r week-18/contracts/src week-18/contracts/script week-19/contracts/
   ls -l week-19/contracts/lib
   ```

   **Verifica**: `lib -> /opt/lib`. Tu página sigue en `week-18/web`; esta semana no cambia.

3. Entra al contenedor publicando los puertos de anvil y de la API, y mira el rojo:

   ```bash
   cd week-19
   docker run --rm -it -p 8545:8545 -p 8000:8000 -v "$PWD":/workspace bc-smartcontracts-dev
   bash test.sh
   ```

**Verifica**: `6 failed, 4 errors`. Los tests de la API dan `ERROR` en su preparación porque
llaman a `create_schema`; todos con su `NotImplementedError: TODO: <función>`.

## Qué hay en el starter

| Ruta | Qué es |
| ---- | ------ |
| `contracts/` | Tu proyecto Foundry: `src/`, `script/`, `foundry.toml` y `lib` |
| `indexer/src/indexer.py` | **Tu trabajo**: seis funciones con `# TODO:` y su pista. Arriba, los topics y los tipos de evento, hechos |
| `indexer/src/api.py` | **Tu trabajo**: tres rutas con `# TODO:`. La conexión, los tipos validados, los modelos y CORS están hechos |
| `indexer/src/chain.py` | `rpc`, `head`, `get_block` y `get_logs`, como en el ejercicio 01. Hecho |
| `indexer/src/main.py` | El indexador en marcha: `sync` cada 2 s, con `START_BLOCK` y `CONFIRMATIONS` del entorno. Hecho |
| `indexer/tests/` | 10 tests contra tu protocolo desplegado. **No los modifiques** |
| `indexer/pyproject.toml`, `indexer/uv.lock` | Las dependencias, copia de las de la imagen |
| `test.sh` | Despliega en un anvil propio (puerto 8546), arranca un PostgreSQL vacío y ejecuta los tests |

## Requisitos

| # | Función | Qué hace |
| - | ------- | -------- |
| 1 | `create_schema` | Tablas `blocks` e `items`; el id como `NUMERIC(78, 0)`; un alta cae con su bloque y una baja se deshace |
| 2 | `decode_label` | La etiqueta del `data` de un `ItemRegistered`, sin romperse con bytes que no son UTF-8 ni con 0x00 |
| 3 | `decode` | Un log de alta o de baja convertido en `Registered` o `Retired` |
| 4 | `apply` | Aplica eventos en orden, de forma idempotente |
| 5 | `rollback_reorg` | Borra los bloques guardados que la cadena ya no tiene, del último hacia atrás |
| 6 | `sync` | Una vuelta en una transacción: deshace el reorg e indexa un tramo con confirmaciones y tamaño máximo |
| 7 | `GET /status` | El último bloque indexado |
| 8 | `GET /items` | Los recursos por id, filtrables por `registrant` y `active`, de 1 a 100 por página |
| 9 | `GET /items/{item_id}` | Un recurso, o 404 `Recurso no indexado` |

Los tests que lo comprueban:

| Test | Qué mira |
| ---- | -------- |
| `test_create_schema` | Un `uint256` máximo cabe; borrar el bloque de la baja reactiva; borrar el del alta borra el recurso |
| `test_decode_label` | `hola`, `cañón`, bytes `ff fe` y un 0x00 en medio |
| `test_decode` | Un alta con etiqueta `<b>hola</b>` y su baja en el bloque siguiente, con el hash correcto |
| `test_apply` | Dos altas y una baja, aplicadas dos veces: el mismo resultado |
| `test_rollback_reorg` | Una baja y un alta que un reorg quita: se borran 2 bloques y el recurso 1 vuelve a estar activo |
| `test_sync` | `start_block`, `max_range`, `confirmations`, una etiqueta con 0x00 y un reorg en mitad |
| `test_status`, `test_list_items`, `test_get_item`, `test_cors` | La API sobre lo indexado: filtros, páginas, 404, 422 y CORS |

## Cómo verificar

### Los tests

```bash
bash test.sh
```

**Verifica**: `10 passed`.

### El indexador en anvil

En el contenedor del paso 3 de *Preparar la rama* (con los puertos publicados), arranca anvil,
despliega tu protocolo y un PostgreSQL:

```bash
anvil --silent &
ETHERSCAN_API_KEY="" forge script --root contracts contracts/script/DeployProtocol.s.sol --rpc-url http://127.0.0.1:8545 \
  --broadcast --slow --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export REGISTRY=$(jq -r '.transactions[] | select(.transactionType == "CREATE" and .contractName == "ERC1967Proxy") | .contractAddress' \
  contracts/broadcast/DeployProtocol.s.sol/31337/run-latest.json)
export PGDATA=$(mktemp -d)
initdb --auth=trust --username=postgres >/dev/null
pg_ctl --options "-k /tmp -c listen_addresses=''" --log "$PGDATA/log" --wait start
export RPC_URL=http://127.0.0.1:8545 DATABASE_URL="host=/tmp user=postgres dbname=postgres"
```

Da de alta diez recursos con la cuenta 1 de anvil y arranca el indexador y la API, cada uno en
segundo plano:

```bash
K1=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
for l in uno dos tres cuatro cinco seis siete ocho nueve diez; do
  cast send $REGISTRY "register(string)" $l --value 0.01ether --private-key $K1 >/dev/null
done
cd indexer
uv run python src/main.py > main.log 2>&1 &
uv run uvicorn api:app --app-dir src --host 0.0.0.0 --port 8000 > api.log 2>&1 &
```

Con los contratos del starter en un anvil recién arrancado, `echo $REGISTRY` da
`0xcf7ed3acca5a467e9e704c703e8d87f634fb0fc9`; con los tuyos puede ser otra. Desde tu máquina:

```bash
curl -s localhost:8000/status
curl -s "localhost:8000/items?limit=2&offset=8"
```

```text
{"last_block":15}
[{"id":"9","registrant":"0x70997970c51812dc3a010c7d01b50e0d17dc79c8","label":"nueve","active":true,"registered_block":14},{"id":"10","registrant":"0x70997970c51812dc3a010c7d01b50e0d17dc79c8","label":"diez","active":true,"registered_block":15}]
```

Retira el 2 y, cuando el indexador haya dado una vuelta, pídelo (en el contenedor):

```bash
cast send $REGISTRY "retire(uint256)" 2 --private-key $K1 >/dev/null
sleep 3; curl -s localhost:8000/items/2
tail -1 main.log
```

```text
{"id":"2","registrant":"0x70997970c51812dc3a010c7d01b50e0d17dc79c8","label":"dos","active":false,"registered_block":7}
Indexado hasta el bloque 16: 1 eventos nuevos
```

Abre `http://localhost:8000/docs` en tu navegador y prueba los filtros de `/items`.

### Un reorg a mano

Con todo en marcha, guarda una foto de la cadena, da un alta, espera a que el indexador la vea
y vuelve a la foto:

```bash
SNAP=$(cast rpc evm_snapshot)
cast send $REGISTRY "register(string)" fantasma --value 0.01ether --private-key $K1 >/dev/null
sleep 3; curl -s "localhost:8000/items?offset=10"
cast rpc evm_revert $SNAP
cast send $REGISTRY "register(string)" real --value 0.01ether --private-key $K1 >/dev/null
sleep 3; curl -s "localhost:8000/items?offset=10"
```

La primera consulta enseña `fantasma` con id 11; la segunda, `real` con el mismo id: el alta
`fantasma` ya no existe en la cadena y tampoco en tu base de datos.

### En Sepolia

Tu Registry de la semana 16 está en Sepolia. Con el RPC que usaste allí:

```bash
export RPC_URL=<tu RPC de Sepolia> REGISTRY=<tu proxy en Sepolia>
START_BLOCK=<bloque del despliegue> CONFIRMATIONS=3 uv run python src/main.py
```

El bloque del despliegue está en `contracts/broadcast/DeployProtocol.s.sol/11155111/run-latest.json`
(`receipts[0].blockNumber`, en hexadecimal) o en la página del proxy en Etherscan. Empezar en 0
serían millones de bloques. Si tu RPC rechaza el rango, baja `max_range` en la llamada de
`main.py`. Usa una base de datos distinta de la de anvil (otro `PGDATA`): son cadenas distintas.

## Ejemplos de adaptación

| Dominio | Pregunta que contesta el indexador | Filtro que añadirías |
| ------- | ---------------------------------- | -------------------- |
| Biblioteca | "Los carnés activos dados de alta este mes" | `registered_block >=` el primer bloque del mes |
| Tienda en línea | "Los vendedores dados de baja, para revisarlos" | `active=false` y orden por `retired_block` |
| Cine | "Las butacas reservadas de una sesión" | Una columna con la sesión, decodificada de la etiqueta |

Los nombres de tablas, columnas y rutas van en inglés y con tu dominio (`members`, `/members`);
los textos de los errores, en español.

## Criterios de calidad (no automatizables)

- Ninguna consulta monta SQL con valores de fuera: todo va con `%s` o `%(nombre)s`. Las únicas
  f-strings con SQL insertan constantes tuyas (`ITEM_COLUMNS`).
- La base de datos se puede borrar y reconstruir desde la cadena: nada de lo que guardas sale de
  otro sitio.
- Cada `uint256` es `NUMERIC(78, 0)` en la tabla y texto en el JSON.
- El estado que cambia con un evento guarda el bloque del cambio, para poder deshacerlo.
- `CONFIRMATIONS` y `START_BLOCK` están documentados en tu README, con los valores que usas en
  Sepolia.
- Ningún secreto en el repo: el RPC de Sepolia con clave va en el entorno, no en el código.

## Entrega

1. `bash test.sh` acaba en `10 passed`.
2. Tu README de `week-19/` explica cómo arrancar el indexador y la API, en anvil y en Sepolia, y
   qué contesta cada ruta.
3. Commit y pull request:

   ```bash
   git add week-19
   git commit -m "feat(week-19): add indexer with FastAPI and PostgreSQL"
   git push -u origin week-19
   ```

   Abre el pull request `week-19` → `main` y fusiónalo cuando esté en verde.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 03 — API con FastAPI](../2-practicas/ejercicio-03-api-con-fastapi/README.md) | **Proyecto — El indexador del protocolo** | [Rúbrica de evaluación →](../rubrica-evaluacion.md) |
