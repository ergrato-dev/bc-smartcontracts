"""API de solo lectura sobre lo que guardó el indexador: estado, saldos y transferencias."""

import os
from collections.abc import Iterator
from typing import Annotated

import psycopg
from fastapi import Depends, FastAPI, HTTPException, Path, Query
from fastapi.middleware.cors import CORSMiddleware
from psycopg.rows import dict_row
from pydantic import BaseModel

from store import balance_of

app = FastAPI(title="Indexador del Token")

# PASO 5: solo la página de la semana 18 (en http://localhost:5173) puede leer la API desde
#   el navegador, y solo con GET.
# Descomenta las líneas que empiezan con `#> `.
#> app.add_middleware(CORSMiddleware, allow_origins=["http://localhost:5173"], allow_methods=["GET"])


# ¿Qué? Una conexión por petición, en autocommit, que se cierra al responder.
# ¿Para qué? FastAPI la pasa a cada ruta que declara un parámetro `Conn` (inyección de dependencias).
def get_conn() -> Iterator[psycopg.Connection]:
    with psycopg.connect(os.environ["DATABASE_URL"], autocommit=True) as conn:
        yield conn


Conn = Annotated[psycopg.Connection, Depends(get_conn)]
# ¿Qué? Una dirección: 0x y 40 caracteres hexadecimales. Si no lo es, FastAPI responde 422.
Address = Annotated[str, Path(pattern="^0x[0-9a-fA-F]{40}$")]
TxHash = Annotated[str, Path(pattern="^0x[0-9a-fA-F]{64}$")]


class Status(BaseModel):
    last_block: int | None


class Balance(BaseModel):
    account: str
    balance: str


class TransferOut(BaseModel):
    block_number: int
    log_index: int
    tx_hash: str
    sender: str
    recipient: str
    value: str


# PASO 1: el último bloque indexado, o `None` si todavía no hay ninguno.
# Borra la línea del raise y descomenta las líneas que empiezan con `#> `.
@app.get("/status")
def status(conn: Conn) -> Status:
    raise NotImplementedError("TODO: Paso 1")
    #> last = conn.execute("SELECT MAX(number) FROM blocks").fetchone()[0]
    #> return Status(last_block=last)


# PASO 2: el saldo de una cuenta, como texto.
@app.get("/balances/{account}")
def balance(conn: Conn, account: Address) -> Balance:
    raise NotImplementedError("TODO: Paso 2")
    #> return Balance(account=account.lower(), balance=str(balance_of(conn, account)))


# PASO 3: las transferencias, de la más nueva a la más antigua, por páginas; si llega
#   `account`, solo las que la envían o la reciben.
@app.get("/transfers")
def transfers(
    conn: Conn,
    account: Annotated[str | None, Query(pattern="^0x[0-9a-fA-F]{40}$")] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> list[TransferOut]:
    raise NotImplementedError("TODO: Paso 3")
    #> rows = conn.cursor(row_factory=dict_row).execute(
    #>     "SELECT block_number, log_index, tx_hash, sender, recipient, value::text AS value FROM transfers"
    #>     " WHERE %(account)s::text IS NULL OR %(account)s IN (sender, recipient)"
    #>     " ORDER BY block_number DESC, log_index DESC LIMIT %(limit)s OFFSET %(offset)s",
    #>     {"account": account and account.lower(), "limit": limit, "offset": offset},
    #> ).fetchall()
    #> return [TransferOut(**row) for row in rows]


# PASO 4: una transferencia por su hash de transacción, o 404 si no está indexada.
@app.get("/transfers/{tx_hash}")
def transfer(conn: Conn, tx_hash: TxHash) -> TransferOut:
    raise NotImplementedError("TODO: Paso 4")
    #> row = conn.cursor(row_factory=dict_row).execute(
    #>     "SELECT block_number, log_index, tx_hash, sender, recipient, value::text AS value"
    #>     " FROM transfers WHERE tx_hash = %s ORDER BY log_index LIMIT 1",
    #>     [tx_hash.lower()],
    #> ).fetchone()
    #> if row is None:
    #>     raise HTTPException(status_code=404, detail="Transferencia no indexada")
    #> return TransferOut(**row)
