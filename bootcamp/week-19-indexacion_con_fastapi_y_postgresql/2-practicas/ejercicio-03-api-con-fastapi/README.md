# Ejercicio 03 — API con FastAPI

> Al terminar tendrás una API de solo lectura sobre el indexador del ejercicio 02: el último
> bloque indexado, el saldo de una cuenta, las transferencias por páginas, una transferencia por
> su hash y CORS solo para tu página.

**Duración estimada**: 2 h
**Prerrequisitos**: [Ejercicio 02](../ejercicio-02-guardar-en-postgresql/README.md) terminado;
[Teoría 03 — Una API con FastAPI](../../1-teoria/03-una-api-con-fastapi.md) leída.

## Contexto

Mismo Token, mismo PostgreSQL. Antes de cada test, `conftest.py` crea las tablas, indexa la
cadena con el `sync` del ejercicio 02 (las tres transferencias de los bloques 1, 2 y 3) y abre un
`TestClient` sobre tu `app`.

| Archivo | Qué es |
| ------- | ------ |
| `src/api.py` | La aplicación y los cinco pasos. Aquí trabajas |
| `src/store.py`, `src/chain.py` | Los ejercicios 02 y 01, resueltos |
| `tests/test_api.py` | Los tests. **No lo modifiques** |
| `tests/conftest.py` | Indexa la cadena y crea el cliente. **No lo modifiques** |

En `api.py` ya están la conexión por petición (`get_conn` y el tipo `Conn`), los tipos
`Address` y `TxHash` con su patrón y los modelos de respuesta. Tú escribes el cuerpo de cada
ruta.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-19-indexacion_con_fastapi_y_postgresql/2-practicas/ejercicio-03-api-con-fastapi/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: `5 failed`. Los pasos 1 a 4, con su `NotImplementedError: TODO: Paso N`; el 5,
con `AssertionError: assert None == 'http://localhost:5173'`: sin CORS, la respuesta no lleva la
cabecera.

## Paso 1: El estado

**Por qué**: la página enseña hasta qué bloque llegan los datos; si el indexador se para, se
nota.

```python
last = conn.execute("SELECT MAX(number) FROM blocks").fetchone()[0]
return Status(last_block=last)
```

`MAX` de ninguna fila es `NULL`, que llega a Python como `None` y al JSON como `null`.

**Abre** `src/api.py`, resuelve `status` y ejecuta `bash test.sh`.

**Verifica**: `test_paso_1_estado PASSED`: `{"last_block": 3}` y, tras vaciar las tablas,
`{"last_block": null}`.

## Paso 2: El saldo

**Por qué**: la consulta ya la tienes (`balance_of`); la ruta valida la entrada y saca el
número como texto.

```python
return Balance(account=account.lower(), balance=str(balance_of(conn, account)))
```

El patrón de `Address` lo comprueba FastAPI antes de llamar a la función.

**Verifica**: `test_paso_2_saldo PASSED`: la cuenta 1 en mayúsculas responde
`{"account": "0x7099…79c8", "balance": "100000000000000000000"}` y `/balances/hola`, 422.

## Paso 3: Las transferencias, por páginas

**Por qué**: es la consulta que el contrato no puede hacer: todas las transferencias de una
cuenta, de la más nueva a la más antigua, de 20 en 20.

```python
rows = conn.cursor(row_factory=dict_row).execute(
    "SELECT block_number, log_index, tx_hash, sender, recipient, value::text AS value FROM transfers"
    " WHERE %(account)s::text IS NULL OR %(account)s IN (sender, recipient)"
    " ORDER BY block_number DESC, log_index DESC LIMIT %(limit)s OFFSET %(offset)s",
    {"account": account and account.lower(), "limit": limit, "offset": offset},
).fetchall()
return [TransferOut(**row) for row in rows]
```

- `dict_row` devuelve cada fila como diccionario con los nombres de las columnas: encaja con los
  campos del modelo.
- `value::text` convierte el `NUMERIC` en texto en la propia consulta.
- `%(account)s::text IS NULL OR ...` es un filtro opcional: sin `account`, la primera condición
  se cumple siempre. El `::text` dice a PostgreSQL de qué tipo es el parámetro cuando llega
  `NULL`.
- `LIMIT` y `OFFSET` son la página. `le=100` en `Query` impide pedir la tabla entera.

**Verifica**: `test_paso_3_transferencias PASSED`: con `limit=2`, los bloques 3 y 2, con el
valor `"50000000000000000000"` como texto; con `offset=2`, la emisión; las tres de la cuenta 0;
y 422 para `limit=1000` y para `account=' OR 1=1 --`.

## Paso 4: Una transferencia, o 404

**Por qué**: la página enlaza a una transferencia por su hash. Si no está indexada (todavía, o
por un reorg), la respuesta tiene que decirlo con su código.

```python
row = conn.cursor(row_factory=dict_row).execute(
    "SELECT block_number, log_index, tx_hash, sender, recipient, value::text AS value"
    " FROM transfers WHERE tx_hash = %s ORDER BY log_index LIMIT 1",
    [tx_hash.lower()],
).fetchone()
if row is None:
    raise HTTPException(status_code=404, detail="Transferencia no indexada")
return TransferOut(**row)
```

Una transacción puede emitir varios `Transfer`; esta ruta devuelve el primero.

**Verifica**: `test_paso_4_una_transferencia PASSED`: la más nueva de `/transfers` se recupera
igual por su hash, y un hash que no existe responde 404 con
`{"detail": "Transferencia no indexada"}`. Necesita el paso 3.

## Paso 5: CORS para tu página

**Por qué**: la página de la semana 18 corre en `http://localhost:5173`. Sin CORS, el navegador
no le deja leer la API; con `"*"`, se lo deja a cualquier página.

Descomenta la línea de `app.add_middleware(...)` del principio de `api.py`:

```python
app.add_middleware(CORSMiddleware, allow_origins=["http://localhost:5173"], allow_methods=["GET"])
```

**Verifica**: `5 passed`. La petición previa desde `http://localhost:5173` recibe la cabecera
`access-control-allow-origin`; desde `https://evil.example`, 400 y sin cabecera.

## Pruébala de verdad

Con todo en verde, arranca la API contra un PostgreSQL y un anvil tuyos. Dentro de un contenedor
con `-p 8000:8000`:

```bash
anvil --silent &
forge script --root contrato contrato/script/DeployToken.s.sol --rpc-url http://127.0.0.1:8545 \
  --broadcast --slow --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export PGDATA=$(mktemp -d)
initdb --auth=trust --username=postgres >/dev/null
pg_ctl --options "-k /tmp -c listen_addresses=''" --log "$PGDATA/log" --wait start
export DATABASE_URL="host=/tmp user=postgres dbname=postgres"
PYTHONPATH=src uv run python -c 'import psycopg, store; c = psycopg.connect("host=/tmp user=postgres", autocommit=True); store.create_schema(c); print(store.sync(c, "http://127.0.0.1:8545", "0x5FbDB2315678afecb367f032d93F642f64180aa3"))'
uv run uvicorn api:app --app-dir src --host 0.0.0.0 --port 8000
```

El `python -c` imprime `3`: las tres transferencias indexadas. Abre
`http://localhost:8000/docs` y prueba `/transfers` desde el navegador.

## Qué aprendiste

- Una ruta de FastAPI declara sus parámetros con tipos y límites; lo que no encaja es 422.
- Los modelos de Pydantic fijan la forma de la respuesta; un `uint256` sale como texto.
- Un filtro opcional en SQL se escribe con `%(x)s::text IS NULL OR ...`, sin montar el SQL a
  trozos.
- CORS decide qué páginas pueden leer la API desde el navegador.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 02 — Guardar en PostgreSQL](../ejercicio-02-guardar-en-postgresql/README.md) | **Ejercicio 03 — API con FastAPI** | [Proyecto — El indexador del protocolo →](../../3-proyecto/README.md) |
