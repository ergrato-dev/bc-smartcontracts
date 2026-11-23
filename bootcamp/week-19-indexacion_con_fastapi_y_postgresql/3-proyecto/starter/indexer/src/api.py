"""La API de solo lectura de los recursos indexados."""

import os
from collections.abc import Iterator
from typing import Annotated

import psycopg
from fastapi import Depends, FastAPI, HTTPException, Path, Query
from fastapi.middleware.cors import CORSMiddleware
from psycopg.rows import dict_row
from pydantic import BaseModel

app = FastAPI(title="Indexador del protocolo")
# ¿Qué? Solo la página de la semana 18 lee la API desde el navegador, y solo con GET.
app.add_middleware(CORSMiddleware, allow_origins=["http://localhost:5173"], allow_methods=["GET"])


def get_conn() -> Iterator[psycopg.Connection]:
    with psycopg.connect(os.environ["DATABASE_URL"], autocommit=True) as conn:
        yield conn


Conn = Annotated[psycopg.Connection, Depends(get_conn)]
Address = Annotated[str, Query(pattern="^0x[0-9a-fA-F]{40}$")]
ItemId = Annotated[int, Path(ge=1, le=2**256 - 1)]

ITEM_COLUMNS = (
    "id::text AS id, registrant, label, retired_block IS NULL AS active, registered_block"
)


class Status(BaseModel):
    last_block: int | None


class Item(BaseModel):
    id: str
    registrant: str
    label: str
    active: bool
    registered_block: int


# TODO: GET /status -> Status
#   El último bloque indexado, o None si todavía no hay ninguno.
@app.get("/status")
def status(conn: Conn) -> Status:
    raise NotImplementedError("TODO: status")


# TODO: GET /items -> list[Item]
#   Los recursos por orden de id, por páginas, filtrados por `registrant` y por `active` si
#   llegan. Pista: parámetros con nombre (`%(registrant)s`) y `%(x)s::text IS NULL OR ...`
#   para un filtro opcional. Ordena por `items.id`: `id` a secas es la columna de texto del
#   SELECT, y "10" va antes que "9".
@app.get("/items")
def list_items(
    conn: Conn,
    registrant: Address | None = None,
    active: bool | None = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> list[Item]:
    raise NotImplementedError("TODO: list_items")


# TODO: GET /items/{item_id} -> Item
#   Un recurso por su id, o 404 con el detalle "Recurso no indexado".
@app.get("/items/{item_id}")
def get_item(conn: Conn, item_id: ItemId) -> Item:
    raise NotImplementedError("TODO: get_item")
