"""Guardar en PostgreSQL las transferencias del Token y seguir a la cadena aunque cambie."""

import psycopg

from chain import Block, Transfer, fetch_transfers, get_block, rpc


# PASO 1: crear las tablas de bloques y transferencias, si no existen.
# Borra la línea del raise y descomenta las líneas que empiezan con `#> `.
def create_schema(conn: psycopg.Connection) -> None:
    raise NotImplementedError("TODO: Paso 1")
    #> conn.execute("""
    #>     CREATE TABLE IF NOT EXISTS blocks (
    #>         number BIGINT PRIMARY KEY,
    #>         hash TEXT NOT NULL
    #>     )
    #> """)
    #> conn.execute("""
    #>     CREATE TABLE IF NOT EXISTS transfers (
    #>         block_number BIGINT NOT NULL REFERENCES blocks (number) ON DELETE CASCADE,
    #>         log_index INTEGER NOT NULL,
    #>         tx_hash TEXT NOT NULL,
    #>         sender TEXT NOT NULL,
    #>         recipient TEXT NOT NULL,
    #>         value NUMERIC(78, 0) NOT NULL,
    #>         PRIMARY KEY (block_number, log_index)
    #>     )
    #> """)


# PASO 2: guardar bloques y transferencias; lo que ya estaba guardado se ignora.
def save(conn: psycopg.Connection, blocks: list[Block], transfers: list[Transfer]) -> None:
    raise NotImplementedError("TODO: Paso 2")
    #> with conn.cursor() as cur:
    #>     cur.executemany(
    #>         "INSERT INTO blocks (number, hash) VALUES (%s, %s) ON CONFLICT DO NOTHING",
    #>         [(b.number, b.hash) for b in blocks],
    #>     )
    #>     cur.executemany(
    #>         "INSERT INTO transfers (block_number, log_index, tx_hash, sender, recipient, value)"
    #>         " VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING",
    #>         [(t.block_number, t.log_index, t.tx_hash, t.sender, t.recipient, t.value) for t in transfers],
    #>     )


# PASO 3: el saldo de `account` según las transferencias guardadas.
def balance_of(conn: psycopg.Connection, account: str) -> int:
    raise NotImplementedError("TODO: Paso 3")
    #> row = conn.execute(
    #>     "SELECT COALESCE(SUM(value) FILTER (WHERE recipient = %(a)s), 0)"
    #>     " - COALESCE(SUM(value) FILTER (WHERE sender = %(a)s), 0) FROM transfers",
    #>     {"a": account.lower()},
    #> ).fetchone()
    #> return int(row[0])


# PASO 4: indexar desde el bloque siguiente al último guardado hasta la cabeza de la cadena,
#   todo o nada. Guarda los bloques con transferencias y el último. Devuelve cuántas
#   transferencias nuevas guardó.
def sync(conn: psycopg.Connection, url: str, token: str) -> int:
    raise NotImplementedError("TODO: Paso 4")
    #> last = conn.execute("SELECT MAX(number) FROM blocks").fetchone()[0]
    #> start = 0 if last is None else last + 1
    #> end = get_block(url, int(rpc(url, "eth_blockNumber", []), 16))
    #> if start > end.number:
    #>     return 0
    #> transfers = fetch_transfers(url, token, start, end.number, chunk=1000)
    #> blocks = [Block(t.block_number, t.block_hash, "") for t in transfers] + [end]
    #> with conn.transaction():
    #>     save(conn, blocks, transfers)
    #> return len(transfers)


# PASO 5: deshacer los bloques guardados que ya no están en la cadena, del último hacia atrás.
#   Devuelve cuántos bloques borró.
def rollback_reorg(conn: psycopg.Connection, url: str) -> int:
    raise NotImplementedError("TODO: Paso 5")
    #> removed = 0
    #> for number, saved_hash in conn.execute("SELECT number, hash FROM blocks ORDER BY number DESC"):
    #>     block = rpc(url, "eth_getBlockByNumber", [hex(number), False])
    #>     if block is not None and block["hash"] == saved_hash:
    #>         break
    #>     conn.execute("DELETE FROM blocks WHERE number = %s", [number])
    #>     removed += 1
    #> return removed
