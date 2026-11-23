"""Tests del indexador. No los modifiques."""

import psycopg
import pytest

from chain import get_logs, head, rpc
from conftest import ACCOUNT_1, ACCOUNT_2, register, retire
from indexer import (
    REGISTERED_TOPIC, RETIRED_TOPIC, Registered, Retired,
    apply, create_schema, decode, decode_label, rollback_reorg, sync,
)


def items(conn):
    return conn.execute(
        "SELECT id, label, retired_block IS NULL FROM items ORDER BY id"
    ).fetchall()


def logs(url, registry):
    return get_logs(url, registry, [REGISTERED_TOPIC, RETIRED_TOPIC], 0, head(url))


def test_create_schema(db):
    create_schema(db)
    create_schema(db)
    db.execute("INSERT INTO blocks VALUES (1, '0xaa'), (2, '0xbb')")
    db.execute("INSERT INTO items VALUES (%s, '0x01', 'a', 1, 2)", [2**256 - 1])
    with pytest.raises(psycopg.errors.ForeignKeyViolation):
        db.execute("INSERT INTO items VALUES (7, '0x01', 'b', 3, NULL)")
    db.execute("DELETE FROM blocks WHERE number = 2")
    assert items(db) == [(2**256 - 1, "a", True)]
    db.execute("DELETE FROM blocks WHERE number = 1")
    assert items(db) == []


def test_decode_label():
    def data(label: bytes) -> str:
        return "0x" + (32).to_bytes(32).hex() + len(label).to_bytes(32).hex() + label.hex().ljust(64, "0")

    assert decode_label(data(b"hola")) == "hola"
    assert decode_label(data("cañón".encode())) == "cañón"
    assert decode_label(data(b"\xff\xfeok")) == "\ufffd\ufffdok"
    assert decode_label(data(b"a\x00b")) == "a\ufffdb"


def test_decode(url, registry):
    register(url, registry, ACCOUNT_1, b"<b>hola</b>")
    retire(url, registry, ACCOUNT_1, 1)
    registered, retired = [decode(log) for log in logs(url, registry)]
    assert isinstance(registered, Registered) and isinstance(retired, Retired)
    assert (registered.id, registered.registrant, registered.label) == (1, ACCOUNT_1, "<b>hola</b>")
    assert (retired.id, retired.block_number) == (1, registered.block_number + 1)
    assert retired.block_hash == rpc(url, "eth_getBlockByNumber", [hex(retired.block_number), False])["hash"]


def test_apply(db):
    create_schema(db)
    db.execute("INSERT INTO blocks VALUES (5, '0xaa'), (6, '0xbb')")
    events = [Registered(5, "0xaa", 1, ACCOUNT_1, "uno"), Registered(5, "0xaa", 2, ACCOUNT_2, "dos"), Retired(6, "0xbb", 1)]
    apply(db, events)
    apply(db, events)
    assert items(db) == [(1, "uno", False), (2, "dos", True)]


def test_rollback_reorg(db, url, registry):
    create_schema(db)
    register(url, registry, ACCOUNT_1, b"uno")
    sync(db, url, registry)
    fork = rpc(url, "evm_snapshot", [])
    retire(url, registry, ACCOUNT_1, 1)
    register(url, registry, ACCOUNT_2, b"dos")
    sync(db, url, registry)
    assert items(db) == [(1, "uno", False), (2, "dos", True)]

    # Reorg: los dos últimos bloques desaparecen y entra otro en su lugar.
    rpc(url, "evm_revert", [fork])
    register(url, registry, ACCOUNT_2, b"otro")
    assert rollback_reorg(db, url) == 2
    assert items(db) == [(1, "uno", True)]
    assert rollback_reorg(db, url) == 0


def test_sync(db, url, registry):
    create_schema(db)
    start = int(rpc(url, "eth_blockNumber", []), 16)
    register(url, registry, ACCOUNT_1, b"uno")
    register(url, registry, ACCOUNT_2, b"a\x00b")
    assert sync(db, url, registry, start_block=start, max_range=1) == 0
    assert db.execute("SELECT MIN(number) FROM blocks").fetchone()[0] == start
    assert sync(db, url, registry, confirmations=1) == 1
    assert items(db) == [(1, "uno", True)]
    assert sync(db, url, registry) == 1
    assert sync(db, url, registry) == 0
    assert items(db) == [(1, "uno", True), (2, "a\ufffdb", True)]

    fork = rpc(url, "evm_snapshot", [])
    retire(url, registry, ACCOUNT_1, 1)
    assert sync(db, url, registry) == 1
    rpc(url, "evm_revert", [fork])
    register(url, registry, ACCOUNT_1, b"tres")
    assert sync(db, url, registry) == 1
    assert items(db) == [(1, "uno", True), (2, "a\ufffdb", True), (3, "tres", True)]
