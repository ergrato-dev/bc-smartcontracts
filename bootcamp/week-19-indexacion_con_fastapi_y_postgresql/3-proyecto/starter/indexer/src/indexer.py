"""Indexar las altas y las bajas del Registry en PostgreSQL, deshaciendo los reorgs."""

from dataclasses import dataclass
from typing import Any

import psycopg

from chain import get_block, get_logs, head

# ¿Qué? topic0 de los dos eventos del Registry, de `cast sig-event "<firma>"`.
REGISTERED_TOPIC = "0x6e25be3619376e564cfe010b907906379faef975c78ba0112d80e039a612a04f"
RETIRED_TOPIC = "0x12af7a600581d3fc0a4be61116ea62205788506780cf4a4c36acf8bfc955dbbc"


@dataclass(frozen=True)
class Registered:
    """`ItemRegistered(uint256 indexed id, address indexed registrant, string label)`."""

    block_number: int
    block_hash: str
    id: int
    registrant: str
    label: str


@dataclass(frozen=True)
class Retired:
    """`ItemRetired(uint256 indexed id, address indexed registrant)`."""

    block_number: int
    block_hash: str
    id: int


# TODO: create_schema(conn) -> None
#   Crea, si no existen, `blocks (number, hash)` y `items (id, registrant, label,
#   registered_block, retired_block)`. Pista: el id es un uint256 (NUMERIC(78, 0)); los dos
#   bloques de `items` apuntan a `blocks`: al borrar un bloque, el alta desaparece
#   (ON DELETE CASCADE) y la baja se deshace (ON DELETE SET NULL). Activo = sin baja.
def create_schema(conn: psycopg.Connection) -> None:
    raise NotImplementedError("TODO: create_schema")


# TODO: decode_label(data) -> str
#   La etiqueta del campo `data` de un log de ItemRegistered: 32 bytes con la posición del
#   texto, 32 con su longitud y los bytes del texto. Pista: `bytes.fromhex` e
#   `int.from_bytes`. Cualquiera registra etiquetas: bytes que no son UTF-8 y el byte 0x00
#   (PostgreSQL no lo admite en TEXT) se cambian por "�".
def decode_label(data: str) -> str:
    raise NotImplementedError("TODO: decode_label")


# TODO: decode(log) -> Registered | Retired
#   Pista: el topic0 dice qué evento es; el id va en topics[1] y el registrant, en los
#   últimos 40 caracteres de topics[2].
def decode(log: dict[str, Any]) -> Registered | Retired:
    raise NotImplementedError("TODO: decode")


# TODO: apply(conn, events) -> None
#   Aplica los eventos en orden: un alta inserta el recurso (si ya estaba, nada) y una baja
#   apunta su retired_block. Aplicar dos veces lo mismo deja lo mismo.
def apply(conn: psycopg.Connection, events: list[Registered | Retired]) -> None:
    raise NotImplementedError("TODO: apply")


# TODO: rollback_reorg(conn, url) -> int
#   Borra, del último hacia atrás, los bloques guardados cuyo hash ya no es el de la cadena
#   (o que la cadena ya no tiene). Para en el primero que coincide. Devuelve cuántos borró.
def rollback_reorg(conn: psycopg.Connection, url: str) -> int:
    raise NotImplementedError("TODO: rollback_reorg")


# TODO: sync(conn, url, registry, start_block=0, confirmations=0, max_range=1000) -> int
#   En una sola transacción: deshace el reorg si lo hay e indexa desde el bloque siguiente al
#   último guardado (o `start_block`) hasta `head - confirmations`, como mucho `max_range`
#   bloques. Guarda los bloques con eventos (su hash viene en el log) y el último del tramo,
#   pedido antes que los logs. Devuelve cuántos eventos guardó.
def sync(
    conn: psycopg.Connection, url: str, registry: str,
    start_block: int = 0, confirmations: int = 0, max_range: int = 1000,
) -> int:
    raise NotImplementedError("TODO: sync")
