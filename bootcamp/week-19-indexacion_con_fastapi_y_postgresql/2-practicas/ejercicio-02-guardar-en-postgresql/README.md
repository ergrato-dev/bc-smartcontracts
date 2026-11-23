# Ejercicio 02 — Guardar en PostgreSQL

> Al terminar tendrás un indexador del Token: crea sus tablas, guarda las transferencias sin
> duplicarlas, calcula saldos en SQL, se pone al día con la cadena de una sola vez y deshace los
> bloques que un reorg dejó fuera.

**Duración estimada**: 2 h 30 min
**Prerrequisitos**: [Ejercicio 01](../ejercicio-01-eventos-desde-python/README.md) terminado;
[Teoría 02](../../1-teoria/02-eventos-en-postgresql.md) y
[Teoría 04](../../1-teoria/04-reorgs-y-confirmaciones.md) leídas.

## Contexto

Mismo Token y mismo formato que el ejercicio 01. `test.sh` arranca además un PostgreSQL vacío
(teoría 02) y deja su dirección en `DATABASE_URL`.

| Archivo | Qué es |
| ------- | ------ |
| `src/store.py` | Los cinco pasos. Aquí trabajas |
| `src/chain.py` | Las funciones del ejercicio 01, resueltas |
| `tests/test_store.py` | Los tests. **No lo modifiques** |
| `tests/conftest.py` | La conexión, la cadena y `send_transfer`. **No lo modifiques** |

Dos cosas que hace `conftest.py` por ti:

- Cada test recibe una conexión en **autocommit** a una base de datos sin tablas.
- Cada test toma un `evm_snapshot` al empezar y vuelve a él al acabar: las transferencias que
  manda un test no las ve el siguiente.

## Paso 0: Entrar y ver el rojo

```bash
cd bootcamp/week-19-indexacion_con_fastapi_y_postgresql/2-practicas/ejercicio-02-guardar-en-postgresql/starter
docker run --rm -it -v "$PWD":/workspace bc-smartcontracts-dev
bash test.sh
```

**Verifica**: `1 failed, 4 errors`. El paso 1 falla con su `TODO`; los otros cuatro dan
`ERROR` antes de empezar, porque su preparación llama a `create_schema`.

## Paso 1: Las tablas

**Por qué**: el diseño de las tablas hace la mitad del trabajo: tipos que caben, nada repetido y
borrado en cascada para los reorgs.

```python
conn.execute("""
    CREATE TABLE IF NOT EXISTS blocks (
        number BIGINT PRIMARY KEY,
        hash TEXT NOT NULL
    )
""")
conn.execute("""
    CREATE TABLE IF NOT EXISTS transfers (
        block_number BIGINT NOT NULL REFERENCES blocks (number) ON DELETE CASCADE,
        log_index INTEGER NOT NULL,
        tx_hash TEXT NOT NULL,
        sender TEXT NOT NULL,
        recipient TEXT NOT NULL,
        value NUMERIC(78, 0) NOT NULL,
        PRIMARY KEY (block_number, log_index)
    )
""")
```

`IF NOT EXISTS` deja ejecutarlo en cada arranque del indexador.

**Abre** `src/store.py`, resuelve `create_schema` y ejecuta `bash test.sh`.

**Verifica**: `1 passed, 4 failed`. El test crea las tablas dos veces, guarda un `2**256 - 1`
y lo lee igual, comprueba que una transferencia de un bloque que no existe da
`ForeignKeyViolation` y que borrar el bloque borra su transferencia. Prueba a cambiar
`NUMERIC(78, 0)` por `BIGINT`: el test falla con `NumericValueOutOfRange: bigint out of range`.
Déjalo como estaba.

## Paso 2: Guardar sin duplicar

**Por qué**: el indexador puede repetir un tramo (se reinició, falló a mitad). Guardar dos
veces lo mismo tiene que dejar lo mismo.

```python
with conn.cursor() as cur:
    cur.executemany(
        "INSERT INTO blocks (number, hash) VALUES (%s, %s) ON CONFLICT DO NOTHING",
        [(b.number, b.hash) for b in blocks],
    )
    cur.executemany(
        "INSERT INTO transfers (block_number, log_index, tx_hash, sender, recipient, value)"
        " VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING",
        [(t.block_number, t.log_index, t.tx_hash, t.sender, t.recipient, t.value) for t in transfers],
    )
```

`executemany` ejecuta la misma sentencia con cada tupla de valores. Los bloques van primero:
las transferencias los apuntan.

**Verifica**: `test_paso_2_guardar_dos_veces PASSED`: tras guardar dos veces, una fila en cada
tabla.

## Paso 3: El saldo, en SQL

**Por qué**: la base de datos suma más rápido que traer todas las filas a Python, y la
dirección llega de fuera: va con parámetro.

```python
row = conn.execute(
    "SELECT COALESCE(SUM(value) FILTER (WHERE recipient = %(a)s), 0)"
    " - COALESCE(SUM(value) FILTER (WHERE sender = %(a)s), 0) FROM transfers",
    {"a": account.lower()},
).fetchone()
return int(row[0])
```

`%(a)s` es un parámetro con nombre: el mismo valor en dos sitios.

**Verifica**: `test_paso_3_saldo PASSED`: la cuenta 1 recibe 100 y envía 30, saldo 70 (también
escrita en mayúsculas), y una cuenta desconocida, 0. Las dos últimas cuentas llevan una comilla:
`x' OR '1'='1` y `o'brien`. Prueba a meter la cuenta en el SQL con una f-string
(`recipient = '{a}'`): el test falla con
`psycopg.errors.SyntaxError: syntax error at or near "brien"`. La comilla del texto cerró la
del SQL: quien escribe la cuenta escribe la consulta. Déjalo como estaba.

## Paso 4: Ponerse al día

**Por qué**: es la vuelta del indexador: desde donde lo dejó hasta la cabeza, todo o nada.

```python
last = conn.execute("SELECT MAX(number) FROM blocks").fetchone()[0]
start = 0 if last is None else last + 1
end = get_block(url, int(rpc(url, "eth_blockNumber", []), 16))
if start > end.number:
    return 0
transfers = fetch_transfers(url, token, start, end.number, chunk=1000)
blocks = [Block(t.block_number, t.block_hash, "") for t in transfers] + [end]
with conn.transaction():
    save(conn, blocks, transfers)
return len(transfers)
```

- El cursor es el bloque más alto guardado: no hace falta otra tabla.
- Se guardan los bloques con transferencias (con el hash que trae el log) y el último, pedido
  **antes** que los logs (teoría 04). `parent_hash` no se guarda: queda vacío.

**Verifica**: `test_paso_4_sincronizar PASSED`. La primera vuelta guarda 3 transferencias y 3
bloques; la segunda, 0. Tras una transferencia nueva, guarda 1. Al final el test hace fallar el
guardado justo después de los bloques: con la transacción, no queda ni el bloque nuevo. Prueba a
quitar el `with conn.transaction():` (y la sangría de `save`): el test falla con
`assert (5, 4) == (4, 4)`, un bloque guardado sin su transferencia. Déjalo como estaba.

## Paso 5: Deshacer un reorg

**Por qué**: sin este paso, una transferencia que desapareció de la cadena sigue contando en
el saldo para siempre.

```python
removed = 0
for number, saved_hash in conn.execute("SELECT number, hash FROM blocks ORDER BY number DESC"):
    block = rpc(url, "eth_getBlockByNumber", [hex(number), False])
    if block is not None and block["hash"] == saved_hash:
        break
    conn.execute("DELETE FROM blocks WHERE number = %s", [number])
    removed += 1
return removed
```

Con `rpc` directamente y no con `get_block`: tras un reorg, el bloque puede no existir, y
`rpc` devuelve `None`.

**Verifica**: `5 passed`. El test indexa una transferencia de 10 BCT a la cuenta 5 en el bloque
4, vuelve al `evm_snapshot` anterior y manda otra, de 3 BCT desde la cuenta 2: el bloque 4 es
otro. `rollback_reorg` borra 1 bloque; la segunda llamada, 0. Tras `sync`, la cuenta 5 tiene
3 BCT, no 13, y la cuenta 1 vuelve a tener 100.

## Qué aprendiste

- `NUMERIC(78, 0)` guarda un `uint256` exacto; la clave primaria de un log impide contarlo dos
  veces.
- `ON CONFLICT DO NOTHING` hace repetible la escritura; una transacción la hace de todo o nada.
- Los valores van siempre con `%s` o `%(nombre)s`.
- Un reorg se deshace borrando bloques del último hacia atrás, y las claves foráneas borran lo
  demás.

---

| Anterior | Actual | Siguiente |
| -------- | ------ | --------- |
| [← Ejercicio 01 — Eventos desde Python](../ejercicio-01-eventos-desde-python/README.md) | **Ejercicio 02 — Guardar en PostgreSQL** | [Ejercicio 03 — API con FastAPI →](../ejercicio-03-api-con-fastapi/README.md) |
